/- Runtime only. No proof imports, implicit foundation or unchecked constants. -/
inductive PsMinTy where
  | empty
  | unit
  | nat
  | arr (domain : PsMinTy) (result : PsMinTy)

inductive PsMinExpr where
  | var (index : Nat)
  | constant (index : Nat)
  | unit
  | nat (value : Nat)
  | lam (domain : PsMinTy) (body : PsMinExpr)
  | app (fn : PsMinExpr) (argument : PsMinExpr)

structure PsMinDeclaration where
  type : PsMinTy
  value : PsMinExpr

def psMinTyEq (fuel : Nat) (left : PsMinTy) (right : PsMinTy) : Bool :=
  match fuel with
  | 0 => false
  | Nat.succ remaining =>
    match left with
    | PsMinTy.empty =>
      match right with
      | PsMinTy.empty => true
      | _ => false
    | PsMinTy.unit =>
      match right with
      | PsMinTy.unit => true
      | _ => false
    | PsMinTy.nat =>
      match right with
      | PsMinTy.nat => true
      | _ => false
    | PsMinTy.arr a b =>
      match right with
      | PsMinTy.arr c d => if psMinTyEq remaining a c then psMinTyEq remaining b d else false
      | _ => false

def psMinLookup (types : List PsMinTy) (index : Nat) : Option PsMinTy :=
  match types with
  | List.nil => Option.none
  | List.cons head tail =>
    match index with
    | 0 => Option.some head
    | Nat.succ previous => psMinLookup tail previous

def psMinInfer (fuel : Nat) (globals : List PsMinTy) (locals : List PsMinTy)
    (expression : PsMinExpr) : Option PsMinTy :=
  match fuel with
  | 0 => Option.none
  | Nat.succ remaining =>
    match expression with
    | PsMinExpr.var index => psMinLookup locals index
    | PsMinExpr.constant index => psMinLookup globals index
    | PsMinExpr.unit => Option.some PsMinTy.unit
    | PsMinExpr.nat _ => Option.some PsMinTy.nat
    | PsMinExpr.lam domain body =>
      match psMinInfer remaining globals (List.cons domain locals) body with
      | Option.none => Option.none
      | Option.some result => Option.some (PsMinTy.arr domain result)
    | PsMinExpr.app fn argument =>
      match psMinInfer remaining globals locals fn with
      | Option.none => Option.none
      | Option.some functionType =>
        match functionType with
        | PsMinTy.arr domain result =>
          match psMinInfer remaining globals locals argument with
          | Option.none => Option.none
          | Option.some argumentType =>
            if psMinTyEq remaining domain argumentType then Option.some result else Option.none
        | _ => Option.none

def psMinCheckDeclarations (termFuel : Nat) (declarationFuel : Nat)
    (globals : List PsMinTy) (declarations : List PsMinDeclaration) : Option (List PsMinTy) :=
  match declarations with
  | List.nil => Option.some globals
  | List.cons declaration rest =>
    match declarationFuel with
    | 0 => Option.none
    | Nat.succ remaining =>
      match psMinInfer termFuel globals List.nil declaration.value with
      | Option.none => Option.none
      | Option.some psMinInferred =>
        if psMinTyEq termFuel psMinInferred declaration.type then
          psMinCheckDeclarations termFuel remaining (List.cons declaration.type globals) rest
        else Option.none

def psMinCheckEnvironment (termFuel : Nat) (declarationFuel : Nat)
    (declarations : List PsMinDeclaration) : Option (List PsMinTy) :=
  psMinCheckDeclarations termFuel declarationFuel List.nil declarations
