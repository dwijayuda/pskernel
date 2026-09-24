import Lean

open Lean

unsafe def main (_args : List String) : IO Unit := do
  initSearchPath (← findSysroot)
  withImportModules #[{module := `Std}] {} fun env => do
    let target := `Init.Data.Int.DivMod.Lemmas
    let rootsPerShard : Nat := 10
    let mut seen : NameSet := {}
    let mut shardOffset : Nat := 0
    let mut rootOffset : Nat := 0
    let mut found := false
    for idx in [0:env.header.moduleNames.size] do
      if let some data := env.header.moduleData[idx]? then
        let mut roots : Array Name := #[]
        for n in data.constNames do
          unless seen.contains n do
            seen := seen.insert n
            roots := roots.push n
        unless roots.isEmpty do
          let moduleName := env.header.moduleNames[idx]!
          let parts := (roots.size + rootsPerShard - 1) / rootsPerShard
          if moduleName == target then
            found := true
            IO.println s!"module={moduleName} moduleIndex={idx} rootOffset={rootOffset} shardOffset={shardOffset} roots={roots.size} parts={parts}"
            let mut start := 0
            let mut part := 0
            while start < roots.size do
              let stop := min roots.size (start + rootsPerShard)
              let slice := roots.extract start stop
              IO.println s!"shard={shardOffset + part} part={part} canonicalRootStart={rootOffset + start} roots={slice.size} names={slice.toList.map Name.toString}"
              start := stop
              part := part + 1
          rootOffset := rootOffset + roots.size
          shardOffset := shardOffset + parts
    unless found do
      throw <| IO.userError "target module not found"
