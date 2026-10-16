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

run_cmd do
  for name in #[``WellFounded.Nat.fix, ``WellFounded.Nat.fix_eq,
      ``skip, ``skip_step, ``branches, ``shiftedMeasure, ``defaultDecrease,
      ``accumulate, ``offset, ``offset_step, ``twoStates, ``fixedOnly,
      ``reverseList, ``digest, ``iterate, ``dependentState, ``bounded, ``bounded_step] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "WF oracle uses an unapproved assumption: {name}: {axioms}"
    Lean.logInfo m!"PSCV0_M3_WF_ASSUMPTIONS: {name}: {axioms}"

end M3WellFoundedOracle

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
  "    Fin.mk(Fin.val(child) + 1, Nat.succ_lt_succ(Fin.isLt(child)))\n" ++
  "}\ntermination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_self(k) }\n" ++
  "theorem m3wfboundedStep(k: Nat): Fin.val(m3wfbounded(Nat.succ(k))) = Fin.val(m3wfbounded(k)) + 1 := by { exact congrArg((fun (value: Fin(Nat.succ(k) + 1)) => Fin.val(value)), m3wfbounded.eq_def(Nat.succ(k))) }\n"

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
  scopeSource ++ parameterSource ++ typedSource ++
  "function m3wfskipoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfskip(if (flag) { 17 } else { 10 }))\n" ++
  "function m3wfbranchesoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfbranches(if (flag) { 9 } else { 6 }))\n" ++
  "function m3wfshiftoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfshift(if (flag) { 17 } else { 10 }))\n" ++
  "function m3wfdefaultoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfdefault(if (flag) { 17 } else { 10 }))\n" ++
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

-- Exercise a real function result already applied to a further typed entry
-- argument. The validator must retain the actual two-lambda header and apply
-- seed afterwards; reclassifying seed as recursive state changes this call.
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
  let some opened := psErasureWellFoundedOpenValue (arguments.take 2) declaredValue
    | throw (IO.userError "WF function result changed the raw declaration lambda prefix")
  if entry.headerArguments.length != 2 || entry.applicationArguments.length != 1 ||
      !psExprAlphaEq entry.value (psExprApplyMany opened (arguments.drop 2)) ||
      !psExprAlphaEq entry.type cursor then
    throw (IO.userError "WF result binder was promoted into the source header or beta/eta-assumed")
  let swapped := { scope with
    currentDefinition := some { current with runtimeParameters := runtimeParameters.reverse } }
  match psErasureValidateRootEntry environment swapped with
  | .ok _ => throw (IO.userError "WF accepted a stale runtime entry argument order")
  | .error _ => pure ()

-- Inspect the real typed construction separately from runtime observations.
-- In particular an opaque P0 declaration, an axiom, or a self-referential
-- definition cannot stand in for WellFounded.Nat.fix or its checked equation.
private def checkConstruction : IO Unit := do
  let parsed ← match psCompilerParsePscv0 (skipSource ++ scopeSource ++ parameterSource ++ typedSource) with
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
    | .error error => throw (IO.userError (psCompilerPscv0ElabError error))
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
      ("m3wfiterate", false), ("m3wfdependent", true), ("m3wfbounded", false)] do
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
    ("m3wfiterate", [], [.runtime, .runtime], 2, 0),
    ("m3wfdependent", ["u"], [.index, .proof, .proof, .runtime, .runtime], 4, 0),
    ("m3wfbounded", [], [.runtime], 1, 0)]
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
  checkResultApplication result.result.environment
  IO.println "PSCV0_M3_WF_CONSTRUCTION: PASS real polymorphic Nat.fix, dependent call proofs and motives, public fix_eq equations with checked extensional transport, universe closure, all-kind entries and result applications, private scope, no recursive axiom or P0 marker"

private def refusals : List (String × String × String) := [
  ("same-size",
    "function bad(n: Nat): Nat := bad(n)\ntermination_by n\n",
    "PSCV0-WF-DECREASE"),
  ("false-measure",
    "function bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by 0\n",
    "PSCV0-WF-DECREASE"),
  ("only-first-goal",
    branchBody ++ "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n",
    "PSCV0-WF-DECREASE"),
  ("unresolved-proof",
    skipSource.replace "exact Nat.lt_succ_of_le(Nat.sub_le(k, 1))" "refine _",
    "PSCV0-WF-DECREASE"),
  ("nonrecursive",
    "function bad(n: Nat): Nat := n\ntermination_by n\n",
    "PSCV0-WF-NOT-RECURSIVE"),
  ("nondecreasing-Bool-domain",
    "function bad(n: Bool): Nat := bad(n)\ntermination_by 0\n",
    "PSCV0-WF-DECREASE"),
  ("nondecreasing-Bool-result",
    "function bad(n: Nat): Bool := bad(n)\ntermination_by n\n",
    "PSCV0-WF-DECREASE"),
  ("unchanged-parameters",
    "function bad(n: Nat, k: Nat): Nat := bad(n, k)\ntermination_by n\n",
    "PSCV0-WF-DECREASE"),
  ("two-changing-measure-dependencies",
    "function bad(n: Nat, acc: Nat): Nat := match n with { | 0 => acc | k + 1 => bad(k, acc + 1) }\ntermination_by n + acc\n",
    "PSCV0-WF-MEASURE-STATE"),
  ("changing-major-domain",
    "function bad(n: Nat, i: Fin(n + 1)): Nat := match n with { | 0 => 0 | k + 1 => bad(k, Fin.mk(0, Nat.zero_lt_succ(k))) }\ntermination_by i.val\n",
    "PSCV0-WF-MAJOR-DOMAIN"),
  ("incomplete-recursive-header",
    "function bad(step: Nat, n: Nat): Nat := bad(n)\ntermination_by n\n",
    "PSCV0-WF-ARITY"),
  ("function-result-measure-scope",
    "function bad(n: Nat): Nat -> Nat := fun (seed: Nat) => bad(n)(seed)\ntermination_by seed\n",
    "unknown name seed"),
  ("body-lambda-is-not-a-header-parameter",
    "const bad: Nat -> Nat := fun (n: Nat) => match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by 0\n",
    "PSCV0-WF-TELESCOPE"),
  ("body-lambda-measure-scope",
    "const bad: Nat -> Nat := fun (n: Nat) => match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by n\n",
    "unknown name n"),
  ("escaping-self",
    "function bad(n: Nat): Nat := (fun (f: Nat -> Nat) => f(n))(bad)\ntermination_by n\n",
    "PSCV0-WF-ESCAPE")]

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
      "m3wfdependentresultoutput"] }
  let requests := #[request] ++ (refusals.map fun (_, text, _) =>
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
  for ((label, _, expected), index) in refusals.zipIdx do
    let some outcome := batch.results[index + 1]?
      | throw (IO.userError ("missing WF refusal: " ++ label))
    match outcome with
    | .ok _ => throw (IO.userError ("WF unexpectedly accepted " ++ label))
    | .error error =>
      if error.phase != "elaborate" || (error.message.splitOn expected).length < 2 then
        throw (IO.userError (label ++ " failed at wrong phase/rule: " ++
          error.phase ++ ": " ++ error.message))
  let rows := [false, true].map fun flag =>
    let n := if flag then 17 else 10
    let branchN := if flag then 9 else 6
    Lean.Json.mkObj [
      ("flag", Lean.toJson flag),
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
      ("m3wfdependentresultoutput", Lean.toJson (toString (M3WellFoundedOracle.bounded n).val))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_WELL_FOUNDED: PASS checked ordered decreases, typed fixed/evolving arguments, polymorphic domains, function results, dependent Fin state/result, all-kind entry slots, public equations, semantic refusals and five-target emission; runtime parity follows"
