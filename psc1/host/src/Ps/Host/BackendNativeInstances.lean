import Ps.BackendCommon.Plan

-- Native diagnostic/equality conveniences are outside the portable compiler closure.
-- Portable target decisions use psBackendTargetEq explicitly.
deriving instance BEq for PsBackendTarget
deriving instance Repr for PsBackendTarget
deriving instance Repr for PsVerifiedIrValidationError
