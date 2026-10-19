import PSC1Kernel.Declaration

namespace PSC1Kernel

def Name.listContains (needle : Name) : List Name → Bool
  | [] => false
  | x :: xs => Name.eq needle x || Name.listContains needle xs

def Name.hasDuplicates : List Name → Bool
  | [] => false
  | x :: xs => Name.listContains x xs || Name.hasDuplicates xs

/--
Portable declaration-index bucket count. A fixed-size Array keeps bucket
selection O(1) while each bucket still uses structural Name.eq for collision
resolution. This stays straightforward to lower through PSC1/TypeScript.
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

abbrev EnvironmentIndex := Array (List ConstantInfo)

def emptyEnvironmentIndex : EnvironmentIndex :=
  Array.replicate environmentBucketCount []

def findConstantInBucket?
    (name : Name) : List ConstantInfo → Option ConstantInfo
  | [] => none
  | info :: rest =>
      if Name.eq info.name name then some info
      else findConstantInBucket? name rest

def insertEnvironmentIndex
    (index : EnvironmentIndex)
    (info : ConstantInfo) : EnvironmentIndex :=
  let key := info.name.bucketHash
  match index[key]? with
  | some values => index.set! key (info :: values)
  | none => index

def buildEnvironmentIndex : List ConstantInfo → EnvironmentIndex
  | [] => emptyEnvironmentIndex
  | info :: rest =>
      insertEnvironmentIndex (buildEnvironmentIndex rest) info

def replaceEnvironmentConstant
    (target : Name)
    (replacement : ConstantInfo) : List ConstantInfo → List ConstantInfo
  | [] => []
  | info :: rest =>
      if Name.eq info.name target then
        replacement :: rest
      else
        info :: replaceEnvironmentConstant target replacement rest

def replaceConstantInBucket
    (target : Name)
    (replacement : ConstantInfo) : List ConstantInfo → List ConstantInfo
  | [] => []
  | info :: rest =>
      if Name.eq info.name target then
        replacement :: rest
      else
        info :: replaceConstantInBucket target replacement rest

structure Environment where
  /-- Canonical newest-first declaration order used by replay/diagnostics. -/
  constants : List ConstantInfo
  /--
  Derived fixed-size lookup index. Bucket collisions are resolved using
  structural Name.eq, so the index cannot change lookup semantics.
  -/
  constantIndex : EnvironmentIndex := #[]
  quotInitialized : Bool

def Environment.empty : Environment :=
  {
    constants := []
    constantIndex := emptyEnvironmentIndex
    quotInitialized := false
  }

def Environment.find? (env : Environment) (name : Name) : Option ConstantInfo :=
  if env.constantIndex.size == environmentBucketCount then
    match env.constantIndex[name.bucketHash]? with
    | some values => findConstantInBucket? name values
    | none => none
  else
    -- Preserve correctness for explicitly constructed legacy environments
    -- that omit the derived index.
    findConstantInBucket? name env.constants

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
  let index :=
    if env.constantIndex.size == environmentBucketCount then
      env.constantIndex
    else
      buildEnvironmentIndex env.constants
  { env with
    constants := info :: env.constants
    constantIndex := insertEnvironmentIndex index info }

def Environment.replaceUnchecked
    (env : Environment)
    (info : ConstantInfo) : Environment :=
  let constants := replaceEnvironmentConstant info.name info env.constants
  let index :=
    if env.constantIndex.size == environmentBucketCount then
      let key := info.name.bucketHash
      match env.constantIndex[key]? with
      | some values =>
          env.constantIndex.set! key
            (replaceConstantInBucket info.name info values)
      | none =>
          buildEnvironmentIndex constants
    else
      buildEnvironmentIndex constants
  { env with
    constants := constants
    constantIndex := index }

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
