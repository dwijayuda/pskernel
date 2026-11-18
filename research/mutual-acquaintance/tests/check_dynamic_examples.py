"""Independent, finite consistency checks for the Boolean witness in Lean v0.2.

This executable Python model is NOT Lean kernel verification, and it does not
validate the behavioral assumptions about real people. The exercise checks
closed examples and the profile-predictor obstruction for short histories.
"""
from dataclasses import dataclass, replace
from itertools import product

@dataclass(frozen=True)
class State:
    traitA: bool = False
    traitB: bool = False
    beliefA: bool = False
    beliefB: bool = False
    preferenceA: bool = False
    preferenceB: bool = False
    relation: bool = False

@dataclass(frozen=True)
class Event:
    a: bool
    b: bool
    shock: bool = False

LISTEN = Event(True, False)
ACT = Event(True, True)
NONE = Event(False, False)
SHOCK = Event(False, False, True)
EVENTS = tuple(Event(a,b,k) for a,b,k in product((False,True),repeat=3))
INITIAL = State()

def step(s:State, e:Event) -> State:
    obs_a=e.a and not e.b
    return State(
       traitA=s.traitA,traitB=s.traitB,
       beliefA=True if obs_a else s.beliefA,
       beliefB=s.beliefB,
       preferenceA=not s.preferenceA if e.shock else s.preferenceA,
       preferenceB=s.preferenceB,
       relation=s.beliefA if (e.a and e.b) else s.relation
    )

def run(s, history):
    for e in history:s=step(s,e)
    return s

def profile(s):
    return (s.traitA,s.traitB,s.beliefA,s.beliefB,s.preferenceA,s.preferenceB)

before=run(INITIAL,[LISTEN,ACT]); after=run(INITIAL,[ACT,LISTEN])
assert before.beliefA and after.beliefA
assert profile(before)==profile(after)
assert before.relation and not after.relation
assert run(INITIAL,[LISTEN,ACT])!=run(INITIAL,[ACT,LISTEN])

assert step(INITIAL,LISTEN).beliefA != INITIAL.beliefA
assert step(INITIAL,LISTEN).relation == INITIAL.relation
informed=replace(INITIAL,beliefA=True)
assert step(informed, ACT).relation != informed.relation
assert step(informed, ACT).beliefA == informed.beliefA
assert step(informed, ACT).beliefB == informed.beliefB
assert step(INITIAL,SHOCK).preferenceA != INITIAL.preferenceA
assert step(INITIAL,SHOCK).relation == INITIAL.relation

# Enumerate histories through length 3 and test prefix associativity,
# preservation of traits and response to current signal/belief.
checked = 0
for n in range(4):
    for history in product(EVENTS,repeat=n):
        full=run(INITIAL,history)
        assert full.traitA==INITIAL.traitA and full.traitB==INITIAL.traitB
        for p in range(n+1):
            assert run(INITIAL,history) == run(run(INITIAL,history[:p]),history[p:])
            checked+=1

# The same full individual profile maps to opposite relational values.
profiles = {}
for n in range(4):
    for history in product(EVENTS,repeat=n):
        s=run(INITIAL,history)
        profiles.setdefault(profile(s),set()).add(s.relation)
assert any(values=={False,True} for values in profiles.values())

# Toy countermodel: a probe is informative, but stipulated harm makes the
# weighted sum lower than if no probe occurs.
def probe_step(s:State,e:Event)->State:
    observation=e.a and not e.b
    return replace(s,
        beliefA=True if observation else s.beliefA,
        relation=False if observation else s.relation)

def score(s:State):return int(s.beliefA)+2*int(s.relation)
present=replace(INITIAL,relation=True)
assert probe_step(present,LISTEN).beliefA
assert score(probe_step(present,LISTEN)) < score(probe_step(present,NONE))

print('PASS Boolean witness and profile obstruction')
print('PASS independent learning, preference, and relationship transitions')
print(f'PASS {checked:,} prefix-composition and stable-trait finite checks')
print(f'PASS {len(profiles)} reachable individual profiles, incl. ambiguous relational outcomes')
print('PASS stipulated active-information counterexample')
print('WARNING: Python is NOT Lean 4 kernel verification.')
