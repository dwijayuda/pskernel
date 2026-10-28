-- Test-only compatibility probe; not a minimal-kernel runtime module.
def psR6ModernAppend (left : String) (right : String) : String :=
  String.append left right

def psR6LegacyAppend (left : String) (right : String) : String :=
  String.Internal.append left right
