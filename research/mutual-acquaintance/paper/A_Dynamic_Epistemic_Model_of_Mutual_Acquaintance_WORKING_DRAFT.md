---
title: 'A Dynamic Epistemic Model of Mutual Acquaintance'
subtitle: 'Working draft: a mathematical reading of Tractatus de Perceptione et Amore'
author: 'Research working notes | interpretive and formal development'
date: '18 November 2026'
lang: en-US
fontsize: 10pt
geometry: 'top=22mm,bottom=22mm,left=23mm,right=23mm'
mainfont: 'Linux Libertine O'
sansfont: 'Carlito'
monofont: 'DejaVu Sans Mono'
colorlinks: true
linkcolor: 'MidnightBlue'
urlcolor: 'MidnightBlue'
header-includes:
  - '\usepackage{microtype}'
  - '\usepackage{fancyhdr}'
  - '\pagestyle{fancy}'
  - '\fancyhead[L]{\footnotesize Mutual Acquaintance | Working draft v0.2}'
  - '\fancyhead[R]{\footnotesize Interpretations and proof obligations}'
  - '\fancyfoot[C]{\thepage}'
  - '\setlength{\headheight}{14pt}'
---

> **WORKING DRAFT v0.2 | 18 November 2026 | Not submitted, not peer reviewed**  
> **Purpose:** interpret the numbered propositions of *Tractatus de Perceptione et Amore* through a dynamic two-person mathematical model.  
> **Source:** the latest Indonesian philosophical edition, including 6.91, 6.92, and its single concluding proposition 7.  
> **Evidence standard:** a derivation proves only what its definitions and assumptions entail. An illustrative model does not validate a psychological law.  
> **Verification status:** selected finite results have companion Lean proofs. The [research audit](../RESEARCH_AUDIT.md) records precisely which statements were checked and gives reproducible CI evidence.

# Working abstract (provisional)

Two people who become acquainted do not merely estimate a fixed pair of hidden personalities. Each constructs a fallible representation of the other, notices and interprets evidence differently, may discover or change personal preferences, and participates in encounters that affect the relation being considered. This working draft reads the seven principal propositions of *Tractatus de Perceptione et Amore* as an ordered set of modeling questions. A finite-state, two-agent stochastic system separates (i) epistemic updating, (ii) preference discovery or change, and (iii) constitutive changes in a dyadic state. We derive elementary results about asymmetric learning, observational equivalence, decision-specific sufficiency, active versus passive information, dependence on shared history, and the underdetermination of unchosen alternatives. For a one-step binary relational outcome, we also derive sharp partial-identification bounds under an invariant but uncalibrated report channel and give explicit alternative mechanisms for the same observed contrast. The results are conditional interpretations and counterexamples. The eventual research contribution, if there is one, must be established by comparing this architecture with dynamic epistemic logic, interactive POMDPs, decision theory, and interpersonal relationship models. It cannot be established by restating the *Tractatus* in symbols.

# How to read this draft

Each of Sections 1–7 follows a principal proposition in the literary work. Within each section:

- **Source proposition** identifies a numbered statement, quoted briefly or closely paraphrased from the Indonesian edition.
- **Interpretation** states what a mathematical model would need to represent, without pretending that the literary sentence is itself an empirical law.
- **Formal candidate** proposes a definition, lemma, theorem, or counterexample.
- **Proof / status** distinguishes a complete finite argument from an unproved conjecture or a merely constitutive definition.
- **Open work** records what must be resolved before any journal submission.

This numbering is an *interpretive crosswalk*, not a renumbering or replacement of the original *Tractatus*. The underlying philosophy remains an independent literary work. The English translations of short source statements are interpretive glosses of the Indonesian primary text, not quotations from Wittgenstein.

| Source in *Tractatus* | Question for a model | Main result or status in this draft |
|:--|:--|:--|
| 1, 1.12, 1.2, 1.22, 1.52 | How can a person differ from a representation, and how can confidence differ from accuracy? | Belief–state distinction; counterexample (C1) |
| 2.21, 2.61, 2.7 | When is evidence informative, and when is knowledge sufficient? | Non-identification (T2); decision sufficiency (T3) |
| 3.23, 3.3 | Is a preference discovered or newly formed? | Observational-equivalence example (C2) |
| 4.3, 4.53, 4.61–4.62 | Does a perceived response identify an intended meaning? | Signaling model; inference limitation (C3) |
| 5.3–5.33, 5.61 | What conditions allow a joint choice? | Necessary willingness condition (D1); bounds (T4) |
| 6.41–6.43, 6.63–6.64, 6.91–6.92 | Can encounters create a state, not just reveal one? Can unrealized possibilities be identified? | Active information counterexample (C4); history dependence (C5); counterfactual non-identification (C6) |
| 7 | What remains outside the scope of a mathematical description? | Boundary of interpretation; no proposed theorem of ineffability |

# 0. Modeling contract: what exists, what is observed, what changes

## 0.1. The agents are two persons, not one optimizing observer

Let $i\in\{A,B\}$ and $t=0,1,\ldots,T$. Let all model spaces be finite in the first version. For each time $t$, set

$$
\omega_t=(x_{A,t},x_{B,t},q_{A,t},q_{B,t},r_t,c_t)\in\Omega.
\tag{M1}
$$

Here $x_i$ represents modeled dispositions and circumstances of person $i$; $q_i$ their *operative* preferences; $r_t$ the history-dependent relational state; and $c_t$ the context. The dyadic state $r_t$ may be a vector that records what each participant experiences as well as a joint coordination component. No equality of the two perspectives is assumed. The variables are abstractions, not measurable souls or moral values.

The private history $h^i_t$ may include observed acts, utterances, private memories, prior context, and imperfect reports about one's own preferences. A belief state is

$$
\pi^i_t(\omega)=\Pr(\omega_t=\omega\mid h^i_t).
\tag{M2}
$$

A joint action $a_t=(a^A_t,a^B_t)$ belongs to an admissible action set. The physical and relational transition follows a stochastic kernel

$$
T_t(\omega'\mid\omega,a)=\Pr(\omega_{t+1}=\omega'\mid\omega_t=\omega,a_t=a),
\tag{M3}
$$

and the participants receive observations with joint kernel

$$
O_t(y_A,y_B\mid\omega',a).
\tag{M4}
$$

The observation law may be correlated across participants, asymmetric, or selectively informative. A public meeting does **not** imply identical effective information. The action $a_t$ may itself be informative; an agent who observes the other person's choice may condition on that choice before updating with $y_i$.

## 0.2. Three distinct processes

A useful decomposition is

$$
\underbrace{\pi^i_t\longrightarrow\pi^i_{t+1}}_{\text{belief update}},\qquad
\underbrace{q_{i,t}\longrightarrow q_{i,t+1}}_{\text{preference change}},\qquad
\underbrace{r_t\longrightarrow r_{t+1}}_{\text{relational change}}.
\tag{M5}
$$

The three arrows can occur in one conversation, but no arrow logically entails another. **Preference discovery** is not identical to preference change: a changed *report* of $q_i$, or a change in the agent's belief about their own $q_i$, can occur with the underlying modeled $q_i$ held fixed.

This is a representational separation. A future empirical model must explain how, and whether, these latent changes could be identified in real observations.

## 0.3. Conditional updating, not psychological mind reading

For a known joint action $a$ and agent-specific, action-conditioned distribution $\pi^{i,a}_t$, prediction and correction can be written

$$
\bar\pi^i_{t+1}(\omega')=\sum_\omega T_t(\omega'\mid\omega,a)\pi^{i,a}_t(\omega),
\tag{M6}
$$

$$
\pi^i_{t+1}(\omega')=
\frac{O^i_t(y_i\mid\omega',a)\bar\pi^i_{t+1}(\omega')}
{\sum_v O^i_t(y_i\mid v,a)\bar\pi^i_{t+1}(v)},
\tag{M7}
$$

when the denominator is positive and the kernels satisfy the conditional independence assumptions relative to the agent’s history: given the current state and action, the next state is independent of that history, and given the next state and action, the observation is independent of that history. If the other person's action is partly hidden, it must be marginalized under an explicit policy model. Neither formula claims that people actually compute Bayes' rule.

# 1. A person is not a representation of that person

**Source propositions:** 1; 1.12–1.2; 1.22; 1.31; 1.52. The *Tractatus* separates A from B's picture $P_B(A)$, then separates sincerity of feeling from accuracy of knowledge.

## 1.1. Interpretation

The representation $P_B(A)$ is better modeled as $\pi^B_t$, or as a posterior over *A-relevant components* of $\omega_t$, than as a complete description of A. Inference targets also need specification: behavior in a familiar setting, future behavior in a new setting, a reported preference, and an intention behind one utterance are different targets.

The model does not infer that every judgment is wrong, or that no one knows another person directly. It claims only that **a representation and its target have different logical roles**. Whether a particular representation is accurate is an empirical question.

## 1.2. Formal candidate C1: shared signal, unequal learning

Let $\Theta,K$ be independent fair bits. Both people observe $Y=\Theta\oplus K$. A privately knows $K$ and B does not. Then

$$
H(\Theta\mid Y,K)=0,\qquad H(\Theta\mid Y)=1\ \mathrm{bit}.
\tag{1.1}
$$

**Proof.** Given $K$ and $Y$, A recovers $\Theta=Y\oplus K$. For B, each possible $\Theta$ makes either value of $Y$ equally likely because the unobserved key is fair. Thus $Y$ and $\Theta$ are independent; B's posterior remains uniform. $\square$

**Interpretation.** This is one logical way to realize 1.4 and 6.51: an apparently identical event can teach the participants different things. It is *not* evidence that one person's emotional interpretation of an actual event is superior.

## 1.3. Confidence versus accuracy [OPEN]

A distribution $\pi$ has a measure of concentration, for example $1-H(\pi)/\log |\Omega|$. Actual accuracy instead concerns a loss $L(\hat\theta,\theta)$ evaluated against the realized truth. Increasing concentration need not decrease loss for a particular individual history. A finite counterexample is straightforward: an observer becomes certain of the wrong binary state after misleading evidence.

**Open work:** distinguish subjective confidence from calibrated Bayesian probabilities; identify whether this section needs a separate theorem or just an explicit example. Do not equate feeling sincere, holding a sharp posterior, and being correct.

# 2. What is known, supposed, and sufficient for a decision

**Source propositions:** 2.21; 2.22; 2.31; 2.61–2.62; 2.7–2.71. The *Tractatus* distinguishes a possible explanation from a known explanation and makes sufficiency relative to the choice considered.

## 2.1. An inference target must be identifiable under the evidence available

Two hypotheses can be different yet produce identical observations in one context. Define $H_n$ to be the full observed history after $n$ encounters, including context and the policy under which observations are collected.

### Theorem T2: repetition need not identify

Assume two hypotheses $\theta_0,\theta_1$ have positive priors and, under the policy actually used,

$$
\Pr(H_n=h\mid\theta_0)=\Pr(H_n=h\mid\theta_1)
\quad\text{for all }n\text{ and }h.
\tag{2.1}
$$

Then for every history with positive common likelihood,

$$
\frac{\Pr(\theta_0\mid H_n=h)}{\Pr(\theta_1\mid H_n=h)}
=\frac{\Pr(\theta_0)}{\Pr(\theta_1)}.
\tag{2.2}
$$

**Proof.** Bayes' rule multiplies prior odds by the ratio of the two history likelihoods. Equation (2.1) makes that ratio one. $\square$

**Restriction that matters.** Identical *one-encounter marginal distributions* are not enough for this theorem if histories differ in their correlations. The assumption must concern the **full law of observed histories**, including sequential effects and information conveyed by actions. Repeating a context may be informative in some models and uninformative in others.

**Source reading:** 2.61 does not imply that repeated observation is useless. It says that observations in one circumstance need not resolve a question about another circumstance.

## 2.2. Decision-relative sufficiency, not omniscience

Let $p(\omega\mid h)$ be an agent's current posterior; $D(h)$ is the finite set of **that agent's feasible decisions**, and $U(d,\omega)$ is a fixed utility mapping for a particular decision problem. Assume $D(h)$ is nonempty and $h$ has positive probability. Define expected value of perfect information

$$
\operatorname{EVPI}(h)=
\sum_\omega p(\omega\mid h)\max_{d\in D(h)}U(d,\omega)
-\max_{d\in D(h)}\sum_\omega p(\omega\mid h)U(d,\omega).
\tag{2.3}
$$

A *candidate definition* is that information at $h$ is $\varepsilon$-sufficient for **this decision problem** when $\operatorname{EVPI}(h)\le\varepsilon$. This is not a definition of knowing a human being 'enough' in any universal or moral sense.

### Theorem T3: perfect identification is unnecessary

For the finite fixed-utility problem in (2.3), $\operatorname{EVPI}(h)=0$ **if and only if** one feasible action $d^*$ is optimal in every state having positive posterior probability, allowing ties.

**Proof.** Choose $d_0$ that maximizes posterior expected utility. For each state let $\delta(\omega)=\max_d U(d,\omega)-U(d_0,\omega)\ge0$. Its posterior expectation equals $\operatorname{EVPI}(h)$. A nonnegative finite weighted sum is zero exactly when each positive-weight summand is zero. This is the common-optimal-action condition. Conversely, a common-optimal action makes the two terms in (2.3) equal. $\square$

**Example.** Suppose the hidden state is either $\omega_0$ or $\omega_1$ with equal probabilities, yet decision $d_0$ yields utility 2 in both and the only alternative yields at most 1. The agent remains uncertain about the state, while $\operatorname{EVPI}=0$. Full knowledge is unnecessary for selecting $d_0$.

**Open work:** in the literary proposition 2.7 the relevance is explicitly to a contemplated choice. A full dynamic decision model may change its options and utilities during acquaintance, so the static $\operatorname{EVPI}$ is only a local approximation.

# 3. The desired person, the perceived person, and changing preferences

**Source propositions:** 3.1; 3.22–3.23; 3.3–3.31; 3.6. A's preferences $I_A$ are not a person, B's picture of A is not A, and discovery of a preference is conceptually different from formation of a new preference.

## 3.1. Two latent variables, one visible report

Let $q_{i,t}$ be an operative preference, $\rho^i_t$ an agent's beliefs about their own preference, and $\hat q_{i,t}$ their report. The report may depend on both their self-belief and the context $e_t$:

$$
\hat q_{i,t}=g(q_{i,t},\rho^i_t,e_t,\eta_t).
\tag{3.1}
$$

A changed $\hat q$ may result from actual preference formation ($q$ changes), preference discovery ($\rho$ changes while $q$ remains fixed), or a change in how a fixed preference is expressed. Distinguishing these possibilities is an *identification problem*, not a claim that reports are insincere.

## 3.2. Counterexample C2: change versus altered report

Let $\hat q_t=q_t\oplus e_t$ for $t=0,1$ with binary variables. Consider:

| Model | $q_0,q_1$ | $e_0,e_1$ | observed $\hat q_0,\hat q_1$ |
|:--|:--:|:--:|:--:|
| F, preference formation | $0,1$ | $0,0$ | $0,1$ |
| R, reporting/context shift | $0,0$ | $0,1$ | $0,1$ |

**Proof.** The identical observed pair follows by substituting into the XOR equation. One model changes the operative preference and the other does not. No statistic based only on this report history distinguishes them. If $e_t$ is also recorded and the XOR reporting rule is known, $q_t$ is recovered directly. This witness uses a context shift, so it does not by itself show equivalence between preference formation and discovery. For that comparison, hold context fixed and use the reporting rule $\hat q_t=\rho_t$. Both a fixed $q=(1,1)$ with a newly accurate self-belief $\rho=(0,1)$ and a changing $q=(0,1)$ with the same self-belief path produce the same reports. $\square$

**Interpretation:** 3.23 survives as a conceptual distinction; a claim about a real person's preference formation requires more observations, assumptions, or study design.

## 3.3. The compatibility question [OPEN]

Define a pair-specific, experienced evaluation $v^i_t$ to depend on the current relation and history, not solely on a person's trait list:

$$
v^i_t=V_i(\pi^i_t,q_{i,t},r_t,h^i_t).
\tag{3.2}
$$

**Question:** Which features of $V_i$ can be estimated apart from actor effects, partner effects, and relationship-specific effects? Baxter et al. (2022) demonstrate the practical importance of that partition in a speed-dating design. The 2026 *compatibility puzzle* review suggests additional routes through shared experiences. Neither source identifies this proposed function $V_i$.

**Do not prove:** 'Matching an ideal is sufficient for attraction.' The *Tractatus* explicitly distinguishes similarity to an ideal, attraction, and willingness.

# 4. What is said, intended, perceived, and understood

**Source propositions:** 4; 4.3; 4.51–4.53; 4.61–4.62; 4.7. Speech and silence are actions and observations, not transparent containers of a private mind.

## 4.1. A signal is not an intention

Let $m^i_t$ be a communicative intention, $u^i_t$ an utterance or action, $y^j_t$ what the other person perceives, and $\hat m^j_t$ what the listener infers. A minimal model is

$$
\Pr(u^i_t\mid m^i_t,h^i_t,c_t),\qquad
\Pr(y^j_t\mid u^i_t,c_t),\qquad
\hat m^j_t=\delta_j(h^j_t,y^j_t).
\tag{4.1}
$$

It allows honest but underspecified expression, errors of attention, and multiple interpretations. **It does not declare that intentions are always unobservable**, only that accurate inference requires more conditions than observing an isolated behavior.

## 4.2. Counterexample C3: equal observation, different intentions

Let $m\in\{0,1\}$ be an intention and let $y=0$ regardless of $m$ under one setting. Both hypotheses produce the same observation. Consequently the observation alone leaves the posterior over $m$ equal to the prior. This realizes the caution about 4.61–4.62: silence or a single unchanged response need not uniquely identify private meaning.

**Proof.** $\Pr(y=0\mid m=0)=\Pr(y=0\mid m=1)=1$, so Bayes' rule leaves the prior odds unchanged. $\square$

The example is deliberately trivial. A richer model must allow direct statements, conversations, context, and repeated observations to improve accuracy. Its purpose is to refute *automatic inference*, not to suggest permanent unknowability.

## 4.3. Felt understanding is not measured inferential accuracy [OPEN]

Introduce two outcome variables:

- $f^i_t$: the participant's **reported feeling of being understood**;
- $\ell^i_t=L(\hat m^j_t,m^i_t)$: an **accuracy loss** against a specified ground-truth criterion, when such a criterion is available.

The two measures are different by definition. One might be low and the other high, or vice versa. But **their empirical joint distribution is not determined by the distinction**. Work on perceived responsiveness is relevant here, but should not be substituted for a direct accuracy measure.

**Open work:** specify what counts as a valid criterion for another person's intention or preference, including uncertainty in self-reports. Study how different measures covary before stating any general relationship.

# 5. Two people who choose: the limits of unilateral optimization

**Source propositions:** 5; 5.3–5.33; 5.5; 5.61. The *Tractatus* describes an outcome that depends on both people without claiming a single central utility function can choose for both.

## 5.1. Joint willingness is necessary by definition, not a scientific discovery

For a specific shared step $s$ at time $t$, let $W_i(s,t)\in\{0,1\}$ mean participant $i$ is willing to take it. If $J(s,t)=1$ represents a step *freely undertaken together*, then

$$
J(s,t)=1\ \Longrightarrow\ W_A(s,t)=1\ \land\ W_B(s,t)=1.
\tag{5.1}
$$

**Status D1: constitutive definition.** Equation (5.1) states a condition included in the meaning of a freely joint action. It is not a derived prediction that actual people will make a particular choice. It should not be advertised as a novel mathematical theorem.

## 5.2. Theorem T4: dependent willingness bounds

If $p_A=\Pr(W_A=1)$ and $p_B=\Pr(W_B=1)$, then

$$
\max(0,p_A+p_B-1)\le\Pr(W_A=1,W_B=1)\le\min(p_A,p_B).
\tag{5.2}
$$

**Proof.** The event $\{W_A=W_B=1\}$ is a subset of each one-person willingness event, giving the upper bound. Also
$\Pr(W_A=1\ \text{or}\ W_B=1)=p_A+p_B-\Pr(W_A=W_B=1)\le1$,
giving the lower bound, together with nonnegativity. $\square$

**Interpretation:** even with marginal estimates, a product $p_Ap_B$ would require an additional independence assumption. These are generic probability bounds, not a model of anyone's feelings.

## 5.3. Sufficient private information is not sufficient joint willingness

**Counterexample:** both participants know their own preferences perfectly; A is willing to undertake $s$ and B is not. Each has no information uncertainty about that fact. The joint outcome still cannot be freely taken under (5.1). Thus **decision sufficiency for one party** (Section 2) should not be equated with **realization of a mutual outcome**.

**Open work:** formulate stable mutually feasible choices when each person may revise preferences and beliefs between meetings. A fully strategic model would need policies and higher-order beliefs; the present draft does not pretend to have solved a dynamic equilibrium.

# 6. What an encounter reveals, and what it brings into being

**Source propositions:** 6.41–6.43; 6.51; 6.61–6.64; 6.91–6.92. This is the draft's principal architectural claim. The same encounter may improve an estimate, disclose a preference, and change the relational state. The second and third changes are not reducible to observation alone.

## 6.1. Passive information has nonnegative *decision value* under restricted assumptions

Suppose $\omega$ is fixed, an agent chooses among finite $D$, the signal $Z$ is costless, the agent may ignore it, and $U(d,\omega)$ is unchanged by its receipt. Assume finite state and signal spaces and a nonempty decision set. Set

$$
V_0=\max_{d\in D}\sum_\omega p(\omega)U(d,\omega),\quad
V_Z=\sum_z\max_{d\in D}\sum_\omega p(\omega,z)U(d,\omega).
\tag{6.1}
$$

### Theorem T5: value of costless passive information

$V_Z\ge V_0$. Equality holds exactly when there is a single action that is conditionally optimal for each positive-probability signal value, allowing ties.

**Proof.** Let $d_0$ maximize $V_0$. For each $z$, the maximum in $V_Z$ is at least the value of $d_0$. Summing gives $V_Z\ge V_0$. If equality holds, the nonnegative gap for every positive-probability $z$ must vanish. Hence $d_0$ is optimal conditional on every such $z$. Conversely, a common conditionally optimal action is optimal before the signal, and the gap is zero. $\square$

**Warning:** this is a theorem about *passive observations*. It does not say that every consequential conversation is worthwhile, harmless, or preferable to silence.

## 6.2. Counterexample C4: an active information-gathering encounter can change the object of evaluation

Let an unknown fair bit $\Theta$ be guessed after an encounter. A correct guess pays 1 and an incorrect guess pays 0. Let a nonnegative relational index $r$ add value $\lambda r$ at the end, where $\lambda>1/2$. Initially $r=1$.

- **Quiet option:** no new information, but $r$ stays 1. Best expected total is $\tfrac12+\lambda$.
- **Active probe:** the encounter reveals $\Theta$ perfectly, but by assumption sets $r=0$. Best total is $1$.

Then

$$
V_{\mathrm{probe}}-V_{\mathrm{quiet}}=\tfrac12-\lambda<0.
\tag{6.2}
$$

**Proof.** The guess is correct with probability $1/2$ under the quiet option and with probability one under the probe. Add the specified terminal relational payoffs. $\square$

The labels are invented choices in an abstract countermodel, **not advice about questioning another person**. The negative relational effect is *assumed*, not observed. The logical target is the invalid move from 'information can improve a fixed decision problem' to 'active information acquisition always improves a changing relationship'.

## 6.3. Counterexample C5: dyadic state is not a function of trait lists alone

Hold both personal trait vectors fixed at $x_A=x_B=0$. Begin with $r_0=0$. Let one feasible history of mutually undertaken interaction yield $r_1=1$, while another history yields $r_1=0$. The trait pair is identical in both cases, but the current relational states differ.

**Proof.** A proposed universal function $g(x_A,x_B)$ would assign one value to $g(0,0)$, yet the admissible histories require both 0 and 1. Contradiction. $\square$

**Reading of 6.92:** one may lack information about an existing feature, or the shared history may genuinely change a relational feature. These are distinct reasons why the future cannot be known simply from a list of individual traits.

### Exact recovery and prediction error

Fix the admissible run set and let $S(h)$ denote the summary available to a predictor, such as an individual profile or one participant’s observed history. Let $R(h)$ be the Boolean relational target. An exact predictor from $S$ exists if and only if $R$ is constant among runs sharing each reachable value of $S$. Necessity follows by applying the predictor to equal inputs. For sufficiency, assign each reachable summary its unique target and give unreachable summaries an arbitrary value. This is an elementary factorization criterion. It applies even when histories are absent from the terminal state description.

For a finite distribution of runs and zero-one loss, the minimum prediction error given $S$ is

$$
\sum_s \min\{\Pr(S=s,R=0),\Pr(S=s,R=1)\}.
$$

On each summary, choosing 0 incurs the mass with target 1, and choosing 1 incurs the mass with target 0. The choices can be minimized separately. For the two reversed histories in the Lean toy model, if only these histories have mass and their probabilities are $p$ and $1-p$, the exact minimum error from their common terminal profile is $\min(p,1-p)$. A predictor who observes which of the two histories occurred has zero error in that model. This is a standard binary classification risk applied to a model witness. The probabilities would require independent justification in any empirical application.

Population identification concerns a different question: whether two admissible mechanisms yield the same observable-data law while giving different values for the specified estimand. A profile collision in a single specified model does not establish such observational equivalence between mechanisms. It also does not rule out calibrated probabilistic profile predictions.

## 6.4. Counterexample C6: the unchosen possibility is not identified by the chosen history alone

Consider models M and N. Both yield the same observed outcome $r_1=0$ under the actual action $a_0$. Under an action $a_1$ never taken, M yields $r_1=1$ while N yields $r_1=0$.

**Proof.** Both models agree on every available observation under $a_0$, so actual data alone cannot distinguish them. Their counterfactual $a_1$ outcomes differ, so the counterfactual is not identified by that actual history alone. $\square$

**Reading of 6.41–6.43:** imagining a favorable alternative does not identify what would have happened. This does **not** show that counterfactuals are unknowable in general: additional structural assumptions or randomized comparisons may identify or bound some alternatives.

## 6.5. What follows from an observed report difference

It is easy to write separate parameters for belief change, preference change, and relational change. It is much harder to estimate them from observed conversation histories because:

1. participants choose whether, when, and how to interact;
2. these choices themselves reveal information and affect future opportunities;
3. the same report may reflect preference formation, discovery, or reporting change;
4. participants' memories and self-reports have their own uncertainty;
5. dyad-specific history and context can confound apparent effects.

### A bounded identification result

Consider a specified binary relational state at a fixed follow-up. Two policies start with the same prevalence $p$ of the true state. The stable policy leaves it unchanged, while the accepted encounter can move a mass $m$ from false to true, with $0\le m\le 1-p$. Both policies use a common measurement channel whose rates for positive reports in the false and true states are $c_0$ and $c_1$. If $q=c_1-c_0$, the passive and active report probabilities are $y_0=c_0+pq$ and $y_1=c_0+(p+m)q$. Their difference is $\Delta=mq$. A nonzero calibrated $q$ gives $m=\Delta/q$.

Suppose instead that $0<p<1$ is known, $\Delta>0$, and the channel is invariant and positively oriented but uncalibrated. The feasible contrast has upper bound $q_{\max}=\min(y_0/p,(1-y_0)/(1-p))$. For compatible data the sharp set is

$$
\frac{\Delta}{q_{\max}}\le m\le 1-p.
$$

The lower bound follows from the two probability restrictions $c_0\ge 0$ and $c_1\le 1$. The upper bound is the available false mass. For every candidate in the interval, take $q=\Delta/m$, $c_0=y_0-pq$ and $c_1=y_0+(1-p)q$. These rates satisfy the channel constraints and reproduce the two observations. The companion Lean development verifies the cross-multiplied bounds and constructs a channel for feasible rational inputs.

For $p=1/4$ and observed positive-report probabilities $3/8$ and $5/8$, the sharp interval is $[3/10,3/4]$. If the policy can change the reporting channel, or if the groups can start with different latent distributions, even zero latent movement can reproduce the two report probabilities. The [sensitivity note](../notes/IDENTIFICATION_SENSITIVITY.md) gives explicit machine-checked witnesses. If transitions can occur in both directions, the invariant calibrated contrast identifies the net prevalence change, while opposing transitions can cancel.

### From a model contrast to a study

A randomized voluntary offer can identify an effect of assignment on observed reports when the study design and follow-up support that inference. The effect of taking up the offer and the effect on a latent relational outcome are distinct estimands. Existing relational state can influence both participants' willingness and the subsequent outcome. An offer can also influence what participants report. These paths require separate assumptions and measurement evidence. This finite model supplies an estimand, conditions for a partial-identification result, and concrete ways those conditions can fail. It leaves causal identification from actual encounters open.

# 7. What a mathematical interpretation can say, and what it cannot

**Source proposition:** 7. In the revised *Tractatus*, the closing proposition says, in effect: as people become acquainted, some things become visible, some things are newly formed, and some remain unknown; not all shared experience is exhausted by words.

## 7.1. Interpretation rather than a theorem of ineffability

A formal model can say *which distinctions are represented, which conclusions follow from assumptions, and where observations fail to identify an unknown*. It cannot infer from such failures that a person's experience is **in principle** unsayable, that another mind is forever inaccessible, or that a mathematical relation captures the whole meaning of knowing someone.

This point matters because the **saying/showing** distinction in Wittgenstein's *Tractatus Logico-Philosophicus* chiefly concerns logical representation and the limits of propositional expression. The literary *Tractatus de Perceptione et Amore* develops an analogy about interpersonal experience. That analogy should remain an analogy; it is not an established theorem in Wittgenstein scholarship.

## 7.2. A deliberately modest closing claim

**Working interpretation of proposition 7:** the model is itself a representation of possibilities. It should not be mistaken for the people or experiences it represents. A finite model can distinguish **not-yet-known** from **not-yet-formed**. It cannot decide how any particular two people ought to relate to one another, nor can it establish whether an individual experience has been fully conveyed by a particular description.

**No theorem is proposed for this section.** This is a boundary statement about the model's scope, not a mathematical proposition pretending to prove something ineffable.

# 8. Proof ledger and interpretive status

| ID | Main source | Formal claim | Status in this draft | What the result does not prove |
|:--|:--|:--|:--|:--|
| C1 | 1.4, 6.51 | Unequal learning from a shared signal | **Proof written**; finite XOR construction | Actual psychological asymmetry in a pair |
| T2 | 2.61 | Equal full history laws imply unchanged posterior odds | **Proof written** | Repetition is always uninformative |
| T3 | 2.7 | $\mathrm{EVPI}=0$ iff a common feasible action is optimal on posterior support | **Proof written** | A universal threshold for relationship readiness |
| C2 | 3.23 | Preference change and report change can look identical | **Counterexample written** | Self-reports are inherently false |
| C3 | 4.61 | One silent observation may not identify a hidden intention | **Counterexample written** | Mental states cannot be known |
| D1 | 5.3 | Jointly voluntary action entails willingness of both | **Definition**, not an empirical theorem | A prediction of any individual's choice |
| T4 | 5.3 | Dependence bounds for two willingness indicators | **Proof written**; classical inequality | Independence of two people |
| T5 | 6.63 | Passive costless information has nonnegative value under fixed utilities | **Proof written** | A conversation is always beneficial |
| C4 | 6.92 | Active information can have negative total value | **Counterexample written** | Actual questions reduce closeness |
| C5 | 6.92 | Dyad state may depend on history beyond trait pair | **Counterexample written** | Real relations follow the chosen transition rule |
| C6 | 6.41–6.43 | Observed path alone cannot fix unchosen counterfactual | **Counterexample written** | All counterfactuals are unknowable |
| I1 | 6.92 | Sharp bounds and observational alternatives for one binary encounter | Cross-multiplied bounds and rational channel construction checked in Lean | Identification from self-selected groups or changing measurement |
| 7 | 7 | Limits of what model entails | **Interpretation only** | Any theorem of unsayability |

**Important:** 'proof written' means a traditional mathematical derivation is supplied under explicit assumptions. This label does not mean Lean checked, published, peer reviewed, or empirically confirmed. A proof may still require revision after independent mathematical scrutiny.

# 9. What is genuinely open in the project?

## 9.1. Formal questions

**F1. The distinction between discovery and change.** What minimal extra observations, instruments, or interventions distinguish a fixed preference poorly known to its holder from an evolving preference? Is identification possible without constraining the reporting channel?

**F2. Reciprocal information value.** Define a version of value of information when two agents have different information histories, different utility functions, and a shared feasible set. Under what assumptions can an information-generating encounter be individually valuable to both, to only one, or to neither?

**F3. Self-knowledge and model reflexivity.** If each agent is uncertain about their own preferences and also about the other's beliefs, which levels of recursive belief are necessary to explain a concrete task? An infinite hierarchy should not be adopted by default.

**F4. Choice when the target evolves.** Formalize a local notion of decision sufficiency when the next action changes $r_t$ and $q_t$. Can a meaningful regret criterion avoid treating a future, transformed person's preferences as fixed at the present time?

**F5. Identifiability under changing contexts.** Find conditions under which encounters across diverse contexts identify an individual disposition, while accounting for the fact that context itself may alter behavior and relation.

**F6. Non-commutativity.** Construct and analyze conditions when 'observe then intervene' and 'intervene then observe' induce different beliefs and relational states. This could become an interpretively useful new theorem if the algebra yields more than a trivial restatement of transitions.

## 9.2. Philosophical questions

**P1.** Does the literary distinction between a person and a perceived person require indirect representationalism, or is it compatible with direct interpersonal knowledge in some circumstances?

**P2.** Does the concept of a 'relationship-specific state' explain something irreducible to individual traits, or merely offer a convenient summary of interaction history? The counterexample establishes that a trait-only function need not exist, not that all reductive models are impossible.

**P3.** Which evaluative claims concern the possibility of a relationship and which concern a person's worth? The mathematical model must not smuggle moral standing into the objective function.

**P4.** Which uses of Wittgenstein's *showing* are legitimate structural analogies, and which risk confusing phenomenological experience with logical form?

## 9.3. Empirical questions

**E1.** What longitudinal data could separately measure an individual's self-report, externally measured behavior across contexts, felt understanding, and pair-specific interaction history?

**E2.** How do culture, communication medium, and existing familiarity change the observation process? Generalizing from speed dating or diary studies would require new samples and measures.

**E3.** What observed outcomes would distinguish this framework from a standard actor–partner interdependence model or Social Relations Model? Without discriminating predictions, the framework is a reorganization of existing ideas, not a novel scientific theory.

# 10. Next iteration plan

1. **Verify mathematical details:** independent proof review of T2–T5, especially equality conditions and the roles of action-conditioned priors, dynamic utilities, and feasibility.
2. **Tighten the reference architecture:** choose either a probability-first finite-state model or a Kripke/action-model-first interpretation; explain the bridge rather than conflating them.
3. **Formalize a bounded core:** translate exact finite combinatorial statements and the willingness bounds to Lean 4; use an original Lean compiler run and preserve the command, version, and output before claiming kernel verification.
4. **Add one nontrivial model comparison:** show a case where a static actor–partner model and a history-dependent model generate different predictions under a specified intervention.
5. **Keep the original work intact:** publish this as an interpretive mathematical companion, not as a rewrite of the philosophical seven-chapter *Tractatus*.

# Reference notes (selected, verified identifiers)

The bibliography is a **working comparison list**. Citations here identify relevant prior literature; they do not certify the new model or establish the originality of its claims.

1. *Tractatus de Perceptione et Amore*. Latest Indonesian literary edition, 18 November 2026. Primary source for all proposition numbers used here; author-provided unpublished manuscript.
2. Wittgenstein, L. (1922). *Tractatus Logico-Philosophicus*, propositions 4.1212, 6.54, 7. Text: <https://wittgensteinproject.org/w/index.php/Tractatus_Logico-Philosophicus_%28English%29>.
3. Stanford Encyclopedia of Philosophy. *Dynamic Epistemic Logic*. <https://plato.stanford.edu/entries/dynamic-epistemic/>.
4. Gmytrasiewicz, P. J., & Doshi, P. (2005). A framework for sequential planning in multi-agent settings. *Journal of Artificial Intelligence Research, 24*, 49–79. <https://doi.org/10.1613/JAIR.1579>.
5. Kenny, D. A. (2019). *Interpersonal Perception: The Foundation of Social Relationships*, 2nd ed. Guilford Press. <https://davidakenny.net/ip/interp.htm>.
6. Laurenceau, J.-P., Barrett, L. F., & Pietromonaco, P. R. (1998). Intimacy as an interpersonal process. *Journal of Personality and Social Psychology, 74*, 1238–1251. <https://doi.org/10.1037/0022-3514.74.5.1238>.
7. Baxter, A. et al. (2022). Initial impressions of compatibility and mate value predict later dating and romantic interest. *PNAS, 119*, e2206925119. <https://doi.org/10.1073/pnas.2206925119>.
8. Eastwick, P. W., Zhao, A. A. Z., & Zietsch, B. P. (2026). Mate preferences and the compatibility puzzle. *Trends in Cognitive Sciences*, advance online publication. <https://doi.org/10.1016/j.tics.2026.10.001>.
9. Paul, L. A. (2014). *Transformative Experience*. Oxford University Press. <https://doi.org/10.1093/acprof:oso/9780198717959.001.0001>.
10. Howard, R. A. (1966). Information value theory. *IEEE Transactions on Systems Science and Cybernetics, 2*, 22–26. <https://doi.org/10.1109/TSSC.1966.300074>.
11. Blackwell, D. (1953). Equivalent Comparisons of Experiments. *Annals of Mathematical Statistics, 24*, 265–272. <https://doi.org/10.1214/aoms/1177729032>.

# Editorial change log

- **v0.1, 18 November 2026:** reorganized the earlier conventional 11-page research manuscript into a seven-part, proposition-indexed *interpretation* of the latest literary *Tractatus*. Reclassified definitional claims, finite counterexamples, theorems, and unproved research questions. Kept the original philosophical work unchanged.
- **Audit revision:** clarified filtering assumptions, added a distinct formation-versus-discovery witness, and specified the limits of profile-only prediction. The [research audit](../RESEARCH_AUDIT.md) records proof correspondence and checked Lean scope. The general stochastic architecture and the classification-risk calculation remain written mathematical arguments.
- **v0.2 identification revision:** integrated the verified one-step binary results and sharp sensitivity bounds into §6.5. The general two-agent filtering model and empirical validation remain open.
