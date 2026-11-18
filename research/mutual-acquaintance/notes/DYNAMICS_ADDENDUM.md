# A Dynamic Epistemic Model of Mutual Acquaintance
## Working formalization addendum v0.2 — 18 November 2026

**Status:** new Lean 4 source authored; kernel verification **pending**. This addendum extends the working draft conceptually, but it does not replace or change the philosophical *Tractatus* or the earlier, reportedly compiled core file.

### 1. Why this extension exists

The original mathematical working draft separates belief updating, preference change, and dyadic change, but its original Lean file is mostly a collection of small static models and Boolean witnesses. The current extension represents the entire *chronological process of interaction* as a deterministic transition system conditioned on a joint action and an external event.

The relevant source propositions are 1.12–1.22 (representations), 2.7 (decision-relative information), 3.23 (preference discovery versus change), 4.53 (experienced understanding versus accurate understanding), 5.31 (mutual choice), 6.63–6.64 (three simultaneous kinds of change), and especially 6.91–6.92 (not-yet-known versus not-yet-formed).

### 2. Model and update rule

A state is

\[
S_t=(x^A_t,x^B_t,b^A_t,b^B_t,q^A_t,q^B_t,r_t),
\]

where the components are **Boolean proxies**, not measurements of real people. Each encounter is \(e_t=(a^A_t,a^B_t,\xi_t)\), with two participant actions and an external input. There are two observation channels \(O_A(S_t,e_t)\), \(O_B(S_t,e_t)\), two belief-update maps \(L_A,L_B\), and other transition maps \(X_A,X_B,Q_A,Q_B,R\). The *simultaneous* transition is

\[
F_m(S,e)=\big(
X_A(S,e),X_B(S,e),
L_A(b^A,O_A(S,e)),L_B(b^B,O_B(S,e)),
Q_A(S,e),Q_B(S,e),R(S,e)
\big).
\]

**Timing convention:** all seven updated components use the same *pre-encounter* state. Thus one encounter can change a belief and a relationship at the same time, but the relational transition does not secretly read a post-update belief unless the chosen transition rule models that through its event input.

For a finite chronological history \(h=[e_0,\ldots,e_{n-1}]\), define

\[
\operatorname{Run}_m(S,[]) = S, \qquad
\operatorname{Run}_m(S,e::h)
  = \operatorname{Run}_m(F_m(S,e),h).
\]

This is a finite-state, discrete-time **deterministic conditioned-on-input** system. The full stochastic kernel \(T_t(\omega'\mid\omega,a)\) and normalized Bayesian posterior from the working draft are **not** yet formalized. The shock is an event variable with no probability distribution attached.

### 3. Abstract mathematical results

**D1. Chronological composition.** For all models \(m\), states \(S\), and histories \(h_1,h_2\),

\[
\operatorname{Run}_m(S,h_1 \mathbin{++} h_2)
=\operatorname{Run}_m(\operatorname{Run}_m(S,h_1),h_2).
\]

This ensures that incremental simulation and single-pass simulation agree. In Lean: `run_append`.

**D2. Observational update coherence.** If two situations have the same prior belief for one agent and yield the same observation to that agent, then that agent's *next modeled belief* is the same under the chosen update map. In Lean: `same_signal_same_next_beliefA`, `same_signal_same_next_beliefB`. This is an explicit property of the model interface, not a psychological prediction.

**D3. Stable traits as an assumption.** If the model's trait-transition maps are identity maps, then traits remain invariant over arbitrarily long histories. In Lean: `run_preserves_traitA`, `run_preserves_traitB`. The model itself does **not** require this assumption for all models.

**D4. Obstruction to profile-only prediction.** Write \(p(S)\) for the six individual components, excluding \(r\). If there are two admissible encounter histories from the same initial state such that

\[
p(\operatorname{Run}(S,h_1))=p(\operatorname{Run}(S,h_2)),\quad
r(\operatorname{Run}(S,h_1))\neq r(\operatorname{Run}(S,h_2)),
\]

then **there is no deterministic function** \(f\) of the current six-dimensional individual profile that correctly gives the relational state **for every history of that model**.

**Proof.** If such a function \(f\) existed, equality of the profiles would require \(f(p_1)=f(p_2)\). By the claimed correctness of \(f\), that would require \(r_1=r_2\), contradicting the assumed relational difference. The general proof appears as `no_profile_only_predictor`.

This is the central formal result of the extension. Its scope is sharply conditional: it neither shows that *every* relationship is history dependent nor rules out sufficiently rich state descriptions that retain history information.

### 4. Constructive, noncommuting example

Let \(S_0\) have all Boolean components false. Define a toy encounter called `listen` which sets A's belief to true without changing the relationship, and a jointly undertaken step `jointlyAct` which sets the relationship to A's **pre-encounter** belief.

The two schedules give:

| Schedule | Final belief A | Final belief B | Final preferences | Final relational bit |
|---|---:|---:|---|---:|
| listen → jointlyAct | true | false | both false | **true** |
| jointlyAct → listen | true | false | both false | **false** |

Both personal trait values remain false. Thus the complete six-component individual profile is identical, but the relational bit differs. The model exhibits an explicitly *order-sensitive interaction history*; a profile-only predictor is impossible for all reachable histories.

Lean declarations: `same_terminal_profile`, `different_terminal_relation`, `encounter_order_matters`, `toy_has_no_profile_only_predictor`.

This particular example encodes an invented relational transition. It demonstrates **mathematical possibility** and a failure of profile-only representation, not the prevalence of such dynamics among actual people.

### 5. Three kinds of change are separable

The same toy model provides three examples: a learning step that leaves the relationship unchanged; a relational change that leaves both modeled beliefs unchanged; and an external event changing A's operative preference without updating either belief or the relationship. This instantiates the distinction articulated in *Tractatus* 6.63–6.64.

Lean declarations: `learning_without_relational_change`, `relational_change_without_learning`, `preference_change_without_learning_or_relational_change`.

A separate countermodel assigns an adverse relational effect to active information gathering. It proves that gaining a modeled bit of knowledge can coexist with lower illustrative *total* value. This does not contradict the standard nonnegative value of **costless, passive** information in a **fixed** decision problem. The adverse effect is a **stipulated assumption** in the example.

### 6. What would actually be novel?

The above proof D4 is elementary mathematics; it becomes useful only if the class of interaction models, observation process, and available profiles are defined in a way that differentiates real theoretical or empirical alternatives. The work does **not** yet establish a new psychological law or a research-level theorem beyond existing multi-agent and dynamic decision theory.

The most promising next target would be a theorem about **identifiability of relational change from longitudinal dyadic observations** under transparent assumptions, ideally compared with a static trait-only model, followed by an empirical design capable of discriminating the models.

### 7. Verification boundary

The previous `MutualAcquaintance.lean` file has been reported as compiling on the user's Windows Lean 4.35.0 and 4.36.0 installations. Its copied SHA-256 is `63103d75b6b9927f68883dec3d8d98c23c6812bd6abfb98175f5e8bb0789ad53`.

The **new** `MutualAcquaintanceDynamics.lean` is **not yet Lean-kernel verified**: the authoring environment has no Lean executable and cannot download it. Independent Python finite checks confirm the constructive Boolean example and chronology on enumerated histories, but do not verify Lean syntax or proofs. See `README.md` and `verify.ps1` for exact local verification commands.