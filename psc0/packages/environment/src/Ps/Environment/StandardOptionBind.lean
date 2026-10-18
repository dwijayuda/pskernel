import Ps.Environment.StandardOptionBindData
import Ps.Environment.StandardClass

/-!
Pinned additive Option bind library. The 36 declarations were exported against
the frozen final recursor and LawfulBEq stage, independently of the original
117-declaration Order asset. Logical dependencies do not automatically become
instance-search inputs.

The selected source method needs the native Monad Option → Bind Option chain.
Only Bind, Monad and MonoBind are registered, together with their three ordinary
dictionaries. Native metadata is audited before this extension is selected.
-/

def psStandardOptionBindExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardOptionBindCandidateDeclarations.foldl
    psEnvironmentInsert environment
  let environment := psStandardOptionBindCandidateReducibility.foldl
    (fun env (name, status) => psEnvironmentSetReducibility env name status) environment
  let environment := ["Bind", "Monad", "Lean.Order.MonoBind"].foldl (fun env name =>
    if env.classes.any (psNameEq (psDecisionName name)) then env
    else psStandardRegisterClass env name) environment
  let registrations : List (String × String) := [
    ("Monad.toBind", "Bind"),
    ("instMonadOption", "Monad"),
    ("Lean.Order.instMonoBindOption", "Lean.Order.MonoBind")]
  registrations.foldl (fun env (name, className) =>
    psStandardRegisterInstances env className
      (psStandardOptionBindCandidateDeclarations.filter (fun declaration =>
        psNameEq (psDeclarationName declaration) (psDecisionName name))) 1000) environment

-- Runtime class evidence follows the same checked declaration owner. The
-- logical MonoBind proof family is erased; only the eight data families,
-- executable method projections and actual Option dictionaries are retained.
def psStandardOptionBindRuntimeNames : List PsName :=
  ["Applicative", "Bind", "Functor", "Monad", "Pure", "Seq", "SeqLeft", "SeqRight",
    "instFunctorOption", "instMonadOption", "Applicative.mk", "Applicative.rec",
    "Bind.bind", "Bind.mk", "Bind.rec", "Functor.map", "Functor.mk", "Functor.rec",
    "Monad.mk", "Monad.rec", "Monad.toBind", "Pure.mk", "Pure.rec", "Seq.mk",
    "Seq.rec", "SeqLeft.mk", "SeqLeft.rec", "SeqRight.mk", "SeqRight.rec"].map psDecisionName

def psStandardOptionBindRuntimeDeclarations (environment : PsEnvironment) :
    List PsDeclaration :=
  psStandardOptionBindRuntimeNames.filterMap (psEnvironmentFind environment)
