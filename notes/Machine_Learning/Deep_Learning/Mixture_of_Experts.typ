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
  particular repository implementation, and a derivation made here. The finite
  checks in `scripts/check_moe_math.py` validate only the labeled examples in
  this note. They do not establish generalization, specialization, throughput,
  or controller convergence.
]

= Sparse MoE Layer <sparse-moe-layer>

== Routing objects <routing-objects>

Let $G$ be one routing-statistics group containing $T$ tokens. Let $N$ be the
number of routed experts, $K$ the number requested from them for each token,
$N_s$ the number of shared experts, and $K_s <= N_s$ the number of shared
expert paths active for each token. In an always-on shared path, $K_s = N_s$.
For a DeepSeek-style accounting mapping, $K_r = K = |S_t|$ names only the
routed request count; $K_s$ does not change that support. The router produces
selection scores $a_(t,i)$ for routed expert $i$. They determine the requested support

$ S_t = op("TopK")_i (a_(t,i)), quad |S_t| = K. $

The fusion coefficient $w_(t,i)$ is a separate quantity. A capacity or dispatch
policy supplies an acceptance mask $m_(t,i)$ after selection. With routed expert
outputs $E_i (x_t)$ and a shared-branch output $H_t$, a useful general form is

$ y_t = H_t + sum_(i in S_t) m_(t,i) w_(t,i) E_i (x_t). $

The shared branch may have its own width, gate, and output scaling. Its form is
model-specific, so the equation does not imply that every shared expert is
unweighted or has the same width as a routed expert. The active-expert count
$K_"active" = K_r + K_s$ is therefore only a count ledger. If an external
configuration fixes that count, call it $K_"total" = K_"active"$ rather than
redefining $K$; it proxies active parameters or compute only when the paths
have the same relevant structure and width. A residual connection, if present,
is another surrounding Transformer operation rather than part of the router
definition.

For accounting, requested and accepted expert loads are different:

$ R_i = sum_(t in G) 1_(i in S_t), quad
  A_i = sum_(t in G) 1_(i in S_t) m_(t,i). $

The requested fraction is $f_i = R_i / (T K)$ when every token asks for $K$
routed experts. The accepted fraction instead uses $A_i$. A balance statistic
must say which one it uses and which tokens belong to $G$.

// moe-typesetting-routing-end: stable boundary for the original routing formulas.
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
pair contributes $0$ without forcing the full output $y_t$ to be $0$.

== Common gate variants <gate-variants>

A normalized selected-softmax gate first fixes $S_t$ and normalizes only within
that support:

$ w_(t,i) = frac(exp(a_(t,i)),
  sum_(j in S_t) exp(a_(t,j))), quad i in S_t. $

When no selected output is dropped, these weights sum to one. If a later mask
rejects a selected pair, an implementation must state whether it leaves the
surviving weights unchanged, renormalizes them, reroutes the token, or sends it
through another path. There is no universal post-drop convention.

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

= Parameters, Cost, and Capacity <cost-and-capacity>

== A consistent ledger <cost-ledger>

A sparse layer has several non-interchangeable cost quantities. Comparisons
should hold the dense baseline, hidden width, sequence length, precision,
batch shape, and parallel layout fixed before quoting a ratio.

#table(
  columns: (1.55fr, 2.25fr, 3fr),
  table.header([Quantity], [What it counts], [Boundary]),
  [Total parameters], [All expert, shared, router, attention, and dense weights in the model], [It is a storage and model-capacity quantity, not per-token compute.],
  [Active parameters], [Weights touched by one token under a stated route], [It depends on $K$, shared paths, and what the source calls active.],
  [Weight storage], [Resident or sharded parameter bytes], [All experts may need distributed storage even when a token executes few.],
  [Activations], [Token and intermediate tensors retained for forward/backward], [Checkpointing, microbatching, and parallelism change this independently of weights.],
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
structures. The `shared_budget_ledger` check verifies this fixed ledger.

== Partial drop preserves other paths <partial-drop>

If one requested pair is rejected, the entire layer output need not be zero.
For instance, with $H_t = 3$, selected routed weights $(0.4, 0.6)$, acceptance
mask $(1, 0)$, and routed outputs $(2, 7)$, the no-renormalization convention
produces $3 + 0.4 dot 2 = 3.8$. The rejected route is zero, while both the
accepted route and the shared branch remain present.

#note[
  Capacity acts on token-expert pairs, not on the abstract existence of a
  layer. The preceding example deliberately fixes the post-drop convention;
  a rerouting or renormalizing implementation has a different equation and
  must be analyzed as such.
]

= Task Gradients and Routing <task-gradients>

== Fixed-support derivative <fixed-support-gradient>

Consider only the routed branch $y_t^r = sum_(i in S_t) w_(t,i) E_i (x_t)$.
Assume a selected-softmax gate, a fixed support $S_t$, no ties at the selection
boundary, no drop, and route scale one. Let $delta = partial cal(L) / partial
y_t^r$ be the upstream vector. For $j in S_t$, differentiation gives

$ frac(partial cal(L), partial a_(t,j))
  = w_(t,j) delta^T (E_j (x_t) - y_t^r), $

and the local derivative through this gate is zero for an index outside $S_t$. The
subtracted term is the *routed* output. A shared branch can affect the upstream
$delta$ through the total model loss, but it must not be substituted for
y_t^r in this softmax derivative.

With three scalar expert outputs $(0, 1, 2)$, $K = 2$, and logits
$(op("ln")(4), op("ln")(2), 0)$, the support is $(0, 1)$ and the selected
weights are $(2/3, 1/3)$. For scalar loss $cal(L) = y_t^r$, the gradient is
$(-2/9, 2/9, 0)$. The finite-difference check named
`fixed_support_gradient` verifies this labeled example.

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

which is nonzero unless its factors vanish. The check `top_one_gradient` uses
the same fixed logits and confirms zero for the normalized path and a nonzero
finite difference for the full-softmax path.

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
the boundary changes. The `support_change` check fixes the tie rule and verifies
this arithmetic. Hard routing does not therefore guarantee specialization, and
a soft mixture does not guarantee homogeneous experts; both are empirical
outcomes of a complete training procedure.

= Load Balancing and Stability <load-balancing>

== Auxiliary balance as a surrogate <balance-stopgrad>

One common balance surrogate is

$ cal(L)_"bal" = alpha N sum_(i=1)^N op("stopgrad")(f_i) P_i, $

where $f_i$ is a measured requested-load fraction and $P_i$ is an average
of a specified differentiable gate probability. The stop-gradient notation
means this local derivative treats the empirical fraction as fixed. For a
single softmax vector $p$, the corresponding direction is

$ frac(partial cal(L)_"bal", partial a_j)
  = alpha N p_j (f_j - sum_i f_i p_i). $

The centering term is $f_j - sum_i f_i p_i$, not generally $f_j - 1/N$.
When $f$ is uniform, the scalar surrogate is constant and this gradient is
silent. When $p$ is uniform but $f$ is unequal, it can be nonzero. The
`balance_stopgrad` check covers both finite cases. Equal scalar values alone
do not prove that every feedback path is inactive.

The coefficient $alpha$ is an auxiliary tradeoff weight, not unconditionally
a Lagrange multiplier. Its value does not by itself establish a universal
inverse-$alpha$ violation law, a required smallness condition, or convergence.
It can also change the task trajectory by changing which experts receive data.

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
rescue gradient. The `zloss_counterexample` check evaluates two stable,
floating-point instances with explicit tolerance.

== Bias feedback changes selection <sign-feedback-cycle>

Auxiliary-loss-free balancing @lossfree2024 can update a per-expert bias from past load
statistics and use

$ a'_(t,i) = a_(t,i) + b_i, quad S_t = op("TopK")_i (a'_(t,i)). $

The intended output fusion may still use the unmodified affinities. For a
two-expert deterministic toy controller, fixed-size sign updates can alternate
between $(0, 0)$ and $(-1, 1)$. The `sign_feedback_cycle` check demonstrates
that two-cycle. Bounded increments alone do not prove bounded controller state
or convergence, and the absence of an additional auxiliary gradient does not
mean that changed selections cannot affect the task path.

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
is not a model-independent sentence. Capacity and balancing choices in Switch
also depend on its training setup; this note uses them as a contrast for the
normalized selected-top-1 derivative, not as a performance comparison.

== Mixtral <mixtral-case>

The frozen Mixtral source is arXiv:2401.04088v1 @mixtral2024. Its 8x7B model
uses eight experts per layer and selects two, then normalizes the selected
softmax weights. Its experts are SwiGLU FFNs. The architecture gives a concrete
multi-expert case without implying that top-2, eight experts, or SwiGLU is
mandatory for an MoE.

== DeepSeekMoE <deepseekmoe-case>

The frozen DeepSeekMoE source is arXiv:2401.06066v1 @deepseekmoe2024. Its
fine-grained segmentation splits a coarse expert budget into more, narrower
routed units, and its shared experts are always-on. The combinatorial choice
space can increase under a matched nominal active width, but that count alone
is not a quality proof. The DeepSeek-specific short explanation and system
consequences are intentionally kept in
#link("../DeepSeek/DeepSeek_Architecture.pdf")[DeepSeek Architecture].

== DeepSeek-V3 <deepseek-v3-case>

The frozen V3 paper source is arXiv:2412.19437v2 @deepseekv3-2024. The
reference implementation is the `Gate` definition @deepseekv3-gate in
#link("https://github.com/deepseek-ai/DeepSeek-V3/blob/f6e34dd26772dd4a216be94a8899276c5dca9e43/inference/model.py")[DeepSeek-V3 commit f6e34dd26772dd4a216be94a8899276c5dca9e43].
At that revision, scores use either softmax or sigmoid; the V3 path uses
sigmoid affinities. The code stores `original_scores`, adds the learned bias
only to selection scores, selects experts, gathers the unmodified affinities,
normalizes the selected sigmoid weights, and multiplies by `route_scale`.

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
$(0, 1)$, the former selects index 0 while the latter selects index 1. The
`affinity_bias_selection` check fixes that example.

V3 calls its main global method auxiliary-loss-free, but its report also adds a
small sequence-wise balance auxiliary term to prevent extreme per-sequence
imbalance. The phrase "loss-free" therefore does not mean that V3 has no
balancing signal of any kind. The report's group/node limits, route scale, and
sequence loss belong to this source version, not to the generic MoE equations.

= Appendix: Finite Examples and Limits <finite-examples>

#table(
  columns: (1.65fr, 2fr, 3.5fr),
  table.header([Text label], [Executable check], [What the fixed example establishes]),
  [#ref(<fixed-support-gradient>)], [`fixed_support_gradient`], [A selected-softmax local derivative agrees with a central finite difference while support is fixed.],
  [#ref(<top-one-gradient>)], [`top_one_gradient`], [Normalized selected top-1 and full-softmax top-1 have different local derivatives.],
  [#ref(<support-change>)], [`support_change`], [Updating only selected logits can change a later top-k support.],
  [#ref(<zloss-counterexample>)], [`zloss_counterexample`], [Zero log partition does not prevent a large two-logit span.],
  [#ref(<balance-stopgrad>)], [`balance_stopgrad`], [A uniform load can be locally silent while unequal load yields a nonzero stop-gradient direction.],
  [#ref(<partial-drop>)], [`partial_drop`], [A rejected token-expert pair need not zero the accepted or shared output.],
  [#ref(<shared-budget-ledger>)], [`shared_budget_ledger`], [Six routed selections plus two shared paths give eight active paths; capacity counts 48 routed requests, not 64.],
  [#ref(<sign-feedback-cycle>)], [`sign_feedback_cycle`], [A fixed-step sign controller can form a two-cycle.],
  [#ref(<affinity-bias-selection>)], [`affinity_bias_selection`], [Bias placement before or after sigmoid can change selection.],
)

These are algebra and finite-difference checks with fixed inputs, explicit
floating-point tolerances, and independent test state. They are deliberately
not proofs of general MoE quality, balanced usage at scale, or optimizer
convergence.

= Sources and Further Reading <sources>

The local bibliography freezes the papers used for general definitions,
stability boundaries, case studies, and dropless execution. For a DeepSeek
reading path, use
#link("../DeepSeek/DeepSeek_Overview.pdf")[DeepSeek Overview] first, then
#link("../DeepSeek/DeepSeek_Architecture.pdf")[DeepSeek Architecture] and
#link("../DeepSeek/DeepSeek_Systems.pdf")[DeepSeek Systems].

#bibliography("references.bib", style: "ieee", full: true)
