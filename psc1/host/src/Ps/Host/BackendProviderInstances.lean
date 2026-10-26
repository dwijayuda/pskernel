import Lean
import Ps.BackendCommon.Plan

-- Native transport adapters stay outside every portable compiler closure.
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrPrimitiveType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrMachineIntegerType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrIntegerBinaryOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrIntegerCompareOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrFloatingType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrFloatBinaryOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrFloatCompareOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrLiteral
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrIntrinsic
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrParameter
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrMatchBinding
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrExpr
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrTypeParameter
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrStructureField
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrStructure
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrConstructorField
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrConstructor
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrInductive
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrDeclaration
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrExternalImport
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrModule

