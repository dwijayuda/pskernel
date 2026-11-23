# Mathematical Companion to *Tractatus de Perceptione et Amore*

**Version 0.4 — proposed multi-agent research edition, 23 November 2026**  
**Philosophical source:** Indonesian *Tractatus* v1.2.0 **proposed**, 126 propositions; the repository's canonical edition at preparation remains v1.1.0, 116 propositions.  
**Edition alignment:** This research companion covers the 126-proposition [proposed manuscript](../editions/v1.2.0-proposed/README.md), including the exact Indonesian wording of §§6.95–6.96 and the revised §7. The mathematical propositions do not purport to *prove* the philosophical text.  
**Relation to preceding work:** extends the repository's readable companion v0.3 (21 November 2026), the technical draft v0.2, and an independent multi-agent extension proposal v0.1 (22 November 2026). The existing proof sources are NOT modified or reverified here.  
**Status:** written mathematical proofs under stated assumptions, formal-code *candidates*, no empirical validation or independent peer review.

## Abstract

We model acquaintance among multiple agents while retaining the philosophical distinction between a person, that person's representation in another mind, and the latter's represented ideal. The enlarged state includes potentially changing individual features, operative preferences, subjective ideals, self-beliefs, directed perceptions, dyad-specific relational states, interaction opportunities, and contexts. We prove conditional stability, locality, observational symmetry, and prediction-sufficiency claims; construct third-party spillover and order-sensitive witnesses; and show why the causal effect of an encounter is generally not identified from observational exposure and outcomes alone. A conditional-information result characterizes exactly when third-party history improves idealized predictive log loss. These results demonstrate mathematical possibilities, **not empirical laws or a general causal explanation of falling in love or separating**.

## 0. A source-to-model contract

For two agents A and B, the original literary shorthand is:

\[
\mathcal D_{AB,t}=(A,B,P_A(B,t),P_B(A,t),I_A(t),I_B(t)).
\]

**Important:** A and B designate persistent *persons*, not time-varying six-dimensional vectors. A modeled state of an individual is denoted \(x_{i,t}\). The expression \(P_A(B,t)\) is A's current representation of aspects of B. It does not equal B, nor is it guaranteed to be accurate. The represented ideal \(I_A(t)\) does not necessarily equal A's *operative* preference \(q_{A,t}\), and neither is necessarily fully self-known. Let \(\rho_{A,t}\) denote A's self-belief about \(q_{A,t}\).

For a finite set \(V=\{1,\dots,N\}\), define the multicomponent modeled state:

\[
\Omega_t=\bigl( (x_{i,t},q_{i,t},I_{i,t},\rho_{i,t})_{i\in V},
(P_{ij,t})_{i\ne j},(r_{\{i,j\},t})_{i<j},G_t,c_t \bigr).
\tag{M0}
\]

- \(r_{\{i,j\},t}\) is a *pair-specific* state, potentially a vector with distinct experiences for i and j. It is not logically reducible to love, mutual consent, or a single score. It may encode remembered interaction history.
- \(G_t\) encodes opportunities and actions in a network of encounters, including interaction selection. A representation \(P_{ij,t}\) may be absent, rather than silently replaced with a neutral score.
- \(c_t\) includes changing context; \(x_{i,t}\) contains only features relevant to the question, never a full definition of the human being.

A possible stochastic model is a transition kernel \(T_t(\omega'\mid\omega,a_t)\), and agent-specific observations follow \(O^i_t(y\mid\omega',a_t)\). Actions \(a_t\) are chosen, not generally randomized. The agent may hold a posterior \(\pi^i_t(\omega)=\Pr(\Omega_t=\omega\mid h^i_t)\), but no claim is made that people consciously perform Bayesian inference.

**Three separate mechanisms:** (i) information about a pre-existing state, (ii) change of someone's preferences/self-conception, and (iii) formation or deterioration of a relational state. A changed report can reflect any of these, as well as a change in reporting behavior. Distinguish *change observed after an encounter* from *change caused by an encounter*.

## 1. Relationship with the earlier seven chapters

- **Person and picture (§§1.12, 1.6–1.61):** different observers can update different perceptions, and each person lives amid others' interactions.
- **Knowledge (§§2.21, 2.7–2.72):** a history can leave several hypotheses observationally equivalent; enough information is always relative to a specified decision.
- **Ideals (§§3.12–3.23, 3.7–3.71):** a representation of one's ideal can be incomplete and affected by experiences with people other than the person currently evaluated.
- **Interpretation (§§4.53–4.54):** feeling understood is distinct from verified inferential accuracy.
- **Choice (§§5.3–5.33):** a freely joint action requires voluntary participation of both; this is definitional, not a statistical law.
- **Change (§§6.23, 6.63–6.66, 6.91–6.94):** persons, representations, and dyadic states may evolve through multiple encounters; temporal succession does not identify causation.
- **Saying, showing, and limits (§§6.95–6.96, 7):** verbal self-reports are evidence but are not the whole possible evidence; behavior and shared experience may also matter, but do not uniquely determine hidden intentions or causes. The final §7 is an epistemic norm: what is not yet known must not be asserted *as though it were known*. It does not prohibit appropriately qualified hypotheses or statistical inference. This application is an interpretive analogy to, **not** the technical logical `Sagen/Zeigen` distinction of early Wittgenstein.

## 2. Model family and what it does NOT assume

A purely illustrative discrepancy mechanism, **not** a universal theory of attraction, places a perceived person \(P_{ij,t}\) and ideal \(I_{i,t}\) in the same metric space \((M,d)\), and defines

\[
D_{ij,t}=d(P_{ij,t},I_{i,t}), \qquad
C_{ij,t}=\mathbf 1\{D_{ij,t}\le\tau_i\}.
\tag{M1}
\]

The symbol \(C_{ij,t}\) is only a *toy classification of represented ideal–perception discrepancy*. It is NOT attraction, happiness, actual compatibility, commitment, or joint willingness. Empirical research shows that simple matching of ideal preferences to perceived partner traits often has weak predictive validity; the appropriate baseline is a strong longitudinal actor-partner/dyadic model rather than an ideal-distance score alone [R1,R2].

A generic *candidate*, not a verified psychometric law, allows

\[
I_{i,t+1}=F_i\big(I_{i,t},\{P_{ik,t},r_{ik,t},e_{ik,t}: k\in N_i(t)\},c_t,\xi_{i,t}\big),
\tag{M2}
\]

\[
P_{ij,t+1}=U_{ij}(P_{ij,t},\mathrm{observations}_{i,t},c_t), \quad
r_{\{i,j\},t+1}=R_{ij}(r_{\{i,j\},t},a_{i,t},a_{j,t},\Omega_t).
\tag{M3}
\]

A transition dependence is an assumption about mechanism, not evidence of its occurrence. Selection of encounters must be modeled, since people already changing their ideals may select different experiences [R4,R5].

## 3. Mathematical results with explicit proofs

### MA-1 — Change in represented matching distance is bounded

**Assumptions:** \((M,d)\) is a metric space; both perception and represented ideal have values in M at consecutive times. Set \(D_t=d(P_t,I_t)\). Then

\[
\boxed{|D_{t+1}-D_t|\le d(P_{t+1},P_t)+d(I_{t+1},I_t).}
\tag{T1}
\]

**Proof.** By the triangle inequality, \(D_{t+1}\le d(P_{t+1},P_t)+D_t+d(I_t,I_{t+1})\). Exchange the two time indices to obtain the reverse bound; combine both. \(\square\)

**Corollary.** If \(|D_t-\tau_i|\) is strictly larger than the right-hand side of (T1), \(C_{ij,t+1}=C_{ij,t}\). **Limitation:** stability of a fictional discrepancy category does not imply stability of real attraction.

### MA-2 — An encounter with X can reverse A's evaluation of absent B

**Existence construction.** Let \(V=\{A,B,X\}\), \(M=[0,1]\), \(d(x,y)=|x-y|\), and \(\tau_A=0.15\). Set \(P_{AB,0}=0.40\), \(I_{A,0}=0.30\). Then \(D_{AB,0}=0.10\le\tau_A\). Define an A–X event, with *stipulated* transition \(I_{A,1}=0.85\), keeping \(P_{AB}\), \(x_B\), and the A–B encounter log unchanged. Thus \(D_{AB,1}=0.45>\tau_A\). \(\square\)

**Meaning:** the mechanism is logically possible under the defined transition. The example does **not** establish that any particular third-party encounter causes such a transition. An alternative model can generate the same observed change through drift, an unobserved event, or a reporting change.

### MA-3 — Finite-speed propagation across a component dependency graph

**Assumptions:** A fixed graph \(G\) has an edge \(u\to v\) if the next value of component \(v\) is permitted to depend on the present value of \(u\). All update functions are deterministic and shared between two trajectories; external inputs are identical. Their initial states differ only at component \(X\).

**Theorem.** If there is **no directed path of length at most** \(k\) from component \(X\) to \(Y\), the values at Y at time k are identical across the trajectories.

**Proof by induction.** At time zero, a difference is possible only at X. Suppose every difference at time k lies at a vertex reachable from X in at most k steps. A difference at vertex v at time k+1 requires a difference at some incoming coordinate u at time k (the rules and exogenous inputs are identical). By induction, X reaches u in at most k steps; append u→v. Therefore v is reachable in at most k+1 steps. Contrapose. \(\square\)

**Caution:** G is a graph of *component dependencies*, not simply a friendship/contact graph. Reflexive self-dependencies must be represented as edges where present. Changing networks require temporal paths; shared unobserved shocks break the comparison unless held fixed.

### MA-4 — Translation symmetry prevents identifying perception and ideal separately

**Assumptions:** \(P_t,I_t\in\mathbb R^d\), observation \(S_t=\phi(\|P_t-I_t\|)\). For any translation sequence \(v_t\) whose shifted states remain admissible, define \(P'_t=P_t+v_t\), \(I'_t=I_t+v_t\).

**Theorem:** \(S'_t=S_t\) for every t.

**Proof:** \(P'_t-I'_t=P_t-I_t\), hence both the norm and its image under \(\phi\) are unchanged. \(\square\)

**Caution:** this only establishes non-uniqueness from discrepancy-only outcomes; direct measurements of P or I, or constrained parameter domains, can remove this specific invariance. Distinguishing operative preference \(q\) from the self-report of an ideal \(I\) requires further measurement assumptions.

### MA-5 — When does a six-part summary exactly determine a relational outcome?

Let H be the set of admissible histories, Z:H→S a summary (for example, the six-part vector), and R:H→{0,1} a relational outcome.

**Theorem:** There is an exact deterministic predictor f:S→{0,1} with \(R(h)=f(Z(h))\) for every h **iff** \(Z(h_1)=Z(h_2)\implies R(h_1)=R(h_2)\) for all admissible histories.

**Proof:** Necessity follows from equal inputs having equal outputs. For sufficiency, define f on each reachable summary to return the unique outcome assigned by all histories with that summary; fill its values arbitrarily on unreachable summaries. \(\square\)

**Status:** this is **pre-existing** in the repository (`exact_bool_predictor_iff`, `profile_only_predictor_iff`). It is included for completeness, not presented as a new result. It does not rule out probabilistic prediction from individual traits.

### MA-6 — Conditional attenuation in a contractive influence model

**Assumptions:** \(z_{t+1}=Wz_t+u_t\) with a common W and identical inputs for two trajectories; the induced infinity norm satisfies \(\|W\|_\infty\le\alpha<1\).

**Theorem:** \(\|z_t-z'_t\|_\infty\le\alpha^t\|z_0-z'_0\|_\infty\).

**Proof:** \(\delta_{t+1}=W\delta_t\), so \(\|\delta_{t+1}\|_\infty\le\|W\|_\infty\|\delta_t\|_\infty\). Iterate. \(\square\)

**Warning:** many normalized opinion averaging models have \(\|W\|_\infty=1\), so this strict contraction theorem does *not* generally establish convergence for them. The result says nothing about all human preferences converging.

### MA-7 — Stability of a matching need not survive changing preferences

Take four agents A,B,C,D with fixed pairing A–B and C–D. At time zero A prefers B to C and C prefers D to A; let B rank A highest and D rank C highest (complete remaining rankings arbitrarily). Then no two agents mutually prefer each other over their current partners, so the pairing is stable in this specified one-to-one matching problem. At the next time A prefers C to B and C prefers A to D; keep B and D's rankings unchanged. Now A and C mutually prefer each other to their assigned partners, forming a blocking pair. The same matching is no longer stable. \(\square\)

**Warning:** stability here is a game-theoretic definition, not relationship permanence. This is not a theory of breakup or divorce, nor evidence that preferences alone explain them.

### MA-8 — Observational encounter–outcome association does not identify encounter causation

**Newly emphasized negative identification result.** Let \(U\sim\mathrm{Bernoulli}(1/2)\). Let E denote whether A encountered X and Y be a later binary observed evaluation of absent B. Compare two structural causal models:

**Model S (selection only).** The observational equations are \(E:=U\) and \(Y:=U\). The observations are \((E,Y)=(0,0)\) and \((1,1)\), each with probability \(1/2\). Under intervention, \(Y(do(E=1))-Y(do(E=0))=0\) for either U.

**Model C (causal influence).** The observational equations are \(E:=U\) and \(Y:=E\). The observed pairs and probabilities are **identical** to Model S, but under intervention, \(Y(do(E=1))-Y(do(E=0))=1\) for either U.

**Proof:** Under observation, E=U in both models, making Y=U and yielding identical joint laws. Under intervention do(E=e), structural assignment to E is replaced. In S, Y still equals U; in C, Y equals e. Thus their interventional effects differ despite observational equivalence. \(\square\)

This is an elementary SCM construction illustrating the familiar confounding of selection and social influence. It is particularly important for the new §6.66. It does not show that effects cannot be identified under stronger designs or assumptions; it shows observational data **alone** cannot distinguish these unrestricted mechanisms [R4,R5].

### MA-9 — Exact condition for added *predictive* value of outside-interaction history

Let \(Y\) be a discrete future observation, Z the admissible pre-outcome history available in a strong dynamic dyadic baseline, and E an additional record of third-party exposure observed **before Y**. Assume the true conditional distributions are available to the forecaster and use logarithmic loss. Then

\[
\boxed{\mathcal L^*(Z)-\mathcal L^*(Z,E)=H(Y\mid Z)-H(Y\mid Z,E)=I(Y;E\mid Z)\ge0.}
\tag{T9}
\]

**Proof:** For each covariate history, expected log loss is minimized by the true conditional probability distribution; its optimal value is conditional entropy. Subtract the two optimal values and apply the definition of conditional mutual information. Its nonnegativity is the standard Gibbs inequality, or nonnegativity of conditional Kullback–Leibler divergence. \(\square\)

**Strict improvement** occurs iff Y is not conditionally independent of E given Z on a set of positive probability (with usual finite-distribution conventions). This is an **ideal population** result, not a guarantee of improved finite-sample or out-of-sample prediction after fitting a higher-dimensional model.

**Corollary — perfect prediction without a causal effect.** In the selection-only model S from MA-8, let Z be constant. Since Y=E=U is a fair bit, \(H(Y)=\log 2\) and \(H(Y\mid E)=0\), so \(I(Y;E)=\log 2>0\). Yet the effect of \(do(E)\) on Y is zero. Thus even perfect predictive usefulness of the outside-interaction indicator does **not** establish that the encounter *caused* the outcome. This is a standard causal-versus-associational distinction expressed in the present notation.

## 4. Interaction order and the condition of voluntary joint action

The prior repository's deterministic Lean core already constructs two histories with identical terminal individual profiles but different relational states. The independent multi-agent candidate file includes an explicit third-party exposure followed by a dyadic event, reversed in the comparison history. Both histories can have the same six-part terminal summary and different relational outputs, **only because those transition rules are stipulated**. Existing results are not automatically novel merely because their interpretations changed.

For a freely undertaken joint step \(J_{AB,t}\), retain the philosophical definition \(J_{AB,t}=1\Rightarrow W_A(B,t)=1\land W_B(A,t)=1\). This is a **necessary definitional condition**, not a proof of feasibility or willingness. No distance criterion, information-gain score, or network intervention can substitute for the actual decision of either participant.

## 5. Explicit failure modes and counterfactual boundaries

1. **Preference report is not operative preference:** \(I_i\), \(q_i\), \(\rho_i\), and \(\hat q_i\) must be kept separate when a question requires it.
2. **Absence of a meeting is not evidence of a fixed person or ideal:** change may happen elsewhere, but a stipulated mathematical possibility is not a measured frequency.
3. **A score is not love:** \(d(P,I)\) is a toy evaluation function; its parameterization is not empirically established.
4. **Time order is not causation:** MA-8 establishes nonidentifiability from unrestricted observational association.
5. **Six components may be insufficient for history:** explicitly track relational state if that is a target. A profile-only sufficiency theorem remains conditional.
6. **Network size:** \(N(N-1)\) directed perceptions only if all ordered pairs are represented; missingness is itself potentially informative.
7. **Interference:** others' interactions can change a focal person's outcomes, contradicting naive no-interference assumptions in causal analysis.
8. **Non-stationarity and feedback:** choosing to meet X depends on past ideals and predictions, while meeting X may change subsequent states; policy must be modeled.
9. **Latent variables are not identified by naming them:** multiple observation models can induce identical distributions.
10. **Context and culture:** effects may change with platform, communication medium, cultural setting, time, and relationship stage.
11. **Formal proof vs science:** Lean checks conditional derivations in chosen definitions, not empirical psychology.
12. **Generalizability:** dating-stage measures do not establish a law of marriage, breakup, or divorce.

## 6. A falsifiable comparison program

A suitable empirical question is whether knowing histories of encounters with **other** agents improves prediction of a person's later evaluation of an otherwise uncontacted partner after conditioning on sufficiently strong dyadic, contextual and temporal baselines.

**Specify three progressively richer models:**

- M0: registered static actor and partner covariates, including represented ideals and perceived traits.
- M1: competitive *dynamic* actor–partner / Social Relations Model with dyad effects, lagged outcomes, varying context and calendar time.
- M2: M1 plus preregistered third-party exposure histories, potential mediators (independently elicited ideals and self-beliefs), and relevant graph pathways.

Pre-register the future observation Y, which must be recorded after the exposure window; avoid using the outcome itself as a baseline covariate or leaking observations between training and test partitions. Evaluate prospective holdout log loss, Brier score, calibration, and uncertainty, clustering or splitting appropriately by participant and dyad. A difference in predictive performance is *not* evidence that the third party caused a change.

For a causal estimand, define the outcome and treatment policy separately. One possible target is \(\mathbb E[Y_A^B(do(E_{AX}=1))-Y_A^B(do(E_{AX}=0))]\) within a precisely defined participant population and follow-up, under ethically permissible exposure. This requires a credible intervention or an identification strategy, consistency, a treatment definition with no ambiguous versions, positivity, appropriate comparability/exchangeability or a justified instrumental strategy, and methods for interference and missingness. Voluntary interactions cannot be made compulsory for identification. Instrumenting *offers* does not automatically identify effects of uptake; exclusion restrictions are substantive assumptions. Respect both participants' agency and privacy throughout.

## 6.1. Epistemic conclusion: what can be claimed (proposed §§6.95–6.96 and 7)

The proposed Chapter 7 no longer concludes that experience is necessarily beyond words. It says, in Indonesian, **“Tentang apa yang belum dapat kita ketahui, kita tidak boleh berbicara seolah telah mengetahuinya.”** For the formal research this has three operational consequences.

1. **Reports and conduct are observations, not direct access to private states.** The observation operator (O^i_t) may include speech, actions and context. Such signals can support probabilistic claims, but MA-4 and MA-8 show why certain hidden distinctions remain unidentifiable without additional assumptions or measurements.
2. **A mathematical possibility is not a historical explanation.** MA-2 constructs a third-party transition that reverses a toy discrepancy category; MA-8 constructs an equally compatible observational account with no causal effect.
3. **A proof is conditional on the defined model.** A Lean-kernel check can validate finite Boolean propositions, not the reality of their psychological premises. MA-1, MA-3, MA-4, MA-5, MA-6 and MA-9 still rely on the separately written proofs as stated here unless exact corresponding Lean theorems are identified in the ledger.

This is compatible with the prior distinction between what an encounter **reveals** and what it **forms** (§§6.92–6.93). It does not make observed acts a version of Wittgenstein's technical logical *showing*: that would conflate a theory of logical representation with interpersonal behavioral evidence.

## 6.2. Traceability to the proposed 126-proposition edition

The accompanying [126-row proposition alignment](../editions/v1.2.0-proposed/COMPANION_ALIGNMENT_v0.4.md) lists all current proposition identifiers and selectively tags those with explicit mathematical treatment. **No mathematical proof is inferred merely from a literary resemblance.** Cross-references to §6.65 and §6.66 relate to MA-2 and MA-8; §6.93 to non-identification; §§6.95–6.96 and §7 to the limits of warranted assertions.

## 7. Verification ledger and prospective work

| Result | Source and scope | Verification as of 23 Nov 2026 |
|---|---|---|
| MA-1, MA-3, MA-4, MA-5, MA-6, MA-9 | Written mathematical proofs under stated assumptions | Written, **not new Lean-kernel-verified proofs** |
| MA-2, MA-7, MA-8 | Explicit constructive models and counterexamples | Written; bounded examples computationally checkable |
| Earlier `MutualAcquaintance*.lean` | Historical, distinct finite / deterministic results | Prior successful GitHub Lean CI on unchanged old source; does not verify these new results |
| `MultiAgentAcquaintance.lean` (GitHub PR #270) | Finite third-party / order / Boolean causal-model witness | **Candidate until exact PR-head CI logs confirm Lean 4 compilation**; verifies only the definitions and propositions in that file |
| `tests/check_proposed_multiagent.py` (GitHub PR #270) | Executable finite witnesses and structural document cross-checks | Computational checks; not universal mathematical proofs |
| Psychological hypotheses | Real people and real relationships | **Unverified; require external longitudinal data** |

**Priority follow-up:** identify sufficient extra measurements for separating self-discovery from new preference formation; generalize MA-3 to temporal networks; derive bounds under measurement error; perform preregistered out-of-sample comparison against existing dyadic and network-coevolution models; and obtain independent mathematical/philological review.

## 8. Selected research, precursors and relevance

[R1] Eastwick et al. (2025), “A worldwide test of the predictive validity of ideal partner preference matching,” *Journal of Personality and Social Psychology* 128(1), 123–146. Registered report: 10,358 participants across 43 countries, 22 languages. DOI: https://doi.org/10.1037/pspp0000524. Preference matching effects should not be assumed universally strong.

[R2] Eastwick, Zhao & Zietsch (2026), “Mate preferences and the compatibility puzzle,” *Trends in Cognitive Sciences*. DOI: https://doi.org/10.1016/j.tics.2026.10.001. Recent review on the distinction between stated traits and developing relational experiences; theoretical synthesis rather than proof of this model.

[R3] Baxter et al. (2022), “Initial impressions of compatibility and mate value predict later dating and romantic interest,” *PNAS*. https://pubmed.ncbi.nlm.nih.gov/36322750/. Social Relations Model actor, partner and unique dyad effects; more than 6,600 speed dates.

[R4] Manski (1993), “Identification of endogenous social effects: the reflection problem,” *Review of Economic Studies* 60(3), 531–542. https://doi.org/10.2307/2298123. Peer associations do not immediately identify influence.

[R5] Shalizi & Thomas (2011), “Homophily and contagion are generically confounded in observational social network studies,” *Sociological Methods & Research* 40(2), 211–239. https://doi.org/10.1177/0049124111404820.

[R6] Snijders, van de Bunt & Steglich (2010), “Introduction to stochastic actor-based models for network dynamics,” *Social Networks*. https://doi.org/10.1016/j.socnet.2009.02.004. Network selection and network-behavior dynamics are prior art.

[R7] “Stability and change of individual differences in ideal partner preferences over 13 years,” *Personality and Social Psychology Bulletin* (2023). https://pubmed.ncbi.nlm.nih.gov/37029599/. Evidence for substantial stability as well as some change; caution against presuming constant flux.

[R8] “Steadfast standards or fluctuating fancies? Stability and change in people's mate criteria over 27 months,” (2018). https://pubmed.ncbi.nlm.nih.gov/30229702/. Stability and context-related changes.

[R9] L. A. Paul (2014), *Transformative Experience*, Oxford University Press. https://academic.oup.com/book/7934/1000. Philosophical context for preference formation and decisions that may change the chooser.

[R10] Longitudinal APIM systematic review, *Journal of Social and Personal Relationships* (2026). https://doi.org/10.1177/02654075261443593. Competing dynamic dyadic research is extensive and must be compared fairly.

## 9. Closing interpretation

A person can change while remaining the same person. A person's representation of another can change without the other person changing. An ideal can change because of experiences that never involved the person being evaluated. A relationship-specific state can vary with history and cannot always be compressed into a snapshot of isolated individual profiles. None of those possibilities explains any particular breakup on its own. Their mathematical role is to make visible which assumptions distinguish these explanations and which observations fail to do so.