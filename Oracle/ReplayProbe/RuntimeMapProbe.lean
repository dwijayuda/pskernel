module

prelude
public import Lean.MetavarContext
public import Lean.Data.PersistentHashMap

public section

namespace ProofScript.RuntimeProbe

abbrev ExprMap :=
  Lean.PersistentHashMap Lean.MVarId Lean.Expr

abbrev ExprNode :=
  Lean.PersistentHashMap.Node Lean.MVarId Lean.Expr

abbrev ExprEntry :=
  Lean.PersistentHashMap.Entry Lean.MVarId Lean.Expr ExprNode

def insertExprMap
    (m : ExprMap)
    (id : Lean.MVarId)
    (value : Lean.Expr) : ExprMap :=
  m.insert id value

def findExprMap?
    (m : ExprMap)
    (id : Lean.MVarId) : Option Lean.Expr :=
  m.find? id

def insertDelayedExprAssignment
    (m : Lean.MetavarContext)
    (id : Lean.MVarId)
    (fvars : Array Lean.Expr)
    (pending : Lean.MVarId) : Lean.MetavarContext :=
  {
    m with
    dAssignment := m.dAssignment.insert id {
      fvars
      mvarIdPending := pending
    }
  }

def firstBucketIndex
    (id : Lean.MVarId) : Nat :=
  let h := hash id |>.toUSize
  (Lean.PersistentHashMap.mod2Shift
    h
    Lean.PersistentHashMap.shift).toNat

def replaceNullEntry
    (entries : Array ExprEntry)
    (index : Nat)
    (id : Lean.MVarId)
    (value : Lean.Expr) : Array ExprEntry :=
  entries.modify index fun entry =>
    match entry with
    | .null => .entry id value
    | other => other

end ProofScript.RuntimeProbe
