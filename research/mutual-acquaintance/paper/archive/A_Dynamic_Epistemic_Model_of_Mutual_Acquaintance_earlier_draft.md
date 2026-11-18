---
title: 'A Dynamic Epistemic Model of Mutual Acquaintance'
subtitle: 'Reciprocal Inference, Preference Formation, and Constitutive Interaction'
author: 'Research manuscript | companion to Tractatus de Perceptione et Amore'
date: '18 November 2026'
lang: en-US
fontsize: 10pt
geometry: 'top=22mm,bottom=22mm,left=22mm,right=22mm'
mainfont: 'Linux Libertine O'
sansfont: 'Carlito'
monofont: 'DejaVu Sans Mono'
colorlinks: true
linkcolor: 'MidnightBlue'
urlcolor: 'MidnightBlue'
header-includes:
  - '\usepackage{microtype}'
  - '\usepackage{booktabs}'
  - '\usepackage{fancyhdr}'
  - '\pagestyle{fancy}'
  - '\fancyhead[L]{\footnotesize A Dynamic Epistemic Model of Mutual Acquaintance}'
  - '\fancyhead[R]{\footnotesize Research manuscript · 2026}'
  - '\fancyfoot[C]{\thepage}'
  - '\setlength{\headheight}{14pt}'
---

# Abstract

When two people become acquainted, they learn about each other, revise their own evaluative priorities, and take part in encounters that can change the relationship being evaluated. These are different processes, even when they occur during the same conversation. This paper develops a finite-state, two-agent, partially observed stochastic model that distinguishes **epistemic change** (revising beliefs about an existing state), **preference change or discovery** (revising an evaluation or one's understanding of it), and **constitutive change** (altering a dyadic state through interaction). Each agent has a potentially different information history, a decision-dependent conception of sufficient knowledge, and an independent choice about any mutual step. The formal results establish: asymmetric learning from a shared public signal; non-identification under repeated observations in one context; observational ambiguity between preference change and reporting change; nonnegative value of costless passive information; the absence of a corresponding guarantee for active encounters; decision sufficiency without full identification; nonrecoverability of dyadic state from individual traits alone; and non-identification of unobserved counterfactual paths. All results are conditional mathematical statements, not claims that actual individuals follow a particular model. A small, reproducible finite calculation checks the examples. The paper situates the construction alongside interpersonal-perception research, relationship science, decision theory, dynamic epistemic logic, and interactive partially observable decision processes. The contribution is **a precise synthesis and a set of discriminating counterexamples**, not a claim to have invented Bayesian inference, two-person dynamics, or mutual choice.

**Keywords:** interpersonal perception; mutual acquaintance; asymmetric information; dynamic epistemic logic; partially observable stochastic systems; preference formation; relationship-specific state; value of information; mutual choice; identifiability.

# 1. The problem and its philosophical source

Consider an ordinary encounter. Two people take part in the same conversation. One notices how carefully the other listens; the other notices that a disagreement can be discussed without the conversation collapsing. Each may learn something different. Each may also discover a previously unnoticed preference. Their next conversation, should it occur, would take place in a relationship already affected by the first one.

The motivating philosophical work, *Tractatus de Perceptione et Amore*, separates a person from another person's representation of that person (1.12--1.2), separates sincerity from accuracy (1.52), makes sufficiency of knowledge relative to the contemplated choice (2.7), distinguishes learning one's preferences from their alteration (3.22--3.23), distinguishes feeling understood from being understood accurately (4.53), and treats freely undertaken joint relationships as requiring both parties' willingness (5.3--5.33). Its concluding development makes a further distinction: **some things already exist but are not yet known; others are brought into being through shared activity** (6.91--6.92). This paper takes those distinctions as research questions, not as established psychological laws.

**Central question.** How can two people acquire decision-relevant knowledge about each other when their encounters can also modify their preferences and the very relation about which they are deciding?

A satisfactory model must keep five distinctions visible:

1. The **individual** is not identical with an observer's beliefs about the individual.
2. **Publicly shared events** can carry different information to differently situated participants.
3. **What is learned** about a preference differs from **a preference that changes**.
4. An encounter may **reveal** a relationship state or may **produce** a new one, and commonly does both.
5. An **informed unilateral preference** is not yet a **jointly selected outcome**.

We work with finite spaces to make all conditional probabilities, optimization statements, and counterexamples explicit. The finite assumption supports exact proofs and computation; it does not imply that human attributes are fundamentally finite or discrete.

# 2. Research basis and relation to earlier models

This is a targeted conceptual review of selected primary papers and mathematical sources, **not a systematic review or meta-analysis**. Where study results are mentioned, they are not equated with causal mechanisms unless the study design warrants that inference. No quantitative psychological parameters are estimated from this literature.

| Literature | Established concern | What the present model borrows, without claiming novelty |
|:--|:--|:--|
| Realistic Accuracy Model; Self--Other Knowledge Asymmetry | Judgment requires relevant cues and their appropriate use; knowledge varies with target and trait [1, 2]. | An observer-specific observation channel. |
| Social Relations Model; romantic speed-dating designs | Actor, partner, and dyad-specific components of interpersonal evaluations [3, 4]. | A dyad state irreducible to individual attributes alone. |
| Interaction diaries and perspective getting | Disclosure, perceived responsiveness, and direct communication have distinguishable correlates or effects [5, 6]. | An encounter can be informative and relationally consequential; no universal effect size is imposed. |
| Preferences and romantic evaluation | Stated qualities do not exhaust person-specific attraction; preference matching and relational processes are actively debated [7--9]. | Separate evaluative priorities, perceived characteristics, and joint outcomes. |
| Transformative experience | Experiencing a possibility can change how it is valued [10]. | Endogenous priorities rather than a fixed pre-interaction ranking. |
| Dynamic epistemic logic, I-POMDPs, Bayes-adaptive POMDPs | Information, partial observability, and multi-agent action are mature formal subjects [11--13]. | A finite two-agent controlled hidden-state system, not a new POMDP family. |
| Value-of-information theory | Information's value depends on the available decisions and utilities [14, 15]. | A distinction between costless observation and intervention. |

In particular, the 2026 review by Eastwick, Zhao, and Zietsch discusses the *compatibility puzzle* and proposes routes by which relationship experiences, rather than static preference-by-trait matching alone, may matter [9]. That is a theoretical comparison, not proof of the specific transition kernel developed below. The empirical speed-dating analysis by Baxter and colleagues partitions attraction into actor, partner, and relationship components and follows later outcomes in its sampled designs [4]; it does not identify a universal equation of romantic choice. Laurenceau and colleagues' event-contingent diaries relate self-disclosure and perceived responsiveness to experienced intimacy [5], but diary associations are not general intervention estimates. Eyal, Steffel, and Epley tested whether *getting* another person's perspective can outperform merely imagining it on specific accuracy tasks [6]; this is not a guarantee that any conversation is accurate.

The originality attempted here is therefore **architectural and analytical**: to place existing ideas in one model where one can ask which conclusions follow from which assumptions, and which intuitions are refuted by finite counterexamples.

# 3. A dynamic, reciprocal, partially observed system

## 3.1 Agents, latent state, and histories

Let the participants be $i\in\{A,B\}$ and time $t=0,1,\ldots,T$. For finite sets, define the latent state

$$
\omega_t=(x_{A,t},x_{B,t},q_{A,t},q_{B,t},r_t,c_t)\in\Omega.
\tag{1}
$$

Here $x_{i,t}$ encodes the attributes and context-dependent dispositions the model seeks to distinguish; $q_{i,t}$ represents the participant's operative evaluative priorities; $r_t\in\mathcal R$ is a **dyadic state** (for example, an abstract index of the history-dependent ease of cooperation); and $c_t\in\mathcal C$ is the encounter context. These are modeling variables, not direct clinical or moral measurements. A component such as $r_t$ need not be symmetric: it may be a vector of each person's experiences and their joint coordination state.

Each participant has a private information history $h^i_t\in\mathcal H^i_t$. This may include perceived utterances, memories of encounters, private circumstances, introspective observations, and the actions the participant knows occurred. In general, $h^A_t\ne h^B_t$ even when the visible meeting is shared.

The participant's belief is a probability distribution over possible current states:

$$
\pi^i_t(\omega):=\Pr(\omega_t=\omega\mid h^i_t),\qquad
\pi^i_t\in\Delta(\Omega).
\tag{2}
$$

This is the formal counterpart of the representation $P_i(j)$ in the literary *Tractatus*. Crucially, the belief includes uncertainty about **one's own priorities** as well as the other person's features. The agent need not have privileged, complete access to a fixed, perfectly articulated preference vector.

## 3.2 Mutual action, physical transition, and signals

At each stage each agent chooses an action $a^i_t\in\mathcal A_i(h^i_t)$; the joint action is $a_t=(a^A_t,a^B_t)$. Permissible joint encounters belong to a feasible set $\mathcal F_t(h^A_t,h^B_t)$, which can represent limitations of time, resources, and **the willingness of both parties**. This makes the feasible set dependent on both participants without construing either participant as an object to be optimized.

A controlled stochastic transition kernel determines the next state:

$$
T_t(\omega'\mid\omega,a)
=\Pr(\omega_{t+1}=\omega'\mid \omega_t=\omega,a_t=a).
\tag{3}
$$

The transition may affect $x_i$, $q_i$, and $r$, so a conversation is not assumed to be passive inspection of fixed objects. After the transition, the participants receive potentially distinct observations $y^A_{t+1}$ and $y^B_{t+1}$. A joint observation kernel

$$
O_t(y_A,y_B\mid\omega',a)
\tag{4}
$$

allows correlated signals, selective attention, and asymmetric private background information.

**No truthful-transparency axiom is imposed.** A report about preferences may be sincere but incomplete; a perceived response may not match the intent behind it; an utterance can be interpreted differently in different histories. The model also does not equate belief probability with emotional confidence or subjective certainty.

## 3.3 Bayesian prediction and correction

For clarity, suppose a joint action $a_t$ is observed and the agent has first updated to
$\pi^{i,a}_t(\omega)=\Pr(\omega_t=\omega\mid h^i_t,a_t)$.
The action can itself be informative, so **this action-conditioned distribution must not automatically be replaced by $\pi^i_t$**. Prediction is

$$
\overline\pi^i_{t+1}(\omega')
=\sum_{\omega\in\Omega}
T_t(\omega'\mid\omega,a_t)\pi^{i,a}_t(\omega).
\tag{5}
$$

When the participant's observation likelihood has the stated Markov form, the corrected belief is

$$
\pi^i_{t+1}(\omega')=
\frac{O^i_t(y^i_{t+1}\mid\omega',a_t)
\overline\pi^i_{t+1}(\omega')}
{\sum_{v\in\Omega}O^i_t(y^i_{t+1}\mid v,a_t)
\overline\pi^i_{t+1}(v)},
\tag{6}
$$

provided the denominator is positive. Here $O^i$ is the appropriate marginal of (4). If other participants' actions are only partly observed, they must be integrated out using an explicit action model; if past memories matter to observation beyond $\omega'$, the state must be enlarged. Formula (6) is a **conditional modeling rule**, not a claim that people literally execute Bayes' rule.

## 3.4 Three changes that must not be conflated

Write the three conceptual effects of an encounter as

$$
\begin{aligned}
E_t^i&:=\pi^i_{t+1}-\overline\pi^i_{t+1}
&&\text{(evidence-based belief revision)},\\
Q_t^i&:=q_{i,t+1}-q_{i,t}
&&\text{(change of operative priorities)},\\
R_t&:=r_{t+1}-r_t
&&\text{(change of the dyadic state)}.
\end{aligned}
\tag{7}
$$

The differences in (7) are componentwise numerical differences when the variables have numerical embeddings; for categorical states read them as the corresponding *events of change*, not as vector subtraction. A participant may learn about another's priorities ($E\ne0$) while those priorities remain fixed ($Q=0$); a preference may change without a new fact about the other ($Q\ne0$, $E=0$); and an encounter can generate a new shared history ($R\ne0$) without identifying a formerly unknown trait.

**Preference discovery** deserves a fourth distinction. A participant's reported priorities $\widehat q_{i,t}$ or beliefs $\rho_{i,t}(q_i)$ can change while the operative latent preference $q_{i,t}$ remains fixed. Thus neither a changed report nor a changed self-description by itself identifies true preference formation.

# 4. Theorems about learning and identification

## Proposition 1. The same public encounter can generate unequal learning

Let $\Theta$ and $K$ be independent fair binary variables. Both agents observe the same public event $Y=\Theta\oplus K$; agent A additionally knows $K$, whereas agent B does not. Then

$$
H(\Theta\mid Y,K)=0,
\qquad H(\Theta\mid Y)=1\text{ bit}.
\tag{8}
$$

Consequently, A can identify $\Theta$ exactly from $Y$ and $K$, while B's posterior over $\Theta$ remains uniform after seeing the identical $Y$.

**Proof.** For each realization, $\Theta=Y\oplus K$, so A's conditional uncertainty is zero. For B, independence and fairness imply $\Pr(Y=y\mid\Theta=0)=\Pr(Y=y\mid\Theta=1)=1/2$. By Bayes' rule, $\Pr(\Theta=0\mid Y=y)=\Pr(\Theta=1\mid Y=y)=1/2$, so conditional entropy remains one bit. $\square$

**Interpretation.** The asymmetry does not mean one person's interpretation is emotionally superior. Their priors and side information differ. A shared event need not constitute shared evidence. This models the possibility raised by *Tractatus* 6.5--6.52 without asserting any actual private thought.

## Proposition 2. Repetition in an uninformative context cannot identify the hidden difference

Fix two hypotheses $\theta_0,\theta_1$ with positive prior probabilities. Suppose that under a fixed context and admissible observation policy, **the full conditional distribution of every finite observation history** is equal:

$$
\Pr(H_n=h\mid\theta_0)
=\Pr(H_n=h\mid\theta_1)
\quad\text{for all }n,h.
\tag{9}
$$

Then for any history with positive likelihood under either hypothesis,

$$
\frac{\Pr(\theta_0\mid H_n=h)}
{\Pr(\theta_1\mid H_n=h)}
=
\frac{\Pr(\theta_0)}{\Pr(\theta_1)}.
\tag{10}
$$

**Proof.** Bayes' rule multiplies the prior odds by the likelihood ratio. Assumption (9) makes that ratio one. $\square$

**Why the assumption is precise.** Equal *one-encounter marginals* do not suffice when sequential correlations or strategic action selection differ. Equation (9) requires observational equivalence of the **whole history law** under the policy actually used. A different context might discriminate the hypotheses, but accessing that context may itself change the relation.

## Proposition 3. Apparent preference change need not identify actual preference formation

Let an observable report at time $t\in\{0,1\}$ be

$$
Y_t=Q_t\oplus E_t,
\tag{11}
$$

where $Q_t\in\{0,1\}$ is a binary operative preference and $E_t$ is a context or reporting effect. Consider two deterministic models:

- **Model F (formation):** $(Q_0,Q_1)=(0,1)$ and $(E_0,E_1)=(0,0)$.
- **Model R (reporting):** $(Q_0,Q_1)=(0,0)$ and $(E_0,E_1)=(0,1)$.

Both produce the identical observed report history $(Y_0,Y_1)=(0,1)$ with probability one, although only Model F changes the operative preference.

**Proof.** Substitute the assignments into (11). In both models $Y_0=0$ and $Y_1=1$, while $Q_1\ne Q_0$ holds only in F. The observation distributions therefore coincide, so no statistic of these reports alone distinguishes the models. $\square$

This is an **identification counterexample**, not evidence that any particular person conceals a preference. Longitudinal measures and contextual intervention are possible research responses, not guaranteed solutions.

# 5. Information is not the same as an encounter

## 5.1 Passive information and its value

Let $\Omega$ be a finite, fixed state space, $D$ a finite set of available individual decisions, $p(\omega,z)$ a joint distribution of a costless signal $Z$ and state, and $U(d,\omega)$ a utility function unaffected by receiving $Z$. Define

$$
V_0=\max_{d\in D}\sum_{\omega}p(\omega)U(d,\omega),
\quad
V_Z=\sum_z\max_{d\in D}\sum_{\omega}p(\omega,z)U(d,\omega).
\tag{12}
$$

## Theorem 4. Costless passive information has nonnegative optimal decision value

Under the conditions of (12),

$$
V_Z\ge V_0.
\tag{13}
$$

Equality holds exactly when there exists a decision $d^*$ that is optimal for every signal realization $z$ with $p(z)>0$ (ties permitted).

**Proof.** Let $d_0$ maximize $V_0$. For each $z$,

$$
\max_d\sum_\omega p(\omega,z)U(d,\omega)
\ge\sum_\omega p(\omega,z)U(d_0,\omega).
$$

Summing over $z$ yields (13). If equality holds, every nonnegative summand in the inequality must vanish, so $d_0$ is conditionally optimal for each positive-probability $z$. Conversely, if one decision is conditionally optimal for every such $z$, it is also ex ante optimal, and the inequality is an equality. $\square$

The theorem does **not** say that more disclosure guarantees a better relationship. It assumes a fixed state, costless signal, unchanged utilities, an option to ignore the signal, and one decision maker's optimal expected utility. Those assumptions are usually false if the information is acquired by performing a consequential encounter with another person.

## Theorem 5. Active information acquisition can have negative total value

There exists a finite model where an encounter reveals the hidden trait perfectly but has **lower expected decision-plus-relational utility** than an uninformative alternative.

**Construction and proof.** Let a binary state $\Theta$ be fair and let the pre-encounter dyadic state be $r=1$. After the encounter, an agent guesses $\Theta$; the guess is worth $1$ if correct and $0$ otherwise. The terminal objective is

$$
U=\mathbf 1\{d=\Theta\}+\lambda r_{\text{after}},\qquad \lambda>\tfrac12.
\tag{14}
$$

A **quiet** action leaves $r=1$ and yields no new information, so the best expected terminal value is $V_{\mathrm{quiet}}=1/2+\lambda$. A **probe** action reveals $\Theta$ perfectly but sets $r_{\mathrm{after}}=0$, so $V_{\mathrm{probe}}=1$. Hence

$$
V_{\mathrm{probe}}-V_{\mathrm{quiet}}
=\tfrac12-\lambda<0.
\tag{15}
$$

By contrast, passively receiving the same perfect information **without changing $r$** would yield $1+\lambda$, improving the quiet outcome by $1/2$. $\square$

The action labels are hypothetical mathematical interventions, **not recommended social strategies**. The decrement in $r$ is an assumption of this counterexample, not a general psychological effect of asking questions. Its logical role is to defeat the inference from *positive value of passive information* to *positive total value of every information-generating encounter*. A participant's freely chosen pace and the other participant's willingness are not costs to override.

# 6. Decision sufficiency and mutual choice

## 6.1 Perfect-information regret as a decision-relative criterion

For an agent at history $h$, let $p(\omega\mid h)$ be the posterior and $D(h)$ the **personally feasible** decisions. Compare the value of knowing the latent state exactly with the best action under current information:

$$
\mathrm{EVPI}(h)
=\sum_\omega p(\omega\mid h)\max_{d\in D(h)}U(d,\omega)
-\max_{d\in D(h)}\sum_\omega p(\omega\mid h)U(d,\omega).
\tag{16}
$$

This value is nonnegative and can be zero while the posterior remains uncertain. A stylized definition of $\varepsilon$-**decision sufficiency** is

$$
\mathrm{EVPI}(h)\le\varepsilon.
\tag{17}
$$

This is a **model-relative sufficiency criterion**, not a requirement that an actual person enter a relationship once a computed threshold is met. Utilities and feasible actions can be unknown, evolve with experience, or be incompletely measurable. The threshold $\varepsilon$ is individual and decision-specific; it is not a universal number of meetings or disclosures.

## Theorem 6. Full identification is unnecessary for decision sufficiency

For a finite posterior distribution and fixed utility function, $\mathrm{EVPI}(h)=0$ if and only if there exists a single feasible decision $d^*$ that maximizes $U(d,\omega)$ for **every** state $\omega$ having positive posterior probability (ties allowed).

**Proof.** Choose an action $d_0$ maximizing expected utility under the posterior. For every state,
$\max_d U(d,\omega)-U(d_0,\omega)\ge0$. The posterior expectation of this nonnegative difference is exactly $\mathrm{EVPI}(h)$. It equals zero exactly when every positive-probability difference equals zero, which is the common-optimality condition. The converse follows immediately. $\square$

**Example.** Suppose two latent states remain equally likely, but decision $d_0$ yields utility $2$ in both, while $d_1$ yields $1$ in one state and $0$ in the other. The participant does not know which state holds, yet $\mathrm{EVPI}=0$. If instead $d_0$ is optimal only in the first state and $d_1$ only in the second, the same posterior uncertainty can be decision-relevant. Thus **uncertainty itself is not a sufficient measure of the value of further acquaintance**.

## 6.2 Two independent participants, not a single optimizing judge

Let $W_i(s,t)\in\{0,1\}$ record whether participant $i$ is willing, at time $t$, to undertake a specified shared step $s$. A joint outcome $J(s,t)$ defined as *freely and jointly undertaken* satisfies

$$
J(s,t)=1\Longrightarrow W_A(s,t)=W_B(s,t)=1.
\tag{18}
$$

This is **constitutive**, not a newly discovered law of human psychology. Its point is to prevent the mathematical model from replacing two autonomous choices with one person's predicted utility. Even if both participants separately satisfy (17), the desired joint step need not follow. They can have different feasible options, preferences, or judgments about the same event.

If willingness is represented probabilistically, the general dependence bounds are

$$
\max(0,p_A+p_B-1)
\le\Pr(W_A=1,W_B=1)
\le\min(p_A,p_B),
\tag{19}
$$

where $p_i=\Pr(W_i=1)$. These are Fréchet bounds, not estimates of willingness in any real pair. Assuming the probability is $p_Ap_B$ would require an additional independence hypothesis that ordinarily lacks justification.

## Proposition 7. Individual traits do not identify a dyadic state

There is no general function $g$ for which $r_t=g(x_{A,t},x_{B,t})$ in every admissible dynamic model.

**Proof by counterexample.** Let both individual trait vectors remain fixed at $x_A=x_B=0$. Set $r_0=0$. Under the joint action $a=\mathrm{cooperate}$, let $r_1=1$; under the joint action $a=\mathrm{separate}$, let $r_1=0$. Both histories have identical ordered individual trait vectors $(0,0)$, but their relational states differ. Any single-valued $g(0,0)$ would have to equal both 0 and 1. $\square$

The example makes no prediction about whether cooperation always increases closeness. It shows that dyad-specific history is a logically permissible additional state variable, consistent with the distinction between actor, partner, and relationship components in interpersonal evaluations [3, 4].

# 7. Limits of knowledge about unchosen possibilities

## Proposition 8. One realized path does not identify an unchosen counterfactual

There exist two dynamic models with identical distributions for every observation along an actually chosen action sequence, but different outcomes under an unchosen alternative.

**Proof by construction.** At time zero let the observed state be $r_0=0$ and let the observed action be $a_0$. In both models, action $a_0$ deterministically produces $r_1=0$ and the same observation. For the unchosen action $a_1$, define model M to produce $r_1=1$ and model N to produce $r_1=0$. Every observation under the actual $a_0$ path coincides, but the counterfactual under $a_1$ differs. Therefore that counterfactual cannot be identified solely from the actual history. $\square$

This formalizes the caution of *Tractatus* 6.41--6.43. It does **not** imply counterfactuals are always unknowable: structural assumptions, randomized data, external comparisons, and domain knowledge can sometimes identify or bound them. A single realized history without such assumptions is insufficient.

# 8. A continuous finite example

Mira and Daniel, two fictional volunteers, meet while managing a community tool library. They first see each other in a routine task, then discuss a disagreement about pickup hours, and later choose whether to work on another task. No event in this example is a prescribed relationship test. It is only a narrative interpretation of model variables.

At the first meeting, the public observation may be the same to both participants: Daniel agrees to test two collection windows. Mira may already know the constraint faced by the volunteers who use the library, while Daniel knows why he preferred flexibility. Their posteriors need not coincide because their histories differ (Proposition 1). Repeated cheerful conversations at the desk may tell them a great deal about friendliness there, while saying comparatively little about conduct in situations neither has experienced (Proposition 2).

When Mira says she now prizes reliability more than spontaneity, the report does not by itself distinguish an old, unrecognized priority from a new one (Proposition 3). If they finish a task well together, their next encounter may begin from a new dyadic state rather than from a better measurement of two unchanged people (Proposition 7). The same exchange can therefore change an assessment, reveal a preference, and create a shared history. None of those changes compels a common next choice.

The numerical examples use binary hidden states on purpose. They illustrate structural distinctions without fitting any trait scores, ideal-partner measures, or psychological transition probabilities to real humans.

## 8.1 Reproducible exact calculations

The companion script `verify_examples.py` enumerates the finite constructions without random sampling. In the recorded run it passed 20,480 bounded cases for Theorem 4 (including its equality condition), 1,215 for Theorem 6, and 255 binary joint-willingness distributions for the Fréchet bounds. Its checks include:

| Construction | Expected exact result | What it does **not** establish |
|:--|:--|:--|
| Public XOR signal and private key | A's posterior certainty; B's entropy remains 1 bit | Actual people have such clean signals |
| Repeated context with equal history laws | Posterior odds unchanged at every finite length | Every repeated encounter is uninformative |
| Preference/report ambiguity | Same observed reports, different latent preference paths | A change in self-description is deceptive |
| Passive perfect signal, $\lambda=.75$ | Value $1.75$ versus no signal $1.25$ | Disclosure always improves a relationship |
| Active perfect signal, $\lambda=.75$ | Value $1.00$ versus quiet $1.25$ | Asking questions generally harms relationships |
| Distinct dyadic histories | Same individual attributes, different $r_1$ | A calibrated psychological dyad metric exists |
| Identical realized paths | Counterfactual alternative differs between models | Counterfactuals can never be studied |

The script checks the **instances**, not universal propositions over all finite domains. The general statements are proved in the paper using explicit assumptions. A separate Lean 4 source file records a small propositional/Boolean skeleton; **no Lean kernel compilation is claimed unless a compiler run is actually recorded**.

# 9. Empirical operationalization and falsifiability

Turning this framework into empirical science requires measurement choices that the mathematics does not supply automatically.

A longitudinal study could recruit mutually consenting pairs who are already participating in some recurring activity. At multiple encounters, each participant might privately report (a) specific predictions about the other's observable responses, (b) confidence in those predictions, (c) their own stated priorities, (d) perceived understanding and comfort, and (e) their freely chosen willingness for a *particular* next shared activity. Independent, consensually available observation or later behavior could provide criterion measures for selected accuracy questions. The study would not infer undisclosed mental states from silent behavior.

The design should separate at least four estimands:

1. **Prediction accuracy:** how an observable target criterion aligns with the agent's earlier prediction, with self-report and behavior treated as different criteria.
2. **Preference stability versus discovery:** whether reported changes persist across contexts and elicitation methods, recognizing that self-reports alone cannot identify a latent preference transition.
3. **Dyad-specific change:** whether a history-sensitive relational measure predicts subsequent behavior beyond actor and partner effects, guarding against common-method bias.
4. **Choice quality:** how well information forecasts the *particular next decision*, with selection, unequal participation, and missing data handled explicitly.

A **model comparison** could contrast (M0) stable preferences plus passive observation, (M1) changing preferences but passive relation, and (M2) changing preferences plus dynamic dyad state. An increase in out-of-sample prediction under M2 would not by itself establish that the model's latent variables are causally identified. A preregistered intervention or stronger natural experiment would be needed to test claims about the causal effects of specific encounters; such interventions require independent ethical review and voluntary participation.

Observable implications are not guaranteed by the axioms: competing parameterizations can be empirically indistinguishable, so posterior predictive checks, sensitivity analysis, and deliberate negative results are essential. No attempt should be made to infer a particular individual's private attraction or to optimize a strategy for bypassing a person's expressed wishes.

# 10. Interpretation and limits

## 10.1 What the theorems say

The model implies that **shared experience need not be shared evidence** (Proposition 1); evidence can fail to identify the state under an uninformative context (Proposition 2); introspective reports alone may not separate discovery from change (Proposition 3); passive free information can help a fixed decision problem but cannot justify every active encounter (Theorems 4 and 5); full knowledge is not necessary when unknown features do not alter the best next action (Theorem 6); and the relation being assessed may depend on the shared path, not only on the properties of its participants (Proposition 7).

These statements match important distinctions in *Tractatus de Perceptione et Amore*, but they do not show that its philosophical last proposition is a theorem of probability theory. The distinction between *what can be said* and *what is shown* in Wittgenstein's *Tractatus Logico-Philosophicus* is fundamentally a logical and philosophical distinction, not a synonym for incomplete interpersonal measurement. A finite stochastic model says precisely what follows **within its specified vocabulary**. It does not prove that all subjective experience is incompressible, ineffable, or mathematically inaccessible.

## 10.2 What the model cannot say

The model cannot certify romantic compatibility, define a universally desirable person, assign human worth, or infer anyone's private feelings without evidence. It cannot identify a stable core of traits independently of the observation method without additional assumptions. It does not imply that Bayesian rationality is a human norm, or that a pair should continue interacting until an optimal information threshold is reached. Values, autonomy, and acceptable uncertainty remain participant-specific and partly outside the utility representation.

Even an apparently complete behavioral dataset would not remove all model uncertainty. The choice of state variables, utility scale, observation mechanism, and counterfactual intervention already embeds theoretical commitments. **A proof is only as general as its assumptions.** In particular, a numerical demonstration of a changed dyadic state is not independent evidence that such a variable has been validly measured in human relationships.

## 10.3 Relation to existing mathematical research

Dynamic epistemic logic formalizes knowledge change; interactive POMDPs model multi-agent decision making under partial observability; Bayes-adaptive POMDPs combine model learning and acting. These precede the present manuscript [11--13]. This paper's particular integration is a **proposed conceptual framework**, not a demonstrated first-in-field mathematical invention. A more substantial research contribution would require either a new identifiability theorem under defensible observation restrictions, an empirically testable structural specification that outperforms alternatives, or a formally verified result not already subsumed by standard decision theory.

# 11. Conclusion

Mutual acquaintance is not adequately captured by a single sequence of increasingly accurate estimates about two fixed people. Participants may acquire different information from the same event, discover or revise what they value, and enter a dyadic state partly constituted by what they have done together. Some uncertainty concerns **what already exists but has not been learned**; some concerns **what has not yet been made real through interaction**. The distinction is central, but it creates no obligation to interact, disclose, or decide together.

Mathematically, this leads to an open-ended, two-observer controlled inference problem with evolving preferences, path-dependent dyadic state, and separately authorized choices. It permits rigorous conclusions about informational asymmetry, decision sufficiency, causal identification limits, and the distinction between passive knowledge and active change. It does not determine the inner life of any pair. The useful question is not whether the model knows everything about two people, but **which assumptions are sufficient for which next question, and which parts of the human experience remain outside what its evidence can establish**.

# References

[1] Funder, D. C. (1995). On the accuracy of personality judgment: A realistic approach. *Psychological Review, 102*(4), 652--670. <https://doi.org/10.1037/0033-295X.102.4.652>.

[2] Vazire, S. (2010). Who knows what about a person? The Self--Other Knowledge Asymmetry (SOKA) model. *Journal of Personality and Social Psychology, 98*(2), 281--300. <https://doi.org/10.1037/a0017908>.

[3] Kenny, D. A. (2019). *Interpersonal Perception: The Foundation of Social Relationships*, 2nd ed. Guilford Press. <https://davidakenny.net/ip/interp.htm>.

[4] Baxter, A., Maxwell, J. A., Bales, K. L., Finkel, E. J., Impett, E. A., & Eastwick, P. W. (2022). Initial impressions of compatibility and mate value predict later dating and romantic interest. *Proceedings of the National Academy of Sciences, 119*(45), e2206925119. <https://doi.org/10.1073/pnas.2206925119>.

[5] Laurenceau, J.-P., Barrett, L. F., & Pietromonaco, P. R. (1998). Intimacy as an interpersonal process: The importance of self-disclosure, partner disclosure, and perceived partner responsiveness in interpersonal exchanges. *Journal of Personality and Social Psychology, 74*(5), 1238--1251. <https://doi.org/10.1037/0022-3514.74.5.1238>.

[6] Eyal, T., Steffel, M., & Epley, N. (2018). Perspective mistaking: Accurately understanding the mind of another requires getting perspective, not taking perspective. *Journal of Personality and Social Psychology, 114*(4), 547--571. <https://doi.org/10.1037/pspa0000115>.

[7] Eastwick, P. W., & Finkel, E. J. (2008). Sex differences in mate preferences revisited: Do people know what they initially desire in a romantic partner? *Journal of Personality and Social Psychology, 94*(2), 245--264. <https://doi.org/10.1037/0022-3514.94.2.245>.

[8] Joel, S., Eastwick, P. W., & Finkel, E. J. (2017). Is romantic desire predictable? Machine learning applied to initial romantic attraction. *Psychological Science, 28*(10), 1478--1489. <https://doi.org/10.1177/0956797617714580>.

[9] Eastwick, P. W., Zhao, A. A. Z., & Zietsch, B. P. (2026). Mate preferences and the compatibility puzzle. *Trends in Cognitive Sciences*, advance online publication 29 October 2026. <https://doi.org/10.1016/j.tics.2026.10.001>.

[10] Paul, L. A. (2014). *Transformative Experience*. Oxford University Press. <https://doi.org/10.1093/acprof:oso/9780198717959.001.0001>.

[11] van Ditmarsch, H., van der Hoek, W., & Kooi, B. (2007). *Dynamic Epistemic Logic*. Springer. <https://doi.org/10.1007/978-1-4020-5839-4>.

[12] Gmytrasiewicz, P. J., & Doshi, P. (2005). A framework for sequential planning in multi-agent settings. *Journal of Artificial Intelligence Research, 24*, 49--79. <https://doi.org/10.1613/JAIR.1579>.

[13] Ross, S., Pineau, J., Chaib-draa, B., & Kreitmann, P. (2011). A Bayesian approach for learning and planning in partially observable Markov decision processes. *Journal of Machine Learning Research, 12*, 1729--1770. <https://jmlr.org/papers/v12/ross11a.html>.

[14] Howard, R. A. (1966). Information value theory. *IEEE Transactions on Systems Science and Cybernetics, 2*(1), 22--26. <https://doi.org/10.1109/TSSC.1966.300074>.

[15] Blackwell, D. (1953). Equivalent comparisons of experiments. *Annals of Mathematical Statistics, 24*(2), 265--272. <https://doi.org/10.1214/aoms/1177729032>.

**Related primary text:** *Tractatus de Perceptione et Amore* (Indonesian philosophical edition, revised 18 November 2026), propositions 1.12, 1.52, 2.7, 3.23, 4.53, 5.3--5.33, 6.41--6.43, 6.63, 6.91--6.92, and 7. Source manuscript supplied in the accompanying project; not a peer-reviewed empirical source.