#import "/templates/lib.typ": conf, definition, note, theorem

#set document(
  title: "DeepSeek Reasoning and Post-Training",
  author: "Abel Zhan",
)

#show: conf

= Scope and notation

This note traces the reasoning line from DeepSeekMath through formal proving, R1, reward modeling, Math-V2, and agentic task synthesis. The as-of date is *2026-09-30*. Results are labelled as *reported*, *interpreted*, or *vendor claim*. A paper, model card, release note, and repository are different evidence classes; a checkpoint card is not a peer-reviewed paper.

Let $pi_theta(y | x)$ be a policy that generates a response $y$ for prompt $x$. A group of $G$ sampled responses is $y_1, dots, y_G$, with scalar rewards $r_1, dots, r_G$. The central design question is how to improve the policy when correctness is partially or fully verifiable without training a large value model.

= DeepSeekMath and GRPO

The DeepSeekMath paper @deepseek-math continued pre-training a 7B code model on a mined mathematical corpus, then used supervised fine-tuning and reinforcement learning. Its durable algorithmic contribution is Group Relative Policy Optimization (GRPO).

== Objective and group baseline

For each sampled response, GRPO computes a group-relative advantage:

$ A_i = frac(r_i - overline(r), sigma_r + epsilon), quad overline(r) = 1/G sum_(j=1)^G r_j $

With an old policy $pi_0$, a clipped surrogate objective can be written schematically as

$ L^c(theta) = 1/G sum_(i=1)^G min(
  rho_i(theta) A_i,
  op("clip")(rho_i(theta), 1-epsilon, 1+epsilon) A_i
), quad rho_i(theta) = frac(pi_theta(y_i | x), pi_0(y_i | x)) $

Token-level implementations factor the sequence ratio into token ratios and mask or normalize them according to the training report. A KL penalty or an explicit reference policy can constrain drift:

$ L(theta) = L^c(theta) - beta D_K(pi_theta || pi_1) $

The important resource trade-off is that GRPO estimates a relative baseline from the group rather than fitting a separate critic $V_phi(x)$. This reduces value-model memory and training complexity, but it increases sampling cost and makes reward variance, group composition, and normalization part of the optimization behavior.

#definition(title: "What GRPO does not imply")[
  Removing the critic does not remove reward modeling. A GRPO run may use a rule verifier, a learned reward model, a compiler, or a mixture of signals. "Critic-free" describes the policy-optimization baseline, not the provenance of the reward.
]

== Data and reported result

The paper reports an iterative web-mining pipeline, decontamination against benchmark n-grams, 500B continued-pretraining tokens, and a 120B-token math corpus. It reports MATH accuracy of 51.7 percent without a toolkit or voting and 60.9 percent with 64-sample self-consistency. These are *paper-reported values* under its protocol. They should not be read as an independently reproduced comparison with every model named in the paper.

*Interpretation:* the lasting contribution is not only the score. The paper supplied a reusable recipe: domain-specific data, a verifier-friendly outcome signal, group-relative policy optimization, and iterative improvement. Later reports explicitly reuse GRPO, which is stronger evidence of lineage than a numerical comparison alone.

= Formal proving: Prover and Prover-V1.5

== DeepSeek-Prover

The DeepSeek-Prover paper @deepseek-prover treats Lean as a correctness oracle. Natural-language competition problems are autoformalized into Lean statements, filtered for quality and inconsistent hypotheses, and paired with machine-checked proofs. The core loop is

$ x -> l -> p -> v -> a $

A rejected proof is not evidence that the theorem is false; it may reflect a bad formalization, an incomplete search, or a timeout. The report therefore uses hypothesis rejection and dual proof search to remove vacuous or malformed examples before training.

The paper reports 8 million formal statements with proofs, 712,073 high-quality formal statements after an earlier collection/filtering stage, and 46.3 percent on miniF2F-test at 64 samples for its whole-proof setting. It reports 5 of 148 FIMO problems solved at 4096 samples in the abstract and introduction, but a later section prints a denominator of 149. Both values remain visible in #link("DeepSeek_Evidence.pdf")[Evidence]; neither is silently corrected.

== Prover-V1.5: verifier feedback and search

The Prover-V1.5 paper @deepseek-prover-v15 turns the proof assistant into an RL environment. In RL from Proof Assistant Feedback (RLPAF), Lean supplies a binary reward. GRPO is useful here because a separate critic is difficult to train when successful proof trajectories are sparse.

The report combines three loops:

- *Truncate and resume:* submit a generated tactic sequence, keep the verified prefix, append the current Lean tactic state, and continue generation.
- *RMaxTS:* use a tree search with an intrinsic exploration reward so the search does not repeatedly follow one failed tactic path.
- *Thought-augmented generation:* train on explanatory comments and tactic states while the proof assistant remains the final verifier.

The paper reports 63.5 percent miniF2F-test with tree search and 60.2 percent for single-pass whole-proof generation. These are reported evaluation values, not a guarantee that every later Prover model uses RLPAF or RMaxTS. The checked sources do not establish such later adoption.

= R1: from verifiable rewards to general reasoning

The DeepSeek-R1 paper @deepseek-r1 separates a pure-RL experiment, R1-Zero, from a later multi-stage R1 recipe.

== R1-Zero

The R1-Zero setup starts from a base model without a supervised reasoning cold start. Its reward is primarily rule-based: an answer-correctness signal for mathematics or code and a format signal for the required reasoning delimiters. The paper explicitly says it did not use neural outcome or process reward models in this phase because of reward-hacking concerns.

The paper presents this as evidence that long chain-of-thought behaviors can emerge under a sufficiently useful verifiable reward. That is an interpretation of the reported training trajectory, not proof that all desirable reasoning emerges from reward-only optimization. External work has also argued that normalization and length effects can shape the apparent emergence; see the third-party discussion of GRPO in #link("DeepSeek_Evidence.pdf")[Evidence].

== A visible source conflict

R1-Zero's AIME 2024 result is printed as 71.0 in one v1-derived rendering and 77.9 in the v2 HTML rendering. The problem setup, model name, and source versions differ in the checked pages, so the collection records both as source-specific values:

- *Reported value A:* 71.0, associated with the v1-based rendering.
- *Reported value B:* 77.9, associated with the v2 rendering.

No independent score is selected as canonical. A reader should cite the exact R1 version and page when using either value.

== Multi-stage R1

The later R1 pipeline adds a small cold-start set of long chain-of-thought examples, reasoning-oriented RL, rejection sampling, supervised fine-tuning on roughly 800,000 accepted samples, and a second RL stage covering broader scenarios. It also adds helpfulness, safety, and language-consistency signals. Distillation transfers reasoning traces into smaller Qwen and Llama dense models using supervised fine-tuning rather than repeating the full RL run.

The distinction matters:

- *Reported:* the paper describes these stages and reports competition and benchmark results under its protocols.
- *Interpretation:* cold start and rejection sampling make the reward landscape easier to explore and improve readability.
- *Not established:* a card or release note that repeats an R1 number does not prove that the same training stages produced a later revision such as R1-0528.

= Reward modeling beyond exact verifiers

Rule-based rewards work well when an answer can be checked by arithmetic, a compiler, a unit test, or Lean. Open-ended helpfulness and proof critique require a softer signal. The DeepSeek line contains at least three distinct uses of learned evaluation:

1. *Coder-V2 reward model:* the code report says it used a reward model rather than raw compiler 0/1 feedback because tests have incomplete coverage and compiler signals are noisy.
2. *R1 helpfulness and safety:* the later RL stage includes learned reward signals after the R1-Zero rule-reward experiment.
3. *Generalist reward modeling:* The Inference-Time Scaling for Generalist Reward Modeling paper @generalist-reward-modeling studies SPCT and DeepSeek-GRM, using multiple sampled evaluations and aggregation rather than assuming one greedy judge is reliable.

A learned reward model is itself a model with calibration and distribution-shift risks. A reward score can be useful for ranking candidates without being a proof of correctness. This is why the collection keeps verifier-backed results and reward-model results in separate descriptions.

= Prover-V2 and Math-V2

== Prover-V2: decomposition before proof search

The DeepSeek-Prover-V2 paper @deepseek-prover-v2 uses a large model to decompose a theorem into intermediate subgoals, then asks a smaller or specialized prover to solve the subgoals in Lean. The design changes the search space from one long proof to a sequence of locally checkable obligations:

$ G_0 -> (G_1, G_2, dots, G_m), quad G_j in cal(G). $

The decomposition is only useful when the generated subgoals preserve equivalence or provide a sufficient proof route. Lean remains the final acceptance test. The report's PutnamBench count appears as 49 of 658 in the abstract and as 47 of 658 in the body. Both are retained as an unresolved internal discrepancy in #link("DeepSeek_Evidence.pdf")[Evidence].

== DeepSeekMath-V2: self-verification

The DeepSeekMath-V2 paper @deepseek-math-v2 extends the idea of a verifier to natural-language mathematical proofs. A generator proposes a solution, a verifier critiques it against a rubric, and a meta-verifier evaluates whether the critique itself is useful. The training signal can be represented as

$ r = alpha r_a + beta r_b, quad alpha + beta = 1 $

The exact components and weights are report-specific. The important systems property is the second-order dependency: improving the critic is part of improving the generator. The report claims 118 of 120 on Putnam 2024 with scaled test-time computation and gold-level results on selected IMO and CMO problems. These are vendor-reported expert-graded results, not independently reproduced facts in this collection.

= Agentic task synthesis and V3.2

The DeepSeek-V3.2 report @deepseek-v32 makes agentic reasoning a data and environment problem as well as a policy problem. The report describes more than 1,800 environments and more than 85,000 complex instructions, specialist distillation across math, programming, general reasoning, coding agents, search, and related domains, followed by a mixed RL stage.

The training abstraction is:

$ x -> e -> o -> r -> g $

The environment must be deterministic enough for useful reward comparisons, but realistic enough to expose tool and planning failures. The report adds routing and sampling consistency mechanisms for MoE RL, including keep routing, an unbiased KL estimate, off-policy sequence masking, and a keep-sampling mask.

*Interpretation:* this is a shift from "make a reasoning trace" to "make a policy survive a stateful task." *Vendor claim:* the report's comparisons with frontier systems and its agent benchmark values are claims made by the report. *Unknown:* the checked sources do not independently reproduce those values or establish that every environment is publicly available.

= Lineage table

#table(
  columns: (1.6fr, 1.9fr, 2.4fr, 2.5fr),
  table.header([Stage], [Reward or verifier], [Core mechanism], [Evidence boundary]),
  [DeepSeekMath], [Math answer and outcome signals], [GRPO; domain data; iterative RL], [Paper-reported 7B results.],
  [Prover], [Lean proof checker], [Autoformalization, filtering, whole-proof generation], [Paper; FIMO denominator conflict remains.],
  [Prover-V1.5], [Lean binary reward], [RLPAF, truncate/resume, RMaxTS, GRPO], [Paper; later adoption unknown.],
  [R1-Zero], [Rule-verified math/code plus format], [Pure RL without SFT cold start], [Paper; AIME values conflict across versions.],
  [R1], [Rule and learned helpfulness/safety signals], [Cold start, RL, rejection sampling, SFT, second RL], [Paper and cards are distinct source classes.],
  [Prover-V2], [Lean plus subgoal validity], [Large-model decomposition and smaller proof search], [Paper; Putnam count conflict.],
  [Math-V2], [Verifier and meta-verifier], [Self-critique and critique-quality reward], [Paper-reported expert grading.],
  [V3.2], [Domain and agent environment outcomes], [Scaled GRPO plus specialist distillation and synthesis], [Report/vendor claims; environment availability partial.],
)

= What is established and what is not

Established in the checked sources: GRPO begins in DeepSeekMath; it is reused in later reports; Lean is used as an external verifier in Prover; R1 distinguishes rule rewards from learned reward models; V3.2 explicitly describes agentic task synthesis. Not established: a single universal GRPO objective used unchanged across every release, production adoption of every proving/search method, or independent reproduction of the headline competition numbers.

The most useful conceptual chain is *verifier -> reward -> search -> environment*. A stronger verifier can make sparse rewards usable; a better reward can guide search; search can generate training data; and an environment can expose failures that static math benchmarks cannot. Each arrow also introduces a new failure mode, so the Evidence note keeps source claims and interpretations separate.

= Source trail

Primary papers: DeepSeekMath @deepseek-math, DeepSeek-Prover @deepseek-prover, Prover-V1.5 @deepseek-prover-v15, R1 @deepseek-r1, Inference-Time Scaling for Generalist Reward Modeling @generalist-reward-modeling, Prover-V2 @deepseek-prover-v2, DeepSeekMath-V2 @deepseek-math-v2, and V3.2 @deepseek-v32. The R1 release note @release-r1 and V3.2 release note @release-v32 are official release artifacts, not substitutes for those papers.

= References

#bibliography("references.bib", title: none)
