import Ps.KernelCore.API.DagGenerated

/-
Direct quotient bootstrap over the current canonical batch owner.

The live environment determines the exact Eq metadata and the sole constructor
name. Its type IDs come only from checked same-batch/initial ownership. These
internal records are not certificates for arbitrary caller-built environments.
The syntax checks below match ExprEq: binder names and binder information are
ignored, but universe syntax, application order and bound indices are exact.
There is no inference, DefEq, reduction, semantic cache or checker-fuel callback.

Four fixed headers are built with the existing paged smart constructors. Their
new nodes are decoded once solely to publish the legacy environment types.
No original expression builder, whole AddQuot call or recursive re-import
constructs the DAG headers. The decoded publication adapter remains explicit.
The complete arena, work table, environment and four refs remain private until
the ordinary admission finish and the complete command batch both succeed.
-/

def psKernelDagQuotNode
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Option PsKernelExprV2Node :=
  match psKernelExprV2PagedFind arena root with
  | Option.none => Option.none
  | Option.some entry => Option.some entry.node

def psKernelDagQuotIsBVar
    (arena : PsKernelExprV2PagedArena) (root index : Nat) : Option Bool :=
  match psKernelDagQuotNode arena root with
  | Option.none => Option.none
  | Option.some node =>
      match node with
      | PsKernelExprV2Node.bvar actual => Option.some (Nat.beq actual index)
      | _ => Option.some false

def psKernelDagQuotIsSort
    (arena : PsKernelExprV2PagedArena) (root : Nat) (level : PsKernelLevel) :
    Option Bool :=
  match psKernelDagQuotNode arena root with
  | Option.none => Option.none
  | Option.some node =>
      match node with
      | PsKernelExprV2Node.sort actual => Option.some (psKernelLevelEq actual level)
      | _ => Option.some false

def psKernelDagQuotCheckEqTail
    (arena : PsKernelExprV2PagedArena) (root : Nat) : Option Bool :=
  match psKernelDagQuotNode arena root with
  | Option.none => Option.none
  | Option.some node =>
      match node with
      | PsKernelExprV2Node.forallE _ type body _ =>
          match psKernelDagQuotIsBVar arena type 0 with
          | Option.none => Option.none
          | Option.some valid =>
              if valid then
                match psKernelDagQuotNode arena body with
                | Option.none => Option.none
                | Option.some next =>
                    match next with
                    | PsKernelExprV2Node.forallE _ otherType result _ =>
                        match psKernelDagQuotIsBVar arena otherType 1 with
                        | Option.none => Option.none
                        | Option.some otherValid =>
                            if otherValid then
                              psKernelDagQuotIsSort arena result PsKernelLevel.zero
                            else Option.some false
                    | _ => Option.some false
              else Option.some false
      | _ => Option.some false

def psKernelDagQuotCheckEqType
    (arena : PsKernelExprV2PagedArena) (root : Nat) (universeName : PsKernelName) :
    Option Bool :=
  match psKernelDagQuotNode arena root with
  | Option.none => Option.none
  | Option.some node =>
      match node with
      | PsKernelExprV2Node.forallE _ type body _ =>
          match psKernelDagQuotIsSort arena type (PsKernelLevel.param universeName) with
          | Option.none => Option.none
          | Option.some valid =>
              if valid then psKernelDagQuotCheckEqTail arena body
              else Option.some false
      | _ => Option.some false

def psKernelDagQuotCheckReflArgs
    (arena : PsKernelExprV2PagedArena) (type left right : Nat) : Option Bool :=
  match psKernelDagQuotIsBVar arena type 1 with
  | Option.none => Option.none
  | Option.some valid =>
      if valid then
        match psKernelDagQuotIsBVar arena left 0 with
        | Option.none => Option.none
        | Option.some leftValid =>
            if leftValid then psKernelDagQuotIsBVar arena right 0
            else Option.some false
      else Option.some false

def psKernelDagQuotCheckReflBody
    (arena : PsKernelExprV2PagedArena) (root : Nat) (universeName : PsKernelName) :
    Option Bool :=
  match psKernelDagQuotNode arena root with
  | Option.none => Option.none
  | Option.some node =>
      match node with
      | PsKernelExprV2Node.app beforeRight right =>
          match psKernelDagQuotNode arena beforeRight with
          | Option.none => Option.none
          | Option.some second =>
              match second with
              | PsKernelExprV2Node.app beforeLeft left =>
                  match psKernelDagQuotNode arena beforeLeft with
                  | Option.none => Option.none
                  | Option.some third =>
                      match third with
                      | PsKernelExprV2Node.app head type =>
                          match psKernelDagQuotNode arena head with
                          | Option.none => Option.none
                          | Option.some final =>
                              match final with
                              | PsKernelExprV2Node.const name levels =>
                                  if psKernelNameEq name psKernelEqName then
                                    if psKernelLevelListEq levels
                                        (List.cons (PsKernelLevel.param universeName) List.nil) then
                                      psKernelDagQuotCheckReflArgs arena type left right
                                    else Option.some false
                                  else Option.some false
                              | _ => Option.some false
                      | _ => Option.some false
              | _ => Option.some false
      | _ => Option.some false

def psKernelDagQuotCheckReflTail
    (arena : PsKernelExprV2PagedArena) (root : Nat) (universeName : PsKernelName) :
    Option Bool :=
  match psKernelDagQuotNode arena root with
  | Option.none => Option.none
  | Option.some node =>
      match node with
      | PsKernelExprV2Node.forallE _ type body _ =>
          match psKernelDagQuotIsBVar arena type 0 with
          | Option.none => Option.none
          | Option.some valid =>
              if valid then psKernelDagQuotCheckReflBody arena body universeName
              else Option.some false
      | _ => Option.some false

def psKernelDagQuotCheckReflType
    (arena : PsKernelExprV2PagedArena) (root : Nat) (universeName : PsKernelName) :
    Option Bool :=
  match psKernelDagQuotNode arena root with
  | Option.none => Option.none
  | Option.some node =>
      match node with
      | PsKernelExprV2Node.forallE _ type body _ =>
          match psKernelDagQuotIsSort arena type (PsKernelLevel.param universeName) with
          | Option.none => Option.none
          | Option.some valid =>
              if valid then psKernelDagQuotCheckReflTail arena body universeName
              else Option.some false
      | _ => Option.some false

def psKernelDagQuotOwnedType
    (info : PsKernelConstantInfo) (state : PsKernelDagGeneratedState) : Option Nat :=
  match psKernelExprV2DeclarationRefFind state.declarations
      (psKernelConstantInfoName info) with
  | Option.none => Option.none
  | Option.some owner =>
      if psKernelExprV2DeclarationRefMatches owner info then Option.some owner.type
      else Option.none

def psKernelDagQuotCheckReflOwned
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (reflName : PsKernelName) : Option (Except String Unit) :=
  match psKernelEnvironmentFind environment reflName with
  | Option.none =>
      Option.some (Except.error "failed to initialize quot module, missing Eq constructor")
  | Option.some reflInfo =>
      match psKernelConstantInfoLevelParams reflInfo with
      | List.nil =>
          Option.some (Except.error "failed to initialize quot module, unexpected universe params at Eq constructor")
      | List.cons universeName rest =>
          match rest with
          | List.cons _ _ =>
              Option.some (Except.error "failed to initialize quot module, unexpected universe params at Eq constructor")
          | List.nil =>
              match psKernelDagQuotOwnedType reflInfo state with
              | Option.none => Option.none
              | Option.some root =>
                  match psKernelDagQuotCheckReflType state.arena root universeName with
                  | Option.none => Option.none
                  | Option.some valid =>
                      if valid then Option.some (Except.ok ())
                      else Option.some (Except.error "failed to initialize quot module, unexpected type for Eq constructor")

def psKernelDagQuotCheckEqOwned
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState) :
    Option (Except String Unit) :=
  match psKernelEnvironmentFind environment psKernelEqName with
  | Option.none =>
      Option.some (Except.error "failed to initialize quot module, environment does not have Eq type")
  | Option.some info =>
      match info with
      | PsKernelConstantInfo.inductInfo eqInfo =>
          match eqInfo.base.levelParams with
          | List.nil =>
              Option.some (Except.error "failed to initialize quot module, unexpected number of universe params at Eq type")
          | List.cons universeName rest =>
              match rest with
              | List.cons _ _ =>
                  Option.some (Except.error "failed to initialize quot module, unexpected number of universe params at Eq type")
              | List.nil =>
                  match eqInfo.ctors with
                  | List.nil =>
                      Option.some (Except.error "failed to initialize quot module, unexpected number of constructors for Eq type")
                  | List.cons reflName tail =>
                      match tail with
                      | List.cons _ _ =>
                          Option.some (Except.error "failed to initialize quot module, unexpected number of constructors for Eq type")
                      | List.nil =>
                          match psKernelDagQuotOwnedType info state with
                          | Option.none => Option.none
                          | Option.some root =>
                              match psKernelDagQuotCheckEqType state.arena root universeName with
                              | Option.none => Option.none
                              | Option.some valid =>
                                  if valid then
                                    psKernelDagQuotCheckReflOwned environment state reflName
                                  else
                                    Option.some (Except.error "failed to initialize quot module, Eq has an unexpected type")
      | _ =>
          Option.some (Except.error "failed to initialize quot module, environment does not have Eq type")

def psKernelDagQuotUserName (value : String) : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous value

/- A fixed topological program over existing Node constructors. The 55 nodes
   share their bound-index, level and application subterms. Every child is
   appended earlier; PagedMk still checks it and computes exact metadata.
   The four roots are base+14, base+19, base+38 and base+54. -/
def psKernelDagQuotHeaderNodes
    (base : Nat) (universeName resultUniverseName : PsKernelName) :
    List PsKernelExprV2Node :=
  let b0 := Nat.add base 0;
  let b1 := Nat.add base 1;
  let b2 := Nat.add base 2;
  let b3 := Nat.add base 3;
  let b4 := Nat.add base 4;
  let prop := Nat.add base 5;
  let sortU := Nat.add base 6;
  let sortV := Nat.add base 7;
  let quot := Nat.add base 8;
  let mk := Nat.add base 9;
  let eqV := Nat.add base 10;
  let relationInner := Nat.add base 11;
  let relation := Nat.add base 12;
  let quotR := Nat.add base 13;
  let quotType := Nat.add base 14;
  let mkAlpha := Nat.add base 15;
  let mkResult := Nat.add base 16;
  let mkA := Nat.add base 17;
  let mkR := Nat.add base 18;
  let mkType := Nat.add base 19;
  let fnType := Nat.add base 20;
  let relA := Nat.add base 21;
  let relAB := Nat.add base 22;
  let eqBeta := Nat.add base 23;
  let fnA := Nat.add base 24;
  let eqFnA := Nat.add base 25;
  let fnB := Nat.add base 26;
  let eqFns := Nat.add base 27;
  let sanityH := Nat.add base 28;
  let sanityB := Nat.add base 29;
  let sanityA := Nat.add base 30;
  let liftAlpha := Nat.add base 31;
  let liftQuot := Nat.add base 32;
  let liftResult := Nat.add base 33;
  let liftH := Nat.add base 34;
  let liftF := Nat.add base 35;
  let liftBeta := Nat.add base 36;
  let liftR := Nat.add base 37;
  let liftType := Nat.add base 38;
  let indMotiveAlpha := Nat.add base 39;
  let indMotiveQuot := Nat.add base 40;
  let indMotive := Nat.add base 41;
  let indMkAlpha := Nat.add base 42;
  let indMkR := Nat.add base 43;
  let indMkA := Nat.add base 44;
  let indMotiveApp := Nat.add base 45;
  let indAllA := Nat.add base 46;
  let indAlpha := Nat.add base 47;
  let indQuot := Nat.add base 48;
  let indResult := Nat.add base 49;
  let indQBinder := Nat.add base 50;
  let indMkBinder := Nat.add base 51;
  let indBeta := Nat.add base 52;
  let indR := Nat.add base 53;
  let indType := Nat.add base 54;
  List.cons
      (PsKernelExprV2Node.bvar 0)
      (List.cons
      (PsKernelExprV2Node.bvar 1)
      (List.cons
      (PsKernelExprV2Node.bvar 2)
      (List.cons
      (PsKernelExprV2Node.bvar 3)
      (List.cons
      (PsKernelExprV2Node.bvar 4)
      (List.cons
      (PsKernelExprV2Node.sort PsKernelLevel.zero)
      (List.cons
      (PsKernelExprV2Node.sort (PsKernelLevel.param universeName))
      (List.cons
      (PsKernelExprV2Node.sort (PsKernelLevel.param resultUniverseName))
      (List.cons
      (PsKernelExprV2Node.const psKernelQuotName (List.cons (PsKernelLevel.param universeName) List.nil))
      (List.cons
      (PsKernelExprV2Node.const psKernelQuotMkName (List.cons (PsKernelLevel.param universeName) List.nil))
      (List.cons
      (PsKernelExprV2Node.const psKernelEqName (List.cons (PsKernelLevel.param resultUniverseName) List.nil))
      (List.cons
      (PsKernelExprV2Node.forallE PsKernelName.anonymous b1 prop PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE PsKernelName.anonymous b0 relationInner PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "r") relation sortU PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "α") sortU quotR PsKernelBinderInfo.implicit)
      (List.cons
      (PsKernelExprV2Node.app quot b2)
      (List.cons
      (PsKernelExprV2Node.app mkAlpha b1)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "a") b1 mkResult PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "r") relation mkA PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "α") sortU mkR PsKernelBinderInfo.implicit)
      (List.cons
      (PsKernelExprV2Node.forallE PsKernelName.anonymous b2 b1 PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.app b4 b1)
      (List.cons
      (PsKernelExprV2Node.app relA b0)
      (List.cons
      (PsKernelExprV2Node.app eqV b4)
      (List.cons
      (PsKernelExprV2Node.app b3 b2)
      (List.cons
      (PsKernelExprV2Node.app eqBeta fnA)
      (List.cons
      (PsKernelExprV2Node.app b3 b1)
      (List.cons
      (PsKernelExprV2Node.app eqFnA fnB)
      (List.cons
      (PsKernelExprV2Node.forallE PsKernelName.anonymous relAB eqFns PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "b") b4 sanityH PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "a") b3 sanityB PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.app quot b4)
      (List.cons
      (PsKernelExprV2Node.app liftAlpha b3)
      (List.cons
      (PsKernelExprV2Node.forallE PsKernelName.anonymous liftQuot b3 PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE PsKernelName.anonymous sanityA liftResult PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "f") fnType liftH PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "β") sortV liftF PsKernelBinderInfo.implicit)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "r") relation liftBeta PsKernelBinderInfo.implicit)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "α") sortU liftR PsKernelBinderInfo.implicit)
      (List.cons
      (PsKernelExprV2Node.app quot b1)
      (List.cons
      (PsKernelExprV2Node.app indMotiveAlpha b0)
      (List.cons
      (PsKernelExprV2Node.forallE PsKernelName.anonymous indMotiveQuot prop PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.app mk b3)
      (List.cons
      (PsKernelExprV2Node.app indMkAlpha b2)
      (List.cons
      (PsKernelExprV2Node.app indMkR b0)
      (List.cons
      (PsKernelExprV2Node.app b1 indMkA)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "a") b2 indMotiveApp PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.app quot b3)
      (List.cons
      (PsKernelExprV2Node.app indAlpha b2)
      (List.cons
      (PsKernelExprV2Node.app b2 b0)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "q") indQuot indResult PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "mk") indAllA indQBinder PsKernelBinderInfo.default)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "β") indMotive indMkBinder PsKernelBinderInfo.implicit)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "r") relation indBeta PsKernelBinderInfo.implicit)
      (List.cons
      (PsKernelExprV2Node.forallE (psKernelDagQuotUserName "α") sortU indR PsKernelBinderInfo.implicit)
      (List.nil)))))))))))))))))))))))))))))))))))))))))))))))))))))))

def psKernelDagQuotAppendHeaderNodes
    (nodes : List PsKernelExprV2Node) :
    PsKernelExprV2PagedArena -> Except String PsKernelExprV2PagedArena :=
  match nodes with
  | List.nil =>
      fun (arena : PsKernelExprV2PagedArena) => Except.ok arena
  | List.cons first rest =>
      fun (arena : PsKernelExprV2PagedArena) =>
        let attempted : Except String (Prod PsKernelExprV2PagedArena Nat) :=
          match first with
          | PsKernelExprV2Node.bvar index => psKernelExprV2PagedMkBVar arena index
          | PsKernelExprV2Node.sort level => psKernelExprV2PagedMkSort arena level
          | PsKernelExprV2Node.const name levels => psKernelExprV2PagedMkConst arena name levels
          | PsKernelExprV2Node.app fn arg => psKernelExprV2PagedMkApp arena fn arg
          | PsKernelExprV2Node.forallE name type body binderInfo =>
              psKernelExprV2PagedMkForall arena name type body binderInfo
          | _ => Except.error "PSKERNEL_V2_QUOT_HEADER_NODE";
        match attempted with
        | Except.error error => Except.error error
        | Except.ok result =>
            let recur := psKernelDagQuotAppendHeaderNodes rest;
            recur (Prod.fst result)

structure PsKernelDagQuotHeaders where
  arena : PsKernelExprV2PagedArena
  quotType : Nat
  mkType : Nat
  liftType : Nat
  indType : Nat

def psKernelDagQuotBuildHeaders
    (arena : PsKernelExprV2PagedArena)
    (universeName resultUniverseName : PsKernelName) :
    Except String PsKernelDagQuotHeaders :=
  let base := arena.size;
  match psKernelDagQuotAppendHeaderNodes
      (psKernelDagQuotHeaderNodes base universeName resultUniverseName) arena with
  | Except.error error => Except.error error
  | Except.ok next =>
      Except.ok (PsKernelDagQuotHeaders.mk next
        (Nat.add base 14) (Nat.add base 19) (Nat.add base 38) (Nat.add base 54))

def psKernelDagQuotPublishTypes
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (headers : PsKernelDagQuotHeaders) (built : PsKernelExprV2Decoded)
    (universeName resultUniverseName : PsKernelName) :
    Except String (Prod PsKernelEnvironment PsKernelDagGeneratedState) :=
  match psKernelExprV2DecodedRequire built headers.quotType with
  | Except.error error => Except.error error
  | Except.ok quotType =>
      match psKernelExprV2DecodedRequire built headers.mkType with
      | Except.error error => Except.error error
      | Except.ok mkType =>
          match psKernelExprV2DecodedRequire built headers.liftType with
          | Except.error error => Except.error error
          | Except.ok liftType =>
              match psKernelExprV2DecodedRequire built headers.indType with
              | Except.error error => Except.error error
              | Except.ok indType =>
                  let levels := List.cons universeName List.nil;
                  let liftLevels := List.cons universeName
                    (List.cons resultUniverseName List.nil);
                  let quotInfo := PsKernelQuotInfo.mk
                    (PsKernelConstantBase.mk psKernelQuotName levels quotType)
                    PsKernelQuotKind.typeQ;
                  let mkInfo := PsKernelQuotInfo.mk
                    (PsKernelConstantBase.mk psKernelQuotMkName levels mkType)
                    PsKernelQuotKind.ctorQ;
                  let liftInfo := PsKernelQuotInfo.mk
                    (PsKernelConstantBase.mk psKernelQuotLiftName liftLevels liftType)
                    PsKernelQuotKind.liftQ;
                  let indInfo := PsKernelQuotInfo.mk
                    (PsKernelConstantBase.mk psKernelQuotIndName levels indType)
                    PsKernelQuotKind.indQ;
                  let quotOwner := PsKernelExprV2DeclarationRef.mk
                    psKernelQuotName levels headers.quotType Option.none
                    (PsKernelExprV2DeclarationRefKind.quotDecl PsKernelQuotKind.typeQ);
                  let mkOwner := PsKernelExprV2DeclarationRef.mk
                    psKernelQuotMkName levels headers.mkType Option.none
                    (PsKernelExprV2DeclarationRefKind.quotDecl PsKernelQuotKind.ctorQ);
                  let liftOwner := PsKernelExprV2DeclarationRef.mk
                    psKernelQuotLiftName liftLevels headers.liftType Option.none
                    (PsKernelExprV2DeclarationRefKind.quotDecl PsKernelQuotKind.liftQ);
                  let indOwner := PsKernelExprV2DeclarationRef.mk
                    psKernelQuotIndName levels headers.indType Option.none
                    (PsKernelExprV2DeclarationRefKind.quotDecl PsKernelQuotKind.indQ);
                  let env1 := psKernelEnvironmentAddUnchecked environment
                    (PsKernelConstantInfo.quotInfo quotInfo);
                  let env2 := psKernelEnvironmentAddUnchecked env1
                    (PsKernelConstantInfo.quotInfo mkInfo);
                  let env3 := psKernelEnvironmentAddUnchecked env2
                    (PsKernelConstantInfo.quotInfo liftInfo);
                  let env4 := psKernelEnvironmentAddUnchecked env3
                    (PsKernelConstantInfo.quotInfo indInfo);
                  let owners := List.cons indOwner
                    (List.cons liftOwner (List.cons mkOwner
                      (List.cons quotOwner state.declarations)));
                  Except.ok (Prod.mk
                    (psKernelEnvironmentMarkQuotInitialized env4)
                    (PsKernelDagGeneratedState.mk headers.arena built owners))

def psKernelDagQuotBuildAndPublish
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelEnvironment PsKernelDagGeneratedState) :=
  let universeName := psKernelDagQuotUserName "u";
  let resultUniverseName := psKernelDagQuotUserName "v";
  match psKernelDagQuotBuildHeaders state.arena universeName resultUniverseName with
  | Except.error error => Except.error error
  | Except.ok headers =>
      -- Only the 55 newly built nodes are decoded for legacy publication.
      -- The original caller table is never extended by the command owner.
      match psKernelExprV2DecodeCanonicalFuel
          (Nat.succ (Nat.sub headers.arena.size state.built.size))
          headers.arena state.built state.built.size with
      | Except.error error => Except.error error
      | Except.ok built =>
          psKernelDagQuotPublishTypes environment state headers built
            universeName resultUniverseName

def psKernelDagTryAddQuotOwned
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState) :
    Option (Except String (Prod PsKernelEnvironment PsKernelDagGeneratedState)) :=
  if environment.quotInitialized then
    Option.some (Except.ok (Prod.mk environment state))
  else
    match psKernelDagQuotCheckEqOwned environment state with
    | Option.none => Option.none
    | Option.some attempted =>
        match attempted with
        | Except.error error => Option.some (Except.error error)
        | Except.ok _ =>
            let reserved := List.cons psKernelQuotName
              (List.cons psKernelQuotMkName
                (List.cons psKernelQuotLiftName
                  (List.cons psKernelQuotIndName List.nil)));
            match psKernelCheckQuotReservedNames environment reserved with
            | Except.error error => Option.some (Except.error error)
            | Except.ok _ =>
                if Nat.beq state.arena.size state.built.size then
                  Option.some (psKernelDagQuotBuildAndPublish environment state)
                else Option.none
