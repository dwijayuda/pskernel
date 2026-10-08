import ProofScript.Data.Option

inductive Result (α : Type) (ε : Type) where
  | ok (value : α)
  | error (error : ε)

def resultMap {α : Type} {β : Type} {ε : Type}
    (f : α -> β) (value : Result α ε) : Result β ε :=
  match value with
  | Result.ok x => Result.ok (f x)
  | Result.error err => Result.error err

def resultMapError {α : Type} {ε : Type} {δ : Type}
    (f : ε -> δ) (value : Result α ε) : Result α δ :=
  match value with
  | Result.ok x => Result.ok x
  | Result.error err => Result.error (f err)

def resultGetOrElse {α : Type} {ε : Type}
    (value : Result α ε) (fallback : α) : α :=
  match value with
  | Result.ok x => x
  | Result.error err => fallback

def resultToOption {α : Type} {ε : Type}
    (value : Result α ε) : Option α :=
  match value with
  | Result.ok x => Option.some x
  | Result.error err => Option.none

def resultBind {α : Type} {β : Type} {ε : Type}
    (value : Result α ε)
    (f : α -> Result β ε) : Result β ε :=
  match value with
  | Result.ok x => f x
  | Result.error err => Result.error err

def resultFromOption {α : Type} {ε : Type}
    (value : Option α) (error : ε) : Result α ε :=
  match value with
  | Option.none => Result.error error
  | Option.some x => Result.ok x

def resultIsOk {α : Type} {ε : Type}
    (value : Result α ε) : Bool :=
  match value with
  | Result.ok x => true
  | Result.error err => false
