#import "/templates/lib.typ": RR, conf, definition, note, theorem
#import "@preview/fletcher:0.5.8": diagram, node, edge

#set document(
  title: "Mixture of Experts for Transformer FFNs",
  author: "Abel Zhan",
)

#show: conf

= Scope and Dense-FFN Context <scope>

This note describes the common Transformer design in which a sparse
mixture-of-experts (MoE) layer replaces a feed-forward network (FFN). It is not
a definition of every historical MoE model. The companion
#link("../DeepSeek/DeepSeek_Architecture.pdf")[DeepSeek Architecture] note
keeps the DeepSeek-specific architecture map, while
#link("../DeepSeek/DeepSeek_Systems.pdf")[DeepSeek Systems] covers the
communication and serving mechanisms that make routed models practical.

For a token representation $x_t in RR^d$, a dense FFN applies one learned
transformation to every token, for example

$ op("FFN")(x_t) = W_2 phi(W_1 x_t). $

A sparse MoE keeps a pool of FFN-like experts and executes only a selected
subset for each token. This can raise total parameter capacity without making
every token execute every expert. The sparsely gated formulation introduced the
modern large-scale form of this idea @shazeer2017. It does not make storage,
communication, or optimizer state disappear; those costs are separated below.

#note[
  This note distinguishes a paper's reported architecture or experiment, a
  particular repository implementation, and a derivation made here. The
  derivations and finite examples in this note depend on their stated
  assumptions and inputs. They do not establish generalization,
  specialization, throughput, or controller convergence.
]

= Sparse MoE Layer <sparse-moe-layer>

== Routing objects <routing-objects>

Let $G$ be one routing-statistics group containing $T$ tokens. Let $N$ be the
number of routed experts, $K$ the number requested from them for each token,
$N_s$ the number of shared experts, and $K_s <= N_s$ the number of shared
expert paths active for each token. In an always-on shared path, $K_s = N_s$.
For a DeepSeek-style accounting mapping, $K_r = K = |S_t|$ names only the
routed request count; $K_s$ does not change that support.

The router is a learned function $g_(theta_r)$ that maps the token representation
$x_t$ to a score vector $a_t = g_(theta_r)(x_t) in RR^N$. Its $i$-th component
$a_(t,i)$ is a scalar score for assigning token $t$ to routed expert $i$, not
an expert output or a fusion weight. For example, a linear router computes
$a_t = W_r x_t + b_r$, where $W_r in RR^(N times d)$ and $b_r in RR^N$ are
trainable parameters. The linear form is an example, not a requirement for
every MoE. In the softmax gate analyzed below, these scores are the
unnormalized logits. The scores determine the requested support

$ S_t = op("TopK")_i (a_(t,i)), quad |S_t| = K. $

The fusion coefficient $w_(t,i)$ is separate from the selection score. Here it
denotes a weight before capacity filtering. A capacity or dispatch policy then
supplies an acceptance mask $m_(t,i) in {0, 1}$: one accepts a requested
token-expert pair, while zero rejects it. With routed expert outputs
$E_i (x_t)$ and a shared-branch output $H_t$, retaining the surviving weights
gives

$ y_t = H_t + sum_(i in S_t) m_(t,i) w_(t,i) E_i (x_t). $

An expert can remain in the requested support $S_t$ even when its path for
token $t$ is rejected by the later policy, so the mask does not duplicate the
restriction in the sum. If every requested pair is accepted, the mask can be
omitted. Equivalent accepted-support and renormalized forms are given in
@post-drop-weights.

The shared branch may have its own width, gate, and output scaling. Its form is
model-specific, so the equation does not imply that every shared expert is
unweighted or has the same width as a routed expert. The active-expert count
$K_"active" = K_r + K_s$ is therefore only a count ledger. If an external
configuration fixes that count, call it $K_"total" = K_"active"$ rather than
redefining $K$; it proxies active parameters or compute only when the paths
have the same relevant structure and width. Here $y_t$ denotes only the MoE
branch output; @moe-residual places it inside a complete Transformer sublayer
with a residual connection.

For accounting, requested and accepted expert loads are different:

$ R_i = sum_(t in G) 1_(i in S_t), quad
  A_i = sum_(t in G) 1_(i in S_t) m_(t,i). $

The requested fraction is $f_i = R_i / (T K)$ when every token asks for $K$
routed experts. The accepted fraction instead uses $A_i$. A balance statistic
must say which one it uses and which tokens belong to $G$.

#definition(title: "Selection, fusion, and acceptance")[
  Selection scores choose the discrete support $S_t$. Fusion weights scale the
  outputs of already selected experts. An acceptance mask represents a later
  capacity or dispatch decision. A shared branch is outside the routed support.
  Treating these four objects as one "gate" hides different gradients and
  different failure modes.
]

As @moe-single-token-forward shows, requested support is distinct from later
acceptance and from the weights used to combine accepted expert outputs.

#let moe-forward-node(pos, name, body, fill: rgb("#EAF1F4")) = node(
  pos,
  align(center)[
    #set text(size: 8.2pt)
    #body
  ],
  name: name,
  width: 19mm,
  inset: 3pt,
  corner-radius: 2pt,
  stroke: 0.7pt + rgb("#315A67"),
  fill: fill,
)

#figure(
  align(center)[
    #diagram(
      cell-size: (18mm, 8mm),
      spacing: (3mm, 5mm),
      edge-stroke: 0.65pt + rgb("#37474F"),
      moe-forward-node((0, 0), <moe-forward-input>, [$x_t$], fill: rgb("#F5EEE5")),
      moe-forward-node((1, 0), <moe-forward-router>, [Router / gate]),
      moe-forward-node((2, 0), <moe-forward-scores>, [selection scores\ $a_(t,i)$], fill: rgb("#E7F3EA")),
      moe-forward-node((3, 0), <moe-forward-support>, [requested support\ $S_t = op("TopK")_i (a_(t,i))$], fill: rgb("#E7F3EA")),
      moe-forward-node((4, 0), <moe-forward-mask>, [capacity\ / dispatch\ mask $m_(t,i)$], fill: rgb("#FFF1D9")),
      moe-forward-node((5, 0), <moe-forward-accepted>, [accepted route\ $i in S_t$, $m_(t,i) = 1$], fill: rgb("#FFF1D9")),
      moe-forward-node((6, 0), <moe-forward-expert>, [routed expert\ $E_i (x_t)$], fill: rgb("#F1EAF4")),
      moe-forward-node((2, 1), <moe-forward-weights>, [fusion weights\ $w_(t,i)$], fill: rgb("#E6F2F4")),
      moe-forward-node((5, 1), <moe-forward-combine>, [weighted routed\ contribution\ $m_(t,i) w_(t,i) E_i (x_t)$], fill: rgb("#E6F2F4")),
      moe-forward-node((6, 1), <moe-forward-output>, [$y_t$], fill: rgb("#F5EEE5")),
      moe-forward-node((3, 2), <moe-forward-shared>, [optional shared branch\ $H_t$ (or $0$)], fill: rgb("#F5EEE5")),
      moe-forward-node((4, 2), <moe-forward-drop>, [dropped pair\ $m_(t,i) = 0$\ contribution $0$], fill: rgb("#FCE8E6")),
      edge(<moe-forward-input>, <moe-forward-router>, "->"),
      edge(<moe-forward-router>, <moe-forward-scores>, "->"),
      edge(<moe-forward-scores>, <moe-forward-support>, "->"),
      edge(<moe-forward-support>, <moe-forward-mask>, "->"),
      edge(<moe-forward-mask>, <moe-forward-accepted>, "->"),
      edge(<moe-forward-accepted>, <moe-forward-expert>, "->"),
      edge(<moe-forward-router>, <moe-forward-weights>, "->"),
      edge(<moe-forward-weights>, <moe-forward-combine>, "->"),
      edge(<moe-forward-mask>, <moe-forward-combine>, "->"),
      edge(<moe-forward-expert>, <moe-forward-combine>, "->"),
      edge(<moe-forward-combine>, <moe-forward-output>, "->"),
      edge(<moe-forward-input>, (0, 2), <moe-forward-shared>, "->"),
      edge(<moe-forward-shared>, (3, 3), (6, 3), <moe-forward-output>, "->"),
      edge(<moe-forward-mask>, <moe-forward-drop>, "->", "dashed"),
    )
  ],
  caption: [Single-token generic MoE forward flow.],
) <moe-single-token-forward>

Selection chooses the requested support; fusion weights are a separate quantity,
and the later mask decides which requested pairs contribute. The shown post-drop
convention leaves $w_(t,i)$ unchanged; rerouting or renormalization are other
implementation choices. The optional shared branch may be $0$, so a dropped
pair contributes $0$ without forcing the full MoE branch output $y_t$ to be $0$.
The figure ends at that branch output; the surrounding normalization and
residual addition are made explicit in @moe-residual.

== Common gate variants <gate-variants>

A normalized selected-softmax gate first fixes $S_t$ and normalizes only within
that support:

$ w_(t,i) = frac(exp(a_(t,i)),
  sum_(j in S_t) exp(a_(t,j))), quad i in S_t. $

When no selected output is dropped, these weights sum to one. If a later mask
rejects a selected pair, an implementation must state whether it leaves the
surviving weights unchanged, renormalizes them, reroutes the token, or sends it
through another path. There is no universal post-drop convention;
@post-drop-weights gives explicit formulas and pinned implementation examples.

A different top-1 form selects $s = op("Top1")(a_t)$ from a full softmax
$p_t = op("softmax")(a_t)$ and combines the selected expert as

$ y_t^r = p_(t,s) E_s (x_t). $

Here $p_(t,s)$ is generally not one. Switch Transformer uses this distinction:
its top-1 route retains the full-softmax probability for the selected expert
@switch2022. It therefore has a different local gate derivative from normalized
selected top-1 routing.

The original sparsely-gated MoE also uses noisy scores to form differentiable
expected-load estimates; noise is not merely an exploration device
@shazeer2017. Which score appears in selection, expected load, and output
fusion is an implementation decision that must be named.

== Shared experts and source boundaries <shared-branch>

DeepSeekMoE isolates a fixed shared-expert path while routing the remaining
conditional work through fine-grained experts @deepseekmoe2024. That is one
architecture instance, not a rule that all MoEs have shared experts. The
case studies record its reported design separately from the generic equations
above. Model-specific details remain in
#link("../DeepSeek/DeepSeek_Architecture.pdf")[DeepSeek Architecture].

== Residual connection around the MoE branch <moe-residual>

A Transformer FFN-MoE commonly keeps the residual connection around the FFN
sublayer it replaces. Routing and fusion define the branch transformation;
they do not by themselves specify the surrounding residual architecture.

Let $h_t$ be the hidden state entering the FFN/MoE sublayer, after the
preceding attention sublayer. A basic Pre-Norm wrapper, omitting dropout and
additional residual scaling, computes

$ x_t = op("Norm")(h_t), quad
  y_t = op("MoE")(x_t), quad
  h_t^"out" = h_t + y_t. $

Here $op("Norm")$ denotes the model's normalization, such as LayerNorm or
RMSNorm. Retaining surviving routed weights gives the expanded expression

$ h_t^"out" = h_t + H_t
  + sum_(i in S_t) m_(t,i) w_(t,i) E_i (x_t). $

The three additive terms have different roles: $h_t$ is the identity shortcut,
$H_t$ is a learned shared-expert update, and the sum is the conditional
routed-expert update. The shared branch does not substitute for the identity
shortcut. In this Pre-Norm form, experts receive the normalized $x_t$, while
the shortcut preserves the unnormalized sublayer input $h_t$. This input is
the current hidden state, not the model's initial token embedding.

With post-capacity renormalization, replace $m_(t,i) w_(t,i)$ by the final
coefficient $overline(w)_(t,i)$ from @post-drop-weights; the outer residual still
adds $h_t$. If every routed pair is rejected, $y_t = H_t$ and
$h_t^"out" = h_t + H_t$. With no shared branch, $H_t = 0$, so the basic
Pre-Norm sublayer returns $h_t$ in this all-rejected case.

A basic Post-Norm wrapper instead has

$ h_t^"out" = op("Norm")(h_t + op("MoE")(h_t)). $

Its identity shortcut is added before normalization. If its whole MoE branch
is zero, the result is $op("Norm")(h_t)$, so an unchanged hidden state is
specific to the basic Pre-Norm case above. Other residual or normalization
layouts must be stated separately from the MoE routing definition.

= Parameters, Cost, and Capacity <cost-and-capacity>

== A consistent ledger <cost-ledger>

A sparse layer has several non-interchangeable cost quantities. Comparisons
should hold the dense baseline, hidden width, sequence length, precision,
batch shape, and parallel layout fixed before quoting a ratio.

#table(
  columns: (1.55fr, 2.25fr, 3fr),
  table.header([Quantity], [What it counts], [Boundary]),
  [Total parameters], [All parameter scalars in the model], [A model-size count; per-token compute depends on the active paths.],
  [Active parameters], [Weights touched by one token under a stated route], [It depends on $K$, shared paths, and what the source calls active.],
  [Activations memory], [Token and intermediate tensors retained for forward/backward], [Checkpointing, microbatching, and parallelism change this independently of weights.],
  [KV cache], [Past attention keys and values retained for decoding], [It is an attention-state cost, not an FFN-MoE parameter count.],
  [Communication], [Dispatch and combine payloads, metadata, and synchronization], [Top-$K$ can require all-to-all movement and create stragglers.],
  [Training state], [Gradients, optimizer moments, master weights, and buffers], [It can dominate memory and is not inferred from active inference parameters.],
)

For matrix products, this note calls one multiply-accumulate one MAC and two
floating-point operations when reported as FLOPs. Router work, padding,
communication, and memory movement are not silently included in an FFN MAC
count. The useful statement is therefore conditional: with comparable expert
widths and no hidden implementation costs, executing $K$ routed experts costs
approximately $K$ expert evaluations per token, while storing the pool costs
approximately $N$ expert parameter sets.

== Capacity is an implementation policy <capacity-policy>

A fixed capacity can reserve at most

$ C = ceil(c T K / N) $

requested token-expert pairs for each routed expert, where $c$ is a capacity
factor and $T$ is the local statistics group. This describes one dispatch
policy, not a mathematical requirement of an MoE layer. With no capacity limit,
all requested pairs can be accepted. MegaBlocks is an example of dropless,
block-sparse execution rather than evidence that every implementation is
dropless @megablocks2023.

== Weights after capacity filtering <post-drop-weights>

For nonnegative pre-filter weights and route scale one, define the accepted
support and the sum of surviving weights as

$ S_t^"acc" = {i in S_t : m_(t,i) = 1}, quad
  q_t = sum_(j in S_t) m_(t,j) w_(t,j). $

*Keep surviving weights.* The routed branch is

$ y_t^r = sum_(i in S_t) m_(t,i) w_(t,i) E_i (x_t)
  = sum_(i in S_t^"acc") w_(t,i) E_i (x_t). $

The mask can therefore be absorbed into effective fusion weights, or replaced
by summing over the accepted support. Keeping it separate exposes which routes
were requested and which were accepted. If the original selected weights sum
to one, rejecting a positive-weight path makes the surviving sum less than one.

*Renormalize surviving weights.* Write $overline(w)_(t,i)$ for the final
post-capacity coefficient, defined by

$ overline(w)_(t,i) = cases(
    frac(m_(t,i) w_(t,i), q_t) & "if " q_t > 0,
    0 & "if " q_t = 0,
  ), quad i in S_t. $

The output becomes

$ y_t = H_t + sum_(i in S_t) overline(w)_(t,i) E_i (x_t). $

When $q_t > 0$, the surviving coefficients sum to one. This restores the sum
of coefficients, not the missing expert output or a guaranteed output norm.
When $q_t = 0$, including when every requested pair is rejected, the routed
branch is zero; the shared branch and any surrounding residual remain governed
by their own definitions.

The DeepSpeed implementation pinned at commit `32d51a1` demonstrates both
policies within one framework @deepspeed-moe-gates:

#table(
  columns: (1.25fr, 1.15fr, 3.6fr),
  table.header([Gate function], [Post-capacity normalization], [Behavior at the pinned revision]),
  [`top1gating`], [No], [Keep the original full-softmax probability on an accepted route; zero a rejected route.],
  [`top2gating`], [Yes], [Filter the two requested routes by capacity, then divide their surviving probabilities by their sum.],
  [`topkgating`], [Yes], [Update the requested-route mask using the capacity policy, then normalize the surviving probabilities per token.],
)

The two renormalizing functions clamp the denominator to machine epsilon to
avoid division by zero; if all paths are rejected, their numerators remain
zero. These are behaviors of the cited source revision, not universal rules
for top-1, top-2, or top-$K$ routing.

Normalization over the requested Top-$K$ set before capacity filtering does
not itself normalize the surviving weights afterward. For top-1, normalizing
an accepted single weight to one also removes its full-softmax scaling and
changes the local gate-weight derivative; see @top-one-gradient.

== Shared-path ledger example <shared-budget-ledger>

Keep shared paths outside the routed request and capacity calculations. Let
$K_r = K = |S_t| = 6$ and $K_s = 2$, so the active-expert count is
$K_"active" = K_r + K_s = 8$. For $T = N = 8$ and $c = 1$, the routed-expert
capacity is

$ C = ceil(1 dot 8 dot 6 / 8) = 6 $

and the routed request count is $T K_r = 48$, not $T K_"active" = 64$.
Capacity reserves routed token-expert pairs; it does not reserve a shared-path
slot. A count of eight can be compared directly to active parameter or compute
only when the shared and routed experts have matching relevant widths and
structures.

== Partial drop preserves other paths <partial-drop>

If one requested pair is rejected, the MoE branch output $y_t$ need not be zero.
For instance, take $H_t = 3$, selected routed weights $(0.4, 0.6)$, acceptance
mask $(1, 0)$, and routed outputs $(2, 7)$. Keeping the surviving weights
produces $3 + 0.4 dot 2 = 3.8$. Renormalizing after capacity filtering instead
gives final coefficients $(1, 0)$ and output $3 + 1 dot 2 = 5$. In both cases,
the rejected route is zero, while the accepted route and shared branch remain
present.

#note[
  Capacity acts on token-expert pairs, not on the abstract existence of a
  layer. The two outputs above follow the distinct weight conventions in
  @post-drop-weights; renormalization changes the accepted contribution but
  does not recover the rejected expert output. The complete Pre-Norm sublayer
  additionally adds the input residual $h_t$, as shown in @moe-residual.
]

= Task Gradients and Routing <task-gradients>

== Fixed-support derivative <fixed-support-gradient>

Consider only the routed branch $y_t^r = sum_(i in S_t) w_(t,i) E_i (x_t)$.
Assume a selected-softmax gate, a fixed support $S_t$, no ties at the selection
boundary, no drop, and route scale one. Let $cal(L)$ be the scalar task loss.

Here $a_(t,j)$ is the router-generated logit defined in @routing-objects, not
an independent trainable parameter. Its loss derivative measures whether a
small increase in this score would help or hurt the task loss. This is an
intermediate backpropagation step: the chain rule through $g_(theta_r)$ then
transmits the task gradient to the actual router parameters, such as $W_r$
and $b_r$. The following derivative concerns the continuous softmax fusion
weights on the fixed support, not differentiation of the discrete Top-K choice.

Define the upstream gradient at the routed output, written as a column vector,
by

$ delta = frac(partial cal(L), partial y_t^r) in RR^d. $

Its $k$-th component $delta_k = frac(partial cal(L), partial y_(t,k)^r)$
measures the loss sensitivity to output coordinate $k$. The later network and
task loss supply this vector during backpropagation. For this local gate
derivative, hold $x_t$ and every expert output $E_i (x_t)$ fixed.

#[
  #set math.equation(numbering: none)

  *1. Differentiate the selected softmax.* Write its normalizing denominator as

  $ Z_t = sum_(i in S_t) exp(a_(t,i)), quad
    w_(t,i) = frac(exp(a_(t,i)), Z_t), quad i in S_t. $

  For $j in S_t$, the fixed support gives
  $frac(partial Z_t, partial a_(t,j)) = exp(a_(t,j))$.
  Let $1_(i=j)$ equal one when $i = j$ and zero otherwise. The quotient rule gives

  $ frac(partial w_(t,i), partial a_(t,j))
    &= frac(1_(i=j) exp(a_(t,i)) Z_t - exp(a_(t,i)) exp(a_(t,j)), Z_t^2) \
    &= w_(t,i) (1_(i=j) - w_(t,j)). $

  The derivative accounts for both the expert's own numerator and the shared
  denominator. With more than one selected expert, increasing $a_(t,j)$ raises
  its own weight and lowers the other selected weights.

  *2. Differentiate the routed mixture.* Since the expert outputs are fixed,
  only their fusion weights contribute to this partial derivative:

  $ frac(partial y_t^r, partial a_(t,j))
    &= sum_(i in S_t) frac(partial w_(t,i), partial a_(t,j)) E_i (x_t) \
    &= sum_(i in S_t) w_(t,i) (1_(i=j) - w_(t,j)) E_i (x_t) \
    &= w_(t,j) E_j (x_t) - w_(t,j) sum_(i in S_t) w_(t,i) E_i (x_t) \
    &= w_(t,j) (E_j (x_t) - y_t^r). $

  This explains the subtraction: locally, increasing the score moves the
  mixture toward that expert's output relative to the current routed output.

  *3. Apply the loss chain rule.* Summing over the output coordinates gives
  the dot product with the upstream gradient:

  $ frac(partial cal(L), partial a_(t,j))
    &= sum_(k=1)^d frac(partial cal(L), partial y_(t,k)^r)
      frac(partial y_(t,k)^r, partial a_(t,j)) \
    &= delta^T frac(partial y_t^r, partial a_(t,j)). $
]

#block(breakable: false)[
  Substituting the routed-output derivative gives, for $j in S_t$,

  $ frac(partial cal(L), partial a_(t,j))
    = w_(t,j) delta^T (E_j (x_t) - y_t^r), $
]

and the local derivative through this gate is zero for an index outside $S_t$. The
subtracted term is the *routed* output. A shared branch can affect the upstream
$delta$ through the total model loss, but it must not be substituted for
$y_t^r$ in this softmax derivative.

Task-gradient availability does not by itself guarantee balanced expert load;
@load-balancing explains the separate load-management question.

With three scalar expert outputs $(0, 1, 2)$, $K = 2$, and logits
$(op("ln")(4), op("ln")(2), 0)$, the support is $(0, 1)$ and the selected
weights are $(2/3, 1/3)$. For scalar loss $cal(L) = y_t^r$, the gradient is
$(-2/9, 2/9, 0)$.

#theorem(title: "Local, not global, statement")[
  The fixed-support derivative applies only while the same no-tie support and
  gate definition remain active. It does not state that an unselected expert
  can never enter, that task learning cannot alter routing, or that an
  auxiliary objective is logically required for every MoE.
]

== Top-1 is gate-definition dependent <top-one-gradient>

For normalized selected top-1 routing, the single retained weight is one on a
fixed support, so the local task derivative through that normalized mixture
weight is zero. This fact does not transfer to full-softmax top-1 routing. In
the latter form $y_t^r = p_(t,s) E_s (x_t)$, a scalar output gives

$ frac(partial y_t^r, partial a_(t,s))
  = p_(t,s)(1 - p_(t,s)) E_s (x_t), $

which is nonzero unless its factors vanish. With the same fixed logits and
the stated fixed-support assumptions, the normalized and full-softmax paths
have distinct local gate-weight derivatives.

As @moe-top-one-gate-comparison shows, the two-expert positive-difference
region keeps the plotted derivatives inside one unchanged support.

#figure(
  image("/assets/diagrams/moe_top1_gate_comparison.svg", width: 100%),
  caption: [Two-expert top-1 gate coefficients and local derivatives.],
) <moe-top-one-gate-comparison>

Two experts with $delta = a_1 - a_2 > 0$, fixed $S = {1}$, no ties, no drop,
and route scale one. Selected-set top-1 normalization has coefficient one and
local gate-weight derivative zero; retaining the full softmax instead gives
$p_1 = sigma(delta)$ and derivative $p_1(1 - p_1)$. These are gate-weight
derivatives on the fixed support, not full task gradients or claims across a
support-changing boundary.

== Support can change after a local step <support-change>

The local zero outside $S_t$ is not a permanent exclusion claim. In the
three-expert example above, a gradient-descent step with
$eta = (9/2) op("ln")(4)$ changes only the initially selected logits by a
gradient-descent update. The old support $(0, 1)$ becomes $(0, 2)$:
expert 2 receives no direct update in this local expression yet enters after
the boundary changes. This arithmetic uses a fixed tie rule. Hard routing does
not therefore guarantee specialization, and a soft mixture does not guarantee
homogeneous experts; both are empirical outcomes of a complete training
procedure.

= Load Balancing and Stability <load-balancing>

When the chosen gate supplies a usable task-gradient path, the task loss can
provide a router learning signal without a balancing auxiliary term.
@fixed-support-gradient derives such a path under its stated assumptions,
and @top-one-gradient explains why this is gate dependent. That signal
optimizes prediction quality; it does not by itself impose a target
distribution on the requested loads $R_i$.

Many tokens can favor a small subset of experts while still reducing the
task loss. With a capacity limit, concentrated requests may be rejected
(@capacity-policy); rarely selected experts can receive fewer routed
training opportunities. Depending on the parallel layout, uneven work
can also produce stragglers and idle devices. These are possible costs,
not a claim that task-only training must collapse.

The balance surrogate below therefore adds a distinct load-management
objective, rather than supplying the task-gradient path just derived.
A balancing auxiliary loss is not universally required: the bias feedback
in @sign-feedback-cycle is another way to influence requested load.
However, omitting a balancing auxiliary loss does not mean that load
management is unnecessary or that task gradients guarantee balanced routing.
Whether extra control is needed, and which mechanism to use, depends on
the complete training and execution setup.

== Auxiliary balance as a surrogate <balance-stopgrad>

One common balance surrogate is

$ cal(L)_"bal" = alpha N sum_(i=1)^N op("stopgrad")(f_i) P_i, $

where $f_i = R_i / (T K)$ is the measured requested-load fraction from
@routing-objects, and $P_i$ is an average of a specified differentiable gate
probability. This scalar auxiliary objective supplies a load-management
signal, distinct from the prediction objective. The following derivation
specifies the probability and follows that signal back to the router parameters.

#[
  #set math.equation(numbering: none)

  *1. Specify the probability and its group average.* For this derivation,
  choose a full softmax over all $N$ routed experts, then average over the
  $T$ tokens in $G$:

  $ p_(t,i) = frac(exp(a_(t,i)), sum_(ell=1)^N exp(a_(t,ell))), quad
    P_i = frac(1, T) sum_(t in G) p_(t,i). $

  These are the probabilities used by the balance surrogate, not necessarily
  the selected fusion weights $w_(t,i)$. A different probability definition
  requires its own derivative.

  *2. Stop the observed-load path.* The forward value of
  $op("stopgrad")(f_i)$ is still $f_i$, but its backward rule sends no gradient
  through $f_i$. This is an automatic-differentiation instruction, not the
  ordinary derivative of an identity function. For this backward pass, the
  measured fractions act as fixed coefficients. Substituting the group average
  therefore gives

  $ cal(L)_"bal" = frac(alpha N, T)
    sum_(t in G) sum_(i=1)^N f_i p_(t,i). $

  Before propagating through the softmax, differentiation at each probability
  component gives

  $ frac(partial cal(L)_"bal", partial p_(t,i)) = frac(alpha N, T) f_i. $

  There is no additional term obtained by differentiating $f_i$.

  *3. Differentiate the full softmax.* Let
  $Z_t^"full" = sum_(ell=1)^N exp(a_(t,ell))$. For expert indices $i$ and $j$,
  the indicator is

  $ 1_(i=j) = cases(
    1 & "if " i = j,
    0 & "if " i != j,
  ). $

  Differentiating the numerator and the common denominator gives

  $ frac(partial p_(t,i), partial a_(t,j))
    &= frac(1_(i=j) exp(a_(t,i)) Z_t^"full"
      - exp(a_(t,i)) exp(a_(t,j)), (Z_t^"full")^2) \
    &= p_(t,i) (1_(i=j) - p_(t,j)). $

  The shared denominator couples the probabilities: they cannot all be
  decreased independently while still summing to one.

  *4. Combine the two derivatives.* For $t in G$ and $j = 1, dots, N$, the
  chain rule sums over all probability components of this token:

  $ frac(partial cal(L)_"bal", partial a_(t,j))
    &= sum_(i=1)^N frac(partial cal(L)_"bal", partial p_(t,i))
      frac(partial p_(t,i), partial a_(t,j)) \
    &= frac(alpha N, T) sum_(i=1)^N
      f_i p_(t,i) (1_(i=j) - p_(t,j)) \
    &= frac(alpha N, T)
      (f_j p_(t,j) - p_(t,j) sum_(i=1)^N f_i p_(t,i)) \
    &= frac(alpha N, T) p_(t,j)
      (f_j - sum_(i=1)^N f_i p_(t,i)). $

  The centering term comes from the common softmax denominator, and the
  factor $1/T$ comes from averaging over the statistics group. The gradient
  passes through the probabilities, not through the discrete load counts.

  *5. Continue to the router parameters.* Recall $a_t = g_(theta_r)(x_t)$.
  For any scalar component $theta_(r,q)$ of the router parameters,

  $ frac(partial cal(L)_"bal", partial theta_(r,q))
    = sum_(t in G) sum_(j=1)^N
      frac(partial cal(L)_"bal", partial a_(t,j))
      frac(partial a_(t,j), partial theta_(r,q)). $

  For a linear router $a_t = W_r x_t + b_r$, collect the score derivatives in
  a column vector $gamma_t in RR^N$ with
  $gamma_(t,j) = frac(partial cal(L)_"bal", partial a_(t,j))$. Holding the router
  inputs fixed gives the actual parameter gradients

  $ frac(partial cal(L)_"bal", partial W_r) = sum_(t in G) gamma_t x_t^T, quad
    frac(partial cal(L)_"bal", partial b_r) = sum_(t in G) gamma_t. $

  For example, gradient descent on the task and balance objectives uses
  the update below, where $cal(L)_"task"$ denotes the prediction loss and
  $alpha$ is already included in $cal(L)_"bal"$:

  $ theta_(r,q) <- theta_(r,q) - eta (
    frac(partial cal(L)_"task", partial theta_(r,q))
    + frac(partial cal(L)_"bal", partial theta_(r,q))). $

  The next forward pass recomputes scores, routing requests, and the measured
  fractions. Thus load feedback can change the router without differentiating
  through the discrete counts, although an update need not change the selected
  experts immediately or guarantee balanced load.
]

#block(breakable: false)[
  A single-vector version instead uses $P_i = p_i$ with
  $p = op("softmax")(a)$, so there is no group-averaging factor $1/T$.
  Its score derivative is

  $ frac(partial cal(L)_"bal", partial a_j)
    = alpha N p_j (f_j - sum_i f_i p_i). $
]

The centering term is $f_j - sum_i f_i p_i$, not generally $f_j - 1/N$.
When $f$ is uniform, the scalar surrogate is constant and this gradient is
silent. When $p$ is uniform but $f$ is unequal, it can be nonzero. Equal
scalar values alone do not prove that every feedback path is inactive.

The coefficient $alpha$ is an auxiliary tradeoff weight, not unconditionally
a Lagrange multiplier. Its value does not by itself establish a universal
inverse-$alpha$ violation law, a required smallness condition, or convergence.
It can also change the task trajectory by changing which experts receive data.

== Bias feedback changes selection <sign-feedback-cycle>

The auxiliary loss and feedback controller have the same load-control goal:
keep the requested counts $R_i$ near a stated target while preserving useful
conditional routing. They differ in where that pressure enters. The surrogate
in @balance-stopgrad adds an objective gradient to the router. Wang et al.
report that a large auxiliary coefficient can create gradients that interfere
with language-modeling optimization @lossfree2024. This is a motivation for a
controller, not a proof that every auxiliary gradient is harmful or that a
controller is task-neutral.

Let $a_(t,i)$ be a router logit and let $s_(t,i)$ be the affinity on which a
particular gate operates, such as $s_(t,i) = sigma(a_(t,i))$. Keep the router's
trainable affine bias $b_r$ in $a_t = W_r x_t + b_r$ distinct from a
*controller* offset $b_i^"ctl"$.

Fix one MoE layer. The superscript $h$ identifies a training step, and $G_h$
is the token group used to measure that layer's load on this step; $|G_h|$
is its token count. For whole-step global feedback, this group aggregates
microbatches and participating parallel ranks, counting each token once.

Let $R_i^(h)$ be the number of routing requests to expert $i$ from $G_h$,
before capacity filtering, rather than the number of accepted paths. Each
token requests $K$ of the $N$ routed experts, giving $|G_h| K$ requests in
total and a mean target of $q_h = |G_h| K / N$ per expert. The indicator
$1_(i in S_t^(h))$ contributes one when token $t$ selects expert $i$ and zero
otherwise. A selection-only rule and its requested-load count are

#[
  #set math.equation(numbering: none)
  $ S_t^(h) = op("TopK")_i (s_(t,i)^(h) + b_i^"ctl,h"), quad
    R_i^(h) = sum_(t in G_h) 1_(i in S_t^(h)), quad q_h = |G_h| K / N. $
]

The selected output may still be fused with the original affinities: for
example, $w_(t,i) = s_(t,i) / sum_(j in S_t) s_(t,j)$ for selected sigmoid
scores. Thus the offset changes the discrete requested support, not the
original affinity values or the router's affine parameters. The task loss still
backpropagates through the stated gate and into $W_r,b_r$; $b^"ctl"$ is updated
outside that backward pass from completed-step counts. A fixed sign controller
is

#[
  #set math.equation(numbering: none)
  $ b_i^"ctl,h+1" = b_i^"ctl,h" + u op("sign")(q_h - R_i^(h)). $
]

An underloaded expert receives a positive selection offset, while an
overloaded expert receives a negative one, but only for a later step. For
example, with $N=4$, $|G_h|=8$, and $K=1$, the target is $q_h=2$; counts
$(4,3,1,0)$ change the offsets by $(-u,-u,+u,+u)$. This historical update is
causal: selecting earlier tokens cannot depend on future-token counts in the
same sequence. It is not equivalent to optimizing a differentiable balancing
objective, and it can still change which experts receive task data and hence
the eventual task trajectory. It also neither replaces a numerical-stability
term such as z-loss nor rules out complementary local or sequence-level losses.

DeepSeek separates these choices explicitly. Original DeepSeekMoE reports
expert- and device-level balance losses; the device loss targets placement and
parallel work, not merely expert popularity @deepseekmoe2024. DeepSeek-V3
instead uses a whole-training-step selection-bias controller for its principal
global load control, while retaining a tiny sequence-wise balance loss to avoid
extreme per-sequence imbalance @deepseekv3-2024. In V3's sigmoid route,
$s = sigma(a)$ and the controller offset is added *after* sigmoid for
selection, while the selected, normalized, and scaled fusion path uses the
original $s$. Its group/node routing limit is a separate communication
constraint. The inference `Gate` is useful evidence for the selection/fusion
path, but cannot by itself establish the paper's training losses; the
DeepSeek-V3 case study cross-references this canonical account.

For a two-expert deterministic toy controller, fixed-size sign updates can
alternate between $(0, 0)$ and $(-1, 1)$, forming a two-cycle. Bounded
increments alone do not prove bounded controller state or convergence, and
the absence of an additional auxiliary gradient does not mean that changed
selections cannot affect the task path.

== Conditional balanced-assignment interpretation <balanced-assignment>

For the minimization-side foundations behind the bound direction, strong duality,
and recovery qualifications used here, see #link("../../Mathematics/Optimization/Lagrangian_Duality.pdf")[Lagrangian Duality].

The purpose of this conditional construction is to explain why bias feedback can
be viewed as controlling a maximum-affinity balanced assignment, and to prepare
for the QB coordinate update below. Fix one MoE layer and one completed routing
step. Let $T = |G_h|$ be the number of tokens in the preceding step notation,
let $N$ be the number of routed experts, and let $K <= N$ be the number of
requests made by each token. Assume the target $q = T K / N$ is an integer.
For token $t in {1, dots, T}$ and expert $i in {1, dots, N}$, binary
$X_(t,i)$ records whether $t$ requests $i$. With fixed affinity score
$s_(t,i)$, define the affinity total $F(X) = sum_t sum_i s_(t,i) X_(t,i)$ and
the requested load $R_i(X) = sum_t X_(t,i)$. This $F$ is an assignment score,
not the neural task loss. The idealized primal problem is

#[
  #set math.equation(numbering: none)
  $ F^* = max_X F(X) quad "subject to" quad
    sum_i X_(t,i) = K, quad sum_t X_(t,i) = q, quad
    X_(t,i) in {0,1}. $
]

Thus every token makes $K$ requests and every expert receives exactly $q$.
There are no capacity limits or dropped requests in this idealization.

For duality, relax only binary values to the interval $[0,1]$ and retain the
row constraints and box constraints in the named row-feasible set

#[
  #set math.equation(numbering: none)
  $ cal(X)_("row") = {X in [0,1]^(T times N) :
    sum_i X_(t,i) = K " for every " t}, $
]

where $[0,1]^(T times N)$ is the set of real $T$-by-$N$ matrices with entries
between zero and one. The expert equalities $R_i(X)=q$ remain the constraints
to be dualized. When $q$ is integral and every token can be assigned to every
expert (the complete bipartite assignment graph), this bipartite
$b$-matching linear program has an integral optimum. The relaxation therefore
has the same optimal value as the binary assignment under these conditions;
it does not say that every fractional feasible or optimal LP solution is
binary.

Introduce an unrestricted real multiplier vector $b in RR^N$ for the expert
load equalities, while keeping $X in cal(X)_("row")$ in the inner problem. Its
Lagrangian is

#[
  #set math.equation(numbering: none)
  $ Lambda(X,b) = F(X) + sum_i b_i (R_i(X)-q)
    = sum_t sum_i (s_(t,i)+b_i) X_(t,i) - q sum_i b_i. $
]

Here $b_i$ rewards an expert in the selection score when it is increased; one
may equivalently regard $-b_i$ as that expert's price. A fixed multiplier only
changes the affinities and does not itself enforce balance. In the last form,
the rowwise Top-$K$ selection of $s_(t,i)+b_i$ is visible explicitly. This
$b$ corresponds to the preceding controller offset in an idealized assignment
model, not the ordinary router affine bias $b_r$, not the auxiliary coefficient
$alpha$, and $Lambda$ is not the neural task loss.

Define the dual function by maximizing this Lagrangian over the row-feasible
relaxation:

#[
  #set math.equation(numbering: none)
  $ D(b) = max_(X in cal(X)_("row")) Lambda(X,b)
    = sum_(t=1)^T max_(x in cal(X)_K)
      sum_i (s_(t,i)+b_i)x_i - q sum_i b_i, $
]

where $x$ is one token's selection vector and
$cal(X)_K = {x in [0,1]^N : sum_i x_i = K}$. These are nested optimizations
with different variables: the outer dual problem chooses $b$, $D(b)$ first
maximizes over the matrix $X$, and that inner maximum separates into rowwise
maxima over $x$. For every balanced feasible $X$, $Lambda(X,b)=F(X)$, whereas
the inner maximum may choose an imbalanced $X$. Hence $D(b) >= F^*$ for every
$b$, and the primal maximization gives the dual problem

#[
  #set math.equation(numbering: none)
  $ min_(b in RR^N) D(b), $
]

which finds the tightest such upper bound. This direction is important: a
textbook primal minimization instead gives a dual maximization of lower bounds;
one cannot silently exchange these min/max roles without the corresponding
conditions.

The inequality above is weak duality. This bounded feasible LP also has strong
duality, so its minimum dual value equals $F^*$; together with the stated
integrality result, that value is the binary assignment value. General
nonconvex routing or learning problems can have a duality gap. Nor does a
dual-optimal bias mean arbitrary Top-$K$ tie-breaking yields a feasible balanced
assignment: tied rows can require coordinated primal recovery. Ties do not
invalidate LP duality.

The load error is a subgradient rather than an assertion about differentiating
through discrete Top-$K$. Let $X^b$ be an inner maximizer that defines
$D(b)$, and write $R_i(b) = R_i(X^b)$. For any other multiplier vector $b'$,

#[
  #set math.equation(numbering: none)
  $ D(b') >= Lambda(X^b,b')
    = D(b) + sum_i (R_i(b)-q)(b'_i-b_i). $
]

Thus the vector with coordinate $R_i(b)-q$ is a valid subgradient of $D$ at
$b$. No derivative through the discrete choice is needed. If the inner
selection is unique, the ordinary gradient has the same coordinate
$R_i(b)-q$. A proportional subgradient descent update is therefore

#[
  #set math.equation(numbering: none)
  $ b_i^(r+1) = b_i^r - eta (R_i(b^r)-q), quad eta > 0, $
]

where $r$ is a dual iteration, not a neural training step, and $eta$ is its
positive step size. It has the same direction as the fixed sign rule
$u_i = op("sign")(q-R_i)$: overloaded experts move down and underloaded
experts move up. Kimi K3 Appendix C writes the equivalent expert-threshold
convention $b=-beta$ and derives coordinate updates from the row/expert dual
@kimik3-2026. Fixed steps can oscillate, and no finite update is guaranteed to
decrease $D$.

For example, with two tokens, experts A and B, and $K=q=1$, let token scores
be $(0.90, 0.85)$ and $(0.80, 0.10)$ for (A, B). The balanced optimum sends the
second token to A and the first to B, giving $F^*=0.80+0.85=1.65$; the other
balanced assignment gives $0.90+0.10=1.00$. The bias $(b_"A",b_"B")=(-0.15,0)$
induces those rowwise choices. Its adjusted row maxima sum to
$0.85+0.65=1.50$, and $D(b)=1.50-1(-0.15)=1.65=F^*$.

This is a fixed-score, fixed-batch analysis, so it supplies no convergence
guarantee when neural scores or batches change. The following QB section uses
the related dual-coordinate viewpoint to choose a bias from fixed cutoffs;
it is not repeated here.

== Quantile balancing in Kimi K3 <kimi-quantile-balancing>

Kimi K3 v2 (2026-08-07; v1 was 2026-07-27) applies Quantile Balancing (QB) at
an extreme sparse setting: 16 of 896 routed experts are active per token
@kimik3-2026. The report motivates QB because fixed-step bias adaptation must
trade slow adjustment against oscillation as the pool approaches one thousand
experts. Its route uses $s_t = sigma(W_r x_t)$, selects Top-$K$ from
$s_t+b^"ctl"$, and normalizes the original selected $s_t$ for fusion.

For a completed step, take Top-$(K+1)$ of $s_t+b^"ctl,h"$. The first $K$
entries are routes and the next entry is the cutoff $tau_t$. Holding those
cutoffs fixed, QB proposes

#[
  #set math.equation(numbering: none)
  $ hat(b)_i = - op("quantile")_(1-K/N)(s_(:,i) - tau), quad
    b_i^"ctl,h+1" = hat(b)_i - frac(1,N) sum_j hat(b)_j. $
]

The mean centering removes a common offset, which cannot change Top-$K$.
With no ties and $q=T K/N$, the candidate count is
$sum_t 1_(s_(t,i)+hat(b)_i > tau_t)$; choosing the $(q+1)$-th largest margin
sets it to $q$. Equivalently, histogramming the required bias $tau_t-s_(t,i)$
uses its $K/N$ lower-tail quantile. This is the expert-coordinate minimizer of
the LP dual when token cutoffs and all other coordinates are fixed, not an
exact joint solve. It is applied on the next training step and the final bias
is frozen for inference. Kimi's Figure 5 turns $(4,3,1,0)$ into $(2,2,2,2)$
only as an illustration, not as a benchmark.

At scale Kimi does not gather all margins. Since sigmoid scores lie in $(0,1)$,
required biases lie in $[b_"min"-1,b_"max"+1]$. Each rank accumulates
per-expert, per-microbatch counts into $B$ bins over that range; one end-of-step
all-reduce produces the pooled histogram, from which every rank recovers the
global quantile. A mean of local quantiles is generally not the global
quantile. With bin width $w=(b_"max"-b_"min"+2)/B$, the threshold estimate and
true quantile share a bin, so their error is at most $w$; this is not a
universal load-error bound near ties. The report uses $B=1000$, reports no
measurable residual imbalance in that setting, and says the integer all-reduce
is below 1 percent of exchanging raw margins every microbatch. Those are
configuration-specific statements, not a general throughput result. Changing
scores or batch data, ties, histogram approximation, and the one-step delay
mean that QB does not guarantee next-batch balance.

== Global-batch differentiable balancing <global-batch-balancing>

A separate axis is the statistics scope of a differentiable auxiliary loss.
Qiu et al.'s 2025 work observes that small, homogeneous microbatches can make
the local loss nearly sequence-wise, pushing even domain-specific tokens
through every expert and suppressing useful specialization @qwen-global-2025.
For groups $g$ with unequal token counts $T_g$, let $f_(g,i)$ be a detached
requested fraction and $P_(g,i)$ the differentiable mean gate probability.
The average of local products differs from the product of token-weighted global
means:

#[
  #set math.equation(numbering: none)
  $ cal(L)_"local" = alpha N sum_g frac(T_g, sum_h T_h)
    sum_i f_(g,i) P_(g,i), $
  $ cal(L)_"global" = alpha N sum_i
    (sum_g frac(T_g, sum_h T_h) f_(g,i))
    (sum_g frac(T_g, sum_h T_h) P_(g,i)). $
]

The global form synchronizes only detached counts or fractions; each rank keeps
its probabilities local for differentiation and aggregates the appropriately
weighted scalar contributions. This equality to the all-token objective needs
the token weights above, not an unweighted average when groups differ in size.
When a full global batch spans gradient accumulation, a count buffer is reset
at the optimizer step and gives an approximation before that step completes.

The authors report, for their 3.4A0.6B/120B-token, global-batch-512 setting,
PPL 8.167 for local Balance BSZ 4 and 8.038 for synchronized BSZ 512; their
sigmoid auxiliary-free comparison is 8.521 and 8.080 at those respective
scopes. These are source-bound configurations, not a universal comparison of
loss families. For 43A6.6B, Table 5 reports local BSZ 8 as 5.862 PPL at
1.55 s/iteration, buffered broad BSZ 128 as 5.779 at 1.64 s, and a broad loss
plus a tiny local term as 5.795 at 1.59 s. The latter local coefficient is
1 percent of the broad one and begins at 20k steps; it trades some reported
PPL for less local imbalance. The ACL paper was published in 2025 and reports
use in Qwen3-MoEs. A 2026-08-27 first-party Qwen3.8-Flash-Next technical post
explicitly describes global load balancing in its ultra-sparse MoE
@qwen-flash-next-2026; it is adoption/design evidence, not a new 2026 balancing
algorithm. Thus Qwen's route is not uniformly loss-free: it retains a
scope-adjusted differentiable balance loss, and its cited experiments also use
z-loss.

== Logit scale and z-loss <zloss-counterexample>

ST-MoE studies a router z-loss of the form

$ cal(L)_z = alpha_z (op("log") sum_i exp(a_i))^2 $

as a training-stability technique @stmoe2022. Its reported benefits are
specific experimental evidence, not a theorem that it rescues every router.
The term anchors the log partition, whereas softmax routing is invariant to a
common shift of all logits.

For any small $epsilon$, take

$ a = (op("log")(1 - epsilon), op("log")(epsilon)). $

Then $op("log") sum_i exp(a_i) = 0$, while the span
$op("log")((1 - epsilon) / epsilon)$ grows as $epsilon$ shrinks. Thus z-loss
alone does not bound every pairwise logit difference or guarantee a useful
rescue gradient.

Z-loss is optional: softmax correctness does not require it, and its value
depends on the numerical implementation and training recipe. The inventory
below records only what the frozen source explicitly reports. "Not reported"
does not prove that every private or later implementation omitted the term.
Load-balancing losses, selection biases, capacity policies, and numerical
stabilization should not be described as interchangeable z-loss substitutes:
they act on different quantities.

#table(
  columns: (1.3fr, 1.25fr, 4.75fr),
  table.header([Frozen source], [Router z-loss], [Other reported mechanism and boundary]),
  [ST-MoE @stmoe2022], [Explicitly used], [Uses router z-loss together with an auxiliary load-balancing loss. The z-loss targets router log-partition scale; the balance loss targets expert usage. They are complementary terms, not substitutes.],
  [Switch Transformer @switch2022], [Not reported], [Reports auxiliary load balancing, router selective precision, and capacity or overflow controls. These address load or implementation stability, not the same objective as z-loss.],
  [Mixtral 8x7B @mixtral2024], [Not reported], [The paper specifies top-2 selected-softmax routing but does not specify a z-loss or a training-time load-balancing objective. Do not infer the original recipe from a later framework or checkpoint implementation.],
  [DeepSeekMoE @deepseekmoe2024], [Not reported], [Uses expert-level and device-level balance losses. Fine-grained experts and always-on shared experts are architectural choices, not z-loss substitutes; the device term depends on the deployment layout.],
  [DeepSeek-V3 @deepseekv3-2024], [Not reported], [Uses the selection-only controller in @sign-feedback-cycle for global load, a very small sequence-wise balance loss, sigmoid affinities, and node-limited routing. These mechanisms address different paths; the report does not identify one as a z-loss replacement.],
  [Kimi K3 v2 @kimik3-2026], [Not reported], [Reports Quantile Balancing, a frozen selection bias, and separate routed-path stabilization. QB is load control, not evidence about a z-loss.],
  [Qiu et al. 2025 @qwen-global-2025], [Used in reported setups], [Studies global-batch differentiable balance loss; the source's reported configurations include z-loss, so global statistics do not make the route loss-free.],
)

= Architecture Case Studies <case-studies>

The following cases share terms from this note but do not define one universal
MoE. Paper versions are frozen in the local bibliography; repository behavior
is separately pinned where it is used.

#table(
  columns: (1.1fr, 2fr, 2.55fr, 2.25fr),
  table.header([Case and frozen source], [Route], [Fusion and expert design], [Capacity and balancing boundary]),
  [Switch @switch2022], [Top-1 selection from a full softmax], [The selected output retains its full-softmax probability rather than normalizing a one-element support to one.], [The paper's capacity and auxiliary-loss design is an instance; it is not a definition of all top-1 MoEs.],
  [Mixtral 8x7B @mixtral2024], [Eight experts per layer; select two per token], [The selected top-2 gate weights are softmax-normalized; the paper uses SwiGLU experts.], [This is a coarse-grained open-weight case study, not evidence for a shared branch or a V3-style bias controller.],
  [DeepSeekMoE @deepseekmoe2024], [Fine-grained routed experts], [The design reserves common capacity on an always-on shared path while routed experts carry conditional work; semantic specialization, if it emerges, depends on data, task, optimization, and training dynamics.], [Fine segmentation changes combination granularity but does not eliminate dispatch or balance constraints.],
  [DeepSeek-V3 report v2 @deepseekv3-2024], [Sigmoid affinity plus a selection-only bias; constrained groups/nodes], [Use the unmodified selected affinity for fusion, normalize selected sigmoid weights, then apply configured route scaling.], [It reports auxiliary-loss-free balancing plus a small sequence-wise balance auxiliary term; neither statement transfers to every DeepSeek or every MoE.],
)

== Switch <switch-case>

The JMLR publication of Switch Transformer freezes the top-1 case used here
@switch2022. Its full-softmax gate explains why "top-1 has zero gate gradient"
is not a model-independent sentence. The paper reports an auxiliary
load-balancing loss, router selective precision, and capacity or overflow
controls; it does not list the later ST-MoE router z-loss in the stated
objective. Capacity and balancing choices in Switch also depend on its
training setup; this note uses them as a contrast for the normalized
selected-top-1 derivative, not as a performance comparison.

== Mixtral <mixtral-case>

The frozen Mixtral source is arXiv:2401.04088v1 @mixtral2024. Its 8x7B model
uses eight experts per layer and selects two, then normalizes the selected
softmax weights. Its experts are SwiGLU FFNs. The paper does not report a
router z-loss or spell out a training-time load-balancing objective, so this
note does not infer either one from the architecture alone. A later framework
or checkpoint configuration must be cited separately. The architecture gives
a concrete multi-expert case without implying that top-2, eight experts, or
SwiGLU is mandatory for an MoE.

== DeepSeekMoE <deepseekmoe-case>

The frozen DeepSeekMoE source is arXiv:2401.06066v1 @deepseekmoe2024. Its
fine-grained segmentation splits a coarse expert budget into more, narrower
routed units, and its shared experts are always-on. For load control, the
paper reports an expert-level balance loss and a device-level balance loss;
the latter targets computation balance across expert-parallel devices. In
configurations that place all experts on one device, the device-level term is
not needed, while the expert-level term still limits routing collapse. These
balance losses are not z-loss substitutes, and the fine-grained/shared design
is architectural rather than an auxiliary objective. The combinatorial choice
space can increase under a matched nominal active width, but that count alone
is not a quality proof. The DeepSeek-specific short explanation and system
consequences are intentionally kept in
#link("../DeepSeek/DeepSeek_Architecture.pdf")[DeepSeek Architecture].

== DeepSeek-V3 <deepseek-v3-case>

The frozen V3 paper source is arXiv:2412.19437v2 @deepseekv3-2024. The
reference implementation is the `Gate` definition @deepseekv3-gate at the
pinned DeepSeek-V3 commit `f6e34dd26772dd4a216be94a8899276c5dca9e43`.
The canonical selection-only controller, retained sequence-wise loss, and
separate node-routing boundary are explained in @sign-feedback-cycle. This
case study fixes the implementation-level selection/fusion detail: scores use
either softmax or sigmoid, while the cited V3 path uses sigmoid affinities.
The code stores `original_scores`, adds the controller bias only to selection
scores, selects experts, gathers the unmodified affinities, normalizes the
selected sigmoid weights, and multiplies by `route_scale`.

@deepseek-v3-selection-fusion makes the selection-only bias and the
unmodified-affinity fusion path explicit for that fixed implementation.

#let v3-flow-node(pos, name, body, fill: rgb("#EAF1F4")) = node(
  pos,
  align(center)[
    #set text(size: 8.2pt)
    #body
  ],
  name: name,
  width: 19mm,
  inset: 3pt,
  corner-radius: 2pt,
  stroke: 0.7pt + rgb("#315A67"),
  fill: fill,
)

#figure(
  align(center)[
    #diagram(
      cell-size: (18mm, 8mm),
      spacing: (3mm, 5mm),
      edge-stroke: 0.65pt + rgb("#37474F"),
      v3-flow-node((0, 0), <v3-logits>, [logits\ $a_(t,i)$], fill: rgb("#F5EEE5")),
      v3-flow-node((1, 0), <v3-sigmoid>, [sigmoid]),
      v3-flow-node((2, 0), <v3-original>, [original\ sigmoid\ affinities\ $sigma(a_(t,i))$], fill: rgb("#E7F3EA")),
      v3-flow-node((0, 1), <v3-topk>, [TopK\ selection\ $S_t$], fill: rgb("#FFF1D9")),
      v3-flow-node((1, 1), <v3-groups>, [group\ restriction\ if enabled], fill: rgb("#FFF1D9")),
      v3-flow-node((2, 1), <v3-selection-scores>, [selection\ scores\ $sigma(a_(t,i)) + b_i$], fill: rgb("#FFF1D9")),
      v3-flow-node((3, 1), <v3-gather>, [gather $S_t$ from\ unmodified affinity], fill: rgb("#E6F2F4")),
      v3-flow-node((4, 1), <v3-normalize>, [normalize\ over $S_t$], fill: rgb("#E6F2F4")),
      v3-flow-node((5, 1), <v3-scale>, [configured\ route scale], fill: rgb("#E6F2F4")),
      v3-flow-node((6, 1), <v3-weights>, [fusion weights\ $w_(t,i)$], fill: rgb("#F1EAF4")),
      edge(<v3-logits>, <v3-sigmoid>, "->"),
      edge(<v3-sigmoid>, <v3-original>, "->"),
      edge(<v3-original>, <v3-selection-scores>, "->"),
      edge(<v3-selection-scores>, <v3-groups>, "->"),
      edge(<v3-groups>, <v3-topk>, "->"),
      edge(<v3-original>, <v3-gather>, "->", [unmodified]),
      edge(<v3-topk>, <v3-gather>, "->", [$S_t$], bend: -35deg),
      edge(<v3-gather>, <v3-normalize>, "->"),
      edge(<v3-normalize>, <v3-scale>, "->"),
      edge(<v3-scale>, <v3-weights>, "->"),
    )
  ],
  caption: [DeepSeek-V3 selection and fusion paths for the cited fixed `Gate` implementation.],
) <deepseek-v3-selection-fusion>

The learned bias changes selection scores and, when configured, group
restriction precedes TopK. Fusion gathers the selected entries from the
original sigmoid affinities, then normalizes and scales them. The bias does not
alter the original affinity values directly, but it can change $S_t$ and
thereby alter the resulting weights and output indirectly.

== Affinity-space bias is version-specific <affinity-bias-selection>

The same implementation exposes `n_expert_groups` and `n_limited_groups`.
When grouping is enabled, it masks groups before the final top-k selection;
these constraints correspond to the paper's limited-destination routing goal.
The exact values come from model arguments, so this note does not invent a V3
configuration from class defaults. In particular, adding a bias to raw logits
is not equivalent to adding it after sigmoid: with logits $(4, 0)$ and bias
$(0, 1)$, the former selects index 0 while the latter selects index 1.

V3 calls its main global method auxiliary-loss-free, but it retains the small
sequence-wise balance term described in @sign-feedback-cycle. The report's
group/node limits, route scale, and sequence loss belong to this source
version, not to the generic MoE equations.

= Appendix: Finite Examples and Limits <finite-examples>

#table(
  columns: (1.65fr, 5.5fr),
  table.header([Section], [Example or boundary]),
  [#ref(<fixed-support-gradient>)], [On the stated fixed no-tie support, outputs $(0, 1, 2)$ and logits $(op("ln")(4), op("ln")(2), 0)$ give gradient $(-2/9, 2/9, 0)$.],
  [#ref(<top-one-gradient>)], [Normalized selected top-1 and full-softmax top-1 have different local derivatives.],
  [#ref(<support-change>)], [Updating only selected logits can change a later top-k support.],
  [#ref(<zloss-counterexample>)], [Zero log partition does not prevent a large two-logit span.],
  [#ref(<balance-stopgrad>)], [A uniform load can be locally silent while unequal load yields a nonzero stop-gradient direction.],
  [#ref(<partial-drop>)], [A rejected token-expert pair need not zero the accepted or shared output.],
  [#ref(<post-drop-weights>)], [Keeping versus renormalizing surviving weights gives distinct outputs; if no positive weight survives, the routed branch is zero.],
  [#ref(<moe-residual>)], [The complete sublayer adds an input residual outside the MoE branch; an all-zero branch returns the input in the basic Pre-Norm wrapper, while Post-Norm still normalizes it.],
  [#ref(<shared-budget-ledger>)], [Six routed selections plus two shared paths give eight active paths; capacity counts 48 routed requests, not 64.],
  [#ref(<sign-feedback-cycle>)], [A fixed-step sign controller can form a two-cycle.],
  [#ref(<affinity-bias-selection>)], [Bias placement before or after sigmoid can change selection.],
)

These are conditional derivations and finite examples with fixed inputs and
stated assumptions. They do not establish general MoE quality, balanced usage
at scale, or optimizer convergence.

= Sources and Further Reading <sources>

The local bibliography freezes the papers used for general definitions,
stability boundaries, case studies, and dropless execution, as well as the
repository revisions used for implementation examples. For a DeepSeek reading
path, use
#link("../DeepSeek/DeepSeek_Overview.pdf")[DeepSeek Overview] first, then
#link("../DeepSeek/DeepSeek_Architecture.pdf")[DeepSeek Architecture] and
#link("../DeepSeek/DeepSeek_Systems.pdf")[DeepSeek Systems].

#bibliography("references.bib", title: none)
