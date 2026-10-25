import PsKernelExprV2SemanticPrefixProofs
import Ps.KernelCore.Core.ExprV2.Decode

/-!
Local correspondence for the actual production paged decoder.

DecodedPrefix describes successful production DecodedRequire lookups, not a
caller-supplied expression array or the research decoder. These lemmas consume
that internal prefix and the strict child ordering already established by
validation. They preserve every syntactic constructor field.

Decoded storage layout, Push preservation, the complete fuel worker and the
public DecodeChecked result are separate obligations. No whole-decoder or
checker-wide soundness conclusion follows from this module alone.
-/
namespace PsKernelExprV2DecodedNodeProofs

open PsKernelExprV2SemanticPrefixProofs

def DecodedPrefix (built : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr) : Prop :=
  ∀ id, id < built.size →
    psKernelExprV2DecodedRequire built id = Except.ok (meaning id)

theorem decoded_node_interprets
    (built : PsKernelExprV2Decoded) (meaning : Nat → PsKernelExpr)
    (node : PsKernelExprV2Node)
    (decoded : DecodedPrefix built meaning)
    (children : ChildrenBefore built.size node) :
    psKernelExprV2DecodedNode built node = Except.ok (Interpret meaning node) := by
  cases node with
  | bvar index => rfl
  | fvar name => rfl
  | mvar name => rfl
  | sort level => rfl
  | const name levels => rfl
  | lit literal => rfl
  | app fn arg =>
      have lookupFn := decoded fn children.1
      have lookupArg := decoded arg children.2
      simp only [psKernelExprV2DecodedNode, psKernelExprV2DecodedWith2,
        lookupFn, lookupArg, Interpret]
  | lam name type body info =>
      have lookupType := decoded type children.1
      have lookupBody := decoded body children.2
      simp only [psKernelExprV2DecodedNode, psKernelExprV2DecodedWith2,
        lookupType, lookupBody, psKernelExprV2DecodedLam, Interpret]
  | forallE name type body info =>
      have lookupType := decoded type children.1
      have lookupBody := decoded body children.2
      simp only [psKernelExprV2DecodedNode, psKernelExprV2DecodedWith2,
        lookupType, lookupBody, psKernelExprV2DecodedForall, Interpret]
  | letE name type value body nondep =>
      have lookupType := decoded type children.1
      have lookupValue := decoded value children.2.1
      have lookupBody := decoded body children.2.2
      simp only [psKernelExprV2DecodedNode, psKernelExprV2DecodedWith3,
        lookupType, lookupValue, lookupBody, psKernelExprV2DecodedLet, Interpret]
  | mdata tag body =>
      have lookupBody := decoded body children
      simp only [psKernelExprV2DecodedNode, psKernelExprV2DecodedWith1,
        lookupBody, Interpret]
  | proj name index body =>
      have lookupBody := decoded body children
      simp only [psKernelExprV2DecodedNode, psKernelExprV2DecodedWith1,
        lookupBody, Interpret]

/- At the worker's current position, the actual source entry decodes to the
   shared meaning previously established by validation. The prefix premise is
   an internal worker invariant; it is not assumed of external input. -/
theorem decoded_entry_interprets
    (source : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr) (id : Nat) (entry : PsKernelExprV2Entry)
    (semantic : SemanticPrefix source meaning)
    (decoded : DecodedPrefix built meaning)
    (position : built.size = id)
    (inside : id < source.size)
    (found : psKernelExprV2PagedFind source id = some entry) :
    psKernelExprV2DecodedNode built entry.node = Except.ok (meaning id) := by
  rcases semantic id inside with
    ⟨witness, lookup, children, interpretation, _metadata⟩
  have same : witness = entry := Option.some.inj (lookup.symm.trans found)
  subst witness
  have bounds : ChildrenBefore built.size entry.node := by
    simpa only [position] using children
  have decodedNode := decoded_node_interprets built meaning entry.node decoded bounds
  exact decodedNode.trans
    (congrArg (fun expr => (Except.ok expr : Except String PsKernelExpr)) interpretation.symm)

end PsKernelExprV2DecodedNodeProofs

#print axioms PsKernelExprV2DecodedNodeProofs.decoded_node_interprets
#print axioms PsKernelExprV2DecodedNodeProofs.decoded_entry_interprets
