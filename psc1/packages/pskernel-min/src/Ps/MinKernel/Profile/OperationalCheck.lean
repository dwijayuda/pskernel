import Ps.MinKernel.Profile.OperationalProfile

inductive PsMinOpTerm where
  | base (expression : PsMinRegTerm)
  | lam (domain : PsMinRegTy) (body : PsMinOpTerm)
  | app (fn : PsMinOpTerm) (argument : PsMinOpTerm)
  | letE (type : PsMinRegTy) (value : PsMinOpTerm) (body : PsMinOpTerm)
  | projection (slot : Nat) (field : Nat)
  | primitive (schema : PsMinOpPrimitive) (sortLevel : Nat) (parameters : Nat)
      (indices : Nat) (motives : Nat) (minors : Nat)

structure PsMinOpDeclaration where
  type : PsMinRegTy
  value : PsMinOpTerm

def psMinOpInfer (fuel : Nat) (specs : List PsMinRegSpec)
    (globals locals : List PsMinRegTy) (expression : PsMinOpTerm) : Option PsMinRegTy :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
    match expression with
    | PsMinOpTerm.base term => psMinRegInfer remaining specs globals locals term
    | PsMinOpTerm.projection slot field => psMinOpProjectionType specs slot field
    | PsMinOpTerm.primitive schema level parameters indices motives minors =>
      psMinOpPrimitiveType remaining (psMinRegSpecCount specs) schema level parameters indices motives minors
    | PsMinOpTerm.lam domain body =>
      if psMinRegTyValid remaining (psMinRegSpecCount specs) domain then
        match psMinOpInfer remaining specs globals (List.cons domain locals) body with
        | Option.none => Option.none
        | Option.some result => Option.some (PsMinRegTy.arr domain result)
      else Option.none
    | PsMinOpTerm.app fn argument =>
      match psMinOpInfer remaining specs globals locals fn with
      | Option.none => Option.none
      | Option.some functionType =>
        match functionType with
        | PsMinRegTy.arr domain result =>
          match psMinOpInfer remaining specs globals locals argument with
          | Option.none => Option.none
          | Option.some argumentType =>
            if psMinRegTyEq remaining domain argumentType then Option.some result else Option.none
        | _ => Option.none
    | PsMinOpTerm.letE type value body =>
      if psMinRegTyValid remaining (psMinRegSpecCount specs) type then
        match psMinOpInfer remaining specs globals locals value with
        | Option.none => Option.none
        | Option.some actual =>
          if psMinRegTyEq remaining actual type then
            psMinOpInfer remaining specs globals (List.cons type locals) body
          else Option.none
      else Option.none

def psMinOpCheckDeclarations (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (globals : List PsMinRegTy) (declarations : List PsMinOpDeclaration) : Option (List PsMinRegTy) :=
  match declarations with
  | List.nil => Option.some globals
  | List.cons declaration rest =>
    match declarationFuel with
    | Nat.zero => Option.none
    | Nat.succ remaining =>
      if psMinRegTyValid termFuel (psMinRegSpecCount specs) declaration.type then
        match psMinOpInfer termFuel specs globals List.nil declaration.value with
        | Option.none => Option.none
        | Option.some actual =>
          if psMinRegTyEq termFuel actual declaration.type then
            psMinOpCheckDeclarations termFuel remaining specs (List.cons declaration.type globals) rest
          else Option.none
      else Option.none

def psMinOpCheckEnvironment (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinOpDeclaration) : Option (List PsMinRegTy) :=
  if psMinRegRegistryValid termFuel specs then
    psMinOpCheckDeclarations termFuel declarationFuel specs List.nil declarations
  else Option.none
