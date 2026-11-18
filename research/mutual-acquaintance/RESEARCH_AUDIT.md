# Mutual acquaintance research audit

Baseline: PR [#267](https://github.com/dwijayuda/pskernel/pull/267), branch `research/mutual-acquaintance-dynamics-20261118`, head `bc985a715c2ae20bd0b6e25805b18258e0a8f1b8`. Scope is the research subtree and its two workflows. The baseline PR added 25 project files and two workflow files.

| Area | Baseline inventory and authority |
|---|---|
| Tractatus | Indonesian source, English and Latin editions, three companion PDFs, and revision notes. All three Markdown editions contain the same 119 proposition identifiers in the same order. Indonesian is authoritative for the crosswalk. |
| Paper | Working draft Markdown and PDF, full proposition index, finite-example script and JSON, reader guide, and three archived predecessors (draft, Indonesian summary, legacy Lean sketch). The Markdown is authoritative. The index supplies interpretive topics rather than 119 formal claims. |
| Lean | Two active independent modules with 22 and 19 theorem declarations, pinned toolchain, reproduction guide, and PowerShell verifier. The archive sketch is outside CI scope. |
| Project support | Root README, historical research notes, dynamics addendum, Python mirror of dynamic examples. |
| Workflows | Linux Lean check and PDF renderer. The former compiles the two active modules. Python scripts and the archived Lean file are outside that workflow. The PDF renderer is separate. |

## Baseline verification

[Run 44344609226](https://github.com/dwijayuda/pskernel/actions/runs/44344609226), [job 134943500032](https://github.com/dwijayuda/pskernel/actions/runs/44344609226/job/134943500032) passed on Linux with Lean 4.36.0, compiler commit `611c117bfaf7b7ae1cfcf246ce6fba31e8f509e9`. The log identifies GitHub’s synthetic merge `8523dba35c95802f3dfe4ddff8fd2de049aded32` and its head parent above. It records both compiler calls and the kernel-check marker.

| Source | Logged SHA-256 |
|---|---|
| MutualAcquaintance.lean | `98439818fa421e9d9c55fcecb06dc02da48e761ecc50c1d0393ddcd46c23f2ac` |
| MutualAcquaintanceDynamics.lean | `df83d0d1af4e2e2bb774fff239f9975551587249fefd3ec84d7133ac76bb3d29` |

The source audit found no active placeholders or user-declared axioms in the two baseline modules. The workflow’s anchored keyword check alone would miss an inline placeholder. A dependency audit should use Lean’s axiom reporting, with a CI failure on `sorryAx` or warnings. The baseline paper’s creation-era claim of no Lean kernel run is stale if read as applying to the companion modules. The PR description and original core preamble are historical statements. PDF text and rendering were beyond this source audit. The style-reference PDF was located, but its caption text was unavailable through page extraction. No stylistic revisions were made to the treatise.

## Philosophy and translation

1. **Representation.** The opening gives the treatise its object. A person, the observer’s model of them, and the truth of a particular inference should remain distinct. The probabilistic interpretation models judgments about defined targets. A whole interpersonal representation also includes salience, narrative and interpretation that the posterior need not capture.
2. **Knowing enough.** Section 2.7 is one of the strongest propositions. Sufficiency depends on the step under consideration. The decision model adds an expected-loss criterion under assumptions. The source does not say that a probability or utility calculation exhausts what it is to know someone.
3. **Preferences.** Section 3.23 separates discovering a prior desire from acquiring a different one. The useful challenge is telling the mechanisms apart when reports shift. This distinction deserves more emphasis than lists of reasons for attraction.
4. **Communication.** Intention, expression, uptake and feeling understood are separate targets. Multiple passages about ambiguity reinforce Chapters 1–2, at some cost in repetition. Preserve the step from generic uncertainty to ambiguity created by expression and interpretation. An analogy from silence illustrates underdetermination given a sparse observation channel.
5. **Reciprocity.** The strongest point is that an informed decision belongs separately to each participant. The logical line in 5.31 illustrates a necessary condition built into voluntary participation. Mutual willingness and a voluntarily undertaken step are distinct if feasibility or agreement on terms is in question. Read claims about how someone ought to proceed as normative when they go beyond that condition.
6. **Development.** The opening about improving oneself is broader than the chapter’s most precise idea. Sections 6.63, 6.64, 6.91 and 6.92 advance the argument by distinguishing three processes, locating them in mutual participation, and spelling out the temporal difference between an unknown fact and a newly established relation. The chapter’s counterfactual discussion is defensible as a limit on inference from one trajectory.
7. **Closing proposition.** The first sentences gather the major distinctions into a coherent conclusion. The last sentence adds an experiential observation. It is a literary coda with a broader meaning than any identification theorem. Wittgenstein’s 4.1212 occurs in a discussion of representation and logical form. Its use here is an analogy and structural inheritance, with no need to interpret the coda as a claim of logical ineffability. [Primary text](https://wittgensteinproject.org/w/index.php/Tractatus_Logico-Philosophicus_%28English%29)

The three source editions preserve the main argument and the key sequence 6.63, 6.91, 6.92 and 7. The English “only come into being” and Latin “tum demum” in 6.92 can sound like stronger exclusivity than “baru terbentuk.” “Can be put into words” and “verbis explicari possunt” in §7 can sound stronger than “selesai dalam kata-kata,” which allows words to express some of the experience without exhausting it. These are localized editorial judgments. A full Latin idiom review and line-by-line certification remain open. Preserve the author’s Indonesian prose. If revising translations later, prefer preserving the weaker §7 sense and rechecking the printed editions.

## Theorem correspondence

“Checked” below refers to the baseline modules and the verification receipt above. Names within a row list the actual declarations, with narrative scope kept explicit.

| Source and paper claim | Checked finite core | Assessment |
|---|---|---|
| 1.4, 6.51 / C1 | `recover_hidden_with_key`, `same_public_signal_compatible_with_both` | XOR reconstruction and feasibility. The fair-bit independence and entropy calculation are written proof only. |
| 2.61 / T2 | `identical_likelihood_preserves_cross_products` | Algebraic equality on pre-normalization weights. Positive priors and positive observation likelihood matter for the written odds statement. Equality of the full history law is a premise. |
| 2.7 / T3 | `perfect_information_unneeded_if_actionA_common_best`, `zero_information_value_iff_common_best_action`, `uncertain_state_can_have_zero_information_value` | Two-by-two table, including ties. Weighted nonnegative integer entries, no probability distribution formalized. The witness contains a table, with uncertainty supplied by its interpretation. |
| 3.23 / C2 | `preference_formation_and_reporting_can_look_identical` | Equal report sequence under different preference and context paths. If context is recorded and the XOR channel known, this ambiguity disappears. Self-belief and discovery are outside this declaration. |
| 4.61–4.62 / C3 | `one_silent_observation_does_not_identify_intention` | Definitional equality under a constant channel. |
| 5.3–5.33 / D1, T4, §5.3 | `jointly_undertaken_requires_both`, `dependent_willingness_cell_bounds`, `individual_information_does_not_force_joint_choice` | Conjunction elimination, integer cell bounds, and a Boolean willingness witness. The last declaration has no knowledge variable. Dividing by a positive total gives the written probability bounds. |
| 6.63 / T5 | `passive_information_never_reduces_optimal_value`, `passive_information_equality_criterion` | Weighted binary signal-by-action table. Equality reduces to T3’s algebra with different semantic indices. Finite nonempty decisions and fixed permissible actions and utilities matter. |
| 6.63–6.64, 6.91–6.92 / §6, C4 | `learning_only_preserves_relation`, `relation_only_preserves_beliefA`, `relation_only_preserves_beliefB`, `relationship_can_change_without_belief_change`, `active_probe_can_underperform_quiet`, `passive_signal_can_outperform_quiet` | The field invariants follow by construction. Scores are preset constants; the draft derives the payoffs from a fair-bit model separately. |
| 6.92 / C5 | `no_universal_trait_only_relation` | Same traits and different history bits block a deterministic trait-only rule in one witness. |
| 6.41–6.43 / C6 | `actual_observation_agrees`, `unchosen_action_disagrees` | Two explicit response functions agree on the taken action and differ on the alternative. |
| 7 | None | Literary and methodological conclusion. |

| Dynamics declarations | Correspondence and audit |
|---|---|
| `run_empty`, `stateAt_zero`, `run_append`, `stateAt_length` | Chronological list semantics. Append composition supplies the useful induction for reasoning about prefixes and continuations. |
| `same_signal_same_next_beliefA`, `same_signal_same_next_beliefB` | Congruence of fixed agent-specific update functions. Applies within each agent given that agent’s equal prior bit and observation. Entails no cross-agent convergence. |
| `run_preserves_traitA`, `run_preserves_traitB`, `toy_stable_traits` | Optional step invariance lifts to histories; the toy witness satisfies it definitionally. |
| `no_profile_only_predictor`, `same_terminal_profile`, `different_terminal_relation`, `encounter_order_matters`, `toy_has_no_profile_only_predictor` | A generic equality obstruction with an explicit order-sensitive witness. The relation update reads A’s pre-step belief. The model represents history dependence without storing history as a field. |
| `unequal_signals_in_one_encounter`, `learning_without_relational_change`, `relational_change_without_learning`, `preference_change_without_learning_or_relational_change` | Boolean reachability and field separation. The learning-only declaration checks A’s belief and the relation, while B stays unchanged by the toy update definition. The preference-change declaration checks A’s preference, both beliefs and the relation. |
| `informative_probe_can_have_lower_total_value` | Scores a positive belief bit against a stipulated relational cost. No hidden variable or accuracy criterion is present here. The paper’s separate fair-bit argument supplies an example with genuine state information. |
| `exact_bool_predictor_iff`, `profile_only_predictor_iff` | Audit revision. Exact recovery is equivalent to constancy on summary classes. The reverse direction supplies the missing criterion for when a profile does suffice. Classical existence allows arbitrary summaries and makes no computability claim. |

## Literature and novelty through the November 2026 search

| Neighboring work | What it already covers and how it bears on this project |
|---|---|
| L. A. Paul, *Transformative Experience* | Separates access to knowledge through experience from changes in one’s point of view or values. The treatise’s discovery/formation distinction fits this lineage. A dyadic state adds an application and an additional modeled object of change. Ordinary preference changes need not be transformative in Paul’s strong sense. [DOI](https://doi.org/10.1093/acprof:oso/9780198717959.001.0001) |
| Van Ditmarsch and Kooi, *Semantic Results for Ontic and Epistemic Change* | Dynamic epistemic events change information and can change facts via postconditions. The distinction motivating §6.92 already exists formally. That literature supplies richer explicit knowledge semantics; the present draft uses individual conditional probabilities and a relational component. [Preprint](https://arxiv.org/abs/cs/0610093) |
| Smallwood and Sondik; Gmytrasiewicz and Doshi; Bernstein et al. | Finite POMDPs supply controlled transitions and filtering. Interactive POMDPs represent a participant’s beliefs about other agents and their models. Decentralized models supply private information and local decisions. A cooperative objective or a single planner would require further justification here given two independent willingness conditions. [POMDP](https://doi.org/10.1287/opre.21.5.1071), [I-POMDP](https://doi.org/10.1613/JAIR.1579), [decentralized control](https://doi.org/10.1287/moor.27.4.819.297) |
| Blackwell, *Equivalent Comparisons of Experiments* | Provides the benchmark for comparisons of information structures across decision problems. T5 uses the simpler option of ignoring a free signal in one fixed decision problem. In a controlled encounter the actions can change the state and future options, so the requisite common decision problem must be justified before invoking an information ordering. [DOI](https://doi.org/10.1214/aoms/1177729032) |
| Hernán and Robins, *Causal Inference: What If* | Distinguishes observed outcomes and interventions, including longitudinal confounding affected by past treatment. Selection into a second encounter can depend on past reactions and change the next feasible action set. A temporal association alone cannot distinguish creation from revelation. [Book](https://www.hsph.harvard.edu/miguel-hernan/causal-inference-book/) |
| Vazire; Kenny and Ledermann | Self–other accuracy can vary with trait observability and evaluativeness. APIM models actor and partner associations in interdependent data. The Social Relations Model’s actor, partner and relationship effects organize dyad-specific variation in round-robin settings. An estimated relationship effect does not identify how or when it was formed. [SOKA](https://doi.org/10.1037/a0017908), [APIM](https://doi.org/10.1037/a0019651), [interpersonal perception](https://davidakenny.net/ip/interp.htm) |
| Laurenceau, Barrett and Pietromonaco | In event-contingent diary studies, disclosure and perceived responsiveness relate to experienced intimacy. This is a close interpersonal precedent for interactions contributing to experienced relation. Perceived responsiveness and feeling understood do not independently certify accuracy about another mind. [DOI](https://doi.org/10.1037/0022-3514.74.5.1238) |
| Eastwick and Finkel; Eastwick, Finkel and Eagly | The 2008 speed-dating design shows a gap between stated ideals and prediction of initial desire. The 2011 studies show context matters, with matching effects in written profiles and different patterns after live interaction. Neither establishes that operative preferences must change. [2008](https://doi.org/10.1037/0022-3514.94.2.245), [2011](https://doi.org/10.1037/a0024062) |
| Joel, Eastwick and Finkel; Baxter et al. | In two speed-dating datasets Joel et al. found predate self-report features predicted some actor and partner variance but failed to predict relationship-specific initial desire. Baxter et al. found that impressions formed after meeting predicted later romantic behaviors. Both are useful benchmarks, with no general impossibility claim and no causal separation of discovery from formation. [Joel et al.](https://doi.org/10.1177/0956797617714580), [Baxter et al.](https://doi.org/10.1073/pnas.2206925119) |
| Eastwick, Zhao and Zietsch, October 2026 | The closest topical review proposes recurrent shared positive experiences as one source of compatibility and examines why simple preference–trait matching is weak. It anticipates the project's broad conceptual account of developing compatibility. It is a review and proposal, so it leaves room for a formal model specifying independently testable contrasts between mechanisms. [DOI](https://doi.org/10.1016/j.tics.2026.10.001) |
| Walter et al., 45-country replication | Broadens evidence about stated mate preferences. It does not supply cross-cultural validation of disclosure, private updating, or relationship development. Those outcomes require their own translated measures and validation. [PubMed](https://pubmed.ncbi.nlm.nih.gov/32196435/) |

The strongest current contribution is the author’s proposition-structured synthesis and the precise correspondence it makes possible between a philosophical distinction, a finite model, and a checked witness. The exact prediction result is generic function factorization. The pure-change examples reflect the independence the model gives its fields. XOR, Fréchet bounds and passive-information inequalities are established mathematics. The new classification-risk calculation strengthens the application by quantifying the error under a specified distribution. It supplies neither estimated probabilities nor a new general theorem in statistics.

The strongest prospective contribution is an identifiable contrast between a stable dyad-specific property that is progressively revealed and a dyad-specific property changed by an encounter. Mere pre/post reports can fit both stories, including through self-belief and context. A hidden action adds another mixture problem: the filter must integrate the action with its policy conditional on relevant private information. The early weighted definitions lack normalization and can even give transition rows different total weights, which rules out interpreting global normalization as an arbitrary row-normalized Markov kernel.

Additional comparisons refine the scope. The philosophical problem of other minds includes perception and testimony as possible sources of knowledge. The posterior model commits to an inferential representation for selected questions, leaving those broader accounts open. Ambady and Rosenthal's thin-slices meta-analysis shows limited behavioral samples can predict some specified outcomes, so the text's warnings about ambiguity are compatible with informative first impressions. Aumann's common-prior and common-knowledge agreement result offers a benchmark whose hypotheses are absent from private histories here. Dual-effect control studies actions that affect both controlled outcomes and uncertainty, while finite asymmetric-information stochastic games formalize independent strategic behavior under explicit information assumptions. These precedents place active encounters and private updating within existing mathematics. [Other minds](https://plato.stanford.edu/entries/other-minds/), [thin slices DOI](https://doi.org/10.1037/0033-2909.111.2.256), [Aumann](https://www.haverford.edu/sites/default/files/Aumann1976.pdf), [dual effect](https://explore.metascienceobservatory.org/papers/W2089063495), [asymmetric information](https://arxiv.org/abs/1209.3549)

## Evaluation rubric

Score each dimension from 0 to 4. A 0 denotes absent evidence, 1 a material gap, 2 a defensible but partial treatment, 3 a strong treatment with specific limitations, and 4 a mature treatment supported within scope. Weights are explicit and totals divide by applicable weight. Philosophical verification and empirical relevance are excluded from the treatise score because it is evaluated as a philosophical-literary work. Empirical relevance in Lean assesses correspondence with testable claims, independently of technical proof validity.

| Dimension | Weight | Tractatus | Paper | Lean | Unified |
|---|---:|---:|---:|---:|---:|
| Correctness | 15 | 3 | 3 | 4 | 3 |
| Coherence | 10 | 4 | 3 | 3 | 3 |
| Originality of treatment | 8 | 3 | 2 | 2 | 3 |
| Established novelty | 8 | 2 | 1 | 1 | 1 |
| Significance | 9 | 3 | 3 | 2 | 3 |
| Parsimony | 7 | 3 | 2 | 3 | 2 |
| Explanatory power | 9 | 3 | 2 | 2 | 2 |
| Rigor appropriate to genre | 9 | 3 | 3 | 4 | 3 |
| Verification | 8 | — | 2 | 4 | 3 |
| Empirical relevance | 6 | — | 2 | 1 | 2 |
| Readability | 6 | 4 | 3 | 3 | 3 |
| Reproducibility or traceability | 5 | 3 | 3 | 4 | 3 |
| **Rounded weighted percent** | **100** | **77** | **62** | **71** | **66** |

The treatise leads because §§2.7 and 6.92 organize a coherent and readable argument despite overlap in §§1, 2 and 4. The paper’s formal arguments are generally sound given finite nonempty decisions and probability assumptions, while mechanisms and predictions remain insufficiently identified. Lean checks its finite statements with transparent inputs, but several declarations are field projections or preset numerical comparisons. The unified project has a traceable progression, with a substantive gap from toy model to data and from the paper’s stochastic architecture to verified code. These scores are an editorial rubric, without reviewer agreement or external calibration.

As a philosophical essay the project has a defensible core now. As a mathematical working paper it provides clear examples and research questions. A formal methods publication would require either a stronger theorem or a reusable verification method, and an interdisciplinary publication would require tighter literature engagement or discriminating evidence. As a basis for empirical research it can motivate operational definitions, competing models and a design.

## Prioritized research ledger

1. **Define a discriminating estimand.** Specify a measurable relational outcome, an observation channel and independently acceptable encounter policies. Start with two observationally equivalent mechanisms under a passive policy and state a sufficient separation condition under a second policy. Use a common measurement model and explicitly handle context and second-encounter selection. Benefit: the problem becomes falsifiable. Risk: plausible narratives can remain equivalent if the channel is unconstrained.
2. **Formalize a normalized controlled filter incrementally.** Use finite rational distributions or Mathlib’s finite probability infrastructure after evaluating the dependency cost. Require nonnegative row weights, unit row sums and positive observation evidence before proving normalization. Treat zero evidence explicitly. Then prove equivalence of predicted observation laws across a policy class or supply a separating policy. Preserve the existing deterministic proofs as witnesses.
3. **Represent both decisions.** Give each participant their own observations, feasibility and continuation evaluation. Separate exact state recovery, low decision regret for each participant and the feasibility of a freely chosen joint step. State whether each preference comparison uses current or anticipated future preferences.
4. **Improve reproducibility.** Audit all proof axiom dependencies in CI, run the Python bounded checks independently, and record Markdown-to-PDF source revisions. Correct stale numbering comments in the example checker before expanding it. The existing toy code processes common global event histories with separate observation functions. It currently has no explicit agent-private logs or strategic policies.
5. **Extend independent review.** Commission a close Latin review and full edition parity check, broaden the search to dynamic games with asymmetric information and empirical longitudinal dyadic models, and seek external assessment before making any novelty claims.

## Audit revision verification

Commit `5325174fcc0a5d1339ac47faa0eaab7bf77b9616` passed [Linux run 44354979353](https://github.com/dwijayuda/pskernel/actions/runs/44354979353), [job 134980517543](https://github.com/dwijayuda/pskernel/actions/runs/44354979353/job/134980517543). Checkout was the synthetic PR merge of that head into `3b6ed20da4900970ff20c6a9f3397baa31118cbe`. The job used Lean 4.36.0 and emitted `LEAN_KERNEL_CHECK_OK`.

- Core SHA-256: `98439818fa421e9d9c55fcecb06dc02da48e761ecc50c1d0393ddcd46c23f2ac`.
- Dynamics SHA-256: `64e6f8ce53bad966f950ce5c47fa7f4259e16f6fb1d2ca04521d7ec837f0a4ca`.
- Both new theorems reported the imported Lean axioms `propext`, `Classical.choice` and `Quot.sound`. The file adds 2 theorem declarations to the 19 baseline dynamics declarations. The normalized-filter and classification-risk proofs are outside this checked result.

### Reproduction and rendered editions

The source revision `3996e0f9019a35ca8cfe567573899c895ed2fb0f` passed the [direct Linux push job 134986097408](https://github.com/dwijayuda/pskernel/actions/runs/44356552353/job/134986097408) and [PR job 134986145826](https://github.com/dwijayuda/pskernel/actions/runs/44356567167/job/134986145826). The Lean version, both source hashes and imported axiom reports matched the receipt above. The bounded Python checks reproduced the committed JSON, including 20,480 passive-information cases, 1,215 decision-sufficiency cases, 255 willingness tables and 2,257 dynamic prefix checks.

[PDF job 134986097407](https://github.com/dwijayuda/pskernel/actions/runs/44356552316/job/134986097407) rendered all four editions from that source revision. It committed only PDF snapshots at `6bf3ee4fe99660c394c1a1e8f13911768fabbc9b` and uploaded artifact `14453436720`. The archive SHA-256 is `5f768ae00f10d14e41013f5bd0eafc76fd91d902c43df2e56f6908db394258a6`. The revised paper PDF SHA-256 is `64df80a7a840e9fcb6bf738690114a20fe7c72ba600876c8f8f310d73df91683`. The job logs contain all four individual hashes. A successful renderer establishes artifact generation, with visual inspection and line-by-line translation review separate.

Additional empirical benchmarks include the [Social Relations Model](https://doi.org/10.1016/S0065-2601(08)60144-6), the [ideal-preference meta-analysis](https://pubmed.ncbi.nlm.nih.gov/23586697/) and a [43-study longitudinal analysis of relationship quality](https://doi.org/10.1073/pnas.1917036117). Initial attraction, current relationship quality and future change are separate prediction targets. Any proposed dyadic model should specify which target it evaluates before comparing its predictive value with a profile-only baseline.

## Follow-up model

[Can an encounter distinguish revelation from change?](notes/REVELATION_VS_CHANGE.md) formalizes the prioritized two-mechanism comparison with exact binary laws and explicit policy acceptance. The follow-up proves binary report normalization and posterior mass after positive evidence, a necessary and sufficient equality criterion for the two report laws, passive equivalence, and a separating accepted-policy witness. The new module adds 11 public theorems and one private algebraic lemma. The measurement and prior are shared across mechanisms and policy contexts.

Source commit `11db3a7a89580eaebd8d7af778fb4b0b1a8ccdd6` passed Lean 4.36.0 on [direct Linux run 44363450396, job 135010749904](https://github.com/dwijayuda/pskernel/actions/runs/44363450396/job/135010749904) and [PR run 44363463675, job 135010799285](https://github.com/dwijayuda/pskernel/actions/runs/44363463675/job/135010799285). The new module's SHA-256 was `3de275db8d84e43a64d1f34caed6d1f9ed16211befe4ed16a6bb9bd9a8c02e81`. The original two module hashes matched the previous receipt. Lean reported `propext` and `Quot.sound` for the report-normalization and law-separation results, and no axioms for the posterior-total equality. Both Python checks also passed. The pinned model concerns a single binary transition and positive-evidence Bayes correction.

### Identification sensitivity

[What two encounter policies can identify](notes/IDENTIFICATION_SENSITIVITY.md) derives sharp bounds for a one-way binary transition under invariant unknown measurement with known baseline prevalence, and describes the assumptions needed to interpret an empirical offer-policy contrast. The general sharp bounds are a written proof. Lean checks the calibrated magnitude equation and uniqueness, and explicit witnesses for unknown calibration, reporting drift, and different participation. All witness comparisons use exact counts.

Source commit `8ded72386d8b1ccb9b87dbaedf67b7ceaf4c83f7` passed [Linux PR run 44365219577, job 135017009883](https://github.com/dwijayuda/pskernel/actions/runs/44365219577/job/135017009883) on Lean 4.36.0. The identification module SHA-256 was `1cec0dc1569f4b8bd0a2472cfd63277777a284987efcbcc7ea44b4c06bd0fb0f`. The five expanded proof dependency reports each list `propext` and `Quot.sound`. The code adds six public theorem declarations. The finite results distinguish candidate mechanisms inside a specified model and provide no population estimates.

### Finite identification milestone

Working draft v0.2 integrates the one-step binary identification study in §6.5 and its proof ledger. Lean verifies `movement_lower_bounds` and `construct_sharp_channel`, giving the necessary inequalities and a channel construction for every feasible rational candidate with positive movement and report contrast. The paper gives the equivalent real-valued sharp interval. The model also supplies exact endpoints of the worked example, observationally equivalent reporting/selection alternatives, and a separate empirical design interpretation. At this milestone the original literary text and its numbered propositions remain intact.

The general sharp-bound theorems passed on source commit `08804919ed8374b14b1f833b83748e4fd00554f6` in [Linux PR run 44366133890, job 135020226165](https://github.com/dwijayuda/pskernel/actions/runs/44366133890/job/135020226165). The job logged source SHA-256 `cb7a773beb5863b0965e9de76246637f564848a645fa7529caba40b467308311` for the identification module. Lean 4.36.0 reported `propext` and `Quot.sound` for the two general bounds and construction results. The later integration revision adds the numerical endpoint check and the revised paper. The general multiround model and empirical validation remain research questions.
