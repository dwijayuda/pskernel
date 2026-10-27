import Ps.MinKernel.Profile.RegularProfile

inductive PsMinRegTerm where
  | var (index : Nat)
  | constant (index : Nat)
  | unit
  | nat (value : Nat)
  | boolean (value : Bool)
  | lam (domain : PsMinRegTy) (body : PsMinRegTerm)
  | app (fn : PsMinRegTerm) (argument : PsMinRegTerm)
  | ctor (dataIndex : Nat) (constructorIndex : Nat)
  | recursor (dataIndex : Nat) (universe : Nat) (parameters : Nat) (indices : Nat)
      (motives : Nat) (minors : Nat) (result : PsMinRegTy)

structure PsMinRegDeclaration where
  type : PsMinRegTy
  value : PsMinRegTerm

def psMinRegLookup (types : List PsMinRegTy) (index : Nat) : Option PsMinRegTy :=
  match types with
  | List.nil => Option.none
  | List.cons type rest =>
    match index with
    | Nat.zero => Option.some type
    | Nat.succ previous => psMinRegLookup rest previous

def psMinRegInfer (fuel : Nat) (specs : List PsMinRegSpec)
    (globals locals : List PsMinRegTy) (expression : PsMinRegTerm) : Option PsMinRegTy :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
    match expression with
    | PsMinRegTerm.var index => psMinRegLookup locals index
    | PsMinRegTerm.constant index => psMinRegLookup globals index
    | PsMinRegTerm.unit => Option.some PsMinRegTy.unit
    | PsMinRegTerm.nat _ => Option.some PsMinRegTy.nat
    | PsMinRegTerm.boolean _ => Option.some PsMinRegTy.boolean
    | PsMinRegTerm.lam domain body =>
      if psMinRegTyValid remaining (psMinRegSpecCount specs) domain then
        match psMinRegInfer remaining specs globals (List.cons domain locals) body with
        | Option.none => Option.none
        | Option.some result => Option.some (PsMinRegTy.arr domain result)
      else Option.none
    | PsMinRegTerm.app fn argument =>
      match psMinRegInfer remaining specs globals locals fn with
      | Option.none => Option.none
      | Option.some functionType =>
        match functionType with
        | PsMinRegTy.arr domain result =>
          match psMinRegInfer remaining specs globals locals argument with
          | Option.none => Option.none
          | Option.some argumentType =>
            if psMinRegTyEq remaining domain argumentType then Option.some result else Option.none
        | _ => Option.none
    | PsMinRegTerm.ctor dataIndex constructorIndex =>
      psMinRegCtorTypeAt specs dataIndex constructorIndex
    | PsMinRegTerm.recursor dataIndex universe parameters indices motives minors result =>
      psMinRegRecursorTypeAt remaining specs dataIndex universe parameters indices motives minors result

def psMinRegCheckDeclarations (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (globals : List PsMinRegTy) (declarations : List PsMinRegDeclaration) : Option (List PsMinRegTy) :=
  match declarations with
  | List.nil => Option.some globals
  | List.cons declaration rest =>
    match declarationFuel with
    | Nat.zero => Option.none
    | Nat.succ remaining =>
      if psMinRegTyValid termFuel (psMinRegSpecCount specs) declaration.type then
        match psMinRegInfer termFuel specs globals List.nil declaration.value with
        | Option.none => Option.none
        | Option.some actual =>
          if psMinRegTyEq termFuel actual declaration.type then
            psMinRegCheckDeclarations termFuel remaining specs (List.cons declaration.type globals) rest
          else Option.none
      else Option.none

def psMinRegCheckEnvironment (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegDeclaration) : Option (List PsMinRegTy) :=
  if psMinRegRegistryValid termFuel specs then
    psMinRegCheckDeclarations termFuel declarationFuel specs List.nil declarations
  else Option.none
