import Ps.KernelCore.Core.Expr.Shared

/-!
Executable comparison of binder Prop/Type regimes. This is not universe
equality. No set model, declarative judgments or checker oracle is imported.
-/
namespace PsKernelSemantics.UniverseRegime

inductive Atom where
  | param (name : PsKernelName)
  | mvar (name : PsKernelName)
  deriving DecidableEq

inductive Profile where
  | never
  | allZero (variables : List Atom)

def inter : Profile → Profile → Profile
  | .allZero xs, .allZero ys => .allZero (xs ++ ys)
  | _, _ => .never

def ofLevel : PsKernelLevel → Profile
  | .zero => .allZero []
  | .succ _ => .never
  | .max a b => inter (ofLevel a) (ofLevel b)
  | .imax _ b => ofLevel b
  | .param n => .allZero [.param n]
  | .mvar n => .allZero [.mvar n]

def subset (xs ys : List Atom) : Bool :=
  xs.all (fun x => decide (x ∈ ys))

def compare : Profile → Profile → Bool
  | .never, .never => true
  | .allZero xs, .allZero ys => subset xs ys && subset ys xs
  | _, _ => false

def check (a b : PsKernelLevel) : Bool := compare (ofLevel a) (ofLevel b)

def isNever : Profile → Bool
  | .never => true
  | .allZero _ => false


end PsKernelSemantics.UniverseRegime
