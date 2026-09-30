#import "/templates/lib.typ": conf, definition, note

#set document(
  title: "DeepSeek Systems, Serving, and Environments",
  author: "Abel Zhan",
)

#show: conf

= Scope and source boundary

This note follows the systems line from Fire-Flyer and 3FS through V3 training, serving-side speculative decoding, and elastic agent environments. The as-of date is *2026-09-30*. Papers and technical reports support what they report; official repositories document artifacts and implementation interfaces but are explicitly *non-paper artifacts* unless a separate paper is cited.

The central systems equation is a balance rather than a single FLOP count:

$ T_s = max(T_c, T_m, T_r) + T_u. $

Sparse models reduce active compute, but routing, KV reads, synchronization, and storage can become the new bottleneck. The systems line is therefore part of the model design rather than an after-the-fact deployment layer.

= Fire-Flyer and the storage substrate

Fire-Flyer AI-HPC [paper, #link("https://arxiv.org/abs/2408.14158")[2408.14158]] describes a cost-oriented cluster built from PCIe A100 nodes, direct network attachment, a two-layer fat-tree, and software that overlaps communication with computation. The report describes roughly 10,000 GPUs, storage integrated with the compute fabric, and HAI-Platform scheduling. Its headline performance and cost ratios are *report-reported comparisons* under the hardware configuration in the paper.

The relevant design principle is locality-aware co-design:

- a NIC on an independent PCIe root complex reduces contention with GPU traffic;
- a two-layer fabric reduces switch count relative to a three-layer design;
- asynchronous all-reduce and pipeline/tensor parallelism hide communication behind useful work;
- checkpoint validation and failure characterization make long training runs operationally possible.

== 3FS

#link("https://github.com/deepseek-ai/3FS")[3FS] is an official DeepSeek repository for a distributed file system. It is a *repository artifact, not a paper*. The DSec report later describes on-demand image data loading from Fire-Flyer File System (3FS), which gives a traceable systems connection without turning the README into a research citation.

The storage lesson is especially important for agentic workloads: a sandbox image or checkpoint need not be eagerly copied to every worker if the data path can fetch layers on demand and the scheduler can overlap I/O with environment startup.

= V3 training: overlap and routing

DeepSeek-V3 [paper, #link("https://arxiv.org/abs/2412.19437")[2412.19437]] combines a 671B-total, 37B-activated MoE with MLA, FP8 mixed precision, auxiliary-loss-free balancing, and DualPipe. The reported training run uses 2,048 H800 GPUs and 2.788 million H800 GPU-hours, with a report-estimated cost of 5.576 million US dollars. Those are values reported by the V3 report, not an independently audited invoice.

== DualPipe

Pipeline parallelism ordinarily leaves bubbles while one stage waits for another. DualPipe uses two micro-batches and overlaps forward/backward computation with expert dispatch and combine communication. A simplified schedule is

$ A: c -> m,
  quad B: m -> c $

The goal is to keep both GPU arithmetic and the interconnect busy. The exact schedule, memory trade-offs, and failure behavior are implementation details of the report and repository.

#link("https://github.com/deepseek-ai/DualPipe")[DualPipe] is an official repository. Its README says the method was introduced in the V3 technical report and cites `2412.19437`; it is still not itself a paper. This distinction matters when a repository's README contains a useful explanation but no peer-reviewed metadata.

== DeepEP and EPLB

#link("https://github.com/deepseek-ai/DeepEP")[DeepEP] provides expert-parallel communication kernels, including cross-node all-to-all paths. #link("https://github.com/deepseek-ai/EPLB")[EPLB] is an expert-parallel load-balancing repository. Both are official repositories and non-paper artifacts. The V3 report is the paper source for its own routing and communication claims; a repository can show code availability without proving that every later checkpoint used the same commit.

The communication volume for a token routed to $K$ experts is approximately proportional to $K d b$, where $d$ is hidden width and $b$ is bytes per scalar, before metadata and replication. Node-limited routing bounds how many destinations a token can reach. The bound can reduce network traffic while making the routing problem more constrained.

= Systems evidence from the V3 hardware reflection

The ISCA industry-track paper *Insights into DeepSeek-V3* [paper, #link("https://arxiv.org/abs/2505.09343")[2505.09343], DOI #link("https://doi.org/10.1145/3695053.3731412")[10.1145/3695053.3731412]] quantifies memory and interconnect effects. It reports 70.272 KB of BF16 KV cache per token for V3, compared with 327.680 KB for Qwen-2.5 72B and 516.096 KB for LLaMA-3.1 405B under its comparison setup. It also reports 250 GFLOPs per token for the V3 MoE at sequence length 4096, compared with 2,448 GFLOPs for the dense 405B comparison.

The paper models an expert-parallel all-to-all step at 120.96 microseconds on a 400 Gbps link and gives a theoretical GB200 comparison at 6.72 microseconds. The result is useful as a bottleneck model, not as a universal production throughput guarantee. Hardware topology, batch shape, kernel version, and contention can change the result.

= Serving and speculative decoding

A target model with distribution $p$ can verify a proposed block from a draft model with distribution $q$. For a proposed token $x_i$, rejection sampling accepts with probability

$ a_i = min(1, p_i / q_i). $

Here $p_i$ is the target probability and $q_i$ is the draft probability for the proposed token under the same prefix.

In practice a serving engine accepts a left-to-right prefix and resamples or falls back at the first rejection. If $a$ tokens are accepted on average from a block and draft plus verification time is $T_d + T_v$, the rough throughput multiplier against one-token target decoding is

$ S approx (1 + a) T_0 / (T_d + T_v) $

This expression is deliberately approximate: batching, scheduler capacity, target-model KV reuse, and rejected suffixes matter.

== MTP baseline

V3's MTP modules propose future tokens that the target can verify in parallel. The systems reflection reports 80--90 percent acceptance for a second subsequent token and about 1.8 times generation throughput in one experiment. The values are source-reported and depend on the target, context, and serving setup.

== DSpark

DSpark [paper, #link("https://arxiv.org/abs/2607.05147")[2607.05147]] targets long-block drafting under production concurrency. Its draft is semi-autoregressive: a parallel backbone proposes most positions, then a lightweight sequential Markov or recurrent head restores within-block dependence. A confidence head estimates prefix survival, and a hardware-aware scheduler chooses how many positions to verify rather than always verifying the entire block.

The paper reports the following evidence chain:

- The #link("https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash-DSpark")[V4-Flash-DSpark] and #link("https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro-DSpark")[V4-Pro-DSpark] model-card records are dated 2026-06-27.
- The DSpark paper was submitted on 2026-07-06.
- The paper says the method ran in the DeepSeek-V4 serving system under live user traffic.
- The cards state that an attached DSpark module is not a new base model and point to #link("https://github.com/deepseek-ai/DeepSpec")[DeepSpec].

The cards carry an arXiv tag for the V4 report rather than the DSpark paper. That is a metadata trap, not evidence that DSpark is described by the V4 paper. The paper reports per-user speed improvements of 60--85 percent for V4-Flash and 57--78 percent for V4-Pro against an MTP-1 baseline at matched aggregate throughput. These are vendor-reported serving claims.

= DSec: environments for agentic training

DeepSeek Elastic Compute (DSec) [paper, #link("https://arxiv.org/abs/2609.22978")[2609.22978]] provides stateful sandboxes for training and evaluating agents. Its SDK spans function-call, container, microVM, and full-VM backends. A request specifies the image or environment, CPU and memory limits, lifetime, and network rules.

The important coupling is between rollout state and preemptible training:

$ A -> B -> C -> A $

Suspension lets GPU resources be reclaimed without discarding the environment's filesystem and process state. High-density scheduling uses memory sharing, reclamation, and CPU quality-of-service controls because most sandboxes wait on an LLM and are not CPU-saturated continuously. Image layers are loaded on demand from 3FS rather than eagerly copied everywhere.

The report gives production-scale figures of about 3 million sandboxes per day, more than 380,000 concurrent sandboxes, and more than 5,000 creations per second. It reports a 1.7 times completion-time stretch for eager image pulling and a 57 percent reduction in cumulative disk writes with on-demand loading. These are report-reported measurements; the bodies of some later ablation sections were not available in the checked extraction, so the collection does not infer additional mechanisms.

The V4.1-Flash report has a DSec section title, and the DSec paper describes the platform as already used in production. That supports an infrastructure lineage, not a claim that every V4.1 training detail is public.

= Repository and paper boundary

#table(
  columns: (1.8fr, 2fr, 2.5fr, 2.3fr),
  table.header([Artifact], [Class], [What it can support], [What it cannot establish alone]),
  [Fire-Flyer AI-HPC], [primary paper/report], [Hardware and software co-design claims in the report], [Which named model used every cluster component.],
  [3FS], [official repository], [Filesystem implementation and README behavior], [A peer-reviewed 3FS paper or every production deployment.],
  [DeepEP], [official repository], [Expert-parallel communication code], [A standalone paper or universal kernel performance.],
  [EPLB], [official repository], [Load-balancing implementation artifact], [Adoption by every later model.],
  [DualPipe], [official repository plus V3 citation], [Code associated with the V3 method], [Repository-as-paper status.],
  [DeepSpec], [official repository], [Checkpoint/config inventory for DSpark, DFlash, and EAGLE-3], [DeepSeek authorship of the third-party drafting algorithms.],
  [DSpark cards], [model card / weights], [Attached module, command-line configuration, shard metadata], [A new base model or replacement for the DSpark paper.],
  [DSec], [primary paper/report], [Sandbox architecture and reported production measurements], [A guarantee that all unreleased V4.1 internals are public.],
)

= Open systems questions

The checked sources do not establish a single public end-to-end serving stack for every V4 revision, the exact production kernel versions behind the reported DSpark gains, or whether LPLB was adopted in a released model. They also do not turn the GitHub PDFs and READMEs for V3.2-Exp into peer-reviewed papers. The absence wording is bounded: these artifacts were *not found in the checked sources as of 2026-09-30*.

= Source trail

Primary sources are #link("https://arxiv.org/abs/2408.14158")[Fire-Flyer], #link("https://arxiv.org/abs/2412.19437")[DeepSeek-V3], #link("https://arxiv.org/abs/2505.09343")[Insights into DeepSeek-V3], #link("https://arxiv.org/abs/2607.05147")[DSpark], and #link("https://arxiv.org/abs/2609.22978")[DSec]. Official non-paper artifacts are #link("https://github.com/deepseek-ai/3FS")[3FS], #link("https://github.com/deepseek-ai/DeepEP")[DeepEP], #link("https://github.com/deepseek-ai/EPLB")[EPLB], #link("https://github.com/deepseek-ai/DualPipe")[DualPipe], and #link("https://github.com/deepseek-ai/DeepSpec")[DeepSpec]. Product timing is sourced from the #link("https://api-docs.deepseek.com/updates/")[DeepSeek release index] and the named model cards.
