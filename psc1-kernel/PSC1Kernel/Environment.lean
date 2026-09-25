import PSC1Kernel.Declaration

namespace PSC1Kernel

def Name.listContains (needle : Name) : List Name → Bool
  | [] => false
  | x :: xs => Name.eq needle x || Name.listContains needle xs

def Name.hasDuplicates : List Name → Bool
  | [] => false
  | x :: xs => Name.listContains x xs || Name.hasDuplicates xs

structure Environment where
  constants : List ConstantInfo
  quotInitialized : Bool

def Environment.empty : Environment :=
  { constants := [], quotInitialized := false }

def Environment.find? (env : Environment) (name : Name) : Option ConstantInfo :=
  let rec go : List ConstantInfo → Option ConstantInfo
    | [] => none
    | info :: rest =>
      if Name.eq info.name name then some info else go rest
  go env.constants

def Environment.contains (env : Environment) (name : Name) : Bool :=
  env.find? name |>.isSome

def Environment.get? (env : Environment) (name : Name) : Option ConstantInfo :=
  env.find? name

def Environment.size (env : Environment) : Nat :=
  env.constants.length

def Environment.addUnchecked (env : Environment) (info : ConstantInfo) : Environment :=
  { env with constants := info :: env.constants }

def Environment.add (env : Environment) (info : ConstantInfo) : Except String Environment :=
  if env.contains info.name then
    .error "already declared"
  else if Name.hasDuplicates info.levelParams then
    .error "duplicate universe parameter"
  else
    .ok (env.addUnchecked info)

def Environment.markQuotInitialized (env : Environment) : Environment :=
  if env.quotInitialized then env else { env with quotInitialized := true }

end PSC1Kernel
