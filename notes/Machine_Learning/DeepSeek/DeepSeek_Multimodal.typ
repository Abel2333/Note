#import "/templates/lib.typ": conf, definition, note

#set document(
  title: "DeepSeek Multimodal Branches",
  author: "Abel Zhan",
)

#show: conf

= Scope and source classes

This note covers DeepSeek-VL, VL2, Janus, OCR, OCR2, and the multimodal material reported for V4.1-Flash. The as-of date is *2026-09-30*. Paper results, model-card metadata, official release notes, and repositories are separated because they answer different questions. In particular, an official OCR repository is not a paper, and a product release is not evidence that every research prototype shipped.

The recurring systems objective is to reduce visual information to a sequence that the language model can use without destroying spatial or linguistic information:

$ x -> v -> z -> y. $

Compression is useful only if the retained tokens preserve the task-relevant information. A lower token count is therefore a systems metric, not a quality metric by itself.

= DeepSeek-VL: high resolution without abandoning language

The DeepSeek-VL paper @deepseek-vl uses a hybrid vision encoder: a text-aligned semantic path and a high-resolution path. A 1024 by 1024 image is condensed to 576 visual tokens in the reported configuration. The training recipe has three broad stages:

1. train an adaptor while the language model is mostly frozen;
2. jointly pre-train vision and language data;
3. supervised fine-tune on real-world multimodal tasks.

The report emphasizes modality warm-up and states that at least 70 percent language data is needed in its mixture to preserve language ability. Its in-house data includes rendered documents, books, charts, OCR, and web-code examples. These dataset and score details are *paper-reported*; they do not establish how later V4 multimodal production models were trained.

The important design constraint is a fixed visual-token budget. If an image produces $N_v$ tokens and text produces $N_t$, the language context is approximately $N_v + N_t$. Increasing resolution without a compression plan can erase the very context window that makes document understanding useful.

= DeepSeek-VL2: dynamic tiling and sparse language modeling

The DeepSeek-VL2 paper @deepseek-vl2 replaces fixed image sizes with dynamic tiling. Candidate layouts of $m times n$ tiles are considered subject to a bounded tile count. One global thumbnail preserves context while local tiles preserve detail. A 2 by 2 pixel shuffle changes a 27 by 27 feature grid into roughly 14 by 14 visual tokens per tile:

$ 27 times 27 = 729 quad -> quad 14 times 14 = 196. $

A simplified sequence-length expression from the report is

$ N_v = 210 + 1 + m_i dot 14 dot (n_i dot 14 + 1), $

where the extra terms represent the thumbnail, separators, and tile-newline structure. The exact tokenization depends on the chosen layout.

VL2 also uses DeepSeekMoE and MLA in its language backbone, with routed and shared experts. That is evidence that the architecture line crosses into multimodality; it is not evidence that every visual encoder is shared with V4. The paper reports three model sizes and distinct total-versus-activated parameter counts. When those counts differ between an abstract and a table, the source version and table location must be cited.

= Janus: decouple visual understanding and generation

== Janus and Janus-Pro

The Janus paper @janus uses one autoregressive transformer with two visual paths:

- an understanding encoder such as SigLIP, flattened and mapped by an adaptor;
- a generation tokenizer, mapped through a separate adaptor and image prediction head.

The language transformer receives a concatenated sequence of text and visual features:

$ z = [z_t; z_u; z_g] $

The paths are decoupled because understanding benefits from semantic, often high-resolution features, while generation benefits from discrete or spatially regular image tokens. A single transformer can share language reasoning while avoiding the demand that one visual representation serve incompatible objectives.

The Janus-Pro paper @janus-pro scales the model and data recipe to 1B and 7B variants. It reports improved MMBench and GenEval values, but those are paper-reported evaluations. The arXiv metadata notes overlap with Janus; that establishes a paper lineage, not a claim that every later product uses the same generation head.

== JanusFlow

The JanusFlow paper @janusflow explores a rectified-flow generation head inside the language-model framework. The image path evolves a latent state by an ODE-like update:

$ z_(t + Delta t) = z_t + v_theta(z_t, t, c) Delta t, $

then decodes the final latent with a VAE. The paper presents this as a way to avoid a separate external autoregressive image-token generator. It is a research paper and is not evidence that the rectified-flow head landed in a later DeepSeek product.

= OCR as optical context compression

== DeepSeek-OCR

The DeepSeek-OCR paper @deepseek-ocr asks whether a page can be represented as an image whose visual tokens are decoded into text. Its DeepEncoder combines perception, convolutional token compression, and a semantic vision stage; the decoder is a sparse DeepSeek language model.

If a page has $N_t$ text tokens and $N_v$ visual tokens, define a compression ratio

$ rho = N_t / N_v. $

The paper reports high OCR precision at ratios below roughly 10 and degradation at much larger ratios. It also reports several resolution modes, such as 64, 100, 256, and 400 visual tokens, plus tiled modes. These are source-reported values, and the exact benchmark depends on language, page type, and resolution.

The model uses a mixture of OCR, general vision, and text-only data. The systems implication is that optical compression can reduce long-document attention length, but it moves work into the encoder and makes image quality, layout, and rendering artifacts part of the language pipeline.

== DeepSeek-OCR 2: visual causal flow

The DeepSeek-OCR 2 paper @deepseek-ocr2 keeps the OCR decoder largely unchanged and changes the visual tokenizer. Its DeepEncoder V2 adds causal-flow queries after bidirectionally attended visual tokens. A simplified mask has four regions:

$ M = [[1_(m times m), 0_(m times n)], [1_(n times m), op("LowerTri")(n) ]] $

The first block lets visual tokens interact bidirectionally; the second lets flow queries attend to visual tokens and to earlier flow queries. Only the flow-query outputs are passed to the decoder. With a global 1024 by 1024 crop and local 768 by 768 crops, the reported visual-token budget is between 256 and 1120.

The paper reports a 3.73 percent gain on OmniDocBench v1.5 relative to its OCR baseline. The model's own overall table value was not available in the checked extraction, so the collection does not invent one from competitor rows. The official DeepSeek-OCR-2 repository @repo-ocr2 is a non-paper artifact that can document code and weights but cannot replace the paper for the number.

= V4 and V4.1-Flash multimodality

The V4 main report @deepseek-v4 is primarily a long-context foundation-model report. The multimodal evolution is more explicit in the V4.1-Flash report @deepseek-v41-flash and card.

== From-scratch visual path

V4.1-Flash describes a DeepSeek-ViT with 2D rotary position information, a linear patch projection selected for optimizer compatibility, RMSNorm, and SwiGLU. A 3 by 3 pixel-unshuffle reduces visual tokens by a factor of nine before the long-context decoder sees them. If a raw patch sequence has $N$ tokens, the approximate sequence is

$ N_v approx N / 9. $

This is a token-budget reduction, not a claim that the information loss is exactly nine-fold. The visual encoder and decoder are trained as a multimodal system, with text and image tokens receiving separate expert-balancing correction biases. That separation matters because image-token routing statistics can differ substantially from text-token statistics.

== Shared long-context mechanisms

V4.1-Flash connects visual processing to CED and CSA2. The encoder can produce global representations once, while decoder layers reuse global KV and index data across layers. The report also describes FP4 main KV caching, bounded replay for local windows, and a hierarchical sparse indexer. These mechanisms reduce prefill and cache cost for both text and image sequences, but the exact benefit depends on visual token count and crop policy.

The report claims 45T multimodal pre-training tokens, 40 layers split into 20 encoder and 20 decoder layers, and 890 bytes per token for global KV. These are *report/card claims*. The headline parameter accounting of 552B backbone plus 196B Engram does not reconcile directly with the safetensors-index total noted in #link("DeepSeek_Evidence.pdf")[Evidence], so parameter totals should be quoted with their source field.

== Product versus paper

The V4-Flash-Vision-Exp API official release note @release-v4-vision is a product event. Its later model card @card-v4-vision-exp is model-card evidence. Neither should be cited as if it were the V4.1-Flash paper. "Thinking with Visual Primitives" is represented in the checked sources by a Zenodo technical-report record @visual-primitives-zenodo and a third-party mirror of its deleted repository @visual-primitives-mirror, not by an arXiv paper. Those artifacts do not establish that the technique shipped in a production visual model.

= Multimodal comparison

#table(
  columns: (1.6fr, 2fr, 2.4fr, 2.3fr),
  table.header([Branch], [Representation], [Main technical move], [Evidence boundary]),
  [DeepSeek-VL], [Hybrid high- and low-resolution features], [Fixed visual budget, modality warm-up, real-world OCR/document data], [Paper-reported; later landing unknown.],
  [DeepSeek-VL2], [Dynamic tiles plus global thumbnail], [Pixel shuffle, layout tokens, MoE/MLA language backbone], [Paper; model configuration is not a universal V4 claim.],
  [Janus / Janus-Pro], [Separate understanding and generation paths], [One autoregressive transformer with decoupled visual encoders], [Papers; later product adoption unknown.],
  [JanusFlow], [Continuous latent and velocity field], [Rectified flow inside the LLM framework], [Research paper; no later landing established.],
  [DeepSeek-OCR], [Rendered page image to sparse decoder tokens], [DeepEncoder and multiple compression ratios], [Paper; benchmark values are source-reported.],
  [DeepSeek-OCR 2], [Visual tokens plus causal-flow queries], [Semantic reordering before decoder input], [Paper plus official repository; own overall table partially unchecked.],
  [V4.1-Flash], [DeepSeek-ViT plus shared long-context cache], [2D-RoPE, 9x pixel unshuffle, multimodal balancing, CED/CSA2], [Card and report; parameter discrepancy remains.],
)

= Claims and limitations

The robust lineage is representation compression plus task-specific paths: high-resolution vision is compressed into a bounded sequence, generation and understanding are decoupled where necessary, and long-context cache mechanisms are shared with text. The weaker claims are product adoption and benchmark superiority outside the named paper protocol.

No checked source establishes a DeepSeek-VL3 release, a later production landing for JanusFlow, or a production use of visual primitives. The correct wording is "not found in the checked sources as of 2026-09-30," not a global non-existence claim. Likewise, an official repository can make code available without changing the source class of the associated research claim.

= Source trail

Papers: DeepSeek-VL @deepseek-vl, DeepSeek-VL2 @deepseek-vl2, Janus @janus, JanusFlow @janusflow, Janus-Pro @janus-pro, DeepSeek-OCR @deepseek-ocr, DeepSeek-OCR 2 @deepseek-ocr2, and V4.1-Flash @deepseek-v41-flash. Product and artifact sources are the Vision release note @release-v4-vision, DeepSeek-OCR-2 repository @repo-ocr2, and Janus repository @repo-janus; each is marked as non-paper evidence where used.

= References

#bibliography("references.bib", title: none)
