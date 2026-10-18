import Ps.Host.NativeV7
import Lean.Util.CollectAxioms

-- Independent pinned Lean definitions. The portable compiler consumes the
-- distinct .ps source below; neither side uses the other's elaborated body.
namespace M3WellFoundedOracle

def skip (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => skip (k - 1) + 1
termination_by n
decreasing_by exact Nat.lt_succ_of_le (Nat.sub_le _ _)

theorem skip_step (k : Nat) : skip (Nat.succ k) = skip (k - 1) + 1 :=
  skip.eq_def (Nat.succ k)

def branches (n : Nat) : Nat :=
  match n with
  | 0 => 1
  | k + 1 => branches (k - 1) + branches k
termination_by n
decreasing_by
  · exact Nat.lt_succ_of_le (Nat.sub_le _ _)
  · exact Nat.lt_succ_self _

def shiftedMeasure (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => shiftedMeasure (k - 1) + 1
termination_by n + 1
decreasing_by exact Nat.succ_le_succ (Nat.succ_le_succ (Nat.sub_le _ _))

def defaultDecrease (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => defaultDecrease k + 1
termination_by n

-- Header order deliberately interleaves changing state, the measured
-- argument, and fixed parameters. These use Lean's independent WF elaborator.
def accumulate (acc n step : Nat) : Nat :=
  match n with
  | 0 => acc
  | k + 1 => accumulate (acc + step) (k - 1) step
termination_by n
decreasing_by exact Nat.lt_succ_of_le (Nat.sub_le _ _)

def offset (acc n step : Nat) : Nat :=
  match n with
  | 0 => acc
  | k + 1 => offset (acc + step) (k - 1) ((fun (x : Nat) => x) step)
termination_by n + step
decreasing_by exact Nat.add_lt_add_right (Nat.lt_succ_of_le (Nat.sub_le _ _)) step

theorem offset_step (acc k step : Nat) :
    offset acc (Nat.succ k) step = offset (acc + step) (k - 1) step :=
  offset.eq_def acc (Nat.succ k) step

def twoStates (left n right step : Nat) : Nat :=
  match n with
  | 0 => left + right
  | k + 1 => twoStates (left + step) (k - 1) (right + left) step
termination_by n
decreasing_by exact Nat.lt_succ_of_le (Nat.sub_le _ _)

def fixedOnly (step n : Nat) : Nat :=
  match n with
  | 0 => step
  | k + 1 => fixedOnly ((fun (x : Nat) => x) step) (k - 1)
termination_by n + step
decreasing_by exact Nat.add_lt_add_right (Nat.lt_succ_of_le (Nat.sub_le _ _)) step

universe u

-- The domain, state and result live at their real universe levels. The
-- reversal result is inspected in order, rather than merely by its length.
def reverseList (A : Type u) (acc xs : List A) : List A :=
  match xs with
  | [] => acc
  | head :: tail => reverseList A (head :: acc) tail
termination_by xs.length
decreasing_by exact Nat.lt_succ_self _

def digest : List Nat → Nat
  | [] => 0
  | head :: tail => head + 10 * digest tail

-- seed is a body lambda, not a declared termination-measure parameter.
def iterate (step : Nat → Nat) (n : Nat) : Nat → Nat :=
  fun seed => match n with
    | 0 => step seed
    | k + 1 => iterate step (k - 1) (step seed)
termination_by n
decreasing_by exact Nat.lt_succ_of_le (Nat.sub_le _ _)

-- family is an erased index; p and h retain ordinary proof Unit slots.
-- The changing Fin state must be specialized to the smaller n at each call.
def dependentState (family : Nat → Type u) (p : Prop) (h : p)
    (n : Nat) (acc : Fin (n + 1)) : Nat :=
  match n with
  | 0 => acc.val
  | k + 1 => acc.val + dependentState family p h (k - 1)
      ⟨k - 1, Nat.lt_succ_self (k - 1)⟩
termination_by n
decreasing_by exact Nat.lt_succ_of_le (Nat.sub_le _ _)

def bounded (n : Nat) : Fin (n + 1) :=
  match n with
  | 0 => ⟨0, Nat.zero_lt_succ 0⟩
  | k + 1 =>
    let child := bounded k
    ⟨child.val + 1, Nat.succ_lt_succ child.isLt⟩
termination_by n
decreasing_by exact Nat.lt_succ_self _

theorem bounded_step (k : Nat) :
    (bounded (Nat.succ k)).val = (bounded k).val + 1 :=
  congrArg (fun (value : Fin (Nat.succ k + 1)) => value.val)
    (bounded.eq_def (Nat.succ k))

-- Both real lexicographic constructors solve their distinct native decrease
-- goals. Only n is measured; acc remains changing state of the unary domain.
def relationLeft (acc n step : Nat) : Nat :=
  match n with
  | 0 => acc
  | k + 1 => relationLeft (acc + step) (k - 1) step
termination_by (n, 0)
decreasing_by exact Prod.Lex.left 0 0 (Nat.lt_succ_of_le (Nat.sub_le _ _))

theorem relationLeft_step (acc k step : Nat) :
    relationLeft acc (Nat.succ k) step = relationLeft (acc + step) (k - 1) step :=
  relationLeft.eq_def acc (Nat.succ k) step

def relationRight (n : Nat) : Nat :=
  match n with
  | 0 => 1
  | k + 1 => relationRight k + 2
termination_by (0, n)
decreasing_by exact Prod.Lex.right 0 (Nat.lt_succ_self _)

theorem relationRight_step (k : Nat) :
    relationRight (Nat.succ k) = relationRight k + 2 :=
  relationRight.eq_def (Nat.succ k)

-- Both changing slots occur in the fixed Nat × Nat measure. Fixed values,
-- erased family and proof slots remain outside Lean's dependent argument pack.
def packed (family : Nat → Type u) (p : Prop) (h : p)
    (n step : Nat) (acc : Fin (n + 1)) : Nat :=
  match n with
  | 0 => acc.val + step
  | k + 1 => acc.val + packed family p h (k - 1) step
      ⟨k - 1, Nat.lt_succ_self (k - 1)⟩
termination_by (n, acc.val)
decreasing_by exact Prod.Lex.left (k - 1) acc.val (Nat.lt_succ_of_le (Nat.sub_le k 1))

theorem packed_step (family : Nat → Type u) (p : Prop) (h : p)
    (k step : Nat) (acc : Fin (Nat.succ k + 1)) :
    packed family p h (Nat.succ k) step acc =
      acc.val + packed family p h (k - 1) step
        ⟨k - 1, Nat.lt_succ_self (k - 1)⟩ :=
  packed.eq_def family p h (Nat.succ k) step acc

-- The packed motive depends on its first projection. This checks real
-- dependent callback equality and the public equation, beyond a Nat result.
def packedBounded (n : Nat) (acc : Fin (n + 1)) : Fin (n + 1) :=
  match n with
  | 0 => acc
  | k + 1 =>
    let child := packedBounded k ⟨0, Nat.zero_lt_succ k⟩
    ⟨child.val + 1, Nat.succ_lt_succ child.isLt⟩
termination_by (n, acc.val)
decreasing_by exact Prod.Lex.left 0 acc.val (Nat.lt_succ_self k)

theorem packedBounded_step (k : Nat) (acc : Fin (Nat.succ k + 1)) :
    (packedBounded (Nat.succ k) acc).val =
      (packedBounded k ⟨0, Nat.zero_lt_succ k⟩).val + 1 :=
  congrArg (fun (value : Fin (Nat.succ k + 1)) => value.val)
    (packedBounded.eq_def (Nat.succ k) acc)

-- Independent changing fields use the same PSigma encoding with a constant
-- second family. Erased captures and the fixed step stay outside the pair.
def independentLeft (family : Nat → Type u) (p : Prop) (h : p)
    (n step right : Nat) : Nat :=
  match n with
  | 0 => right + step
  | k + 1 => right + independentLeft family p h (k - 1) step (right + 1)
termination_by (n, right)
decreasing_by exact Prod.Lex.left (right + 1) right (Nat.lt_succ_of_le (Nat.sub_le k 1))

theorem independentLeft_step (family : Nat → Type u) (p : Prop) (h : p)
    (k step right : Nat) :
    independentLeft family p h (Nat.succ k) step right =
      right + independentLeft family p h (k - 1) step (right + 1) :=
  independentLeft.eq_def family p h (Nat.succ k) step right

-- Both coordinates change across the complete function. Right steps preserve
-- the first coordinate; a left step resets the second to the fixed step.
def independentRight (bias left step right : Nat) : Nat :=
  match left with
  | 0 =>
    match right with
    | 0 => bias
    | k + 1 => independentRight bias 0 step k + step
  | j + 1 =>
    match right with
    | 0 => independentRight bias j step step
    | k + 1 => independentRight bias (j + 1) step k + step
termination_by (left, right)
decreasing_by
  · exact Prod.Lex.right 0 (Nat.lt_succ_self k)
  · exact Prod.Lex.left step 0 (Nat.lt_succ_self j)
  · exact Prod.Lex.right (j + 1) (Nat.lt_succ_self k)

theorem independentRight_step (bias j step k : Nat) :
    independentRight bias (Nat.succ j) step (Nat.succ k) =
      independentRight bias (Nat.succ j) step k + step :=
  independentRight.eq_def bias (Nat.succ j) step (Nat.succ k)

theorem independentRight_reset (bias j step : Nat) :
    independentRight bias (Nat.succ j) step 0 =
      independentRight bias j step step :=
  independentRight.eq_def bias (Nat.succ j) step 0


-- The measured dependent pair stays separate from a changing leading state.
-- The fixed bias between the packed slots must retain its original position.
def packedState (total n bias : Nat) (acc : Fin (n + 1)) : Nat :=
  match n with
  | 0 => total + bias + acc.val
  | k + 1 => packedState (total + acc.val + 1) k bias ⟨0, Nat.zero_lt_succ k⟩
termination_by (n, acc.val)
decreasing_by exact Prod.Lex.left 0 acc.val (Nat.lt_succ_self k)

theorem packedState_step (total k bias : Nat) (acc : Fin (Nat.succ k + 1)) :
    packedState total (Nat.succ k) bias acc =
      packedState (total + acc.val + 1) k bias ⟨0, Nat.zero_lt_succ k⟩ :=
  packedState.eq_def total (Nat.succ k) bias acc

-- The formerly unsupported second-slot measure must still refuse the
-- recursive call with n = 1, i = 0: packing cannot turn 0 < 0 into a proof.
theorem packed_zero_does_not_decrease : ¬ (0 : Nat) < 0 := Nat.not_lt_zero 0

-- Pinned Main handles genuine nonrecursive definitions before unused hints.
-- The unused section variable must not become an extra declared parameter.
section
variable (unused : Nat)
def unusedWF (n : Nat) : Nat := n
termination_by unused

def unusedP1 (n : Nat) : Nat := n
partial_fixpoint
end

theorem unusedWF_step (n : Nat) : unusedWF n = n := rfl
theorem unusedP1_step (n : Nat) : unusedP1 n = n := rfl

run_cmd do
  for name in #[``WellFounded.Nat.fix, ``WellFounded.Nat.fix_eq,
      ``WellFounded.fix, ``WellFounded.fix_eq,
      ``skip, ``skip_step, ``branches, ``shiftedMeasure, ``defaultDecrease,
      ``accumulate, ``offset, ``offset_step, ``twoStates, ``fixedOnly,
      ``reverseList, ``digest, ``iterate, ``dependentState, ``bounded, ``bounded_step,
      ``relationLeft, ``relationLeft_step, ``relationRight, ``relationRight_step,
      ``packed, ``packed_step, ``packedBounded, ``packedBounded_step,
      ``independentLeft, ``independentLeft_step,
      ``independentRight, ``independentRight_step, ``independentRight_reset,
      ``packedState, ``packedState_step,
      ``packed_zero_does_not_decrease,
      ``unusedWF, ``unusedP1, ``unusedWF_step, ``unusedP1_step] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "WF oracle uses an unapproved assumption: {name}: {axioms}"
    Lean.logInfo m!"PSCV0_M3_WF_ASSUMPTIONS: {name}: {axioms}"
  let environment ← Lean.getEnv
  for name in [``unusedWF, ``unusedP1] do
    match environment.find? name with
    | some (.defnInfo _) => pure ()
    | _ => throwError "an unused hint changed the native nonrecursive declaration kind: {name}"

-- Three changing fields, including a dependent last field, interleave a
-- fixed capture. Four fields additionally retain an evolving unmeasured state.
def packedThree (total n bias : Nat) (i : Fin (n + 1)) : Nat :=
  match n with
  | 0 => total + i.val
  | k + 1 => packedThree (total + bias) k bias ⟨0, Nat.zero_lt_succ k⟩
termination_by (n, i.val + total)
decreasing_by exact Prod.Lex.left _ _ (Nat.lt_succ_self _)

def packedFour (acc n left right bias : Nat) (i : Fin (n + 1)) : Nat :=
  match n with
  | 0 => acc + left + right + i.val
  | k + 1 => packedFour (acc + 1) k (left + bias) (right + left) bias
      ⟨0, Nat.zero_lt_succ k⟩
termination_by (n, i.val + left + right)
decreasing_by exact Prod.Lex.left _ _ (Nat.lt_succ_self _)

theorem packedThree_step (total k bias : Nat) (i : Fin (Nat.succ k + 1)) :
    packedThree total (Nat.succ k) bias i =
      packedThree (total + bias) k bias ⟨0, Nat.zero_lt_succ k⟩ :=
  packedThree.eq_def total (Nat.succ k) bias i


-- The ordinary application telescope also owns recursive implicit, instance,
-- named and dependent-default arguments. These use Lean's own elaborator.
def genericArgs {A : Type u} [Inhabited A] (seed : A) (n : Nat) (acc : Nat := 0) : A :=
  match n with
  | 0 => if acc == 0 then Inhabited.default else seed
  | k + 1 => genericArgs (n := k) (acc := acc + 1) (seed := seed)
termination_by n
decreasing_by exact Nat.lt_succ_self _

def defaultReset (n : Nat) (acc : Nat := n + 7) : Nat :=
  match n with
  | 0 => acc
  | k + 1 => defaultReset (n := k)
termination_by n
decreasing_by exact Nat.lt_succ_self _

def implicitMajor {n : Nat} (seed : Fin (n + 1)) : Nat :=
  match n with
  | 0 => seed.val
  | k + 1 => seed.val + implicitMajor (seed := ⟨0, Nat.zero_lt_succ k⟩) (n := k)
termination_by n
decreasing_by exact Nat.lt_succ_self _

theorem defaultReset_step (k acc : Nat) :
    defaultReset (Nat.succ k) acc = defaultReset (n := k) :=
  defaultReset.eq_def (Nat.succ k) acc

run_cmd do
  for name in [``packedThree, ``packedFour, ``packedThree_step,
      ``genericArgs, ``defaultReset, ``implicitMajor, ``defaultReset_step] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "WF oracle uses an unapproved assumption: {name}: {axioms}"
    Lean.logInfo m!"PSCV0_M3_WF_ASSUMPTIONS: {name}: {axioms}"

end M3WellFoundedOracle

private def unusedHintSource : String :=
  "section\nvariable (unused: Nat)\n" ++
  "function m3wfunused(n: Nat): Nat := n\ntermination_by unused\n" ++
  "function m3p1unused(n: Nat): Nat := n\npartial_fixpoint\nend\n" ++
  "theorem unusedWFEquation(n: Nat): m3wfunused(n) = n := by { exact m3wfunused.eq_def(n) }\n" ++
  "theorem unusedP1Equation(n: Nat): m3p1unused(n) = n := by { exact m3p1unused.eq_def(n) }\n"

private def skipSource : String :=
  "function m3wfskip(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => m3wfskip(k - 1) + 1 }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n"

private def branchBody : String :=
  "function m3wfbranches(n: Nat): Nat := match n with { | 0 => 1 | k + 1 => m3wfbranches(k - 1) + m3wfbranches(k) }\n" ++
  "termination_by n\n"

private def scopeSource : String :=
  "namespace M3WFScope\n" ++
  "private theorem bound(k: Nat): Nat.lt(k - 1, Nat.succ(k)) := by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n" ++
  "private function loop(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => loop(k - 1) + 1 }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact bound(k) }\n" ++
  "function use(n: Nat): Nat := loop(n)\n" ++
  "end M3WFScope\n"

private def parameterSource : String :=
  "function m3wfaccumulate(acc: Nat, n: Nat, step: Nat): Nat := match n with { | 0 => acc | k + 1 => m3wfaccumulate(acc + step, k - 1, step) }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n" ++
  "function m3wfoffset(acc: Nat, n: Nat, step: Nat): Nat := match n with { | 0 => acc | k + 1 => m3wfoffset(acc + step, k - 1, (fun (x: Nat) => x)(step)) }\n" ++
  "termination_by n + step\n" ++
  "decreasing_by by { exact Nat.add_lt_add_right(Nat.lt_succ_of_le(Nat.sub_le(k, 1)), step) }\n" ++
  "theorem m3wfoffsetStep(acc: Nat, k: Nat, step: Nat): m3wfoffset(acc, Nat.succ(k), step) = m3wfoffset(acc + step, k - 1, step) := by { exact m3wfoffset.eq_def(acc, Nat.succ(k), step) }\n" ++
  "function m3wfstates(left: Nat, n: Nat, right: Nat, step: Nat): Nat := match n with { | 0 => left + right | k + 1 => m3wfstates(left + step, k - 1, right + left, step) }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n" ++
  "function m3wffixed(step: Nat, n: Nat): Nat := match n with { | 0 => step | k + 1 => m3wffixed((fun (x: Nat) => x)(step), k - 1) }\n" ++
  "termination_by n + step\n" ++
  "decreasing_by by { exact Nat.add_lt_add_right(Nat.lt_succ_of_le(Nat.sub_le(k, 1)), step) }\n"

private def typedSource : String :=
  "universe u v\n" ++
  "function m3wfreverse(A: Type u, acc: List A, xs: List A): List A := match xs with { | .nil => acc | .cons head tail => m3wfreverse(A, List.cons(head, acc), tail) }\n" ++
  "termination_by List.length(xs)\n" ++
  "decreasing_by by { exact Nat.lt_succ_self(List.length(tail)) }\n" ++
  "function m3wfdigest(xs: List Nat): Nat := match xs with { | .nil => 0 | .cons head tail => head + 10 * m3wfdigest(tail) }\n" ++
  "function m3wfiterate(step: Nat -> Nat, n: Nat): Nat -> Nat := fun (seed: Nat) => match n with { | 0 => step(seed) | k + 1 => m3wfiterate(step, k - 1)(step(seed)) }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n" ++
  "theorem m3wfiterateStep(step: Nat -> Nat, k: Nat): m3wfiterate(step, Nat.succ(k)) = (fun (seed: Nat) => m3wfiterate(step, k - 1)(step(seed))) := by { exact m3wfiterate.eq_def(step, Nat.succ(k)) }\n" ++
  "function m3wfdependent(family: Nat -> Type u, p: Prop, h: p, n: Nat, acc: Fin(n + 1)): Nat := match n with { | 0 => Fin.val(acc) | k + 1 => Fin.val(acc) + m3wfdependent(family, p, h, k - 1, Fin.mk(k - 1, Nat.lt_succ_self(k - 1))) }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n" ++
  "function m3wfbounded(n: Nat): Fin(n + 1) := match n with {\n" ++
  "  | 0 => Fin.mk(0, Nat.zero_lt_succ(0))\n" ++
  "  | k + 1 =>\n" ++
  "    let child: Fin(k + 1) := m3wfbounded(k)\n" ++
  "    Fin.mk(Fin.val(child) + 1, Nat.succ_le_succ(Fin.isLt(child)))\n" ++
  "}\ntermination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_self(k) }\n" ++
  "theorem m3wfboundedStep(k: Nat): Fin.val(m3wfbounded(Nat.succ(k))) = Fin.val(m3wfbounded(k)) + 1 := by { exact congrArg((fun (value: Fin(Nat.succ(k) + 1)) => Fin.val(value)), m3wfbounded.eq_def(Nat.succ(k))) }\n"

private def relationSource : String :=
  "function m3wfrelationLeft(acc: Nat, n: Nat, step: Nat): Nat := match n with { | 0 => acc | k + 1 => m3wfrelationLeft(acc + step, k - 1, step) }\n" ++
  "termination_by Prod.mk(n, 0)\n" ++
  "decreasing_by by { exact Prod.Lex.left(0, 0, Nat.lt_succ_of_le(Nat.sub_le(k, 1))) }\n" ++
  "theorem m3wfrelationLeftStep(acc: Nat, k: Nat, step: Nat): m3wfrelationLeft(acc, Nat.succ(k), step) = m3wfrelationLeft(acc + step, k - 1, step) := by { exact m3wfrelationLeft.eq_def(acc, Nat.succ(k), step) }\n" ++
  "function m3wfrelationRight(n: Nat): Nat := match n with { | 0 => 1 | k + 1 => m3wfrelationRight(k) + 2 }\n" ++
  "termination_by Prod.mk(0, n)\n" ++
  "decreasing_by by { exact Prod.Lex.right(0, Nat.lt_succ_self(k)) }\n" ++
  "theorem m3wfrelationRightStep(k: Nat): m3wfrelationRight(Nat.succ(k)) = m3wfrelationRight(k) + 2 := by { exact m3wfrelationRight.eq_def(Nat.succ(k)) }\n"

private def packingSource : String :=
  "function m3wfpacked(family: Nat -> Type u, p: Prop, h: p, n: Nat, step: Nat, acc: Fin(n + 1)): Nat := match n with { | 0 => Fin.val(acc) + step | k + 1 => Fin.val(acc) + m3wfpacked(family, p, h, k - 1, step, Fin.mk(k - 1, Nat.lt_succ_self(k - 1))) }\n" ++
  "termination_by Prod.mk(n, Fin.val(acc))\n" ++
  "decreasing_by by { exact Prod.Lex.left(k - 1, Fin.val(acc), Nat.lt_succ_of_le(Nat.sub_le(k, 1))) }\n" ++
  "theorem m3wfpackedStep(family: Nat -> Type u, p: Prop, h: p, k: Nat, step: Nat, acc: Fin(Nat.succ(k) + 1)): m3wfpacked(family, p, h, Nat.succ(k), step, acc) = Fin.val(acc) + m3wfpacked(family, p, h, k - 1, step, Fin.mk(k - 1, Nat.lt_succ_self(k - 1))) := by { exact m3wfpacked.eq_def(family, p, h, Nat.succ(k), step, acc) }\n" ++
  "function m3wfpackedBounded(n: Nat, acc: Fin(n + 1)): Fin(n + 1) := match n with {\n" ++
  "  | 0 => acc\n" ++
  "  | k + 1 =>\n" ++
  "    let child: Fin(k + 1) := m3wfpackedBounded(k, Fin.mk(0, Nat.zero_lt_succ(k)))\n" ++
  "    Fin.mk(Fin.val(child) + 1, Nat.succ_le_succ(Fin.isLt(child)))\n" ++
  "}\ntermination_by Prod.mk(n, Fin.val(acc))\n" ++
  "decreasing_by by { exact Prod.Lex.left(0, Fin.val(acc), Nat.lt_succ_self(k)) }\n" ++
  "theorem m3wfpackedBoundedStep(k: Nat, acc: Fin(Nat.succ(k) + 1)): Fin.val(m3wfpackedBounded(Nat.succ(k), acc)) = Fin.val(m3wfpackedBounded(k, Fin.mk(0, Nat.zero_lt_succ(k)))) + 1 := by { exact congrArg((fun (value: Fin(Nat.succ(k) + 1)) => Fin.val(value)), m3wfpackedBounded.eq_def(Nat.succ(k), acc)) }\n"

private def independentSource : String :=
  "function m3wfindependentLeft(family: Nat -> Type u, p: Prop, h: p, n: Nat, step: Nat, right: Nat): Nat := match n with { | 0 => right + step | k + 1 => right + m3wfindependentLeft(family, p, h, k - 1, step, right + 1) }\n" ++
  "termination_by Prod.mk(n, right)\n" ++
  "decreasing_by by { exact Prod.Lex.left(right + 1, right, Nat.lt_succ_of_le(Nat.sub_le(k, 1))) }\n" ++
  "theorem m3wfindependentLeftStep(family: Nat -> Type u, p: Prop, h: p, k: Nat, step: Nat, right: Nat): m3wfindependentLeft(family, p, h, Nat.succ(k), step, right) = right + m3wfindependentLeft(family, p, h, k - 1, step, right + 1) := by { exact m3wfindependentLeft.eq_def(family, p, h, Nat.succ(k), step, right) }\n" ++
  "function m3wfindependentRight(bias: Nat, left: Nat, step: Nat, right: Nat): Nat := match left with {\n" ++
  "  | 0 => match right with { | 0 => bias | k + 1 => m3wfindependentRight(bias, 0, step, k) + step }\n" ++
  "  | j + 1 => match right with { | 0 => m3wfindependentRight(bias, j, step, step) | k + 1 => m3wfindependentRight(bias, j + 1, step, k) + step }\n" ++
  "}\ntermination_by Prod.mk(left, right)\n" ++
  "decreasing_by by {\n" ++
  "  · exact Prod.Lex.right(0, Nat.lt_succ_self(k))\n" ++
  "  · exact Prod.Lex.left(step, 0, Nat.lt_succ_self(j))\n" ++
  "  · exact Prod.Lex.right(j + 1, Nat.lt_succ_self(k))\n" ++
  "}\n" ++
  "theorem m3wfindependentRightStep(bias: Nat, j: Nat, step: Nat, k: Nat): m3wfindependentRight(bias, Nat.succ(j), step, Nat.succ(k)) = m3wfindependentRight(bias, Nat.succ(j), step, k) + step := by { exact m3wfindependentRight.eq_def(bias, Nat.succ(j), step, Nat.succ(k)) }\n" ++
  "theorem m3wfindependentRightReset(bias: Nat, j: Nat, step: Nat): m3wfindependentRight(bias, Nat.succ(j), step, 0) = m3wfindependentRight(bias, j, step, step) := by { exact m3wfindependentRight.eq_def(bias, Nat.succ(j), step, 0) }\n"

private def packingStateSource : String :=
  "function m3wfpackedState(total: Nat, n: Nat, bias: Nat, acc: Fin(n + 1)): Nat := match n with {\n" ++
  "  | 0 => total + bias + Fin.val(acc)\n" ++
  "  | k + 1 => m3wfpackedState(total + Fin.val(acc) + 1, k, bias, Fin.mk(0, Nat.zero_lt_succ(k)))\n" ++
  "}\n" ++
  "termination_by Prod.mk(n, Fin.val(acc))\n" ++
  "decreasing_by by { exact Prod.Lex.left(0, Fin.val(acc), Nat.lt_succ_self(k)) }\n" ++
  "theorem m3wfpackedStateStep(total: Nat, k: Nat, bias: Nat, acc: Fin(Nat.succ(k) + 1)): m3wfpackedState(total, Nat.succ(k), bias, acc) = m3wfpackedState(total + Fin.val(acc) + 1, k, bias, Fin.mk(0, Nat.zero_lt_succ(k))) := by { exact m3wfpackedState.eq_def(total, Nat.succ(k), bias, acc) }\n"

private def narySource : String :=
  "function packedThree(total: Nat, n: Nat, bias: Nat, i: Fin(n + 1)): Nat := match n with { | 0 => total + i.val | k + 1 => packedThree(total + bias, k, bias, Fin.mk(0, Nat.zero_lt_succ(k))) }\n" ++
  "termination_by Prod.mk(n, Fin.val(i) + total)\n" ++
  "decreasing_by by { exact Prod.Lex.left(0 + (total + bias), Fin.val(i) + total, Nat.lt_succ_self(k)) }\n" ++
  "theorem packedThree_step(total: Nat, k: Nat, bias: Nat, i: Fin(Nat.succ(k) + 1)): Eq(packedThree(total, Nat.succ(k), bias, i), packedThree(total + bias, k, bias, Fin.mk(0, Nat.zero_lt_succ(k)))) := by { exact packedThree.eq_def(total, Nat.succ(k), bias, i) }\n" ++
  "function packedFour(acc: Nat, n: Nat, left: Nat, right: Nat, bias: Nat, i: Fin(n + 1)): Nat := match n with { | 0 => acc + left + right + i.val | k + 1 => packedFour(acc + 1, k, left + bias, right + left, bias, Fin.mk(0, Nat.zero_lt_succ(k))) }\n" ++
  "termination_by Prod.mk(n, Fin.val(i) + left + right)\n" ++
  "decreasing_by by { exact Prod.Lex.left(0 + (left + bias) + (right + left), Fin.val(i) + left + right, Nat.lt_succ_self(k)) }\n"

private def argumentSource : String :=
  "function wfGenericArgs {A: Type u} [dictionary: Inhabited A] (seed: A, n: Nat, acc: Nat := 0): A := match n with { | 0 => if (acc == 0) { Inhabited.default } else { seed } | k + 1 => wfGenericArgs(n := k, acc := acc + 1, seed := seed) }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_self(k) }\n" ++
  "function wfDefaultReset(n: Nat, acc: Nat := n + 7): Nat := match n with { | 0 => acc | k + 1 => wfDefaultReset(n := k) }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_self(k) }\n" ++
  "function wfImplicitMajor {n: Nat} (seed: Fin(n + 1)): Nat := match n with { | 0 => seed.val | k + 1 => seed.val + wfImplicitMajor(seed := Fin.mk(0, Nat.zero_lt_succ(k)), n := k) }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_self(k) }\n" ++
  "theorem wfDefaultReset_step(k: Nat, acc: Nat): Eq(wfDefaultReset(Nat.succ(k), acc), wfDefaultReset(n := k)) := by { exact wfDefaultReset.eq_def(Nat.succ(k), acc) }\n"

private def source : String :=
  skipSource ++
  "theorem m3wfskipStep(k: Nat): m3wfskip(Nat.succ(k)) = m3wfskip(k - 1) + 1 := by { exact m3wfskip.eq_def(Nat.succ(k)) }\n" ++
  branchBody ++
  "decreasing_by by {\n" ++
  "  · exact Nat.lt_succ_of_le(Nat.sub_le(k, 1))\n" ++
  "  · exact Nat.lt_succ_self(k)\n" ++
  "}\n" ++
  "function m3wfshift(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => m3wfshift(k - 1) + 1 }\n" ++
  "termination_by n + 1\n" ++
  "decreasing_by by { exact Nat.succ_le_succ(Nat.succ_le_succ(Nat.sub_le(k, 1))) }\n" ++
  "function m3wfdefault(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => m3wfdefault(k) + 1 }\n" ++
  "termination_by n\n" ++
  scopeSource ++ parameterSource ++ typedSource ++ relationSource ++ packingSource ++ independentSource ++
  packingStateSource ++ narySource ++ argumentSource ++
  "function m3wfargumentsoutput(flag: Bool): UInt64 := {\n" ++
  "  let n: Nat := if (flag) { 4 } else { 0 }\n" ++
  "  UInt64.ofNat(wfGenericArgs(if (flag) { 17 } else { 29 }, n) + 100 * wfDefaultReset(n, 99) + 10000 * wfImplicitMajor(n := n, seed := Fin.mk(n, Nat.lt_succ_self(n))))\n" ++
  "}\n" ++
  "function m3wfnaryoutput(flag: Bool): UInt64 := {\n" ++
  "  let n: Nat := if (flag) { 7 } else { 4 }\n" ++
  "  let i: Fin(n + 1) := Fin.mk(n, Nat.lt_succ_self(n))\n" ++
  "  UInt64.ofNat(packedThree(5, n, 3, i) + 1000 * packedFour(2, n, 3, 4, 2, i))\n" ++
  "}\n" ++
  "function m3wfskipoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfskip(if (flag) { 17 } else { 10 }))\n" ++
  "function m3wfbranchesoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfbranches(if (flag) { 9 } else { 6 }))\n" ++
  "function m3wfshiftoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfshift(if (flag) { 17 } else { 10 }))\n" ++
  "function m3wfdefaultoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfdefault(if (flag) { 17 } else { 10 }))\n" ++
  "function m3wfrelationsoutput(flag: Bool): UInt64 := {\n" ++
  "  let n: Nat := if (flag) { 17 } else { 10 }\n" ++
  "  UInt64.ofNat(m3wfrelationLeft(5, n, 3) + 1000 * m3wfrelationRight(n))\n" ++
  "}\n" ++
  "function m3wfpackedoutput(flag: Bool): UInt64 := {\n" ++
  "  let n: Nat := if (flag) { 17 } else { 10 }\n" ++
  "  let acc: Fin(n + 1) := Fin.mk(n, Nat.lt_succ_self(n))\n" ++
  "  UInt64.ofNat(m3wfpacked((fun (index: Nat) => Nat), True, True.intro, n, 3, acc) + 1000 * Fin.val(m3wfpackedBounded(n, acc)))\n" ++
  "}\n" ++
  "function m3wfindependentleftoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfindependentLeft((fun (index: Nat) => Nat), True, True.intro, if (flag) { 17 } else { 10 }, 3, 5))\n" ++
  "function m3wfindependentrightoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfindependentRight(if (flag) { 7 } else { 5 }, if (flag) { 3 } else { 2 }, if (flag) { 3 } else { 2 }, if (flag) { 5 } else { 4 }))\n" ++
  "function m3wfaccoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfaccumulate(5, if (flag) { 17 } else { 10 }, 3))\n" ++
  "function m3wfoffsetoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfoffset(5, if (flag) { 17 } else { 10 }, 3))\n" ++
  "function m3wfstatesoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfstates(3, if (flag) { 17 } else { 10 }, 5, 2))\n" ++
  "function m3wffixedoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wffixed(if (flag) { 7 } else { 4 }, if (flag) { 17 } else { 10 }))\n" ++
  "function m3wflistoutput(flag: Bool): UInt64 := {\n" ++
  "  let xs: List Nat := if (flag) { List.cons(2, List.cons(4, List.cons(7, List.nil))) } else { List.cons(1, List.cons(3, List.cons(8, List.nil))) }\n" ++
  "  UInt64.ofNat(m3wfdigest(m3wfreverse(Nat, List.cons(9, List.nil), xs)))\n" ++
  "}\n" ++
  "function m3wffunctionoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfiterate((fun (value: Nat) => value + 3), if (flag) { 17 } else { 10 })(5))\n" ++
  "function m3wfdependentstateoutput(flag: Bool): UInt64 := {\n" ++
  "  let n: Nat := if (flag) { 17 } else { 10 }\n" ++
  "  UInt64.ofNat(m3wfdependent((fun (index: Nat) => Nat), True, True.intro, n, Fin.mk(n, Nat.lt_succ_self(n))))\n" ++
  "}\n" ++
  "function m3wfdependentresultoutput(flag: Bool): UInt64 := UInt64.ofNat(Fin.val(m3wfbounded(if (flag) { 17 } else { 10 })))\n"

-- Suffix ownership is checked before elaboration. Malformed selected syntax
-- must fail here, while a well-formed strategy survives into its semantic owner.
private def checkSource : IO Unit := do
  let plain := "termination_by n\n"
  let proved := plain ++ "decreasing_by by { exact Nat.lt_succ_self(n) }\n"
  for (sourcePrefix, suffix, privacy, registration) in [
      ("def fixed(n: Nat): Nat := fixed(n)\n", plain, false, ""),
      ("function fixed(n: Nat): Nat := fixed(n) ", proved, false, ""),
      ("function fixed(n: Nat): Nat := fixed(n)\n  ", proved, false, ""),
      ("private function fixed(n: Nat): Nat := fixed(n)\n", proved, true, ""),
      ("abbrev fixed(n: Nat): Nat := fixed(n)\n", plain, false, "abbrev"),
      ("opaque fixed(n: Nat): Nat := fixed(n)\n", plain, false, "opaque")] do
    let text := sourcePrefix ++ suffix
    let program ← match psPscv0ParseProgram (text ++ "const following: Nat := 1\n") with
      | .ok value => pure value
      | .error message => throw (IO.userError ("WF source: " ++ message))
    let (declaration, actualPrivacy, actualRegistration) ← match program.commands with
      | [.declaration value, .declaration (.definition ..)] => pure (value, false, "")
      | [.privateDeclaration value, .declaration (.definition ..)] => pure (value, true, "")
      | [.registeredDeclaration value .abbrevDecl, .declaration (.definition ..)] =>
        pure (value, false, "abbrev")
      | [.registeredDeclaration value .opaqueDecl, .declaration (.definition ..)] =>
        pure (value, false, "opaque")
      | _ => throw (IO.userError "WF suffix consumed the following command or its registration")
    if actualPrivacy != privacy || actualRegistration != registration then
      throw (IO.userError "WF command lost its privacy/registration")
    let .wellFoundedDefinition name _ _ body termination span := declaration
      | throw (IO.userError "WF strategy was discarded or relabeled")
    let .reference measure := termination.measure
      | throw (IO.userError "WF measure was changed")
    if name.segments != ["fixed"] || measure.segments != ["n"] ||
        span.start.byteOffset != (if privacy then 8 else 0) ||
        span.stop.byteOffset != text.utf8ByteSize - 1 ||
        termination.span.start.byteOffset != sourcePrefix.utf8ByteSize ||
        termination.span.stop.byteOffset != span.stop.byteOffset ||
        (psSyntaxTermSpan body).stop.byteOffset > termination.span.start.byteOffset then
      throw (IO.userError "WF body/measure/suffix source spans were not retained")
    if suffix == plain then
      if termination.decreasing.isSome then
        throw (IO.userError "WF parser invented a decreasing proof")
    else
      match termination.decreasing with
      | some (.byE [.exactE _ false _] _ proofSpan) =>
        if proofSpan.stop.byteOffset != span.stop.byteOffset ||
            proofSpan.start.byteOffset <= measure.span.stop.byteOffset then
          throw (IO.userError "WF proof span was not retained")
      | _ => throw (IO.userError "WF proof sequence was discarded")
  let body := "function fixed(n: Nat): Nat := fixed(n)\n"
  for (text, expected) in [
      (body ++ "termination_by structural n\n", "PSCV0-TERM-01"),
      (body ++ plain ++ "decreasing_by exact Nat.lt_succ_self(n)\n", "PSCV0-TERM-01"),
      (body ++ plain ++ "decreasing_by by exact Nat.lt_succ_self(n)\n", "PSCV0-TERM-01"),
      (body ++ "decreasing_by by { rfl }\n", "PSCV0-TERM-01"),
      (body ++ plain ++ plain, "PSCV0-REC-STRATEGY-01"),
      (body ++ proved ++ "decreasing_by by { rfl }\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ plain ++ "partial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ "partial_fixpoint\n" ++ plain, "PSCV0-REC-STRATEGY-01"),
      ("theorem fixed: True := True.intro\n" ++ plain, "PSCV0-REC-STRATEGY-01"),
      ("partial " ++ body ++ plain, "PSCV0-REC-STRATEGY-01")] do
    match psPscv0ParseProgram text with
    | .ok _ => throw (IO.userError ("invalid WF source accepted: " ++ text))
    | .error message =>
      if !message.startsWith expected then
        throw (IO.userError ("WF source failed at wrong rule: " ++ message))
  let parsed ← match psPscv0ParseProgram skipSource with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let [.declaration declaration] := parsed.commands
    | throw (IO.userError "unexpected WF print input")
  let lean ← match psPrintLeanDeclaration declaration with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF native printing failed")
  if (lean.splitOn "\ntermination_by n").length != 2 ||
      (lean.splitOn "\ndecreasing_by\n  exact ").length != 2 ||
      (lean.splitOn "decreasing_by by").length != 1 then
    throw (IO.userError "WF native printer retained the source by wrapper")
  let printed ← match psPrintProofScriptDeclaration declaration with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF proofscript printing failed")
  let reparsed ← match psPscv0ParseProgram (printed ++ "\n") with
    | .ok value => pure value
    | .error message => throw (IO.userError ("WF proofscript round-trip: " ++ message))
  let [.declaration (.wellFoundedDefinition name binders type value termination span)] := reparsed.commands
    | throw (IO.userError "WF proofscript round-trip lost its strategy")
  let reprinted ← match psPrintProofScriptDeclaration
      (.wellFoundedDefinition name binders type value termination span) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF proofscript reprinting failed")
  if reprinted != printed then throw (IO.userError "WF proofscript round-trip changed the declaration")
  let surface ← match psPscv0ParseSource true skipSource with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let lowered ← match psPscv0LowerModule surface with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  match lowered.declarations with
  | [.wellFoundedDefinition ..] => pure ()
  | _ => throw (IO.userError "WF flat source lowering discarded its strategy")
  IO.println "PSCV0_M3_WF_SOURCE: PASS measure/proof/span and following-command ownership, selected heads, strategy refusals and both printers"

-- Check the actual operational lambda prefix independently of the original
-- two-parameter source equation. A separately checked two-lambda wrapper keeps
-- the residual-result application control over the same WF function.
private def checkResultApplication (environment : PsEnvironment) : IO Unit := do
  let name := psRootName "m3wfiterate"
  let some declaration := psEnvironmentFind environment name
    | throw (IO.userError "missing function-valued WF declaration")
  let .definitionDecl _ _ declaredType declaredValue := declaration
    | throw (IO.userError "function-valued WF declaration is not a definition")
  let mut localContext := psLocalEmpty
  let mut cursor := declaredType
  let mut arguments : List PsExpr := []
  let mut runtimeLocals : List (Nat × String) := []
  let runtimeParameters := ["wfStep", "wfN", "wfSeed"]
  for parameterName in runtimeParameters do
    let parameter ← match psInferEnsureForall environment psMetaEmpty localContext cursor with
      | .ok value => pure value
      | .error _ => throw (IO.userError "function-valued WF entry lost a typed argument")
    let pushed := psLocalPushBinding localContext parameter.name parameter.domain parameter.binder
    localContext := pushed.context
    arguments := arguments ++ [.fvar pushed.id]
    runtimeLocals := (pushed.id, parameterName) :: runtimeLocals
    cursor := psExprInstantiate1 parameter.body (.fvar pushed.id)
  let base ← match psErasurePrepareDeclarationEntries environment [declaration]
      (psErasureScopeEmpty [(name, "m3wfiterate")]) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "failed to prepare actual WF entry metadata")
  let current : PsErasureCurrentDefinition := {
    name := "m3wfiterate"
    typeArgumentsRev := []
    runtimeParameters
    coreName := some name
    coreParametersRev := arguments.reverse }
  let scope := { base with
    localContext
    runtimeLocals
    currentDefinition := some current }
  let entry ← match psErasureValidateRootEntry environment scope with
    | .ok value => pure value
    | .error _ => throw (IO.userError "typed WF result application was rejected")
  let some opened := psErasureWellFoundedOpenValue arguments declaredValue
    | throw (IO.userError "WF entry lost an actual checked operational lambda")
  if entry.headerArguments.length != 3 || !entry.applicationArguments.isEmpty ||
      !psExprAlphaEq entry.value opened || !psExprAlphaEq entry.type cursor then
    throw (IO.userError "WF entry did not retain the complete checked operational prefix")
  -- Operational entry arity does not change the original two-parameter
  -- source equation. Its equality still relates functions before seed is applied.
  let some (.theoremDecl _ equationLevels equationType _) :=
      psEnvironmentFind environment (psNameAppendStr name "eq_def")
    | throw (IO.userError "function-valued WF source equation is missing")
  if !equationLevels.isEmpty then
    throw (IO.userError "function-valued WF source equation changed universe closure")
  let mut equationCursor := equationType
  let mut sourceResult := declaredType
  for argument in arguments.take 2 do
    let equationParameter ← match psInferEnsureForall environment psMetaEmpty
        localContext equationCursor with
      | .ok value => pure value
      | .error _ => throw (IO.userError "WF source equation lost an original header parameter")
    let sourceParameter ← match psInferEnsureForall environment psMetaEmpty
        localContext sourceResult with
      | .ok value => pure value
      | .error _ => throw (IO.userError "WF source type lost an original header parameter")
    if !psBinderInfoEq equationParameter.binder sourceParameter.binder ||
        !psDefEqReadOnlyWithEnv environment psMetaEmpty localContext
          equationParameter.domain sourceParameter.domain then
      throw (IO.userError "WF source equation changed the original header telescope")
    equationCursor := psExprInstantiate1 equationParameter.body argument
    sourceResult := psExprInstantiate1 sourceParameter.body argument
  let equationView := psExprAppView equationCursor
  let .constE equationHead [_] := equationView.head
    | throw (IO.userError "WF source equation promoted seed into its header")
  let [equationResult, equationLeft, _] := equationView.args
    | throw (IO.userError "WF source equation lost its function equality")
  if !psNameEq equationHead psEqName ||
      !psDefEqReadOnlyWithEnv environment psMetaEmpty localContext equationResult sourceResult ||
      !psExprAlphaEq equationLeft
        (psExprApplyMany (.constE name []) (arguments.take 2)) then
    throw (IO.userError "WF source equation changed its original function-valued contract")
  -- Keep the independent residual-result application cell: this checked
  -- wrapper has two raw lambdas and returns the actual WF function at seed.
  let .forallE stepName stepDomain (.forallE nName nDomain _ nBinder) stepBinder := declaredType
    | throw (IO.userError "WF result wrapper lost the original source telescope")
  let wrapperName := psRootName "m3wfiterateResultApplication"
  let wrapperValue := PsExpr.lam stepName stepDomain
    (.lam nName nDomain
      (psExprApplyMany (.constE name []) [.bvar 1, .bvar 0]) nBinder) stepBinder
  let wrapper := PsDeclaration.definitionDecl wrapperName [] declaredType wrapperValue
  let resultEnvironment ← match psAddDeclarationList environment [wrapper] with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF result wrapper failed independent Core checking")
  let resultBase ← match psErasurePrepareDeclarationEntries resultEnvironment [wrapper]
      (psErasureScopeEmpty [(wrapperName, "m3wfiterateResultApplication")]) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF result wrapper lost its actual entry metadata")
  let resultScope := { resultBase with
    localContext
    runtimeLocals
    currentDefinition := some { current with
      name := "m3wfiterateResultApplication"
      coreName := some wrapperName } }
  let resultEntry ← match psErasureValidateRootEntry resultEnvironment resultScope with
    | .ok value => pure value
    | .error _ => throw (IO.userError "typed WF residual result application was rejected")
  let some resultOpened := psErasureWellFoundedOpenValue (arguments.take 2) wrapperValue
    | throw (IO.userError "WF result wrapper changed its raw lambda prefix")
  if resultEntry.headerArguments.length != 2 || resultEntry.applicationArguments.length != 1 ||
      !psExprAlphaEq resultEntry.value (psExprApplyMany resultOpened (arguments.drop 2)) ||
      !psExprAlphaEq resultEntry.type cursor then
    throw (IO.userError "WF residual result argument was promoted or beta/eta-assumed")
  let swapped := { scope with
    currentDefinition := some { current with runtimeParameters := runtimeParameters.reverse } }
  match psErasureValidateRootEntry environment swapped with
  | .ok _ => throw (IO.userError "WF accepted a stale runtime entry argument order")
  | .error _ => pure ()

-- Validate the actual constructed pair against the admitted root and its
-- original dependent entry slots. Reordered, duplicated and foreign fields
-- must be refused even when an ordinary pair-shaped expression is supplied.
private def checkPackedEntry (environment : PsEnvironment) (sourceName : String)
    (runtimeParameters : List String) (firstPosition secondPosition : Nat)
    (expectDependency : Bool) (statePositions : List Nat := []) : IO Unit := do
  let name := psRootName sourceName
  let some declaration := psEnvironmentFind environment name
    | throw (IO.userError "missing packed WF declaration")
  let .definitionDecl _ _ declaredType _ := declaration
    | throw (IO.userError "packed WF declaration is not a definition")
  let mut localContext := psLocalEmpty
  let mut cursor := declaredType
  let mut arguments : List PsExpr := []
  let mut runtimeLocals : List (Nat × String) := []
  for parameterName in runtimeParameters do
    let parameter ← match psInferEnsureForall environment psMetaEmpty localContext cursor with
      | .ok value => pure value
      | .error _ => throw (IO.userError "packed WF entry lost its original telescope")
    let pushed := psLocalPushBinding localContext parameter.name parameter.domain parameter.binder
    localContext := pushed.context
    arguments := arguments ++ [.fvar pushed.id]
    runtimeLocals := (pushed.id, parameterName) :: runtimeLocals
    cursor := psExprInstantiate1 parameter.body (.fvar pushed.id)
  let base ← match psErasurePrepareDeclarationEntries environment [declaration]
      (psErasureScopeEmpty [(name, sourceName)]) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "failed to prepare the actual packed WF entry")
  let current : PsErasureCurrentDefinition := {
    name := sourceName, typeArgumentsRev := [], runtimeParameters
    coreName := some name, coreParametersRev := arguments.reverse }
  let scope := { base with localContext, runtimeLocals, currentDefinition := some current }
  let entry ← match psErasureValidateRootEntry environment scope with
    | .ok value => pure value
    | .error _ => throw (IO.userError "the actual packed WF root was rejected")
  let view := psErasureAppView entry.value
  let fixed ← match psWellFoundedFixApplicationView view.head view.args with
    | .ok (some value) => pure value
    | _ => throw (IO.userError "packed WF did not retain its typed fix application")
  let entryIds ← entry.headerArguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw (IO.userError "packed WF header contains a computed argument")
  let majorIds ← match psErasureWellFoundedTupleEntry environment
      scope entryIds fixed.plan.domain fixed.major with
    | .ok value => pure value
    | .error _ => throw (IO.userError "the actual two-field pack was rejected")
  let [firstId, secondId] := majorIds
    | throw (IO.userError "the actual two-field pack changed arity")
  let some packing := psWellFoundedPairPackingView fixed.plan.domain
    | throw (IO.userError "the actual pair lost its domain")
  let stateIds ← statePositions.mapM fun position =>
    match entryIds[position]? with
    | some id => pure id
    | none => throw (IO.userError "packed-state fixture selected a missing original state slot")
  let stateArguments := stateIds.map PsExpr.fvar
  if entryIds[firstPosition]? != some firstId || entryIds[secondPosition]? != some secondId ||
      entryIds.length != runtimeParameters.length || !entry.applicationArguments.isEmpty ||
      fixed.arguments.length != stateArguments.length ||
      !(fixed.arguments.zip stateArguments).all (fun pair => psExprAlphaEq pair.fst pair.snd) then
    throw (IO.userError "packed WF changed its original header slots, state or fixed captures")
  let some (.binding _ secondName secondType secondBinder) := psLocalFindById localContext secondId
    | throw (IO.userError "packed WF lost its original second binding")
  if (psExprFVarIds secondType).contains firstId != expectDependency then
    throw (IO.userError "packed WF changed the dependency of its actual second field")
  if !stateIds.isEmpty then
    let .lam _ callbackType _ .explicit :=
        psWhnf environment psMetaEmpty scope.localContext (.app fixed.functional fixed.major)
      | throw (IO.userError "packed-state functional lost its checked callback binder")
    let some (.binding _ firstName _ _) := psLocalFindById localContext firstId
      | throw (IO.userError "packed state lost its first original entry slot")
    let sourceType ← match psWellFoundedTupleCurryType environment psMetaEmpty localContext
        [firstName, secondName] callbackType with
      | .ok value => pure value
      | .error _ => throw (IO.userError "packed-state callback lost the shared curried telescope")
    let recursiveCore ← match psErasureWellFoundedCallback environment scope entry.name
        entry.levelArguments entry.headerArguments [firstId, secondId] stateIds sourceType with
      | .ok value => pure value
      | .error _ => throw (IO.userError "packed-state runtime callback was rejected")
    let mut callbackLocals := localContext
    let mut callbackBody := recursiveCore
    let mut callbackArguments : List PsExpr := []
    for _ in List.range (3 + stateIds.length) do
      let .lam callbackName callbackDomain callbackTail callbackBinder := callbackBody
        | throw (IO.userError "packed-state runtime callback lost an argument or proof slot")
      let pushed := psLocalPushBinding callbackLocals callbackName callbackDomain callbackBinder
      callbackLocals := pushed.context
      callbackArguments := callbackArguments ++ [.fvar pushed.id]
      callbackBody := psExprInstantiate1 callbackTail (.fvar pushed.id)
    let some firstArgument := callbackArguments[0]?
      | throw (IO.userError "missing first curried callback argument")
    let some secondArgument := callbackArguments[1]?
      | throw (IO.userError "missing second curried callback argument")
    let [_, _, _, nextState] := callbackArguments
      | throw (IO.userError "packed-state fixture lost its one trailing state binder")
    let [_, _, capturedBias, _] := entry.headerArguments
      | throw (IO.userError "packed-state fixture lost its fixed middle capture")
    -- This fixture's source order is total, n, bias, acc; the callback order
    -- is smaller n, smaller acc, decrease proof, next total.
    let expectedArguments := [nextState, firstArgument, capturedBias, secondArgument]
    let call := psErasureAppView callbackBody
    if !psExprAlphaEq call.head (.constE entry.name entry.levelArguments) ||
        call.args.length != expectedArguments.length ||
        !(call.args.zip expectedArguments).all (fun pair => psExprAlphaEq pair.fst pair.snd) then
      throw (IO.userError "packed-state callback changed source argument order or a fixed capture")
    let invalidProofType ← match sourceType with
      | .forallE first firstType (.forallE second secondType
          (.forallE proof _ result proofBinder) secondBinder) firstBinder =>
        pure (PsExpr.forallE first firstType (.forallE second secondType
          (.forallE proof (.constE psNatName []) result proofBinder) secondBinder) firstBinder)
      | _ => throw (IO.userError "packed-state source callback lost its proof telescope")
    let _ ← match psInferType environment psMetaEmpty localContext invalidProofType with
      | .ok value => pure value
      | .error _ => throw (IO.userError "non-proof callback control was not a well-formed type")
    match psErasureWellFoundedCallback environment scope entry.name
        entry.levelArguments entry.headerArguments [firstId, secondId] stateIds invalidProofType with
    | .ok _ => throw (IO.userError "packed-state erasure accepted a runtime Nat as its decrease proof slot")
    | .error _ => pure ()
  let foreign := psLocalPushBinding localContext secondName secondType secondBinder
  let foreignScope := { scope with localContext := foreign.context }
  let foreignMajor := psWellFoundedPairPack packing (.fvar firstId) (.fvar foreign.id)
  for (candidateScope, candidate) in [
      (scope, psWellFoundedPairPack packing (.fvar secondId) (.fvar firstId)),
      (scope, psWellFoundedPairPack packing (.fvar firstId) (.fvar firstId)),
      (foreignScope, foreignMajor)] do
    -- With Nat/Nat fields all three mutations are well typed. Their refusal
    -- must come from original entry identity/order, rather than field typing.
    if !expectDependency then
      let candidateType ← match psInferType environment psMetaEmpty candidateScope.localContext candidate with
        | .ok value => pure value
        | .error _ => throw (IO.userError "independent entry mutation was not well typed")
      unless psInferDefEq (psInferType environment psMetaEmpty) environment psMetaEmpty
          candidateScope.localContext candidateType fixed.plan.domain do
        throw (IO.userError "independent entry mutation changed the packed domain")
    match psErasureWellFoundedTupleEntry environment candidateScope entryIds fixed.plan.domain candidate with
    | .ok _ => throw (IO.userError "packed WF accepted reordered, duplicated or foreign entry fields")
    | .error _ => pure ()

-- Failure-only replay of the original command stream. The successful
-- qualification still uses psElabProgramWithOrigins on the complete program.
private def traceWFElaborationFailure (label : String) (program : PsSyntaxProgram) : IO Unit := do
  let environment := psSelfHostProdPreludeEnvironment
  let namespaces := environment.declarations.foldl (fun acc declaration =>
    ((psScopeNamePrefixes (psDeclarationName declaration)).drop 1).foldl psScopeRemember acc) []
  let mut state : PsCommandState := { environment, namespaces }
  let mut failed := false
  for (command, index) in program.commands.zipIdx do
    if !failed then
      match psElabCommand state command with
      | .ok next => state := next
      | .error error =>
        failed := true
        let sources := match command with
          | .declaration source | .registeredDeclaration source _
          | .privateDeclaration source | .privateRegisteredDeclaration source _
          | .derivingDeclaration source _ _ => [source]
          | .mutualDeclarations members _ => members.map PsSyntaxMutualMember.declaration
          | _ => []
        let names := sources.map fun source =>
          String.intercalate "." (psScopeQualified state.scope (psElabOriginSource source).fst).segments
        let previous := match state.originsRev with
          | origin :: _ => String.intercalate "." origin.sourceName.segments
          | [] => "<none>"
        let kind := match error with
          | .typeMismatch => "PsElabError.typeMismatch (no expected/actual payload)"
          | .atDeclaration name _ => "PsElabError.atDeclaration " ++ psNameToString name
          | _ => "other PsElabError"
        IO.println s!"PSCV0_M3_WF_ELAB_FAILURE: {label}; original-command={index + 1}; names={String.intercalate ", " names}; previous-origin={previous}; kind={kind}; {psCompilerPscv0ElabError error}"
  if !failed then
    IO.println s!"PSCV0_M3_WF_ELAB_FAILURE: {label}; all {program.commands.length} original commands replayed; open-scopes={state.frames.length}"

-- An ignored hint owns no extra section capture or fixedpoint dependency.
private def checkUnusedHints : IO Unit := do
  let parsed ← match psCompilerParsePscv0 unusedHintSource with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let result ← match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed with
    | .ok value => pure value
    | .error error => do
      traceWFElaborationFailure "unused-hints" parsed
      throw (IO.userError (psCompilerPscv0ElabError error))
  for name in [psRootName "m3wfunused", psRootName "m3p1unused"] do
    match psEnvironmentFind result.result.environment name,
        psEnvironmentFind result.result.environment (psNameAppendStr name "eq_def") with
    | some (.definitionDecl _ levels type value), some (.theoremDecl _ _ equationType proof) =>
      let .forallE _ domain codomain _ := type
        | throw (IO.userError "an unused hint changed the ordinary source header")
      if !levels.isEmpty || !psExprAlphaEq domain (.constE psNatName []) ||
          !psExprAlphaEq codomain (.constE psNatName []) ||
          psExprHasConst psWellFoundedFixName value || psExprHasConst psWellFoundedFixEqName proof ||
          psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value ||
          psExprHasUnresolvedMeta equationType || psExprHasUnresolvedMeta proof ||
          !(psExprFVarIds value).isEmpty || !(psExprFVarIds proof).isEmpty then
        throw (IO.userError "an unused hint added a capture or invoked WF construction instead of a checked ordinary equation")
    | _, _ => throw (IO.userError "a genuine nonrecursive WF/P1 source lost its checked ordinary definition/equation")

-- Inspect the real typed construction separately from runtime observations.
-- In particular an opaque P0 declaration, an axiom, or a self-referential
-- definition cannot stand in for WellFounded.Nat.fix or its checked equation.
-- A user PSigma in the final source slot is one field, not two generated
-- fields. This checks the same entry view used by executable adaptation.
private def checkUserSigmaSlot : IO Unit := do
  let environment := psSelfHostProdPreludeEnvironment
  let nat := PsExpr.constE psNatName []
  let family := PsExpr.lam (psRootName "element") nat nat .explicit
  let userType ← match psWellFoundedPairTypeChecked environment psMetaEmpty psLocalEmpty nat family with
    | .ok value => pure value
    | .error _ => throw (IO.userError "user PSigma control has no checked type")
  let first := psLocalPushBinding psLocalEmpty (psRootName "n") nat .explicit
  let last := psLocalPushBinding first.context (psRootName "userPair") userType .explicit
  let values := [PsExpr.fvar first.id, PsExpr.fvar last.id]
  let domain ← match psWellFoundedTupleTypeChecked environment psMetaEmpty last.context values with
    | .ok value => pure value
    | .error _ => throw (IO.userError "user PSigma slot could not be packed")
  let major ← match psWellFoundedTuplePack domain values with
    | .ok value => pure value
    | .error _ => throw (IO.userError "user PSigma slot lost its constructor")
  let scope := { psErasureScopeEmpty [] with localContext := last.context }
  let slots ← match psErasureWellFoundedTupleEntry environment scope [first.id, last.id] domain major with
    | .ok value => pure value
    | .error _ => throw (IO.userError "user PSigma slot changed the actual entry view")
  unless slots == [first.id, last.id] do
    throw (IO.userError "a user PSigma field was flattened")

private def checkConstruction : IO Unit := do
  checkUserSigmaSlot
  let parsed ← match psCompilerParsePscv0 (skipSource ++ scopeSource ++ parameterSource ++ typedSource ++ relationSource ++ packingSource ++ independentSource ++ packingStateSource ++ narySource ++ argumentSource) with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let some iterateCommand := parsed.commands.find? (fun command =>
      match command with
      | .declaration (.wellFoundedDefinition name ..) => name.segments == ["m3wfiterate"]
      | _ => false)
    | throw (IO.userError "missing source function-valued WF declaration")
  let .declaration (.wellFoundedDefinition _ header _ (.lambda bodyBinders _ _) termination _) :=
      iterateCommand
    | throw (IO.userError "WF function result lost its body lambda")
  let .reference measure := termination.measure
    | throw (IO.userError "WF function result changed its source measure")
  if header.length != 2 || bodyBinders.length != 1 || measure.segments != ["n"] then
    throw (IO.userError "WF result lambda crossed the source header/measure boundary")
  let result ← match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed with
    | .ok value => pure value
    | .error error => do
      traceWFElaborationFailure "construction" parsed
      throw (IO.userError (psCompilerPscv0ElabError error))
  -- These Core witnesses distinguish the real lexicographic constructors and
  -- generic fix/equation from the retained Nat specialization checked below.
  for (sourceName, constructor) in [("m3wfrelationLeft", "left"), ("m3wfrelationRight", "right")] do
    let name := psRootName sourceName
    match psEnvironmentFind result.result.environment name,
        psEnvironmentFind result.result.environment (psNameAppendStr name "eq_def") with
    | some (.definitionDecl _ _ type value), some (.theoremDecl _ _ equationType proof) =>
      let lexConstructor := psNameAppendStr (psNameAppendStr psProdName "Lex") constructor
      unless psExprHasConst psWellFoundedGenericFixName value &&
          psExprHasConst psWellFoundedGenericFixEqName proof &&
          psExprHasConst lexConstructor value &&
          !psExprHasConst psWellFoundedFixName value && !psExprHasConst name value &&
          !([type, value, equationType, proof].any psExprHasUnresolvedMeta) &&
          ([type, value, equationType, proof].all fun term => (psExprFVarIds term).isEmpty) do
        throw (IO.userError "generic WF lost its checked lexicographic proof, exact equation or closed construction")
    | _, _ => throw (IO.userError "generic WF did not produce its real definition and checked equation")
  for (text, constructors) in [("m3wfpacked", ["left"]), ("m3wfpackedBounded", ["left"]),
      ("m3wfindependentLeft", ["left"]), ("m3wfindependentRight", ["left", "right"]),
      ("m3wfpackedState", ["left"]), ("packedThree", ["left"]), ("packedFour", ["left"])] do
    let name := psRootName text
    match psEnvironmentFind result.result.environment name,
        psEnvironmentFind result.result.environment (psNameAppendStr name "eq_def") with
    | some (.definitionDecl _ _ type value), some (.theoremDecl _ _ equationType proof) =>
      let pairCases := psNameAppendStr psWellFoundedPairName "casesOn"
      let lexConstructors := constructors.map (psNameAppendStr (psNameAppendStr psProdName "Lex"))
      unless ([psWellFoundedGenericFixName, psWellFoundedPairName, pairCases] ++ lexConstructors).all
          (fun constantName => psExprHasConst constantName value) &&
          [psWellFoundedGenericFixEqName, pairCases, psRootName "funext",
            psRootName "congrArg", psNameAppendStr psEqName "trans"].all
            (fun constantName => psExprHasConst constantName proof) &&
          !psExprHasConst name value && !psExprHasConst psWellFoundedFixName value &&
          !([type, value, equationType, proof].any psExprHasUnresolvedMeta) &&
          ([type, value, equationType, proof].all fun term => (psExprFVarIds term).isEmpty) do
        throw (IO.userError "packed WF lost its real dependent domain, casesOn functional, checked callback equality or public equation")
    | _, _ => throw (IO.userError "packed WF did not produce a checked definition and equation")
  let name := psRootName "m3wfskip"
  let equationName := psNameAppendStr name "eq_def"
  match psEnvironmentFind result.result.environment name with
  | some (.definitionDecl _ _ type value) =>
    if !psExprHasConst psWellFoundedFixName value || psExprHasConst name value ||
        psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value then
      throw (IO.userError "WF declaration lost its checked fixedpoint construction")
  | _ => throw (IO.userError "WF declaration is not an ordinary checked definition")
  match psEnvironmentFind result.result.environment equationName with
  | some (.theoremDecl _ _ type value) =>
    if !psExprHasConst psWellFoundedFixEqName value ||
        psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value then
      throw (IO.userError "WF equation did not use the checked fix_eq theorem")
  | _ => throw (IO.userError "WF equation is missing or unproved")
  match result.result.declarations.take 6 with
  | [_, _, .theoremDecl boundName .., .definitionDecl loopName _ _ loopBody,
      .theoremDecl loopEquation .., .definitionDecl publicName _ _ publicBody] =>
    if !psNameEq loopEquation (psNameAppendStr loopName "eq_def") ||
        !psNameEq publicName (psNameAppendStr (psRootName "M3WFScope") "use") ||
        !psExprHasConst boundName loopBody || !psExprHasConst loopName publicBody ||
        ![boundName, loopName, loopEquation].all (fun name => result.privateNames.any (psNameEq name)) ||
        result.privateNames.any (psNameEq publicName) then
      throw (IO.userError "WF namespace/private proof or generated-equation ownership was lost")
  | _ => throw (IO.userError "WF private declaration batch changed shape")
  for (text, hasState) in [("m3wfaccumulate", true), ("m3wfoffset", true),
      ("m3wfstates", true), ("m3wffixed", false), ("m3wfreverse", true),
      ("m3wfiterate", true), ("m3wfdependent", true), ("m3wfbounded", false),
      ("wfGenericArgs", true), ("wfDefaultReset", true), ("wfImplicitMajor", true)] do
    let name := psRootName text
    match psEnvironmentFind result.result.environment name with
    | some (.definitionDecl _ _ type value) =>
      if !psExprHasConst psWellFoundedFixName value || psExprHasConst name value ||
          psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value then
        throw (IO.userError (text ++ " lost its checked Nat.fix construction"))
    | _ => throw (IO.userError (text ++ " is not a checked ordinary definition"))
    match psEnvironmentFind result.result.environment (psNameAppendStr name "eq_def") with
    | some (.theoremDecl _ _ type value) =>
      if !psExprHasConst psWellFoundedFixEqName value || !psExprHasConst name type ||
          psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value then
        throw (IO.userError (text ++ " lost its proved public unfolding equation"))
      if hasState && ![psRootName "funext", psRootName "congrArg",
          psNameAppendStr psEqName "trans"].all (fun constantName => psExprHasConst constantName value) then
        throw (IO.userError (text ++ " omitted the checked function-state equality transport"))
    | _ => throw (IO.userError (text ++ " has no checked equation"))
  let expectedEntries : List (String × List String × List PsErasedBinderKind × Nat × Nat) := [
    ("m3wfreverse", ["u"], [.type, .runtime, .runtime], 2, 1),
    ("m3wfiterate", [], [.runtime, .runtime, .runtime], 3, 0),
    ("m3wfdependent", ["u"], [.index, .proof, .proof, .runtime, .runtime], 4, 0),
    ("m3wfbounded", [], [.runtime], 1, 0),
    ("m3wfpacked", ["u"], [.index, .proof, .proof, .runtime, .runtime, .runtime], 5, 0),
    ("m3wfpackedBounded", [], [.runtime, .runtime], 2, 0),
    ("m3wfindependentLeft", ["u"], [.index, .proof, .proof, .runtime, .runtime, .runtime], 5, 0),
    ("m3wfindependentRight", [], [.runtime, .runtime, .runtime, .runtime], 4, 0),
    ("m3wfpackedState", [], [.runtime, .runtime, .runtime, .runtime], 4, 0),
    ("packedThree", [], [.runtime, .runtime, .runtime, .runtime], 4, 0),
    ("packedFour", [], [.runtime, .runtime, .runtime, .runtime, .runtime, .runtime], 6, 0),
    ("wfGenericArgs", ["u"], [.type, .runtime, .runtime, .runtime, .runtime], 4, 1),
    ("wfDefaultReset", [], [.runtime, .runtime], 2, 0),
    ("wfImplicitMajor", [], [.runtime, .runtime], 2, 0)]
  for (text, expectedLevels, expectedKinds, runtimeArity, typeArity) in expectedEntries do
    let name := psRootName text
    let some (.definitionDecl _ levels type value) := psEnvironmentFind result.result.environment name
      | throw (IO.userError ("missing typed WF declaration " ++ text))
    let info ← match psErasureEntryInfoWithFuel result.result.environment 4096 psLocalEmpty type value with
      | .ok value => pure value
      | .error _ => throw (IO.userError ("invalid typed WF entry " ++ text))
    if levels.map psNameToString != expectedLevels || info.binders.length != expectedKinds.length ||
        !(info.binders.zip expectedKinds).all (fun pair => psErasureEntryBinderKindEq pair.fst pair.snd) ||
        info.runtimeArity != runtimeArity || info.typeArity != typeArity then
      throw (IO.userError ("WF changed universe closure or typed entry roles for " ++ text))
  checkPackedEntry result.result.environment "m3wfpackedBounded" ["packedN", "packedAcc"] 0 1 true
  checkPackedEntry result.result.environment "m3wfindependentRight"
    ["independentBias", "independentLeft", "independentStep", "independentRight"] 1 3 false
  checkPackedEntry result.result.environment "m3wfpackedState"
    ["changingTotal", "packedN", "fixedBias", "packedAcc"] 1 3 true [0]
  if M3WellFoundedOracle.packedState 5 2 7 ⟨2, Nat.lt_succ_self 2⟩ != 16 ||
      M3WellFoundedOracle.packedState 4 3 2 ⟨3, Nat.lt_succ_self 3⟩ != 12 then
    throw (IO.userError "independent native packed-state observations changed")
  IO.println "PSCV0_M3_WF_PACKED_STATE: PASS checked pair-plus-state source equation, native 16/12 observations, original entry order and fixed capture, shared typed callback state forwarding, rejected non-proof callback and invalid packed entries"
  checkResultApplication result.result.environment
  checkUnusedHints
  IO.println "PSCV0_M3_WF_CONSTRUCTION: PASS real polymorphic Nat.fix, generic lexicographic fix and dependent/independent PSigma packing, dependent call proofs and motives, public fix_eq equations with checked extensional transport, universe closure, all-kind entries and result applications, private scope, ordinary unused-hint definitions without extra captures, no recursive axiom or P0 marker"

private def checks : List (String × String × Option String) := [
  ("recursive-unknown-name",
    "function bad(n: Nat): Nat := bad(missing := n)\ntermination_by n\n",
    some "unknown named argument"),
  ("recursive-duplicate-name",
    "function bad(n: Nat): Nat := bad(n := n, n := n)\ntermination_by n\n",
    some "duplicate named argument"),
  ("same-size",
    "function bad(n: Nat): Nat := bad(n)\ntermination_by n\n",
    some "PSCV0-WF-DECREASE"),
  ("false-measure",
    "function bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by 0\n",
    some "PSCV0-WF-DECREASE"),
  ("only-first-goal",
    branchBody ++ "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n",
    some "PSCV0-WF-DECREASE"),
  ("unresolved-proof",
    skipSource.replace "exact Nat.lt_succ_of_le(Nat.sub_le(k, 1))" "refine _",
    some "PSCV0-WF-DECREASE"),
  ("ordinary-unused-hints", unusedHintSource, none),
  ("nondecreasing-Bool-domain",
    "function bad(n: Bool): Nat := bad(n)\ntermination_by 0\n",
    some "PSCV0-WF-DECREASE"),
  ("nondecreasing-Bool-result",
    "function bad(n: Nat): Bool := bad(n)\ntermination_by n\n",
    some "PSCV0-WF-DECREASE"),
  ("unchanged-parameters",
    "function bad(n: Nat, k: Nat): Nat := bad(n, k)\ntermination_by n\n",
    some "PSCV0-WF-DECREASE"),
  ("independent-sum-measure-does-not-decrease",
    "function bad(n: Nat, acc: Nat): Nat := match n with { | 0 => acc | k + 1 => bad(k, acc + 1) }\ntermination_by n + acc\n",
    some "PSCV0-WF-DECREASE"),
  ("dependent-second-measure-does-not-prove-decrease",
    "function bad(n: Nat, i: Fin(n + 1)): Nat := match n with { | 0 => 0 | k + 1 => bad(k, Fin.mk(0, Nat.zero_lt_succ(k))) }\ntermination_by i.val\n",
    some "PSCV0-WF-DECREASE"),
  ("incomplete-recursive-header",
    "function bad(step: Nat, n: Nat): Nat := {\n  let callback: Nat -> Nat := bad(n)\n  callback(n)\n}\ntermination_by n\n",
    some "PSCV0-WF-ARITY"),
  ("function-result-measure-scope",
    "function bad(n: Nat): Nat -> Nat := fun (seed: Nat) => bad(n)(seed)\ntermination_by seed\n",
    some "unknown name seed"),
  ("body-lambda-is-not-a-header-parameter",
    "const bad: Nat -> Nat := fun (n: Nat) => match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by 0\n",
    some "PSCV0-WF-TELESCOPE"),
  ("body-lambda-measure-scope",
    "const bad: Nat -> Nat := fun (n: Nat) => match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by n\n",
    some "unknown name n"),
  ("escaping-self",
    "function bad(n: Nat): Nat := (fun (f: Nat -> Nat) => f(n))(bad)\ntermination_by n\n",
    some "PSCV0-WF-ESCAPE"),
  ("independent-tuple-measure-does-not-decrease",
    "function bad(n: Nat, acc: Nat): Nat := match n with { | 0 => acc | k + 1 => bad(k, acc + 1) }\ntermination_by Prod.mk(n + acc, 0)\n",
    some "PSCV0-WF-DECREASE"),
  ("measure codomain depends on changing argument",
    "function bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by Fin.mk(n, Nat.lt_succ_self(n))\n",
    some "PSCV0-WF-MEASURE-TYPE"),
  ("three-changing-dependent-pack-slots",
    "function bad(n: Nat, i: Fin(n + 1), total: Nat): Nat := match n with { | 0 => total | k + 1 => bad(k, Fin.mk(0, Nat.zero_lt_succ(k)), total + 1) }\ntermination_by Prod.mk(n, Fin.val(i))\n",
    some "PSCV0-WF-DECREASE"),
  ("three-measured-changing-pack-slots",
    "function bad(n: Nat, i: Fin(n + 1), total: Nat): Nat := match n with { | 0 => total | k + 1 => bad(k, Fin.mk(0, Nat.zero_lt_succ(k)), total + 1) }\ntermination_by Prod.mk(n, Fin.val(i) + total)\n",
    some "PSCV0-WF-DECREASE"),
  ("packed-state-stale-dependent-argument",
    packingStateSource.replace "Fin.mk(0, Nat.zero_lt_succ(k))" "acc",
    some "PSCV0-TYPE-MISMATCH"),
  ("packed-state-unresolved-decrease-proof",
    packingStateSource.replace "exact Prod.Lex.left(0, Fin.val(acc), Nat.lt_succ_self(k))" "refine _",
    some "PSCV0-WF-DECREASE"),
  ("packed-state-changing-measure-codomain",
    packingStateSource.replace "termination_by Prod.mk(n, Fin.val(acc))" "termination_by acc",
    some "PSCV0-WF-MEASURE-TYPE"),
  ("dependent-pack-measure-codomain",
    "function bad(n: Nat, i: Fin(n + 1)): Nat := match n with { | 0 => 0 | k + 1 => bad(k, Fin.mk(0, Nat.zero_lt_succ(k))) }\ntermination_by i\n",
    some "PSCV0-WF-MEASURE-TYPE"),
  ("generic relation does not justify a same-argument call",
    "function bad(n: Nat): Nat := bad(n)\ntermination_by Prod.mk(n, 0)\n",
    some "PSCV0-WF-DECREASE")]

def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  checkSource
  checkConstruction
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "wellfounded.ps") source
  let request : PsV7Native.Request := {
    source, sourceName := "m3-well-founded.ps", outputStem := "wellfounded"
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent]
    exports := .selected ["m3wfskipoutput", "m3wfbranchesoutput",
      "m3wfshiftoutput", "m3wfdefaultoutput", "m3wfaccoutput",
      "m3wfoffsetoutput", "m3wfstatesoutput", "m3wffixedoutput",
      "m3wflistoutput", "m3wffunctionoutput", "m3wfdependentstateoutput",
      "m3wfdependentresultoutput", "m3wfrelationsoutput", "m3wfpackedoutput",
      "m3wfindependentleftoutput", "m3wfindependentrightoutput", "m3wfnaryoutput", "m3wfargumentsoutput"] }
  let requests := #[request] ++ (checks.map fun (_, text, _) =>
    ({ source := text } : PsV7Native.Request)).toArray
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  let some first := batch.results[0]? | throw (IO.userError "missing WF result")
  let result ← match first with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  if result.artifacts.length != request.targets.length then
    throw (IO.userError "WF did not emit every requested target")
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  for ((label, _, expected), index) in checks.zipIdx do
    let some outcome := batch.results[index + 1]?
      | throw (IO.userError ("missing WF source check: " ++ label))
    match expected, outcome with
    | none, .ok _ => pure ()
    | none, .error error =>
      throw (IO.userError (label ++ " unexpectedly failed: " ++ error.phase ++ ": " ++ error.message))
    | some _, .ok _ => throw (IO.userError ("WF unexpectedly accepted " ++ label))
    | some expected, .error error =>
      if error.phase != "elaborate" || (error.message.splitOn expected).length < 2 then
        throw (IO.userError (label ++ " failed at wrong phase/rule: " ++
          error.phase ++ ": " ++ error.message))
  let rows := [false, true].map fun flag =>
    let n := if flag then 17 else 10
    let branchN := if flag then 9 else 6
    Lean.Json.mkObj [
      ("flag", Lean.toJson flag),
      ("m3wfargumentsoutput", Lean.toJson (toString (let argumentN := if flag then 4 else 0;
        M3WellFoundedOracle.genericArgs (if flag then 17 else 29) argumentN +
          100 * M3WellFoundedOracle.defaultReset argumentN 99 +
          10000 * M3WellFoundedOracle.implicitMajor (n := argumentN) ⟨argumentN, Nat.lt_succ_self argumentN⟩))),
      ("m3wfnaryoutput", Lean.toJson (toString (let packedN := if flag then 7 else 4;
        M3WellFoundedOracle.packedThree 5 packedN 3 ⟨packedN, Nat.lt_succ_self packedN⟩ +
          1000 * M3WellFoundedOracle.packedFour 2 packedN 3 4 2 ⟨packedN, Nat.lt_succ_self packedN⟩))),
      ("m3wfskipoutput", Lean.toJson (toString (M3WellFoundedOracle.skip n))),
      ("m3wfbranchesoutput", Lean.toJson (toString (M3WellFoundedOracle.branches branchN))),
      ("m3wfshiftoutput", Lean.toJson (toString (M3WellFoundedOracle.shiftedMeasure n))),
      ("m3wfdefaultoutput", Lean.toJson (toString (M3WellFoundedOracle.defaultDecrease n))),
      ("m3wfaccoutput", Lean.toJson (toString (M3WellFoundedOracle.accumulate 5 n 3))),
      ("m3wfoffsetoutput", Lean.toJson (toString (M3WellFoundedOracle.offset 5 n 3))),
      ("m3wfstatesoutput", Lean.toJson (toString (M3WellFoundedOracle.twoStates 3 n 5 2))),
      ("m3wffixedoutput", Lean.toJson (toString (M3WellFoundedOracle.fixedOnly (if flag then 7 else 4) n))),
      ("m3wflistoutput", Lean.toJson (toString (M3WellFoundedOracle.digest
        (M3WellFoundedOracle.reverseList Nat [9] (if flag then [2, 4, 7] else [1, 3, 8]))))),
      ("m3wffunctionoutput", Lean.toJson (toString (M3WellFoundedOracle.iterate (· + 3) n 5))),
      ("m3wfdependentstateoutput", Lean.toJson (toString (M3WellFoundedOracle.dependentState
        (fun _ => Nat) True True.intro n ⟨n, Nat.lt_succ_self n⟩))),
      ("m3wfdependentresultoutput", Lean.toJson (toString (M3WellFoundedOracle.bounded n).val)),
      ("m3wfpackedoutput", Lean.toJson (toString
        (M3WellFoundedOracle.packed (fun _ => Nat) True True.intro n 3
          ⟨n, Nat.lt_succ_self n⟩ +
          1000 * (M3WellFoundedOracle.packedBounded n ⟨n, Nat.lt_succ_self n⟩).val))),
      ("m3wfindependentleftoutput", Lean.toJson (toString
        (M3WellFoundedOracle.independentLeft (fun _ => Nat) True True.intro n 3 5))),
      ("m3wfindependentrightoutput", Lean.toJson (toString
        (M3WellFoundedOracle.independentRight (if flag then 7 else 5)
          (if flag then 3 else 2) (if flag then 3 else 2) (if flag then 5 else 4)))),
      ("m3wfrelationsoutput", Lean.toJson (toString
        (M3WellFoundedOracle.relationLeft 5 n 3 + 1000 * M3WellFoundedOracle.relationRight n)))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_WELL_FOUNDED: PASS checked ordered decreases, typed fixed/evolving arguments, polymorphic domains, function results, dependent Fin state/result and checked dependent/independent n-ary packing, all-kind entry slots, public equations, semantic refusals and five-target emission; runtime parity follows"
