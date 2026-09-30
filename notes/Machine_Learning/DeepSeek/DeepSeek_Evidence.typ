#import "/templates/lib.typ": conf, note

#set document(
  title: "DeepSeek Evidence, Sources, and Corrections",
  author: "Abel Zhan",
)

#show: conf

= Audit scope

This evidence register supports the DeepSeek collection as of *2026-09-30*. It records what was found in the checked sources, what class of artifact supplied it, and what remains unresolved. It does not claim global completeness. The phrase "not found" always means *not found in the checked sources as of 2026-09-30*.

The source outline is not a build dependency and is not a canonical citation source. The durable source map is this note plus `references.bib`; the focused notes link directly to stable arXiv, DOI, DeepSeek release, Hugging Face, Zenodo, and GitHub pages.

= Source taxonomy

#table(
  columns: (1.8fr, 2.7fr, 2.7fr, 2.3fr),
  table.header([Class], [Positive evidence], [Permitted claim], [Boundary]),
  [Primary paper or technical report], [ArXiv, DOI, conference record, or stable report], [What the document reports, its equations, dates, and stated experiments], [Peer review and independent reproduction must be stated separately.],
  [Official release note], [DeepSeek API or product announcement], [A release event, product timing, and claims printed in that note], [It is not a paper and does not establish unpublished mechanisms.],
  [Model card / weights], [Hugging Face card, checkpoint metadata, or weight index], [Availability, configuration, card-reported values, and model-specific metadata], [It is not automatically a technical report; tags can be wrong.],
  [Official repository], [DeepSeek GitHub code, README, or attached PDF], [Code/artifact availability and README claims], [A repository is a non-paper artifact unless a separate paper is cited.],
  [Third-party source], [External paper, benchmark, critique, news, or review], [The external source's own analysis or reported result], [It cannot be silently presented as a DeepSeek-authored result.],
  [Unresolved / partial], [Conflicting fields, incomplete extraction, inferred identity, or bounded search], [Both values and the limitation], [Do not normalize uncertainty into a single fact.],
)

== Citation keys and links

The direct links identify the artifact and source class used for each claim. Parenthesized citations resolve to maintained `references.bib` records; they do not convert a card, release note, repository, mirror, or technical-record page into a paper.

= Correction ledger

#table(
  columns: (1.8fr, 2.1fr, 2.1fr, 3fr),
  table.header([Issue], [Value or label A], [Value or label B], [How to cite it]),
  [R1-Zero AIME 2024], [71.0 in a v1-derived rendering], [77.9 in the v2 HTML rendering], [Use the exact R1 version/page. Neither value is selected as canonical; the conflict is reported in #link("https://arxiv.org/abs/2501.12948")[R1].],
  [Prover-V2 PutnamBench], [49 of 658 in abstract and v1/v2 abstract], [47 of 658 in the v2 body], [Report both as source-specific values; see #link("https://arxiv.org/abs/2504.21801")[Prover-V2].],
  [Prover FIMO denominator], [5 of 148 in abstract/introduction], [a later section prints 149], [Do not turn the count into a single normalized rate; see #link("https://arxiv.org/abs/2405.14333")[Prover].],
  [NSA pre-training tokens], [260B in the introduction], [270B in section 4.1], [Both refer to the same reported research setup in #link("https://arxiv.org/abs/2502.11089")[NSA]; the discrepancy is unresolved.],
  [V2-0628 baselines], [Changelog: HumanEval 79.88 and MATH 55.02], [Card: HumanEval 81.1 and MATH 53.9], [Post-update values agree, but baselines do not. Cite #link("https://api-docs.deepseek.com/updates/")[the 2024-06-28 changelog] (@release-v2-0628) and #link("https://huggingface.co/deepseek-ai/DeepSeek-V2-Chat-0628")[the V2-0628 card] (@card-v2-0628) separately.],
  [V4 identifier and date], [ArXiv identifier begins `2606`], [Printed submission date is 2026-04-26; blog preview is 2026-04-24], [Three checked date sources say April; the numeric prefix suggests June. Keep both facts visible in #link("https://arxiv.org/abs/2606.19348")[V4].],
  [V4.1 parameter accounting], [Headline: 552B backbone plus 196B Engram], [Safetensors index total and I8 entry count do not reconcile with that sum], [Quote the field and source version; do not infer a corrected total. See #link("https://arxiv.org/abs/2609.19969")[V4.1-Flash] and its card.],
  [DeepSeek-Coder token count], [Series description says 2T tokens], [1.3B-base model summary says 1T], [Treat as model-card metadata disagreement, not as a paper correction.],
  [Author-count conventions], [Abs pages may truncate with "additional authors"], [API/HTML may expose a different count], [Use exact list/count only when read; submitter identity is not last-author evidence.],
  [AlignBench], [V2 card presents it among evaluation references], [AlignBench is a THUDM/Tsinghua third-party benchmark paper, arXiv:2311.18743], [It is a third-party benchmark, not a DeepSeek paper; cite #link("https://arxiv.org/abs/2311.18743")[AlignBench] as external.],
  [Model-card arXiv tags], [V2 card tags AlignBench; Coder-V2 cards tag DeepSeekMoE], [DSpark cards tag V4; V3.1-family cards tag V3; R1-0528 tags original R1], [A tag is metadata, not proof that the tagged paper describes the checkpoint. Use the checkpoint page and the correct report separately.],
)

= Paper, model, product, and revision dates

A paper date is the arXiv submission or publication date visible on the paper record. A card/weight date is the checkpoint or model-card creation/publication date. A product date is an official release note or API event. A revision is a later checkpoint or report that may preserve the architecture while changing post-training or serving behavior.

Important examples:

- V2: initial card/weights approximately 2024-04-22, paper 2024-05-07, API update 2024-05-17, and V2-0628 revision 2024-06-28.
- Coder-V2: cards/weights approximately 2024-06-14, API update 2024-06-14, and paper 2024-06-17; the same date does not make the artifacts interchangeable.
- R1: card/weights around 2025-01-20, product release 2025-01-20, and paper 2025-01-22; card, release note, and paper are separate sources.
- V3: product/blog 2024-12-26, report 2024-12-27, card/weights around the same release.
- V3.2-Exp: model/card 2025-09-29, DSA report 2025-12-02; model first, paper later.
- DSpark: checkpoint cards 2026-06-27, paper 2026-07-06; the cards say the attached module is not a new base model.
- V4.1-Flash: card/product 2026-09-10, report 2026-09-17; model first, paper later.

The source-anchor table below identifies the specific card, release, and technical-record links. This separation is why the Overview timeline has separate columns instead of one "release date."

= Bounded completeness procedure

The checked inventory used several bounded angles rather than a single author query:

1. Search the arXiv export API for the collective author field `DeepSeek-AI` over the relevant date range.
2. Search for named authors such as Wenfeng Liang, while recognizing that many DeepSeek papers omit that name.
3. Search title and all-field queries for model and repository names.
4. Check the official DeepSeek release-note index and named model-card families.
5. Follow official repository links and distinguish source code, attached PDFs, and papers.

The union is useful but not globally complete. Collective-author metadata is inconsistent: Engram, DSpark, and DSec list individual authors rather than the collective entry, while many math and multimodal papers omit Wenfeng Liang. Preprints without arXiv records and private or deleted artifacts are invisible to arXiv queries. Therefore this collection makes only bounded statements such as:

> No standalone DeepSeek-VL3 paper was found in the checked arXiv, model-card, API, and repository sources as of 2026-09-30.

It does *not* state that no such paper exists anywhere. The same wording applies to V3.1, V3.1-Terminus, R1-0528, V4-Pro GA, LPLB adoption, and later multimodal landings.

= Open questions and partial evidence

- Whether NSA was adopted in a released model remains unknown; a later V3 revision says its structure is V3, not NSA.
- Whether ESFT, RLPAF, RMaxTS, SPCT/DeepSeek-GRM, or JanusFlow entered a flagship production model was not found in the checked sources.
- The V3.2-Exp GitHub PDF was not text-extracted reliably, so mechanism claims are attributed to the arXiv report and model card rather than that PDF.
- Several long papers were only partially available in the checked HTML extraction. Missing tables are not reconstructed from search snippets or third-party summaries.
- The exact V4.1-Flash author count is treated as unknown from the truncated abs page; an API count of 593 is recorded as metadata, not as an independently normalized author list.
- "Thinking with Visual Primitives" has a #link("https://zenodo.org/records/20125351")[Zenodo technical-report record] and a #link("https://huggingface.co/datasets/NodeLinker/deepseek-ai-Thinking-with-Visual-Primitives-deleted-repo")[mirror of the deleted repository], but no checked arXiv record. Its reported benchmark values from a news article remain third-party and unverified here.

= Model-card and release anchors

These stable anchors identify the source class and date used for the corresponding claim. Cards, API change logs, technical-record pages, and mirrors remain non-paper artifacts even when a bibliography record or citation accompanies them.

#table(
  columns: (2.1fr, 2.4fr, 3.7fr),
  table.header([Artifact or event], [Class], [Stable source]),
  [V2 initial card / weights, approx. 2024-04-22], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-V2")[DeepSeek-V2 card] (@card-v2).],
  [V2-0517 API update, 2024-05-17], [official release note], [#link("https://api-docs.deepseek.com/updates/")[Updates entry] (@release-v2-0517).],
  [Coder-V2 cards / weights, approx. 2024-06-14], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-Coder-V2-Instruct")[Coder-V2 Instruct card] (@card-coder-v2).],
  [Coder-V2 API update, 2024-06-14], [official release note], [#link("https://api-docs.deepseek.com/updates/")[Updates entry] (@release-coder-v2-0614).],
  [V2-0628, 2024-06-28], [model card / weights plus changelog], [#link("https://api-docs.deepseek.com/updates/")[changelog] (@release-v2-0628); #link("https://huggingface.co/deepseek-ai/DeepSeek-V2-Chat-0628")[card] (@card-v2-0628).],
  [DeepSeek-Coder 1.3B], [model card / weights], [#link("https://huggingface.co/deepseek-ai/deepseek-coder-1.3b-base")[1.3B base card]],
  [DeepSeek-R1 card / weights, around 2025-01-20], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-R1")[DeepSeek-R1 card] (@card-r1).],
  [DeepSeek-R1 release, 2025-01-20], [official release note], [#link("https://api-docs.deepseek.com/news/news250120/")[R1 release note] (@release-r1).],
  [V3.2-Exp], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-V3.2-Exp")[V3.2-Exp card]],
  [R1-0528], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-R1-0528")[R1-0528 card]],
  [V4-Flash-DSpark and V4-Pro-DSpark, 2026-06-27], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash-DSpark")[Flash-DSpark card] (@card-dspark-flash); #link("https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro-DSpark")[Pro-DSpark card] (@card-dspark-pro).],
  [V4.1-Flash], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-V4.1-Flash")[V4.1-Flash card]],
  [V4-Flash-Vision-Exp], [model card / weights], [#link("https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash-Vision-Exp")[Vision-Exp card]],
  [Thinking with Visual Primitives, 2026-04-30], [Zenodo technical-report record / third-party mirror], [#link("https://zenodo.org/records/20125351")[Zenodo record] (@visual-primitives-zenodo); #link("https://huggingface.co/datasets/NodeLinker/deepseek-ai-Thinking-with-Visual-Primitives-deleted-repo")[mirror] (@visual-primitives-mirror).],
)

= Third-party context

The following are external papers that extend or critique DeepSeek techniques; they are not DeepSeek papers:

#table(
  columns: (2.1fr, 2.1fr, 3.8fr),
  table.header([Source], [Target], [Role]),
  [#link("https://arxiv.org/abs/2601.05732")[mHC-lite]], [mHC], [Questions finite Sinkhorn convergence and portability; external critique.],
  [#link("https://arxiv.org/abs/2503.20783")[Understanding R1-Zero-Like Training]], [R1 / GRPO], [Studies normalization and length bias; external critique.],
  [#link("https://arxiv.org/abs/2503.14476")[DAPO]], [GRPO], [Proposes scaling modifications; external system.],
  [#link("https://arxiv.org/abs/2507.18071")[GSPO]], [GRPO], [Uses sequence-level ratios; external method.],
  [#link("https://arxiv.org/abs/2505.24298")[AReaL]], [Asynchronous rollout], [External systems design for RL throughput.],
  [#link("https://arxiv.org/abs/2602.06036")[DFlash] and #link("https://arxiv.org/abs/2503.01840")[EAGLE-3]], [Speculative decoding], [External drafting methods referenced by DeepSpec; not DeepSeek-originated algorithms.],
)

The point of this table is provenance, not a ranking. A third-party paper can test or criticize a DeepSeek mechanism without becoming evidence for what DeepSeek shipped.

= Reading order for auditability

1. Read #link("DeepSeek_Overview.pdf")[Overview] for the chronology and four-line map.
2. Read #link("DeepSeek_Architecture.pdf")[Architecture] for equations and complexity/memory assumptions.
3. Read #link("DeepSeek_Reasoning.pdf")[Reasoning] for GRPO, verifier boundaries, and result categories.
4. Read #link("DeepSeek_Systems.pdf")[Systems] for repository-versus-paper boundaries and serving evidence.
5. Read #link("DeepSeek_Multimodal.pdf")[Multimodal] for visual token and product/report distinctions.
6. Return to this ledger before quoting a conflicting number or making an absence claim.

= Bibliography

The bibliography is deliberately shared by the collection. `full: true` keeps uncited core records visible so a reader can use this note as a source index.

#bibliography("references.bib", style: "ieee", full: true)
