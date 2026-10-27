import Ps.MinKernel.Profile.RegularIngressOperational

-- Every declared constructor type is checked again against the derived ambient
-- signature. This closes source/context rebasing through the actual type checker.
def psMinRegCoreCheckConstructors (fuel total visible : Nat) (groups : List PsMinRegCorePlan)
    (specs : List PsMinRegSpec) (slot index : Nat) (constructors : List PsMinRegCoreConstructor) : Bool :=
  match constructors with
  | List.nil => true
  | List.cons ctor rest =>
    match fuel with
    | Nat.zero => false
    | Nat.succ remaining =>
      match psMinRegCoreType 256 total visible groups ctor.type with
      | Option.none => false
      | Option.some sourceType => match psMinRegCtorTypeAt specs slot index with
        | Option.none => false
        | Option.some derived => if psMinRegTyEq 512 sourceType derived then
            psMinRegCoreCheckConstructors remaining total visible groups specs slot (Nat.succ index) rest
          else false

def psMinRegCoreCheckSignatures (total : Nat) (all : List PsMinRegCorePlan)
    (groups : List PsMinRegCorePlan) : Bool :=
  match groups with
  | List.nil => true
  | List.cons plan rest =>
    if Nat.blt plan.ordinal total then
      if psMinRegCoreCheckConstructors 512 total (Nat.succ plan.ordinal) all (psMinRegCoreSpecs all)
          (Nat.sub total (Nat.succ plan.ordinal)) 0 plan.source.constructors then
        psMinRegCoreCheckSignatures total all rest
      else false
    else false

def psMinRegCoreMotiveType (total visible : Nat) (groups : List PsMinRegCorePlan)
    (domain : PsMinCoreExpr) (motive : PsMinCoreExpr) : Option PsMinRegTy :=
  match motive with
  | .lam _ _ annotation body =>
    if psMinCoreExprEq 256 annotation domain then
      match psMinRegCoreType 256 total visible groups body with
      | Option.none => Option.none
      | Option.some result => if psMinCoreIsType result then Option.some result else Option.none
    else Option.none
  | _ => Option.none

def psMinRegCoreTypedPrimitive (total visible : Nat) (groups : List PsMinRegCorePlan)
    (expr : PsMinCoreExpr) : Option PsMinOpTerm :=
  match expr with
  | .app fn type => match fn with
    | .constant name levels => if psMinByteEq levels List.nil then
      match psMinRegCoreType 256 total visible groups type with
      | Option.none => Option.none
      | Option.some a => if psMinCoreIsType a then
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) [110, 105, 108]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.listNil a) 0 1 0 0 0) else
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) [99, 111, 110, 115]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.listCons a) 0 1 0 0 0) else
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [110, 111, 110, 101]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.optionNone a) 0 1 0 0 0) else
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [115, 111, 109, 101]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.optionSome a) 0 1 0 0 0) else Option.none
      else Option.none else Option.none
    | _ => Option.none
  | _ => Option.none

def psMinRegCoreRecursor (total visible : Nat) (groups : List PsMinRegCorePlan)
    (expr : PsMinCoreExpr) : Option PsMinRegCoreTerm :=
  match expr with
  | .app head motive =>
    match head with
    | .constant name levels =>
      if psMinByteEq levels [1] then
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) [114, 101, 99]) then
          match psMinRegCoreMotiveType total visible groups (PsMinCoreExpr.constant (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) List.nil) motive with
          | Option.none => Option.none
          | Option.some result => Option.some
              (PsMinRegCoreTerm.ordinary (PsMinOpTerm.primitive (PsMinOpPrimitive.natRec result) 1 0 0 1 2))
        else match psMinRegCoreFindRecursor total visible groups name with
          | Option.none => Option.none
          | Option.some binding =>
            match psMinRegCoreMotiveType total visible groups (PsMinCoreExpr.constant binding.owner List.nil) motive with
            | Option.none => Option.none
            | Option.some result => Option.some (PsMinRegCoreTerm.recursor binding.slot result)
      else Option.none
    | .app base element =>
      match base with
      | .constant name levels =>
        if psMinByteEq levels [1] then
          match psMinRegCoreType 256 total visible groups element with
          | Option.none => Option.none
          | Option.some a =>
            if psMinCoreIsType a then
              if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) [114, 101, 99]) then
                match psMinRegCoreMotiveType total visible groups
                    (PsMinCoreExpr.app (PsMinCoreExpr.constant (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) List.nil) element) motive with
                | Option.none => Option.none
                | Option.some result => Option.some
                    (PsMinRegCoreTerm.ordinary (PsMinOpTerm.primitive (PsMinOpPrimitive.listRec a result) 1 1 0 1 2))
              else if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [114, 101, 99]) then
                match psMinRegCoreMotiveType total visible groups
                    (PsMinCoreExpr.app (PsMinCoreExpr.constant (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) List.nil) element) motive with
                | Option.none => Option.none
                | Option.some result => Option.some
                    (PsMinRegCoreTerm.ordinary (PsMinOpTerm.primitive (PsMinOpPrimitive.optionRec a result) 1 1 0 1 2))
              else Option.none
            else Option.none
        else Option.none
      | _ => Option.none
    | _ => Option.none
  | _ => Option.none

-- Unlike the first domain, source terms may use validated regular data heads.
def psMinRegCoreTranslate (fuel total visible : Nat) (groups : List PsMinRegCorePlan)
    (names : List PsMinCoreName) (expr : PsMinCoreExpr) : Option PsMinRegCoreTerm :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ rest =>
    match psMinCoreConditionalView expr with
    | Option.some view =>
      match psMinRegCoreType 256 total visible groups view.type with
      | Option.none => Option.none
      | Option.some type =>
        if psMinCoreIsType type then
          match psMinRegCoreTranslate rest total visible groups names view.left with
          | Option.none => Option.none
          | Option.some left => match psMinRegCoreTranslate rest total visible groups names view.right with
            | Option.none => Option.none
            | Option.some right => match psMinRegCoreTranslate rest total visible groups names view.yes with
              | Option.none => Option.none
              | Option.some yes => match psMinRegCoreTranslate rest total visible groups names view.no with
                | Option.none => Option.none
                | Option.some no => Option.some
                  (PsMinRegCoreTerm.app (PsMinRegCoreTerm.app (PsMinRegCoreTerm.app (PsMinRegCoreTerm.app
                    (PsMinRegCoreTerm.ordinary (PsMinOpTerm.primitive (PsMinOpPrimitive.boolEqIte type) 1 1 0 0 0)) left) right) yes) no)
        else Option.none
    | Option.none =>
      match psMinRegCoreTypedPrimitive total visible groups expr with
      | Option.some primitive => Option.some (PsMinRegCoreTerm.ordinary primitive)
      | Option.none =>
        match psMinRegCoreRecursor total visible groups expr with
        | Option.some primitive => Option.some primitive
        | Option.none => match expr with
          | .bvar index => Option.some (PsMinRegCoreTerm.ordinary (PsMinOpTerm.base (PsMinRegTerm.var index)))
          | .natural value => Option.some (PsMinRegCoreTerm.ordinary (PsMinOpTerm.base (PsMinRegTerm.nat value)))
          | .constant name levels => if psMinByteEq levels List.nil then
              match psMinCorePrimitive name with
              | Option.some primitive => Option.some (PsMinRegCoreTerm.ordinary primitive)
              | Option.none => match psMinRegCoreFindConstructor total visible groups name with
                | Option.some binding => Option.some (PsMinRegCoreTerm.ordinary (PsMinOpTerm.base (PsMinRegTerm.ctor binding.slot binding.index)))
                | Option.none => match psMinCoreResolve names name with
                  | Option.none => Option.none
                  | Option.some index => Option.some (PsMinRegCoreTerm.ordinary (PsMinOpTerm.base (PsMinRegTerm.constant index)))
            else Option.none
          | .app fn arg =>
            match psMinRegCoreTranslate rest total visible groups names fn with
            | Option.none => Option.none
            | Option.some f => match psMinRegCoreTranslate rest total visible groups names arg with
              | Option.none => Option.none
              | Option.some a => Option.some (PsMinRegCoreTerm.app f a)
          | .lam _ _ type body =>
            match psMinRegCoreType 256 total visible groups type with
            | Option.none => Option.none
            | Option.some t => match psMinRegCoreTranslate rest total visible groups names body with
              | Option.none => Option.none
              | Option.some b => Option.some (PsMinRegCoreTerm.lam t b)
          | .letE _ type value body =>
            match psMinRegCoreType 256 total visible groups type with
            | Option.none => Option.none
            | Option.some t => match psMinRegCoreTranslate rest total visible groups names value with
              | Option.none => Option.none
              | Option.some v => match psMinRegCoreTranslate rest total visible groups names body with
                | Option.none => Option.none
                | Option.some b => Option.some (PsMinRegCoreTerm.letE t v b)
          | .projection owner field major =>
            match psMinRegCoreGroupSlot total visible groups owner with
            | Option.none => Option.none
            | Option.some slot => match psMinRegCoreTranslate rest total visible groups names major with
              | Option.none => Option.none
              | Option.some value => Option.some (PsMinRegCoreTerm.app (PsMinRegCoreTerm.ordinary (PsMinOpTerm.projection slot field)) value)
          | _ => Option.none

-- Original entries remain ordered. A group changes visibility, never the global
-- definition context; all type codes are rebased into the final validated registry.
def psMinRegCoreTranslateEntries (fuel total visible : Nat) (groups : List PsMinRegCorePlan)
    (names : List PsMinCoreName) (entries : List PsMinRegCoreEntry) : Option (List PsMinRegCoreDefinition) :=
  match entries with
  | List.nil => Option.some List.nil
  | List.cons entry rest =>
    match fuel with
    | Nat.zero => Option.none
    | Nat.succ remaining =>
      match entry with
      | .inductiveE _ => psMinRegCoreTranslateEntries remaining total (Nat.succ visible) groups names rest
      | .definition decl =>
        match psMinRegCoreType 256 total visible groups decl.type with
        | Option.none => Option.none
        | Option.some type => match psMinRegCoreTranslate 256 total visible groups names decl.value with
          | Option.none => Option.none
          | Option.some value =>
            match psMinRegCoreTranslateEntries remaining total visible groups (List.cons decl.name names) rest with
            | Option.none => Option.none
            | Option.some tail => Option.some (List.cons (PsMinRegCoreDefinition.mk type value) tail)

structure PsMinRegCoreChecked where
  plans : PsMinRegCoreState
  normalized : List PsMinRegCoreDefinition
  types : List PsMinRegTy

-- Typed AST admission is internal. The bounded byte certificate guard is composed
-- by RegularIngressBytes; untrusted inputs can never supply the plans or registry.
def psMinRegCoreCheckEntries (entries : List PsMinRegCoreEntry) : Option PsMinRegCoreChecked :=
  match psMinRegCorePlans entries with
  | Option.none => Option.none
  | Option.some state =>
    if psMinRegCoreCheckSignatures state.count state.groups state.groups then
      match psMinRegCoreTranslateEntries 512 state.count 0 state.groups List.nil entries with
      | Option.none => Option.none
      | Option.some normalized =>
        match psMinRegCoreCheckEnvironment 512 512 (psMinRegCoreSpecs state.groups) normalized with
        | Option.none => Option.none
        | Option.some types => Option.some (PsMinRegCoreChecked.mk state normalized types)
    else Option.none
