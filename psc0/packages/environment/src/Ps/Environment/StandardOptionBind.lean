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

-- The selected method is specialized through its checked dictionary before
-- runtime erasure. Retain only the Bind family and projection metadata needed
-- to authenticate its unboxed field; Option.bind already has a runtime owner.
def psStandardOptionBindRuntimeNames : List PsName :=
  ["Bind", "Bind.mk", "Bind.rec", "Bind.bind"].map psDecisionName

def psStandardOptionBindRuntimeDeclarations (environment : PsEnvironment) :
    List PsDeclaration :=
  psStandardOptionBindRuntimeNames.filterMap (psEnvironmentFind environment)
