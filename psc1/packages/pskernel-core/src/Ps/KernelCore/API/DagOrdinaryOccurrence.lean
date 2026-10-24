import Ps.KernelCore.Core.ExprV2.TransformSpine

/-
Ordinary uniform-occurrence analysis over canonical expression IDs.
An occurrence is checked at its current binder offset. Shared IDs are revisited
at each occurrence; an ID-only visited set would lose this semantic input.
The traversal bound is separate from checker fuel. Head matches stop the
subtree exactly as in the recursive-expression worker; oversaturated heads
continue through function then argument in the original order.
-/
/- The V1 membership helper lives above the checker session layer. This small
   scalar worker keeps the structural DAG module below that dependency; native
   proof material establishes equality with the existing helper for all lists. -/
def psKernelExprV2OrdinaryDeclaredNameMember
    (target : PsKernelName) (values : List PsKernelName) : Bool :=
  match values with
  | List.nil => false
  | List.cons first rest =>
      if psKernelNameEq target first then true
      else psKernelExprV2OrdinaryDeclaredNameMember target rest

def psKernelExprV2OrdinaryUniformParamArgs
    (args : List Nat) :
    PsKernelExprV2PagedArena -> Nat -> Nat -> Except String Bool :=
  match args with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_offset : Nat) (_index : Nat) =>
        Except.ok true
  | List.cons arg rest =>
      fun (arena : PsKernelExprV2PagedArena) (offset : Nat) (index : Nat) =>
        match psKernelExprV2PagedRequire arena arg with
        | Except.error error => Except.error error
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.bvar bvarIndex =>
                let expected := Nat.sub (Nat.sub offset 1) index;
                if Nat.beq bvarIndex expected then
                  psKernelExprV2OrdinaryUniformParamArgs rest arena offset (Nat.succ index)
                else
                  Except.ok false
            | _ => Except.ok false

def psKernelExprV2OrdinaryUniformOccurrenceHead
    (arena : PsKernelExprV2PagedArena)
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (root : Nat)
    (offset : Nat) : Except String Bool :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok entry =>
          match entry.node with
          | PsKernelExprV2Node.const name levels =>
              let args := Prod.snd spine;
              let declared := psKernelExprV2OrdinaryDeclaredNameMember name declaredNames;
              let shortEnough :=
                Nat.ble (psKernelExprV2TransformNatLength args) numParams;
              if declared then
                if shortEnough then
                  let enoughOffset := psKernelNatGe offset numParams;
                  let fullParams :=
                    Nat.beq (psKernelExprV2TransformNatLength args) numParams;
                  let levelsOk := psKernelLevelListEq levels expectedLevels;
                  if enoughOffset then
                    if fullParams then
                      if levelsOk then
                        match psKernelExprV2OrdinaryUniformParamArgs args arena offset 0 with
                        | Except.error error => Except.error error
                        | Except.ok argsOk =>
                            if argsOk then
                              Except.ok true
                            else
                              Except.error
                                "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
                      else
                        Except.error
                          "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
                    else
                      Except.error
                        "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
                  else
                    Except.error
                      "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
                else
                  Except.ok false
              else
                Except.ok false
          | _ => Except.ok false

def psKernelExprV2OrdinaryUniformOccurrenceWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> List PsKernelName -> List PsKernelLevel ->
    Nat -> Nat -> Nat -> Except String Unit :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (_declaredNames : List PsKernelName)
          (_expectedLevels : List PsKernelLevel) (_numParams : Nat)
          (_root : Nat) (_offset : Nat) =>
        Except.error "simple inductive uniform-occurrence budget exhausted"
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (declaredNames : List PsKernelName)
          (expectedLevels : List PsKernelLevel) (numParams : Nat)
          (root : Nat) (offset : Nat) =>
        match psKernelExprV2OrdinaryUniformOccurrenceHead
            arena declaredNames expectedLevels numParams root offset with
        | Except.error error => Except.error error
        | Except.ok stop =>
            if stop then
              Except.ok ()
            else
              match psKernelExprV2PagedRequire arena root with
              | Except.error error => Except.error error
              | Except.ok entry =>
                  let recur := psKernelExprV2OrdinaryUniformOccurrenceWithFuel remaining;
                  match entry.node with
                  | PsKernelExprV2Node.app fn arg =>
                      match recur arena declaredNames expectedLevels numParams fn offset with
                      | Except.error error => Except.error error
                      | Except.ok _ =>
                          recur arena declaredNames expectedLevels numParams arg offset
                  | PsKernelExprV2Node.lam _ type body _ =>
                      match recur arena declaredNames expectedLevels numParams type offset with
                      | Except.error error => Except.error error
                      | Except.ok _ =>
                          recur arena declaredNames expectedLevels numParams body (Nat.succ offset)
                  | PsKernelExprV2Node.forallE _ type body _ =>
                      match recur arena declaredNames expectedLevels numParams type offset with
                      | Except.error error => Except.error error
                      | Except.ok _ =>
                          recur arena declaredNames expectedLevels numParams body (Nat.succ offset)
                  | PsKernelExprV2Node.letE _ type value body _ =>
                      match recur arena declaredNames expectedLevels numParams type offset with
                      | Except.error error => Except.error error
                      | Except.ok _ =>
                          match recur arena declaredNames expectedLevels numParams value offset with
                          | Except.error error => Except.error error
                          | Except.ok _ =>
                              recur arena declaredNames expectedLevels numParams body (Nat.succ offset)
                  | PsKernelExprV2Node.mdata _ body =>
                      recur arena declaredNames expectedLevels numParams body offset
                  | PsKernelExprV2Node.proj _ _ body =>
                      recur arena declaredNames expectedLevels numParams body offset
                  | _ => Except.ok ()

/- This internal entry requires canonical metadata. It does not accept a memo
   or a traversal result supplied by the caller. -/
def psKernelExprV2OrdinaryUniformOccurrenceOnCanonical
    (arena : PsKernelExprV2PagedArena)
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (root : Nat)
    (offset : Nat) : Except String Unit :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      psKernelExprV2OrdinaryUniformOccurrenceWithFuel
        (Nat.succ entry.depth) arena declaredNames expectedLevels numParams root offset

def psKernelExprV2OrdinaryUniformOccurrences
    (ctorTypes : List Nat) :
    PsKernelExprV2PagedArena -> List PsKernelName -> List PsKernelLevel ->
    Nat -> Except String Unit :=
  match ctorTypes with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_declaredNames : List PsKernelName)
          (_expectedLevels : List PsKernelLevel) (_numParams : Nat) =>
        Except.ok ()
  | List.cons first rest =>
      fun (arena : PsKernelExprV2PagedArena) (declaredNames : List PsKernelName)
          (expectedLevels : List PsKernelLevel) (numParams : Nat) =>
        match psKernelExprV2OrdinaryUniformOccurrenceOnCanonical
            arena declaredNames expectedLevels numParams first 0 with
        | Except.error error => Except.error error
        | Except.ok _ =>
            psKernelExprV2OrdinaryUniformOccurrences rest
              arena declaredNames expectedLevels numParams
