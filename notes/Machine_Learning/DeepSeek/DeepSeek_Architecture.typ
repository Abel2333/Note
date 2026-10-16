#import "/templates/lib.typ": RR, conf, definition, note, theorem

#set document(
  title: "DeepSeek Architecture and Efficiency",
  author: "Abel Zhan",
)

#show: conf

= Scope and notation

This note follows the architecture line from DeepSeekMoE and MLA through V3, DSA, V4, and V4.1-Flash. The as-of date is *2026-09-30*. A source label such as `[paper]`, `[model card]`, or `[repository]` identifies the evidence class; a model card or repository is not silently treated as a paper. General Transformer-FFN MoE definitions, gate variants, capacity semantics, and local routing derivatives are centralized in #link("../Deep_Learning/Mixture_of_Experts.pdf")[Mixture of Experts]; this note keeps only the DeepSeek-specific architecture map.

Let $L$ be sequence length, $d$ the hidden width, $h$ the number of query heads, and $d_h$ the head dimension. For an MoE layer, let $N$ be the number of routed experts, $K_r$ the number selected from them per token, $K_s$ the number of always-on shared experts, and $d_f$ the dense intermediate width. This maps the generic MoE notation as $K = K_r = |S_t|$. The active-expert count is $K_"active" = K_r + K_s$; if an external configuration fixes that total, write $K_"total" = K_"active"$ rather than redefining $K$. Such a count directly proxies active parameters or compute only when shared and routed experts have the same relevant structure and width. The comparisons below hold under the stated assumptions: equal hidden width, comparable optimizer state, and no hidden communication or quantization overhead unless noted.

= DeepSeekMoE: sparse compute and specialization intent

A dense feed-forward block applies one transformation to every token:

$ op("FFN")(x) = W_2 op("sigma")(W_1 x), quad W_1 in RR^(d_f times d), quad W_2 in RR^(d times d_f) $

Its parameter and multiply cost scale with $d d_f$. A conventional sparse MoE replaces one FFN by $N$ experts $E_i$ and routes a token to $K_r$ of them:

$ y_t = sum_(i in S_t) p_(t,i) E_i(x_t), quad S_t = op("TopK")_i(s_(t,i)), quad |S_t| = K_r, quad sum_(i in S_t) p_(t,i) = 1 $

The total parameter capacity is approximately $N$ times a single expert, while the active routed compute is approximately $K_r$ expert evaluations; shared-path cost is accounted for separately. This design can encourage specialization, but observed semantic roles still depend on the data, task, optimization, and training dynamics. It also creates two failure modes: tokens can crowd a few experts, and experts can learn mixtures of unrelated knowledge.

== Fine-grained segmentation

DeepSeekMoE splits each coarse expert into $m$ experts with intermediate width $d_f / m$. It then selects $m K_r$ of $m N$ experts. Ignoring router cost,

$ (m K_r) (d_f / m) = K_r d_f $

so active FLOPs remain approximately constant, while the number of possible expert combinations grows from $binom(N, K_r)$ to $binom(m N, m K_r)$. The paper's illustrative comparison is

$ binom(16, 2) = 120 quad "versus" quad binom(64, 8) = 4_426_165_368 $

The combinatorial count is not itself a quality proof. Its useful interpretation is that a token can form a much finer mixture of learned subskills under the same nominal active width.

== Shared expert isolation

A fixed set of $K_s$ shared experts is always activated as a design intended to give broadly reused transformations a common path. The router independently chooses $K_r$ routed experts, with $|S_t| = K_r$. A simplified layer is

$ y_t = sum_(i=1)^(K_s) E_i^s(x_t) + sum_(i in S_t) p_(t,i) E_i^r(x_t) $

The architecture separates an always-on path from conditional routed paths and can encourage the intended common-versus-specialized roles; whether semantic specialization emerges still depends on the data, task, optimization, and training dynamics. The DeepSeekMoE paper @deepseek-moe reports the design; the DeepSeek-V2 report @deepseek-v2 and later reports reuse the family. The V2 card and later model cards are evidence of model configuration, not independent paper results.

#note[
  The phrase "activated parameters" is conditional on a token and routing policy. Total parameters, active parameters, communication volume, and memory residency are different quantities. A 671B total / 37B activated model can still require distributed storage and all-to-all communication for the routed experts.
]

== Routing and communication consequence

Top-$K_r$ routing sends token representations to expert-parallel devices and returns the results. If $T$ tokens are routed uniformly over $D$ devices, the ideal payload per device is about $T K_r / D$. Skew increases the maximum payload and therefore the step time. Fine-grained experts improve selection granularity, but they do not remove the all-to-all; node-limited routing and communication kernels are systems solutions discussed in #link("DeepSeek_Systems.pdf")[Systems].

= MLA: compress the KV cache, preserve positional information

For a standard MHA baseline with $h$ independent KV heads, a decoder stores a key and value vector for every past token and head. The cache size per token is approximately

$ M_"MHA" = 2 h d_h b $,

where $d_h$ is the per-head width and $b$ is bytes per scalar. For a sequence of length $L$, memory is $L M_"MHA"$. This baseline deliberately excludes MQA/GQA sharing, whose KV-head count changes the comparison.

== Low-rank joint compression

Let $h_t in RR^d$ be the hidden state at position $t$, and let $c_t^("KV") in RR^(d_c)$ be a compact KV latent, where $d_c << h d_h$. MLA forms it with a down projection:

$ c_t^("KV") = W^("DKV") h_t, quad W^("DKV") in RR^(d_c times d) $

For exposition, concatenate all content heads. The content key and value can then be reconstructed conceptually as

$ k_t^C = W^("UK") c_t^("KV"), quad v_t = W^("UV") c_t^("KV"), $

where $k_t^C, v_t in RR^(h d_h)$ and $W^("UK"), W^("UV") in RR^((h d_h) times d_c)$. The distinct $W^("DKV")$, $W^("UK")$, and $W^("UV")$ names distinguish hidden-to-latent, latent-to-key, and latent-to-value maps.

At inference, MLA caches the latent $c_j^("KV")$ for each prior position $j$, not the conceptual materializations $k_j^C$ and $v_j$. The content projections can be absorbed or fused into the current-query and output computation, so caching the latent is sufficient for that path.

== Decoupled RoPE

Rotary position embeddings cannot generally be absorbed into a position-independent low-rank projection. MLA therefore keeps a separate positional path:

$ q_t^R = op("RoPE")(W^("QR") h_t, t), quad k_t^R = op("RoPE")(W^("KR") h_t, t) $

with $q_t^R, k_t^R in RR^(d_r)$ and $W^("QR"), W^("KR") in RR^(d_r times d)$. The attention inputs combine content and positional components,

$ q_t = [q_t^C; q_t^R], quad k_j = [k_j^C; k_j^R], $

where $q_t^C$ is computed for the current token and is not cached. The actual cached pair for each prior token is therefore $(c_j^("KV"), k_j^R)$: the KV latent plus the decoupled RoPE key. If $d_r$ denotes the total stored RoPE-key width across KV heads, the idealized cache is

$ M_"MLA" = (d_c + d_r) b, $

and, against the stated MHA baseline,

$ M_"MLA" / M_"MHA" = (d_c + d_r) / (2 h d_h) $

This is a cache-storage comparison, not an attention-FLOP or universal runtime theorem; projection fusion, KV-head sharing, precision, and kernel layout affect realized savings. The V2 report gives the mechanism and reports a 93.3 percent KV-cache reduction against the DeepSeek 67B baseline. A later systems report @v3-hardware gives a concrete BF16 comparison: V3 at 70.272 KB per token, Qwen-2.5 72B at 327.680 KB, and LLaMA-3.1 405B at 516.096 KB. Those are source-reported measurements under that report's configurations, not universal constants.

== Training-memory distinction

MLA also uses a low-rank query projection during training. That reduces activation traffic for the training computation, but it is not the same claim as decoder KV-cache compression. The cache result concerns keys and values retained across time; training activation memory also depends on checkpointing, sequence parallelism, precision, and batch shape.

= Auxiliary-loss-free load balancing

The standard MoE balance loss adds a gradient objective to equalize expert usage. It can interfere with the language-model objective, especially when the router needs a nonuniform allocation. The auxiliary-loss-free method instead changes only the selection score; the gate variants, local-gradient conditions, and controller limits are developed in #link("../Deep_Learning/Mixture_of_Experts.pdf")[Mixture of Experts]:

$ s'_(t,i) = s_(t,i) + b_i, quad S_t = op("TopK")_i(s'_(t,i)) $

The bias $b_i$ is not added to the mixture weight used to combine expert outputs. Let $c_i$ be a recent load estimate and $bar(c)$ the mean load. A sign update is

$ b_i = b_i + u dot op("sign")(bar(c) - c_i) $

An underused expert receives a positive bias; an overused expert receives a negative bias. Updating from historical or completed-batch statistics avoids using future tokens from the current sequence. The method paper @loss-free-balancing reports lower load violation without the same auxiliary-loss interference. The V3 report @deepseek-v3 explicitly names an auxiliary-loss-free strategy and also reports a small sequence-wise balance auxiliary term to prevent extreme per-sequence imbalance. Thus V3's "loss-free" label does not mean that it has no balancing signal. V4 has its own separately reported routing configuration and does not retroactively define V3.

#definition(title: "Router versus mixture")[
  The router chooses $S_t$ with the biased score $s'_(t,i)$. The output mixture uses the unmodified gate weights $p_(t,i)$. Conflating these two operations incorrectly implies that the bias directly changes the expert output scale.
]

= Precision: FP8 training and FP4 cache paths

For a block of values $x$, a simple symmetric quantizer can be written as

$ q = op("clip")(op("round")(x / s), q_min, q_max), quad hat(x) = s q $

Fine-grained scales reduce the range represented by one scale. The quantization error depends on the block distribution and saturation; accumulation precision and rescaling policy determine whether the error is amplified by matrix products.

== FP8 in V3

The V3 report @deepseek-v3 describes FP8 mixed precision with fine-grained quantization, online scaling, higher-precision accumulation, and low-precision states or communication where appropriate. The systems consequence is not simply half the bytes: scale metadata, reductions, overflow handling, and kernel support must fit the communication schedule. FP8 is reported as a training and communication design in V3; it should not be generalized to every DeepSeek checkpoint without a source.

== FP4 in V4 and V4.1-Flash

The V4 report @deepseek-v4 describes FP4 quantization-aware training for routed expert weights and the indexer query/key path. The V4.1-Flash report @deepseek-v41-flash additionally reports training with an FP4 main KV cache and marginal degradation in its experiments. Cache quantization trades memory bandwidth for quantization error and dequantization work; it does not alter the asymptotic attention expression by itself. The claims are report-specific and should be read with their calibration and hardware assumptions.

= Multi-Token Prediction and speculative verification

A next-token model estimates $p(x_(t+1) | x_(<=t))$. MTP adds lightweight prediction modules that estimate several future positions, for example

$ p_j = p_theta(x_(t+j) | h_t, x_(t+1), dots, x_(t+j-1)), quad j = 1, dots, k $

At inference, these predictions can propose a block. The target model verifies the block in parallel or near-parallel, accepting a prefix and rejecting at the first mismatch. If the mean accepted draft length is $a$ and draft plus verification cost is $C_d + C_v$, a rough token cost is

$ C_"acc" approx (C_d + C_v) / (1 + a) $

The estimate assumes the target can verify multiple positions efficiently and that rejected suffix work is bounded. V3 introduces MTP and states that it can support speculative decoding; the V3 report @deepseek-v3 and the systems reflection @v3-hardware report 80--90 percent acceptance for a second subsequent token and about 1.8 times generation throughput in one setting. DSpark replaces a fixed draft/verify policy with confidence scheduling; see #link("DeepSeek_Systems.pdf")[Systems].

= Sparse attention: NSA, DSA, CSA, and HCA

Full causal attention computes scores for every query-key pair, with score and value work proportional to $O(L^2 d_h)$ and a KV read that grows with $L$. Sparse attention keeps a subset of keys per query. If $k << L$, the core attention work becomes $O(L k d_h)$, but the indexer, memory gathers, and kernel utilization can dominate.

== NSA: trainable hardware-aligned sparsity

The Native Sparse Attention (NSA) paper @nsa combines three branches:

$ o_t = g_t^c op("Attn")(q_t, K_t^c, V_t^c) + g_t^s op("Attn")(q_t, K_t^s, V_t^s) + g_t^w op("Attn")(q_t, K_t^w, V_t^w) $

The branches are compressed blocks, selected blocks, and a local sliding window. Block selection and group-consistent GQA are designed so the memory access pattern matches the theoretical sparsity. The paper gives an internal pre-training-token conflict: 260B in the introduction and 270B in the experimental section for the same research backbone. No checked source establishes that NSA shipped in a released DeepSeek model as of the as-of date.

== DSA: model-first sparse attention

DeepSeek Sparse Attention (DSA) uses a lightweight lightning indexer to score query/prior-token pairs and retains the top $k$ KV entries:

$ I_t = op("TopK")_j(f_i(q_t, h_j)), quad |I_t| = k,
  quad o_t = op("Attn")(q_t, K_(I_t), V_(I_t)) $

The attention part is $O(L k)$ rather than $O(L^2)$, while index construction and top-K selection add their own cost. The V3.2 report @deepseek-v32 uses $k = 2048$, a dense indexer warm-up, KL alignment to the dense attention distribution, and then sparse training. The V3.2-Exp official release note @release-v32-exp dates the model to 2025-09-29; the arXiv report arrived 2025-12-02. This is a model-before-paper case.

== CSA and HCA in V4

The V4 report @deepseek-v4 combines two complementary approximations:

- *Compressed Sparse Attention (CSA)* compresses sequence-wise KV information and then applies a DSA-style sparse lookup.
- *Heavily Compressed Attention (HCA)* compresses more aggressively but retains dense attention over the compressed representation.

The hybrid is a systems compromise. CSA supplies long-range sparsity; HCA preserves a dense path that can recover information lost by aggressive selection. The report claims that at one million tokens V4-Pro needs 10 percent of V3.2's KV cache and 27 percent of its single-token inference FLOPs. Those are vendor-reported comparisons, not a proof that every workload gets the same ratio.

= mHC: constrain residual mixing

Hyper-Connections widen the residual stream and mix branches with a matrix $H_l^r$. An unconstrained matrix can amplify or cancel signals across depth. mHC projects the residual map to the Birkhoff polytope:

$ cal(B) = {H | H 1 = 1, quad 1^T H = 1^T, quad H >= 0} $

A Sinkhorn-Knopp projection approximately normalizes rows and columns. Since a doubly stochastic matrix is a convex combination of permutation matrices, the residual operation is a structured feature mixing rather than arbitrary amplification. Under the ideal constraint, the spectral norm is at most one in the stated norm and products remain in the same family.

The mHC paper @mhc also constrains pre- and post-mixing maps to be nonnegative. Its systems argument matters as much as the geometry: ordinary Hyper-Connections add memory traffic approximately proportional to expansion rate $n$, with the paper's per-token read/write forms

$ R_d = (5n + 1) C + n^2 + 2n, quad W_d = (3n + 1) C + n^2 + 2n $

Here $C$ is the channel width and $n$ is typically small, such as 4. The report claims 6.7 percent extra time at $n=4$ after kernel fusion. V4 names mHC as a headline upgrade, and V4.1-Flash names a single-pass mHC and Mega-mHC kernel. The landing is therefore paper-first, then model/report evidence.

= Engram: conditional memory as another sparsity axis

MoE makes compute conditional; Engram makes static memory conditional. For an N-gram context $g_t$, a hash lookup selects table rows:

$ e_t = e_1 + dots + e_R $

A context-aware gate fuses the retrieved memory $m_t$ with the dynamic hidden state $h_t$, schematically

$ z_t = h_t + alpha_t dot m_t $

The exact implementation uses multiple N-gram orders, multi-head hashing, normalization, a depthwise causal convolution, and selected layers. Host-memory prefetch and sharding make the lookup a systems operation rather than a free table read.

The Engram paper @engram reports gains against an iso-parameter, iso-FLOPs MoE-27B baseline and a 100B table offloaded to host memory with less than 3 percent overhead in one experiment. The standalone Engram repository @repo-engram is a demo that mocks standard components; it is an official repository, not a paper. V4.1-Flash's card and report name a 196B Engram component, which is separate model evidence.

= CED and CSA2 in V4.1-Flash

V4.1-Flash changes the V4 hybrid into a causal encoder-decoder arrangement. Let $N$ be prompt tokens, $L$ the total number of transformer layers, and $n_w$ the local decoder replay-window length. For an even split, the first $L/2$ layers encode all $N$ prompt tokens and the remaining $L/2$ decoder layers consume projected global KV from the final encoder state while replaying a local window.

Counting layer-token processing only, a conventional causal stack has idealized prefill complexity $O(N L)$. Under the stated long-prompt assumption $N >> n_w$, CED has the idealized comparison

$ O(N L) quad "versus" quad O(N L / 2 + n_w L / 2). $

This is a source-oriented prefill accounting comparison, not an exact runtime theorem. Actual work also includes projecting encoder outputs into global KV, CSA2 index construction, cache writes and transfers, sparse-attention gathers, and bounded replay of local-window states. Those costs and their kernel implementations determine the realized latency and can dominate at smaller prompts.

CED avoids recomputing full-prompt decoder state at every later layer by shifting work into encoder representations and projected cache state. The V4.1-Flash report @deepseek-v41-flash describes the architecture and its bounded-replay implementation; this note does not infer an unsupported exact speedup.

CSA2 reuses global KV and index information across layers with three modes:

- *Full:* generate global KV and index entries.
- *Reindex:* reuse the previous layer's global KV but rescore with the current query.
- *Reuse:* reuse both global KV and top-K indices and perform sparse attention directly.

V4.1-Flash reports pure CSA2 instead of V4's CSA+HCA hybrid, 890 bytes per token for global KV, and a bounded-replay method for local-window states. These are report/card claims tied to a 1M-token implementation. The parameter metadata does not reconcile cleanly with the headline "552B backbone + 196B Engram"; the discrepancy is retained in #link("DeepSeek_Evidence.pdf")[Evidence].

= Comparison table

#table(
  columns: (1.5fr, 1.8fr, 2.4fr, 2.3fr),
  table.header([Mechanism], [Main bottleneck], [Idealized comparison], [Systems consequence]),
  [DeepSeekMoE], [Dense FFN compute and parameter capacity], [Total parameters scale with experts; active compute scales with selected experts], [All-to-all routing, load skew, and expert placement remain first-order costs.],
  [MLA], [KV memory and decode bandwidth], [$O(L^2)$ attention remains, but cache bytes per token fall from $2 h d_h b$ to $(d_c+d_r)b$], [Less HBM traffic; positional path and projection absorption must be implemented correctly.],
  [Loss-free balancing], [Router collapse and auxiliary-loss interference], [Bias changes top-K decisions without changing output gate weights], [Requires historical load state and stable expert/device routing.],
  [FP8 / FP4], [Arithmetic, memory, and communication bytes], [Fewer bits per scalar, subject to scale and accumulation error], [Needs kernels, calibration, metadata, and overflow handling.],
  [DSA / CSA], [Quadratic long-context attention], [$O(L^2)$ core attention to approximately $O(L k)$ after selection], [Indexer and gather kernels must make sparsity real on hardware.],
  [mHC], [Residual amplification and extra memory traffic], [Doubly stochastic residual mixing is non-expansive in the stated analysis], [Sinkhorn and fused kernels trade mathematical stability for implementation work.],
  [Engram], [Repeated static patterns consuming depth and FLOPs], [Lookup cost is conditional and largely independent of deep dynamic compute], [Hash collisions, host-memory locality, and prefetch determine benefit.],
  [CED / CSA2], [Repeated decoder prefill and cross-layer cache construction], [$O(N L)$ to idealized $O(N L / 2 + n_w L / 2)$ for $N >> n_w$; projections and replay remain], [Replay, cache persistence, projection, and layer modes become part of the serving scheduler.],
)

= Source trail

The primary architecture trail is DeepSeekMoE @deepseek-moe, DeepSeek-V2 @deepseek-v2, Auxiliary-Loss-Free Balancing @loss-free-balancing, DeepSeek-V3 @deepseek-v3, NSA @nsa, V3.2 @deepseek-v32, mHC @mhc, Engram @engram, V4 @deepseek-v4, and V4.1-Flash @deepseek-v41-flash. Official repositories such as DualPipe @repo-dualpipe and DeepEP @repo-deepep are covered in #link("DeepSeek_Systems.pdf")[Systems] and are explicitly non-paper artifacts.

= References

#bibliography("references.bib", title: none)
