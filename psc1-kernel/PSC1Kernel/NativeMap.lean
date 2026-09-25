import PSC1Kernel.Replay

namespace PSC1Kernel.NativeMap

inductive NativeMapValue where
  | bool (value : Bool)
  | nat (value : Nat)

structure NativeMapEntry where
  name : Name
  value : NativeMapValue

def nativeMapNamePart (prefix : Name) (part : String) : Name :=
  match part.toNat? with
  | some index => .num prefix index
  | none => .str prefix part

def nativeMapName (text : String) : Except String Name := do
  if text.isEmpty then
    throw "native map name is empty"
  let parts := text.splitOn "."
  let rec go (prefix : Name) : List String → Except String Name
    | [] => pure prefix
    | part :: rest => do
        if part.isEmpty then
          throw ("native map name has an empty segment: " ++ text)
        go (nativeMapNamePart prefix part) rest
  go .anonymous parts

def nativeMapFind?
    (name : Name)
    (entries : List NativeMapEntry) : Option NativeMapValue :=
  match entries with
  | [] => none
  | entry :: rest =>
      if Name.eq entry.name name then some entry.value
      else nativeMapFind? name rest

def nativeMapContains (name : Name) (entries : List NativeMapEntry) : Bool :=
  (nativeMapFind? name entries).isSome

def parseNativeMapLine
    (lineNo : Nat)
    (line : String) : Except String (Option NativeMapEntry) := do
  if line.isEmpty || line.startsWith "#" then
    return none
  match line.splitOn "\t" with
  | ["nat", nameText, valueText] => do
      let name ← nativeMapName nameText
      let some value := valueText.toNat?
        | throw ("native map line " ++ toString lineNo ++ ": invalid Nat value")
      pure (some { name := name, value := .nat value })
  | ["bool", nameText, "true"] =>
      pure (some { name := ← nativeMapName nameText, value := .bool true })
  | ["bool", nameText, "false"] =>
      pure (some { name := ← nativeMapName nameText, value := .bool false })
  | _ =>
      throw (
        "native map line " ++ toString lineNo ++
        ": expected 'nat<TAB>Name<TAB>Nat' or 'bool<TAB>Name<TAB>true|false'")

def parseNativeMap (text : String) : Except String (List NativeMapEntry) := do
  let rec go
      (lineNo : Nat)
      (seen : List NativeMapEntry)
      (lines : List String) : Except String (List NativeMapEntry) := do
    match lines with
    | [] => pure seen.reverse
    | line :: rest =>
        match ← parseNativeMapLine lineNo line with
        | none => go (lineNo + 1) seen rest
        | some entry =>
            if nativeMapContains entry.name seen then
              throw (
                "native map line " ++ toString lineNo ++
                ": duplicate constant " ++ PSC1Kernel.Replay.replayNameString entry.name)
            go (lineNo + 1) (entry :: seen) rest
  go 1 [] (text.splitOn "\n")

def nativeMapEvaluator (entries : List NativeMapEntry) : NativeEvaluator :=
  {
    evalBool := fun name =>
      match nativeMapFind? name entries with
      | some (.bool value) => .ok (some value)
      | some (.nat _) => .error (
          "native map kind mismatch for " ++ PSC1Kernel.Replay.replayNameString name)
      | none => .ok none
    evalNat := fun name =>
      match nativeMapFind? name entries with
      | some (.nat value) => .ok (some value)
      | some (.bool _) => .error (
          "native map kind mismatch for " ++ PSC1Kernel.Replay.replayNameString name)
      | none => .ok none
  }

def loadNativeMap (path : String) : IO NativeEvaluator := do
  let text ← IO.FS.readFile path
  match parseNativeMap text with
  | .ok entries => pure (nativeMapEvaluator entries)
  | .error err =>
      throw <| IO.userError ("invalid native evaluator map " ++ path ++ ": " ++ err)

end PSC1Kernel.NativeMap
