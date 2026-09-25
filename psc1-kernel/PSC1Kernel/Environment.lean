import PSC1Kernel.Declaration

namespace PSC1Kernel

def Name.listContains (needle : Name) : List Name → Bool
  | [] => false
  | x :: xs => Name.eq needle x || Name.listContains needle xs

def Name.hasDuplicates : List Name → Bool
  | [] => false
  | x :: xs => Name.listContains x xs || Name.hasDuplicates xs

/--
Portable declaration-index bucket count.  This is deliberately a small fixed
number rather than a host HashMap so the same source remains straightforward
to lower through PSC1/TypeScript.
-/
def environmentBucketCount : Nat := 256

def stringBucketHashCore : List Char → Nat → Nat
  | [], acc => acc
  | char :: rest, acc =>
      stringBucketHashCore rest
        ((acc * 33 + char.toNat + 1) % environmentBucketCount)

def stringBucketHash (value : String) : Nat :=
  stringBucketHashCore value.toList 5381

def Name.bucketHash : Name → Nat
  | .anonymous => 0
  | .str parent value =>
      (parent.bucketHash * 33 + stringBucketHash value + 1) %
        environmentBucketCount
  | .num parent value =>
      (parent.bucketHash * 33 + (value % environmentBucketCount) + 17) %
        environmentBucketCount

abbrev EnvironmentBucket := Nat × List ConstantInfo

def findEnvironmentBucket?
    (key : Nat) : List EnvironmentBucket → Option (List ConstantInfo)
  | [] => none
  | (candidate, values) :: rest =>
      if candidate == key then some values
      else findEnvironmentBucket? key rest

def findConstantInBucket?
    (name : Name) : List ConstantInfo → Option ConstantInfo
  | [] => none
  | info :: rest =>
      if Name.eq info.name name then some info
      else findConstantInBucket? name rest

def insertEnvironmentBucket
    (key : Nat)
    (info : ConstantInfo) : List EnvironmentBucket → List EnvironmentBucket
  | [] => [(key, [info])]
  | (candidate, values) :: rest =>
      if candidate == key then
        (candidate, info :: values) :: rest
      else
        (candidate, values) :: insertEnvironmentBucket key info rest

def buildEnvironmentIndex : List ConstantInfo → List EnvironmentBucket
  | [] => []
  | info :: rest =>
      insertEnvironmentBucket info.name.bucketHash info
        (buildEnvironmentIndex rest)

def replaceEnvironmentConstant
    (target : Name)
    (replacement : ConstantInfo) : List ConstantInfo → List ConstantInfo
  | [] => []
  | info :: rest =>
      if Name.eq info.name target then
        replacement :: rest
      else
        info :: replaceEnvironmentConstant target replacement rest

structure Environment where
  /-- Canonical newest-first declaration order used by replay/diagnostics. -/
  constants : List ConstantInfo
  /--
  Derived lookup index.  Entries are still validated with structural Name.eq,
  so bucket collisions cannot change lookup semantics.
  -/
  constantIndex : List EnvironmentBucket
  quotInitialized : Bool

def Environment.empty : Environment :=
  { constants := [], constantIndex := [], quotInitialized := false }

def Environment.find? (env : Environment) (name : Name) : Option ConstantInfo :=
  match findEnvironmentBucket? name.bucketHash env.constantIndex with
  | some values => findConstantInBucket? name values
  | none => none

def Environment.contains (env : Environment) (name : Name) : Bool :=
  env.find? name |>.isSome

def Environment.get? (env : Environment) (name : Name) : Option ConstantInfo :=
  env.find? name

def Environment.size (env : Environment) : Nat :=
  env.constants.length

def Environment.isNonRecStructure (env : Environment) (name : Name) : Bool :=
  match env.find? name with
  | some (.inductInfo info) =>
    !info.isRec && info.numIndices == 0 && info.ctors.length == 1
  | _ => false

def Environment.addUnchecked (env : Environment) (info : ConstantInfo) : Environment :=
  { env with
    constants := info :: env.constants
    constantIndex :=
      insertEnvironmentBucket info.name.bucketHash info env.constantIndex }

def Environment.replaceUnchecked
    (env : Environment)
    (info : ConstantInfo) : Environment :=
  let constants := replaceEnvironmentConstant info.name info env.constants
  { env with
    constants := constants
    constantIndex := buildEnvironmentIndex constants }

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
