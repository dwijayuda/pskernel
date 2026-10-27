namespace Ps.MinKernel

/- Runtime only. No proof imports, implicit foundation or unchecked constants. -/
inductive Ty where
  | empty
  | unit
  | nat
  | arr (domain : Ty) (result : Ty)

inductive Expr where
  | var (index : Nat)
  | constant (index : Nat)
  | unit
  | nat (value : Nat)
  | lam (domain : Ty) (body : Expr)
  | app (fn : Expr) (argument : Expr)

structure Declaration where
  type : Ty
  value : Expr

def tyEq (fuel : Nat) (left : Ty) (right : Ty) : Bool :=
  match fuel with
  | 0 => false
  | Nat.succ remaining =>
    match left with
    | Ty.empty =>
      match right with
      | Ty.empty => true
      | _ => false
    | Ty.unit =>
      match right with
      | Ty.unit => true
      | _ => false
    | Ty.nat =>
      match right with
      | Ty.nat => true
      | _ => false
    | Ty.arr a b =>
      match right with
      | Ty.arr c d => if tyEq remaining a c then tyEq remaining b d else false
      | _ => false

def lookup (types : List Ty) (index : Nat) : Option Ty :=
  match types with
  | List.nil => Option.none
  | List.cons head tail =>
    match index with
    | 0 => Option.some head
    | Nat.succ previous => lookup tail previous

def infer (fuel : Nat) (globals : List Ty) (locals : List Ty)
    (expression : Expr) : Option Ty :=
  match fuel with
  | 0 => Option.none
  | Nat.succ remaining =>
    match expression with
    | Expr.var index => lookup locals index
    | Expr.constant index => lookup globals index
    | Expr.unit => Option.some Ty.unit
    | Expr.nat _ => Option.some Ty.nat
    | Expr.lam domain body =>
      match infer remaining globals (List.cons domain locals) body with
      | Option.none => Option.none
      | Option.some result => Option.some (Ty.arr domain result)
    | Expr.app fn argument =>
      match infer remaining globals locals fn with
      | Option.none => Option.none
      | Option.some functionType =>
        match functionType with
        | Ty.arr domain result =>
          match infer remaining globals locals argument with
          | Option.none => Option.none
          | Option.some argumentType =>
            if tyEq remaining domain argumentType then Option.some result else Option.none
        | _ => Option.none

def checkDeclarations (termFuel : Nat) (declarationFuel : Nat)
    (globals : List Ty) (declarations : List Declaration) : Option (List Ty) :=
  match declarations with
  | List.nil => Option.some globals
  | List.cons declaration rest =>
    match declarationFuel with
    | 0 => Option.none
    | Nat.succ remaining =>
      match infer termFuel globals List.nil declaration.value with
      | Option.none => Option.none
      | Option.some inferred =>
        if tyEq termFuel inferred declaration.type then
          checkDeclarations termFuel remaining (List.cons declaration.type globals) rest
        else Option.none

def checkEnvironment (termFuel : Nat) (declarationFuel : Nat)
    (declarations : List Declaration) : Option (List Ty) :=
  checkDeclarations termFuel declarationFuel List.nil declarations

end Ps.MinKernel
