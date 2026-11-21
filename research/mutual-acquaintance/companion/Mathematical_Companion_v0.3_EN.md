# Mathematical Companion to *Tractatus de Perceptione et Amore*

*An accessible guide to its models, examples, theorems, and proofs.*

**Companion version 0.3 — 21 November 2026**  
**Source text:** *Tractatus de Perceptione et Amore*, canonical version **1.1.0** (19 November 2026), 116 active propositions. The Indonesian text remains the canonical literary source; quotations here follow the accompanying English edition.  
**Purpose:** To make the philosophical distinctions precise enough to examine, without turning the *Tractatus* itself into a conventional mathematical research paper.

This companion is an **interpretation and mathematical development** of the existing work, not a new edition of its propositions or an empirically established account of human relationships. The detailed technical working draft (v0.2), proof ledger, and Lean 4 formalization remain separate.

## Before we begin: six things that must not be confused

Imagine two people, **A** and **B**, getting to know each other. At least six things matter:

| Symbol | Meaning |
| --- | --- |
| \(A\), \(B\) | The two people, neither reduced to a description or a number |
| \(P_A(B)\) | A's picture or interpretation of B |
| \(P_B(A)\) | B's picture or interpretation of A |
| \(I_A\) | A's image of a desirable partner |
| \(I_B\) | B's image of a desirable partner |

These six things can develop at different rates. A person's circumstances can change; an impression can become more accurate or more confident without becoming more accurate; and an ideal can be discovered, revised, or partly abandoned.

This is the central question:

> How can two people come to know one another well enough to make an informed, mutual choice, when knowing, wanting, and relating can all change through their encounters?

The mathematical language is modest. It helps keep different questions apart. It is not a claim that people consciously perform Bayesian inference or maximize a numerical utility function every time they speak.

### A small map of what changes

At time \(t\), write a simplified modeled state as

\[
S_t=(x_{A,t},x_{B,t},q_{A,t},q_{B,t},r_t,c_t).
\]

Here \(x_A\) and \(x_B\) stand for the particular individual features relevant to a question, not whole persons. The variables \(q_A\) and \(q_B\) represent operative preferences; a person's stated ideal \(I_A\) or \(I_B\) is a **representation** of those preferences and need not capture them perfectly. The variable \(r_t\) represents something about the pair's **relationship-specific state**, such as a developing pattern of trust, coordination, or ease together. The term \(c_t\) records context.

Neither participant directly observes all these components. A's personal history \(h_{A,t}\) and B's history \(h_{B,t}\) may differ even if they attend the same encounter. In a probabilistic model, their separate beliefs can be written \(\pi_{A,t}(S)\) and \(\pi_{B,t}(S)\).

A meeting can therefore change three different things:

\[
\underbrace{\pi_{i,t}\rightarrow\pi_{i,t+1}}_{\text{learning about what is so}}
\qquad
\underbrace{q_{i,t}\rightarrow q_{i,t+1}}_{\text{discovering or changing what matters}}
\qquad
\underbrace{r_t\rightarrow r_{t+1}}_{\text{changing what exists between them}}.
\]

These are conceptually distinct. They may occur together, but observing one is not proof of the others.

---

## 1. The person and the picture of the person

> **§1.** “The person we know is not always the same as the person we think we know.”

This proposition is the starting point, not a claim that every impression is false. A person is the object of the interpretation; \(P_A(B)\) is A's interpretation of that person. A's impression may be accurate about B's conduct at work but mistaken about B's behavior with close friends. Two people may also have different, partly correct pictures of the same person (§§1.4–1.42).

### Example: identical words, unequal information

Two people hear the same remark. One knows that it refers to an earlier conversation; the other does not. What is publicly heard is identical, but what can be learned from it is not.

We can make this possibility exact, without pretending it is a full model of conversation.

**Example C1 — A shared signal need not yield shared knowledge.** Let the hidden fact \(\Theta\) and a private key \(K\) be independent, fair binary variables. Everyone sees \(Y=\Theta\oplus K\), where \(\oplus\) means exclusive OR. Only A sees \(K\).

**Why the example works.** A recovers \(\Theta\) by computing \(Y\oplus K\). B, who sees only \(Y\), cannot distinguish the two values of \(\Theta\): a fair independent key makes both equally likely for any observed \(Y\). The XOR identity has a finite Lean counterpart; the probability interpretation is a separate mathematical argument.

**What it does not establish.** It does not say that one partner always understands more, that every private context is decisive, or that two people can never converge. It shows only that observing the same event does not **guarantee** acquiring the same information.

The same caution applies to confidence (§§1.22, 1.31). Feeling certain of \(P_A(B)\) is not a measurement of how closely that picture matches B. The sincerity of an emotion and the accuracy of the picture on which it rests are different questions (§1.52).

## 2. What is known, what is supposed, and what is enough

> **§2.21.** “A single event may fit several explanations; without further information, we may have no grounds for treating one of them as true.”
>
> **§2.7.** “Knowing someone well enough also depends on the choice being considered.”

A delayed message may fit many explanations. One observation can tell us *what happened* without telling us *why*. Sometimes more observations help; sometimes repeating the same conditions only strengthens confidence in an explanation that the evidence has not distinguished.

### Theorem 2.1 — Repetition need not distinguish two explanations (T2)

Let \(\theta_0\) and \(\theta_1\) be two hypotheses with positive prior probability, and let \(H_n\) be the **entire observed history** after \(n\) encounters, including observation-relevant choices and context. Suppose, for every \(n\) and every possible history \(h\),

\[
\Pr(H_n=h\mid\theta_0)=\Pr(H_n=h\mid\theta_1).
\]

Then whenever that history has positive likelihood,

\[
\frac{\Pr(\theta_0\mid H_n=h)}
     {\Pr(\theta_1\mid H_n=h)}
=
\frac{\Pr(\theta_0)}
     {\Pr(\theta_1)}.
\]

**Proof.** By Bayes' rule, posterior odds are prior odds multiplied by the ratio of the two likelihoods. The assumed likelihood ratio is one; the odds do not change. \(\square\)

**Why the assumption matters.** Identical *single-encounter* distributions are not enough if the patterns or correlations across a history differ. The theorem concerns the full observable history under the actual observation policy. It does not say repeated contact is useless. Rather, repetition cannot distinguish hypotheses that always make the **same predictions about what is observed** (§2.61).

### Theorem 2.2 — Complete knowledge may be unnecessary for one decision (T3)

Consider a decision problem with two possible states, two available actions, fixed payoffs, positive probabilities for the states under consideration, and costless perfect information. Assume the decision maker may ignore the information.

**Claim.** The value of perfect information is zero **if and only if** one available action is optimal in every possible state (ties allowed).

**Proof.** With perfect information, the decision maker can use the best action in each state. Without it, the decision maker must choose one action for all states. The first value is at least the second. If a single action is optimal in each state, knowing the state does not improve the result. Conversely, if neither action is optimal in every positive-probability state, every fixed choice sacrifices some payoff in at least one state, so perfect information has positive value. \(\square\)

**Example.** Action X yields a payoff of 2 in either state; Y yields 1 in either state. You do not know which state obtains, but the uncertainty does not matter to this particular choice: X wins either way.

The philosophical point is narrower than omniscience. “Enough to decide whether to spend an afternoon together” and “enough to decide whether to share a life” are different standards (§§2.71–2.72). A decision model can clarify how uncertainty affects a specified choice, but it does **not** establish a universal ethical threshold for entering a relationship. The consequences of error, consent, and what is at stake still matter.

## 3. The person we want, and wants that develop

> **§3.23.** “The first helps us recognize an old desire. The second changes the desire itself.”

The *Tractatus* distinguishes a previously existing preference that becomes **recognized** from a preference that is **formed or altered** through experience. It also distinguishes an actual person from the picture of that person and the ideal against which the picture is compared (§§3.1–3.3).

When B feels \(P_B(A)\) matches \(I_B\), B compares two **representations**. That can help explain an attraction without proving the picture accurate, the ideal stable, or A's reciprocal willingness.

### Example C2 — A changed answer does not identify a changed preference

Suppose an observable yes/no report follows

\[
Y_t=Q_t\oplus C_t,
\]

where \(Q_t\) is the modeled underlying preference and \(C_t\) is a reporting-context effect.

Two mechanisms can produce the same visible sequence \(Y=(0,1)\):

| Mechanism | Preference \(Q\) | Reporting context \(C\) | Observed report \(Y\) |
| --- | --- | --- | --- |
| Same preference, different context | \((0,0)\) | \((0,1)\) | \((0,1)\) |
| Changed preference, same context | \((0,1)\) | \((0,0)\) | \((0,1)\) |

**Proof.** Substituting either row into the same XOR equation gives the same observed report sequence. The report alone cannot determine which mechanism generated it. If the context and reporting rule are independently known, this particular ambiguity can disappear.

This is a **counterexample to identification from reports alone**, not evidence that somebody is concealing their true feelings. A changed answer could represent newly recognized preferences, new preferences, a changed expression, or several processes at once. The available evidence has to tell these apart; the notation cannot do it by itself.

This is also why **attraction**, **compatibility through shared experience**, and **willingness to proceed** should not be treated as synonyms (§3.6).

## 4. Meaning, expression, understanding, and the feeling of being understood

> **§4.53.** “Some conversations leave us feeling understood. Whether the other person really caught what we meant is another question.”
>
> **§4.54.** “The response to someone's story may affect how close two people feel, even when the accuracy of their mutual understanding remains uncertain.”

At least four things must be separated: the intention behind an utterance, the expression itself, the listener's interpretation, and the experience of feeling understood. Sometimes all four align. Sometimes a person sincerely explains something and is misunderstood. Sometimes an attentive response produces a sense of closeness while the listener still misunderstands an important detail.

### Example C3 — Silence does not uniquely reveal an intention

Let two possible intentions, \(m_0\) and \(m_1\), both produce the same recorded response: **silence**.

**Proof of the limitation.** A many-to-one observation function cannot be uniquely inverted from its output alone. The single observation is compatible with both intentions. More context might distinguish them; the silent response by itself does not.

This does not make all interpretation arbitrary. Nor does it claim that responsiveness is unimportant. It says only that **felt understanding is not identical to measured interpretive accuracy**. Whether a particular response actually promotes intimacy is an empirical question, not a mathematical theorem about the human mind.

## 5. Two people, two choices

> **§5.** “A relationship between two people cannot be determined by what only one of them wants.”

A knows something of A's reasons. B knows something of B's reasons. They may understand the same event differently and reach different decisions without either being irrational (§§5.1–5.22).

### A defining condition, not a discovery (D1; §§5.3–5.32)

Let \(W_A(B,t)\) mean A's willingness to enter a specified relationship with B at time \(t\), and \(W_B(A,t)\) mean B's corresponding willingness. Let \(H(A,B,t)\) mean a relationship **freely undertaken together** at that time. Then

\[
H(A,B,t)\ \Longrightarrow\
W_A(B,t)\land W_B(A,t).
\]

**Why is this true?** Because “freely undertaken together” already includes the willing participation of both. The formula records a **necessary condition built into the definition**, not a prediction that both will choose each other. The reverse implication need not hold: both may be willing yet unable to proceed because of timing, commitments, feasibility, or other circumstances (§5.33).

### Theorem 5.1 — Bounds on joint willingness (T4)

If \(p_A=\Pr(W_A=1)\) and \(p_B=\Pr(W_B=1)\), then without assuming independence,

\[
\max(0,p_A+p_B-1)
\le
\Pr(W_A=1,W_B=1)
\le
\min(p_A,p_B).
\]

**Proof.** Joint willingness is a subset of each individual willingness event, so its probability cannot exceed either marginal. For the other side, the union of the two events has probability at most one. Inclusion–exclusion gives \(p_A+p_B-\Pr(W_A\land W_B)\le1\). A probability also cannot be negative. The bounds are attainable with different dependence structures. \(\square\)

**Example.** If each person's willingness has marginal probability \(0.6\), the probability of both being willing could lie anywhere from \(0.2\) to \(0.6\). The often-assumed value \(0.36\) requires **independence**—which should not be presumed in an interacting pair.

This result neither predicts two particular people's decisions nor turns consent into a probabilistic calculation. It illustrates why **two individually plausible choices do not mathematically force one mutual choice**.

## 6. What an encounter reveals, and what it brings into being

> **§6.63.** “Getting to know someone, becoming aware of what we want, and experiencing a change in a relationship are three different things. Still, all three can happen in the same meeting.”
>
> **§6.92.** “Some things were already there; we simply did not know them yet. Others come into being through what two people experience together.”

This is the structural center of the model.

An encounter can **reveal** a characteristic that was already present. It can also **help form** a new preference or a new relationship-specific pattern. Before two people cooperate on something difficult, neither may know exactly how they will communicate as a pair. After doing so, the cooperative pattern they have developed is not merely a newly learned fact about two separately existing trait lists.

The distinction does not require mystical language. It requires that the modeled **relationship-specific state** may change as the participants interact.

### Theorem 6.1 — Costless passive information cannot hurt the specified decision (T5)

Suppose the underlying state stays fixed; the action set and payoffs stay unchanged; a signal is free; and the decision maker can ignore it. Then the optimal expected decision value after seeing the signal is at least its value before the signal.

To write this exactly, with state \(\omega\), signal \(Z\), action \(d\), and payoff \(U\),

\[
V_0=\max_d\sum_\omega p(\omega)U(d,\omega),
\]

\[
V_Z=\sum_z\max_d\sum_\omega p(\omega,z)U(d,\omega).
\]

**Claim:** \(V_Z\ge V_0\). Equality holds precisely when one action is optimal after every positive-probability signal (including ties), under the finite decision assumptions above.

**Proof.** Choose an action \(d_0\) that maximizes value before seeing the signal. After each possible signal, the decision maker can still choose \(d_0\), so the new maximum is at least its payoff. Sum across signals. Equality requires every nonnegative signal-specific improvement to vanish; hence a common optimal action exists. The converse follows by using that common action. \(\square\)

**The important qualification:** this concerns *passively receiving* information about a state that remains unchanged. An actual conversation is an action. Asking, listening, meeting, and testing a reaction may influence what is being evaluated (§6.8).

### Example C4 — A more informative encounter can have a lower total value

Suppose a person may either make a guess without probing or conduct a perfectly informative probe. In an illustrative model, a correct guess gives 1 point, while the relation-specific component gives **2 points without probing** and **0 with probing**. The probability of a correct unprobed guess is \(1/2\).

- Without probing: \(1/2+2=2.5\).
- With a perfect probe: \(1+0=1\).

**Why it works.** The probe improves factual accuracy but incurs a stipulated relational cost larger than that improvement. The numerical comparison is immediate.

**What it does not prove.** Those relational payoffs are **assumed for the example**, not observed effects of asking questions. This is not advice to avoid difficult conversations; it is a counterexample to the inference that “more information must always make every encounter better.”

### Example C5 — The same two individual profiles need not determine the same relational outcome

Imagine two possible histories with identical final individual profiles \(x_A,x_B\), but different relationship-specific outcomes, \(r=0\) and \(r=1\).

**Claim.** There cannot be an **exact deterministic** function \(r=f(x_A,x_B)\) that fits both histories.

**Proof.** Equal inputs to a function must have equal outputs, but the constructed histories require unequal outputs. \(\square\)

This does **not** say individual traits are useless for probabilistic prediction. It says that when different interaction histories matter, a list of individual traits alone may not be a sufficient summary.

### Theorem 6.2 — When is a summary enough for exact prediction?

For allowed histories \(h\), let \(S(h)\) be a summary (perhaps the two profiles) and \(R(h)\) a binary relational outcome.

There is an exact predictor \(f\) with \(R(h)=f(S(h))\) for every allowed history **if and only if**:

> Whenever two histories have the same summary, they have the same outcome.

**Proof.** If \(f\) exists, equal summaries must be mapped to equal outcomes. Conversely, if every group of histories sharing a summary has the same outcome, define \(f\) to return that outcome on the group's summary. Set it arbitrarily for summaries that never occur. \(\square\)

This theorem states the **precise condition** under which a profile-only explanation suffices. It does not claim that all relationship histories violate that condition.

### Example C6 — One life does not reveal every unchosen alternative

Suppose models M and N agree about the outcome of an action \(a_0\), which was actually chosen. They disagree about the unchosen action \(a_1\): M predicts 1, N predicts 0.

**Proof of non-identification from the actual observation alone.** Both models fit the observed \(a_0\) outcome equally, yet assign different outcomes to \(a_1\). The observation alone therefore cannot identify the unchosen result (§§6.41–6.43). Other observations, assumptions, or experiments could sometimes help.

### §6.93 — An observed change does not identify the mechanism

> **§6.93.** “An observed change after a meeting is not enough to tell whether something previously hidden has been revealed or something new has come into being.”

Let a latent state be binary, and suppose a proportion \(m\) of people moves **only** from 0 to 1. The measured yes/no report has a constant response mechanism: \(c_0\) is the chance of a positive report in latent state 0, and \(c_1\) that chance in state 1. Write \(q=c_1-c_0\).

If the initial share in state 1 is \(p\), the initial positive-report rate is \(y_0=c_0+pq\); after the one-way movement it is \(y_1=c_0+(p+m)q\). Subtracting gives

\[
\Delta:=y_1-y_0=mq.
\]

**Proof.** Subtract the two preceding expressions and simplify. \(\square\)

The formula says that an observable report difference is the product of **the amount of latent movement** and **how well the report differentiates the latent states**. Observing \(\Delta\) alone does not in general reveal \(m\).

**A conditional sharp bound (I1).** Assume \(0<p<1\), \(\Delta>0\), an invariant positively oriented but uncalibrated binary reporting channel, a comparable population at both times, one-way latent movement, and observed rates compatible with these assumptions. Define

\[
q_{\max}=\min\left(\frac{y_0}{p},\frac{1-y_0}{1-p}\right).
\]

Then

\[
\boxed{\frac{\Delta}{q_{\max}}\le m\le1-p.}
\]

**Proof sketch.** Nonnegative reporting probabilities imply \(q\le y_0/p\) and \(q\le(1-y_0)/(1-p)\). Thus \(q\le q_{\max}\), and since \(\Delta=mq\), \(m\ge\Delta/q_{\max}\). At most the original share \(1-p\) in state 0 can move. Conversely, for any \(m\) in this interval, choose \(q=\Delta/m\), \(c_0=y_0-pq\), and \(c_1=c_0+q\). These values respect the stipulated probability bounds and reproduce both report rates, making the interval **sharp within this restricted model**. \(\square\)

**Numerical example.** For \(p=1/4\), \(y_0=3/8\), and \(y_1=5/8\), the interval is \(3/10\le m\le3/4\). Even with these assumptions, the exact amount of movement remains unknown.

These identification results do **not** survive unchanged if reporting behavior changes, participant groups differ, the transition runs in both directions, or the binary model is inadequate. They are a disciplined illustration of §6.93, not evidence that a specific interpersonal change has one particular cause.

## 7. What the model can say, and what it cannot

> **§7.** “We can know a great deal about someone. But as we get to know each other, some things come into view, some take shape for the first time, and some remain unknown. Words do not always exhaust what we experience together.”

The preceding constructions identify different limits:

- A picture is not identical to the person pictured.
- Several explanations may fit the same observed history.
- A decision can sometimes be made without resolving every uncertainty.
- A changed report may reflect discovery, formation, expression, or a combination.
- Consent requires two independent participants, not one convincing description.
- Encounters can change the relation being considered, so learning is not always passive.
- One actual history does not by itself establish what would have happened along every alternative path.

These are **conditional logical distinctions**. They cannot tell us who a particular person “really is,” whether someone should marry someone else, or that meaningful experiences must be ineffable.

The mathematical model is useful precisely when it knows where to stop. Equations may tell us which conclusion follows from which premise. They are not a substitute for the living people, the choices they make, and the history they actually share.

---

## A reader's guide to the evidence

This is a map of **what kind of support** each mathematical passage provides; it is not a list of experimentally established relationship laws.

| Source propositions | Companion device | What it establishes under its assumptions |
| --- | --- | --- |
| §§1.4, 6.51 | C1, shared-signal example | One event need not supply equal information |
| §2.61 | T2, history-likelihood argument | More observations do not distinguish observationally equivalent hypotheses |
| §§2.7–2.72 | T3, fixed-decision theorem | Perfect information may add no decision value |
| §3.23 | C2, alternate reporting mechanisms | Report changes alone need not identify preference changes |
| §§4.61–4.62 | C3, silence example | One response need not uniquely determine intention |
| §§5.3–5.32 | D1, definition of voluntary joint action | Both participants' willingness is necessary |
| §5.3 | T4, probability bounds | Individual willingness rates need not determine a joint rate |
| §§6.8, 6.63 | T5 and C4 | A passive information theorem need not apply to relational intervention |
| §§6.64, 6.92 | C5 and exact-predictor criterion | History may matter beyond a profile summary |
| §§6.41–6.43 | C6, unchosen-action construction | One observed path may not identify an alternative |
| §6.93 | I1, restricted binary reporting model | Observed reports may only partly identify latent change |
| §7 | Philosophical conclusion | Not a mathematical theorem |

**Proof status.** The repository's Lean 4 modules formally check selected **finite and deterministic** components—bit identities, Boolean willingness conditions, algebraic bounds, history-sensitive examples, and restricted identification constructions. They do not formally establish the complete probabilistic narrative or verify any psychological generalization. No Lean source has been changed for this companion version. The technical draft and proof audit remain the appropriate places to inspect full assumptions and exact theorem correspondence.

**Further reading within this repository:** the [technical mathematical draft v0.2](../paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md), [index of all 116 active propositions](../paper/PROPOSITION_INDEX.md), [dynamics notes](../notes/DYNAMICS_ADDENDUM.md), [identification and sensitivity notes](../notes/IDENTIFICATION_SENSITIVITY.md), [edition and proof-alignment audit](../COMPANION_ALIGNMENT_v1.1.0.md), and [Lean modules](../lean/).

## Closing thought

The *Tractatus* does not merely ask, “How much do I know about you?” It also asks:

**What do I actually know, what am I merely assuming, what changes through our encounters, and what can the two of us genuinely choose together?**

The mathematics does not finish that question. It makes the question harder to misunderstand.
