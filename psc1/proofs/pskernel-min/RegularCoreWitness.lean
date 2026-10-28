import RegularSourceInstance
import Lean

open Lean

def regularWitnessName : PsName → Json
  | .anonymous => Json.mkObj [("k", Json.str "a")]
  | .str parent value => Json.mkObj [("k", Json.str "s"), ("p", regularWitnessName parent), ("v", toJson value)]
  | .num parent value => Json.mkObj [("k", Json.str "n"), ("p", regularWitnessName parent), ("v", toJson (toString value))]

def regularWitnessLevel : PsLevel → Json
  | .zero => Json.mkObj [("k", Json.str "z")]
  | .succ level => Json.mkObj [("k", Json.str "s"), ("o", regularWitnessLevel level)]
  | _ => Json.null

def regularWitnessExpr : PsExpr → Json
  | .bvar index => Json.mkObj [("k", Json.str "b"), ("i", toJson index)]
  | .constE name levels => Json.mkObj [("k", Json.str "const"), ("n", regularWitnessName name), ("ls", toJson (levels.map regularWitnessLevel))]
  | .app fn arg => Json.mkObj [("k", Json.str "app"), ("f", regularWitnessExpr fn), ("a", regularWitnessExpr arg)]
  | .lam name type body .explicit => Json.mkObj [("k", Json.str "lam"), ("n", regularWitnessName name), ("bi", Json.str "default"), ("t", regularWitnessExpr type), ("b", regularWitnessExpr body)]
  | _ => Json.null

def main : IO Unit := IO.println (regularWitnessExpr Ps.MinKernel.RegularSource.sourceCoreInstance).compress
