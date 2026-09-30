#import "/templates/lib.typ": conf, note

#set document(
  title: "DeepSeek: Evolution, Architecture, Reasoning, and Systems",
  author: "Abel Zhan",
)

#show: conf

= Scope and map

This collection is a study map of the DeepSeek research and release surface, current as of *2026-09-30*. It is organized around four interacting lines:

- *Architecture and efficiency:* sparse experts, compressed attention, precision, memory, and long-context mechanisms.
- *Reasoning and post-training:* mathematical reinforcement learning, formal proving, reward modeling, and agentic task synthesis.
- *Systems and environments:* training clusters, communication overlap, serving, speculative decoding, and sandboxes.
- *Multimodality:* vision-language models, unified generation, optical compression, OCR, and V4.1 visual processing.

The durable sources are the six Typst notes and `references.bib`. The Markdown outline that informed this collection is a mutable research aid and is neither read nor built by these notes.

== Start here

#table(
  columns: (1.5fr, 3fr, 2fr),
  table.header([Document], [Question answered], [Primary path]),
  [#link("DeepSeek_Architecture.pdf")[Architecture]], [How do MoE routing, MLA, sparse attention, residual constraints, and conditional memory reduce cost?], [V2 -> V3 -> V4.1],
  [#link("DeepSeek_Reasoning.pdf")[Reasoning]], [How did GRPO grow from a math training trick into proving, R1, reward models, and agentic RL?], [Math -> Prover -> R1 -> V3.2],
  [#link("DeepSeek_Systems.pdf")[Systems]], [Which hardware, communication, serving, and sandbox mechanisms make sparse models usable?], [Fire-Flyer -> V3 -> DSpark/DSec],
  [#link("DeepSeek_Multimodal.pdf")[Multimodal]], [How did visual encoding, unified generation, OCR, and V4.1 multimodality evolve?], [VL -> VL2/Janus -> OCR -> V4.1],
  [#link("DeepSeek_Evidence.pdf")[Evidence]], [What is a paper, what is a release artifact, and which claims remain conflicted or unresolved?], [Read alongside every note],
)

#note[
  A benchmark number in these notes means "the value reported by the named source." It is not an independent reproduction. Vendor claims, third-party measurements, and interpretations are labelled where they occur.
]

= Chronological evolution map

The dates below deliberately separate four events that are often collapsed into one: *paper submission*, *model-card or weight release*, *product or API release*, and a *later revision or report*. A dash means that the checked source did not establish that event, not that the event could not exist.

#table(
  columns: (1.05fr, 2.15fr, 1.25fr, 1.25fr, 1.25fr, 2.2fr),
  table.header([Date], [Artifact or event], [Paper], [Card / weights], [Product / revision], [Interpretive boundary]),
  [2023-10-23], [DeepSeek-Coder first open checkpoints], [--], [model card / weights], [--], [Release artifact; no paper claim here.],
  [2023-11-29], [DeepSeek LLM open checkpoints], [--], [model card / weights], [--], [Release artifact preceding the paper.],
  [2024-01-05], [DeepSeek LLM], [arXiv:2401.02954], [same family], [--], [Scaling and foundation report.],
  [2024-01-11], [DeepSeekMoE], [arXiv:2401.06066], [research models], [--], [Architecture paper; later model adoption is separately sourced.],
  [2024-01-25], [DeepSeek-Coder], [arXiv:2401.14196], [same family], [--], [Code model report, not a V2 report.],
  [2024-02-05], [DeepSeekMath and GRPO], [arXiv:2402.03300], [math checkpoints], [--], [Reasoning/post-training method first appears here.],
  [2024-03-08], [DeepSeek-VL], [arXiv:2403.05525], [1.3B and 7B], [--], [First documented DeepSeek vision-language family.],
  [approx. 2024-04-22], [DeepSeek-V2 initial card / weights], [--], [#link("https://huggingface.co/deepseek-ai/DeepSeek-V2")[model card / weights]], [--], [Approximate card timestamp; distinct from the paper and API update.],
  [2024-05-07], [DeepSeek-V2 paper], [#link("https://arxiv.org/abs/2405.04434")[arXiv:2405.04434 v1]], [--], [--], [MLA and V2 MoE report; not a card or API event.],
  [2024-05-17], [V2-0517 API and chat update], [--], [--], [#link("https://api-docs.deepseek.com/updates/")[product / API update]], [Official changelog entry; distinct from the paper and card.],
  [approx. 2024-06-14], [DeepSeek-Coder-V2 cards / weights], [--], [#link("https://huggingface.co/deepseek-ai/DeepSeek-Coder-V2-Instruct")[model cards / weights]], [--], [Approximate card timing; their paper tag is not the Coder-V2 report.],
  [2024-06-14], [Coder-V2 API update], [--], [--], [#link("https://api-docs.deepseek.com/updates/")[product / API update]], [Official changelog event; separate from the cards and paper.],
  [2024-06-17], [DeepSeek-Coder-V2 paper], [#link("https://arxiv.org/abs/2406.11931")[arXiv:2406.11931]], [--], [--], [Continued pre-training from a V2 checkpoint.],
  [2024-06-28], [V2-0628 revision], [--], [#link("https://huggingface.co/deepseek-ai/DeepSeek-V2-Chat-0628")[model card]], [#link("https://api-docs.deepseek.com/updates/")[product / API revision]], [Changelog and card disagree on baselines; see Evidence.],
  [2024-08-15], [DeepSeek-Prover-V1.5], [arXiv:2408.08152], [prover checkpoints], [--], [Formal proving and GRPO from verifier feedback.],
  [2024-08-26], [Fire-Flyer AI-HPC], [arXiv:2408.14158], [--], [infrastructure], [Systems report; no named model landing is asserted.],
  [2024-08-28], [Auxiliary-loss-free balancing], [arXiv:2408.15664], [--], [--], [Component paper before explicit V3 adoption.],
  [2024-10-17], [Janus], [arXiv:2410.13848], [1.3B], [--], [Unified multimodal model with decoupled visual paths.],
  [2024-12-13], [DeepSeek-VL2], [arXiv:2412.10302], [VL2 family], [--], [Dynamic tiling plus sparse language model.],
  [2024-12-26], [Introducing DeepSeek-V3], [--], [V3 release materials], [product preview], [Official product/blog release one day before the report.],
  [2024-12-27], [DeepSeek-V3 Technical Report], [arXiv:2412.19437], [V3 card / weights], [--], [MLA, MoE, FP8, DualPipe, and MTP integration point.],
  [around 2025-01-20], [DeepSeek-R1 card / weights], [--], [#link("https://huggingface.co/deepseek-ai/DeepSeek-R1")[model card / weights]], [--], [Card evidence is kept separate from the same-period product release and later paper.],
  [2025-01-20], [DeepSeek-R1 product release], [--], [--], [#link("https://api-docs.deepseek.com/news/news250120/")[product release]], [Official release artifact; not a paper.],
  [2025-01-22], [DeepSeek-R1 paper], [#link("https://arxiv.org/abs/2501.12948")[arXiv:2501.12948]], [--], [--], [R1-Zero and multi-stage R1 post-training report.],
  [2025-01-29], [Janus-Pro], [arXiv:2501.17811], [1B and 7B], [--], [Follow-up scaling of Janus; no later landing is claimed.],
  [2025-02-16], [Native Sparse Attention (NSA)], [arXiv:2502.11089], [research backbone], [--], [Research sparse-attention line; later adoption is unknown.],
  [2025-03-24], [V3-0324], [--], [model card / weights], [product revision], [No standalone paper found in checked sources.],
  [2025-04-30], [DeepSeek-Prover-V2], [arXiv:2504.21801], [7B and 671B cards], [same-day release], [Paper and weights are distinct artifacts.],
  [2025-05-14], [Insights into DeepSeek-V3], [arXiv:2505.09343; DOI], [--], [ISCA 2025 revision/context], [Retrospective systems paper, not a new model.],
  [2025-05-28], [R1-0528], [--], [model card / weights], [product revision], [Large reported score change without a separate report.],
  [2025-08-21], [V3.1], [--], [model card / weights], [product release], [No paper found in the checked sources as of the as-of date.],
  [2025-09-22], [V3.1-Terminus], [--], [model card / weights], [product revision], [No standalone paper found in the checked sources.],
  [2025-09-29], [V3.2-Exp], [--], [model card / weights and GitHub PDF], [product release], [DSA appears in the model before the arXiv write-up.],
  [2025-10-21], [DeepSeek-OCR], [arXiv:2510.18234], [weights / card], [--], [Optical compression and OCR report.],
  [2025-11-27], [DeepSeekMath-V2], [arXiv:2511.22570], [model card / weights], [--], [Self-verifying mathematical reasoning.],
  [2025-12-01], [V3.2 and Speciale release], [--], [model cards], [product release], [Official release note before the technical report.],
  [2025-12-02], [DeepSeek-V3.2 report], [arXiv:2512.02556], [same family], [--], [DSA, scaled GRPO, and agentic synthesis.],
  [2025-12-31], [mHC], [arXiv:2512.24880], [--], [--], [Theory/component paper before V4 naming.],
  [2026-01-12], [Engram], [arXiv:2601.07372], [standalone demo repo], [--], [Conditional memory paper; V4.1 landing is later.],
  [2026-01-28], [DeepSeek-OCR 2], [arXiv:2601.20552], [weights / repo], [--], [Visual causal flow; its own table was only partially checked.],
  [2026-04-24], [V4 preview], [--], [V4 release materials], [product preview], [Official preview before the report.],
  [2026-04-26], [DeepSeek-V4], [arXiv:2606.19348], [V4-Pro / V4-Flash], [product family], [Printed date says April although identifier begins 2606; see Evidence.],
  [2026-04-30], [Thinking with Visual Primitives], [no checked arXiv record], [#link("https://zenodo.org/records/20125351")[Zenodo record] / #link("https://huggingface.co/datasets/NodeLinker/deepseek-ai-Thinking-with-Visual-Primitives-deleted-repo")[mirror]], [technical-report release], [Technical-report record and third-party mirror; not counted as an arXiv paper.],
  [2026-06-27], [V4-Flash-DSpark and V4-Pro-DSpark], [--], [checkpoint cards], [serving release], [Attached draft modules, not new base models.],
  [2026-07-06], [DSpark], [arXiv:2607.05147], [checkpoint cards precede paper], [live serving claim], [Model/checkpoint first, paper nine days later.],
  [2026-07-31], [V4-Flash-0731], [--], [model card / weights], [product revision], [Card describes post-training revision with unchanged architecture.],
  [2026-08-13], [V4-Pro general availability], [--], [model card / weights], [product release], [Release artifact; no new paper claim.],
  [2026-08-21], [V4-Flash-Vision-Exp], [--], [model card later], [multimodal product release], [First stated production API multimodal release; later retirement is a product event.],
  [2026-09-10], [V4.1-Flash], [--], [model card / weights], [product release], [CED, CSA2, FP4 cache, Engram, and multimodality named before the report.],
  [2026-09-17], [V4.1-Flash report], [arXiv:2609.19969], [same family], [technical revision], [Report follows the model/card by seven days.],
  [2026-09-19], [DeepSeek Elastic Compute (DSec)], [arXiv:2609.22978], [--], [in-production infrastructure], [Sandbox systems report; not a foundation-model paper.],
)

#note[
  The chronology is an evidence map, not a claim that every undocumented date is absent. In particular, "no paper found" means "not found in the checked sources as of 2026-09-30".
]

= The four lines as one system

== Architecture and efficiency

DeepSeekMoE makes the feed-forward block sparse by routing each token to a small number of fine-grained experts while reserving shared experts for common knowledge. MLA then compresses the key-value state rather than storing one full key and value per attention head. V3 combines those ideas with loss-free routing, FP8 arithmetic, MTP, and communication overlap. NSA is a research branch; DSA is the later model-first branch. V4 and V4.1-Flash add CSA/HCA, mHC, Engram, CED, CSA2, and low-precision caches for million-token contexts. The derivations and assumptions are in #link("DeepSeek_Architecture.pdf")[Architecture].

== Reasoning and post-training

DeepSeekMath introduced GRPO as a critic-free policy optimization method. Prover made a proof assistant a verifier; R1 used rule-based rewards and separated R1-Zero from the later cold-start pipeline; reward-model work handles less verifiable tasks; Prover-V2 and Math-V2 make self-critique and proof decomposition explicit. V3.2 treats agentic task synthesis as an environment-and-data scaling problem. See #link("DeepSeek_Reasoning.pdf")[Reasoning].

== Systems and environments

Fire-Flyer and 3FS establish a hardware/software co-design context. V3's DualPipe and cross-node kernels make MoE communication overlap feasible. DSpark targets serving latency with semi-autoregressive drafts and confidence-scheduled verification; DSec targets stateful, elastic sandboxes for training and evaluation. These artifacts are not all papers, and the repository boundary is made explicit in #link("DeepSeek_Systems.pdf")[Systems].

== Multimodality

DeepSeek-VL begins with high-resolution OCR-aware vision-language understanding. VL2 adds dynamic tiling and sparse language modeling; Janus decouples visual understanding and generation; OCR and OCR2 make visual tokens an information-compression problem. V4.1-Flash describes a from-scratch vision encoder, pixel unshuffle, modality-specific balancing, and shared long-context mechanisms. See #link("DeepSeek_Multimodal.pdf")[Multimodal].

= Reading paths

- *Architecture first:* DeepSeekMoE -> V2/MLA -> V3/FP8/MTP -> DSA -> V4 -> V4.1-Flash. Use the correction ledger for NSA's unknown landing and the V4 date discrepancy.
- *Reasoning first:* DeepSeekMath/GRPO -> Prover-V1.5 -> R1 -> Prover-V2 -> Math-V2 -> V3.2 agentic synthesis.
- *Deployment first:* Fire-Flyer/3FS -> V3 DualPipe and DeepEP -> ISCA systems analysis -> DSpark -> DSec.
- *Vision first:* VL -> VL2 and Janus -> OCR/OCR2 -> V4.1-Flash multimodality.
- *Audit first:* read #link("DeepSeek_Evidence.pdf")[Evidence], then follow its source-class table and correction ledger into the focused notes.

= How to interpret claims

The collection uses the following source classes:

- *Primary paper or technical report:* an arXiv, conference, DOI, or stable technical-report record. It can support what that document reports; peer-review status is stated separately when relevant.
- *Official release note:* a DeepSeek product or API announcement. It supports a release event and the claims printed there, not an unstated research method.
- *Model card or weights:* a checkpoint page and its metadata. It supports model availability, configuration, and card-reported numbers; it is not automatically a paper.
- *Official repository:* source code, kernels, PDFs, or infrastructure documentation. It is a non-paper artifact unless a separate paper is cited.
- *Third-party source:* an external paper, benchmark, news report, or critique. It is labelled as external and is not silently promoted to a DeepSeek result.
- *Unresolved or partial:* conflicting values, truncated source coverage, inferred identity, or a bounded negative search. Both values and the limitation remain visible.

Completeness language is scoped to the checked sources and the date above. A query returning no result does not establish global non-existence, and a reported benchmark is not independently reproduced here.

= Selected source links

The full key-to-source mapping is in #link("DeepSeek_Evidence.pdf")[Evidence] and `references.bib`. The central papers are #link("https://arxiv.org/abs/2405.04434")[DeepSeek-V2], #link("https://arxiv.org/abs/2412.19437")[DeepSeek-V3], #link("https://arxiv.org/abs/2402.03300")[DeepSeekMath], #link("https://arxiv.org/abs/2501.12948")[DeepSeek-R1], #link("https://arxiv.org/abs/2512.02556")[DeepSeek-V3.2], #link("https://arxiv.org/abs/2606.19348")[DeepSeek-V4], and #link("https://arxiv.org/abs/2609.19969")[DeepSeek-V4.1-Flash].

Official non-paper surfaces include the #link("https://api-docs.deepseek.com/updates/")[DeepSeek release index], #link("https://github.com/deepseek-ai/DeepEP")[DeepEP], #link("https://github.com/deepseek-ai/DualPipe")[DualPipe], #link("https://github.com/deepseek-ai/3FS")[3FS], #link("https://github.com/deepseek-ai/DeepSpec")[DeepSpec], and #link("https://github.com/deepseek-ai/DeepSeek-OCR-2")[DeepSeek-OCR-2].

= Boundaries and open questions

The checked material does not establish whether NSA, ESFT, RLPAF, RMaxTS, SPCT/DeepSeek-GRM, JanusFlow's rectified-flow head, or visual primitives shipped in a later production model. It also does not establish a paper for V3.1, V3.1-Terminus, R1-0528, V4-Flash-0731, or V4-Pro general availability. These are bounded evidence statements, not global non-existence claims. The detailed ledger records what was checked and what remains unknown.
