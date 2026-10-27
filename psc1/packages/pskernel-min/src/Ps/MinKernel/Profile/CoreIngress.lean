import Ps.MinKernel.Profile.CoreBytes

def psMinCoreResolve (names : List PsMinCoreName) (name : PsMinCoreName) : Option Nat :=
  match names with
  | List.nil => Option.none
  | List.cons head rest => if psMinCoreNameEq name head then Option.some 0 else
      match psMinCoreResolve rest name with
      | Option.none => Option.none
      | Option.some index => Option.some (Nat.succ index)

def psMinCoreNameRoot (name : PsMinCoreName) : PsMinCoreName :=
  match name with
  | .anonymous => PsMinCoreName.anonymous
  | .str parent bytes => match parent with
    | .anonymous => PsMinCoreName.str parent bytes
    | _ => psMinCoreNameRoot parent
  | .num parent value => match parent with
    | .anonymous => PsMinCoreName.num parent value
    | _ => psMinCoreNameRoot parent

def psMinCoreReservedRoots : List PsMinCoreName := [(PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]), (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]), (PsMinCoreName.str PsMinCoreName.anonymous [85, 110, 105, 116]), (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]), (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]), (PsMinCoreName.str PsMinCoreName.anonymous [69, 113]), (PsMinCoreName.str PsMinCoreName.anonymous [68, 101, 99, 105, 100, 97, 98, 108, 101]), (PsMinCoreName.str PsMinCoreName.anonymous [105, 116, 101]), (PsMinCoreName.str PsMinCoreName.anonymous [95, 112, 115, 99, 49, 79, 114, 100, 101, 114, 70, 97, 108, 115, 101])]

def psMinCoreNameMember (names : List PsMinCoreName) (name : PsMinCoreName) : Bool :=
  match names with
  | List.nil => false
  | List.cons head rest => if psMinCoreNameEq name head then true else psMinCoreNameMember rest name

def psMinCoreFresh (names : List PsMinCoreName) (name : PsMinCoreName) : Bool :=
  match name with
  | .anonymous => false
  | _ => if psMinCoreNameMember psMinCoreReservedRoots (psMinCoreNameRoot name) then false else
    if psMinCoreNameMember names name then false else true

def psMinCoreType (fuel : Nat) : PsMinCoreExpr -> Option PsMinRegTy :=
  match fuel with
  | Nat.zero => fun _ => Option.none
  | Nat.succ rest => fun expr =>
    let smaller : PsMinCoreExpr -> Option PsMinRegTy := psMinCoreType rest;
    match expr with
    | .constant name levels =>
      if psMinByteEq levels List.nil then
        if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [95, 112, 115, 99, 49, 79, 114, 100, 101, 114, 70, 97, 108, 115, 101]) then Option.some PsMinRegTy.empty else
        if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [85, 110, 105, 116]) then Option.some PsMinRegTy.unit else
        if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) then Option.some PsMinRegTy.nat else
        if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]) then Option.some PsMinRegTy.boolean else Option.none
      else Option.none
    | .forallE _ _ domain body =>
      match smaller domain with
      | Option.none => Option.none
      | Option.some a => match smaller body with
        | Option.none => Option.none
        | Option.some b => Option.some (PsMinRegTy.arr a b)
    | .app fn arg => match fn with
      | .constant name levels => if psMinByteEq levels [1] then
          match smaller arg with
          | Option.none => Option.none
          | Option.some a => if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) then Option.some (PsMinRegTy.list a) else
              if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) then Option.some (PsMinRegTy.option a) else Option.none
        else Option.none
      | _ => Option.none
    | _ => Option.none

def psMinCorePrimitive (name : PsMinCoreName) : Option PsMinOpTerm :=
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [85, 110, 105, 116]) [117, 110, 105, 116]) then Option.some (PsMinOpTerm.base PsMinRegTerm.unit) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]) [102, 97, 108, 115, 101]) then Option.some (PsMinOpTerm.base (PsMinRegTerm.boolean false)) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]) [116, 114, 117, 101]) then Option.some (PsMinOpTerm.base (PsMinRegTerm.boolean true)) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) [122, 101, 114, 111]) then Option.some (PsMinOpTerm.base (PsMinRegTerm.nat 0)) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 99, 99]) then Option.some (PsMinOpTerm.primitive PsMinOpPrimitive.natSucc 0 0 0 0 0) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) [97, 100, 100]) then Option.some (PsMinOpTerm.primitive PsMinOpPrimitive.natAdd 0 0 0 0 0) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 98]) then Option.some (PsMinOpTerm.primitive PsMinOpPrimitive.natSub 0 0 0 0 0) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) [98, 101, 113]) then Option.some (PsMinOpTerm.primitive PsMinOpPrimitive.natBeq 0 0 0 0 0) else
  if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [78, 97, 116]) [98, 108, 116]) then Option.some (PsMinOpTerm.primitive PsMinOpPrimitive.natBlt 0 0 0 0 0) else
  Option.none

structure PsMinCoreConditional where
  type : PsMinCoreExpr
  left : PsMinCoreExpr
  right : PsMinCoreExpr
  yes : PsMinCoreExpr
  no : PsMinCoreExpr

def psMinCoreEquality (left right : PsMinCoreExpr) : PsMinCoreExpr :=
  PsMinCoreExpr.app (PsMinCoreExpr.app (PsMinCoreExpr.app (PsMinCoreExpr.constant (PsMinCoreName.str PsMinCoreName.anonymous [69, 113]) [1]) (PsMinCoreExpr.constant (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]) List.nil)) left) right

def psMinCoreDecision (left right : PsMinCoreExpr) : PsMinCoreExpr :=
  PsMinCoreExpr.app (PsMinCoreExpr.app (PsMinCoreExpr.constant (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]) [100, 101, 99, 69, 113]) List.nil) left) right

-- Exact proposition and decision operands, universe instances and complete spine.
def psMinCoreConditionalView (expr : PsMinCoreExpr) : Option PsMinCoreConditional :=
  match expr with
  | .app a no => match a with
    | .app b yes => match b with
      | .app d decision => match d with
        | .app e proposition => match e with
          | .app head type => match head with
            | .constant n levels => if psMinCoreNameEq n (PsMinCoreName.str PsMinCoreName.anonymous [105, 116, 101]) then
              if psMinByteEq levels [1] then match decision with
                | .app dc right => match dc with
                  | .app dh left => if psMinCoreExprEq 48 dh (PsMinCoreExpr.constant (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [66, 111, 111, 108]) [100, 101, 99, 69, 113]) List.nil) then
                      if psMinCoreExprEq 48 proposition (psMinCoreEquality left right) then
                        Option.some (PsMinCoreConditional.mk type left right yes no)
                      else Option.none
                    else Option.none
                  | _ => Option.none
                | _ => Option.none
              else Option.none
              else Option.none
            | _ => Option.none
          | _ => Option.none
        | _ => Option.none
      | _ => Option.none
    | _ => Option.none
  | _ => Option.none

def psMinCoreTypedPrimitive (fuel : Nat) (expr : PsMinCoreExpr) : Option PsMinOpTerm :=
  match expr with
  | .app fn type => match fn with
    | .constant name levels => if psMinByteEq levels [1] then
      match psMinCoreType fuel type with
      | Option.none => Option.none
      | Option.some a =>
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) [110, 105, 108]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.listNil a) 0 1 0 0 0) else
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) [99, 111, 110, 115]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.listCons a) 0 1 0 0 0) else
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [110, 111, 110, 101]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.optionNone a) 0 1 0 0 0) else
        if psMinCoreNameEq name (PsMinCoreName.str (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [115, 111, 109, 101]) then Option.some (PsMinOpTerm.primitive (PsMinOpPrimitive.optionSome a) 0 1 0 0 0) else Option.none
      else Option.none
    | _ => Option.none
  | _ => Option.none

def psMinCoreTranslate (fuel : Nat) : List PsMinCoreName -> PsMinCoreExpr -> Option PsMinOpTerm :=
  match fuel with
  | Nat.zero => fun _ _ => Option.none
  | Nat.succ rest => fun names expr =>
    let recur : List PsMinCoreName -> PsMinCoreExpr -> Option PsMinOpTerm := psMinCoreTranslate rest;
    let smaller : PsMinCoreExpr -> Option PsMinOpTerm := recur names;
    match psMinCoreConditionalView expr with
    | Option.some view =>
      match psMinCoreType rest view.type with
      | Option.none => Option.none
      | Option.some type => match smaller view.left with
        | Option.none => Option.none
        | Option.some left => match smaller view.right with
          | Option.none => Option.none
          | Option.some right => match smaller view.yes with
            | Option.none => Option.none
            | Option.some yes => match smaller view.no with
              | Option.none => Option.none
              | Option.some no => Option.some
                (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app
                  (PsMinOpTerm.primitive (PsMinOpPrimitive.boolEqIte type) 1 1 0 0 0) left) right) yes) no)
    | Option.none =>
      match psMinCoreTypedPrimitive rest expr with
      | Option.some primitive => Option.some primitive
      | Option.none => match expr with
        | .bvar index => Option.some (PsMinOpTerm.base (PsMinRegTerm.var index))
        | .natural value => Option.some (PsMinOpTerm.base (PsMinRegTerm.nat value))
        | .constant name levels => if psMinByteEq levels List.nil then
            match psMinCorePrimitive name with
            | Option.some primitive => Option.some primitive
            | Option.none => match psMinCoreResolve names name with
              | Option.none => Option.none
              | Option.some index => Option.some (PsMinOpTerm.base (PsMinRegTerm.constant index))
          else Option.none
        | .app fn arg => match smaller fn with
          | Option.none => Option.none
          | Option.some f => match smaller arg with
            | Option.none => Option.none
            | Option.some a => Option.some (PsMinOpTerm.app f a)
        | .lam _ _ type body => match psMinCoreType rest type with
          | Option.none => Option.none
          | Option.some t => match smaller body with
            | Option.none => Option.none
            | Option.some b => Option.some (PsMinOpTerm.lam t b)
        | .letE _ type value body => match psMinCoreType rest type with
          | Option.none => Option.none
          | Option.some t => match smaller value with
            | Option.none => Option.none
            | Option.some v => match smaller body with
              | Option.none => Option.none
              | Option.some b => Option.some (PsMinOpTerm.letE t v b)
        | _ => Option.none

def psMinCoreTranslateDeclarations (termFuel declarationFuel : Nat) :
    List PsMinCoreName -> List PsMinCoreDeclaration -> Option (List PsMinOpDeclaration) :=
  match declarationFuel with
  | Nat.zero => fun _ decls => match decls with
    | List.nil => Option.some List.nil
    | List.cons _ _ => Option.none
  | Nat.succ rest => fun names decls =>
    let smaller : List PsMinCoreName -> List PsMinCoreDeclaration -> Option (List PsMinOpDeclaration) :=
      psMinCoreTranslateDeclarations termFuel rest;
    match decls with
    | List.nil => Option.some List.nil
    | List.cons decl tail => if psMinCoreFresh names decl.name then
      match psMinCoreType termFuel decl.type with
      | Option.none => Option.none
      | Option.some type => match psMinCoreTranslate termFuel names decl.value with
        | Option.none => Option.none
        | Option.some value => match smaller (List.cons decl.name names) tail with
          | Option.none => Option.none
          | Option.some declarations => Option.some (List.cons (PsMinOpDeclaration.mk type value) declarations)
      else Option.none

structure PsMinCoreAdmission where
  source : List PsMinCoreDeclaration
  normalized : List PsMinOpDeclaration
  types : List PsMinRegTy

def psMinCoreAdmit (bytes : List Nat) (candidate : List PsMinCoreDeclaration) : Option PsMinCoreAdmission :=
  match psMinCoreDecodeCertificate bytes candidate with
  | Option.none => Option.none
  | Option.some source => match psMinCoreTranslateDeclarations 64 128 List.nil source with
    | Option.none => Option.none
    | Option.some normalized => match psMinOpCheckEnvironment 128 128 List.nil normalized with
      | Option.none => Option.none
      | Option.some types => Option.some (PsMinCoreAdmission.mk source normalized types)

-- Host construction uses a source-owned function, never an assumed record ABI.
def psMinCoreMakeDeclaration (name : PsMinCoreName) (height : Nat) (type value : PsMinCoreExpr) :
    PsMinCoreDeclaration := PsMinCoreDeclaration.mk name height type value
