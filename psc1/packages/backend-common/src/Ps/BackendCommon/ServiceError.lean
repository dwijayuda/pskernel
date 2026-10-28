-- Shared candidate error data. The namespace is retained for source/API compatibility.
-- This module has no frontend, checking or publication authority.
namespace Ps.Internal.CompilerService

structure Error where
  phase : String
  code : String
  moduleName : String
  declaration : String
  line : Nat
  column : Nat

def failure (phase code : String) : Error :=
  Error.mk phase code "" "" 0 0

end Ps.Internal.CompilerService
