import Ps.KernelCore.Metatheory.Judgments

/- Semantic environment-extension relations used by checked admission proofs. -/

def PsKernelEnvironmentExtendsBy
    (before after : PsKernelEnvironment)
    (added : List PsKernelConstantInfo) : Prop :=
  after.constants = List.append added before.constants ∧
  after.runtime = before.runtime

def PsKernelEnvironmentExtendsOne
    (before after : PsKernelEnvironment)
    (info : PsKernelConstantInfo) : Prop :=
  PsKernelEnvironmentExtendsBy before after (List.cons info List.nil)

def PsKernelDeclarationExtension
    (before after : PsKernelEnvironment)
    (info : PsKernelConstantInfo) : Prop :=
  PsKernelEnvironmentExtendsOne before after info ∧
  after.quotInitialized = before.quotInitialized

def PsKernelQuotExtension
    (before after : PsKernelEnvironment)
    (added : List PsKernelConstantInfo) : Prop :=
  PsKernelEnvironmentExtendsBy before after added ∧
  before.quotInitialized = false ∧
  after.quotInitialized = true

theorem psKernelEnvironmentExtendsBy_refl
    (environment : PsKernelEnvironment) :
    PsKernelEnvironmentExtendsBy environment environment List.nil := by
  constructor <;> rfl
