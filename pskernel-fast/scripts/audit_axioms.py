#!/usr/bin/env python3
"""Fail-closed P0/P1 theorem-assumption audit (NOT a kernel soundness proof).

The Lean source itself emits '#print axioms <theorem>' for all qualified
cross-layer P1 lemmas. GitHub CI obtains these statements from the exact
pinned Lean compiler and this script pins their names and allowed
assumptions. This is deliberately limited to the theorems listed below.
"""
import pathlib
import re
import sys

REPORTED = re.compile(
    r"'(?P<theorem>[^']+)' (?:depends on axioms:\s*\[(?P<axioms>[^\]]*)\]"
    r"|(?P<none>does not depend on any axioms))"
)
ALLOWED = {"propext", "Classical.choice", "Quot.sound"}
THEOREMS = {
    "PSKernelFast.Spec.ContextScoped.lookup_scoped",
    "PSKernelFast.Spec.closedInput_iff",
    "PSKernelFast.Proof.generalPiRule_scope",
    "PSKernelFast.Proof.generalPiContextWF_scoped",
    "PSKernelFast.Proof.certified_ne_malformedResult",
    "PSKernelFast.Proof.inferred_success_certifiable",
    "PSKernelFast.Proof.inferClosedGeneralPi_source_and_result_scoped",
    "PSKernelFast.Proof.liftBVars_one_instantiate_cancel",
    "PSKernelFast.Proof.liftBVars_zero",
    "PSKernelFast.Proof.bound_zero_substitution_preserves_type",
    "PSKernelFast.Proof.dependent_identity_beta_preserves_type",
    "PSKernelFast.Proof.dependent_let_variable_zeta_preserves_type",
    "PSKernelFast.Proof.dependent_outer_variable_beta_preserves_type",
    "PSKernelFast.Proof.dependent_outer_variable_let_preserves_type",
    "PSKernelFast.Proof.eraseExpr_lift",
    "PSKernelFast.Proof.eraseExpr_instantiate",
    "PSKernelFast.Proof.eraseExpr_beta_redex",
    "PSKernelFast.Proof.eraseExpr_let_redex",
    "PSKernelFast.Proof.generalPiRule_erasable",
    "PSKernelFast.Proof.generalPiContextWF_erasable",
    "PSKernelFast.Proof.inferClosedGeneralPi_erasable",
    "PSKernelFast.Spec.SetTheoryBasis.universe_two_steps",
    "PSKernelFast.Spec.SetTheoryBasis.exists_empty",
    "PSKernelFast.Spec.SetTheoryBasis.not_member_empty",
    "PSKernelFast.Spec.SetTheoryBasis.universe_subset_closed",
    "PSKernelFast.Spec.SetTheoryBasis.universe_powerset_closed",
    "PSKernelFast.Spec.propUniverse_mem_typeOne",
    "PSKernelFast.Spec.propFalse_mem",
    "PSKernelFast.Spec.propTrue_mem",
    "PSKernelFast.Spec.propFalse_ne_true",
    "PSKernelFast.Spec.powerset_empty_exact",
    "PSKernelFast.Spec.propUniverse_exactly_two",
    "PSKernelFast.Spec.propPi_member_prop",
    "PSKernelFast.Spec.propPi_true_iff",
    "PSKernelFast.Spec.propPi_false_of_counterexample",
    "PSKernelFast.Spec.propPi_exact_truth_range",
    "PSKernelFast.Spec.interpProp_pi_member",
    "PSKernelFast.Spec.forallPropProp_fibres_valid",
    "PSKernelFast.Spec.forallPropProp_member_prop",
    "PSKernelFast.Spec.forallPropProp_is_false",
    "PSKernelFast.Proof.forallPropProp_actual_inference",
    "PSKernelFast.Proof.forallPropProp_actual_erasure",
    "PSKernelFast.Proof.forallPropProp_type_erases_to_Prop",
    "PSKernelFast.Proof.forallPropProp_checked_body_prop",
    "PSKernelFast.Proof.forallPropProp_checked_set_denotation",
    "PSKernelFast.Spec.prop_imp_self_true",
    "PSKernelFast.Spec.forallPropIdentity_fibres_valid",
    "PSKernelFast.Spec.forallPropIdentity_member_prop",
    "PSKernelFast.Spec.forallPropIdentity_is_true",
    "PSKernelFast.Proof.forallPropIdentity_actual_inference",
    "PSKernelFast.Proof.forallPropIdentity_actual_erasure",
    "PSKernelFast.Proof.forallPropIdentity_type_erases_to_Prop",
    "PSKernelFast.Proof.forallPropIdentity_checked_set_denotation",
    "PSKernelFast.Proof.checkedPropAnnotation_erases",
    "PSKernelFast.Proof.checkedPropAnnotation_typed",
    "PSKernelFast.Proof.checkedPropAnnotation_pi_model_member",
    "PSKernelFast.Proof.forallPropProp_checked_annotation",
    "PSKernelFast.Proof.forallPropProp_annotated_executed",
    "PSKernelFast.Proof.forallPropProp_checked_annotation_model",
    "PSKernelFast.Proof.forallPropIdentity_checked_annotation",
    "PSKernelFast.Proof.forallPropIdentity_annotated_executed",
    "PSKernelFast.Proof.forallPropIdentity_checked_annotation_model",
    "PSKernelFast.Spec.old_true_forces_truth_value",
    "PSKernelFast.Spec.set_not_member_self",
    "PSKernelFast.Spec.proofPointV2_mem_true",
    "PSKernelFast.Spec.proofPointV2_not_prop",
    "PSKernelFast.Spec.false_mem_propV2",
    "PSKernelFast.Spec.true_mem_propV2",
    "PSKernelFast.Spec.trueV2_ne_false",
    "PSKernelFast.Spec.propUniverseV2_exactly_two",
    "PSKernelFast.Spec.universe_singleton_closed",
    "PSKernelFast.Spec.propUniverseV2_mem_typeOne",
    "PSKernelFast.Spec.powerEmpty_is_singletonEmpty",
    "PSKernelFast.Spec.proofPointV2_is_kuratowski_empty_pair",
    "PSKernelFast.Spec.member_modelSingleton",
    "PSKernelFast.Spec.modelSingleton_inj",
    "PSKernelFast.Spec.member_orderedPair_nonempty",
    "PSKernelFast.Spec.member_modelGraph",
    "PSKernelFast.Spec.member_modelNatSucc",
    "PSKernelFast.Spec.empty_member_modelNat_succ",
    "PSKernelFast.Spec.universe_modelSingleton_closed",
    "PSKernelFast.Spec.taggedPointTag_ne_singleton",
    "PSKernelFast.Spec.taggedPointTag_ne_orderedPair",
    "PSKernelFast.Spec.taggedPoint_ne_orderedPair",
    "PSKernelFast.Spec.taggedPoint_ne_graph",
    "PSKernelFast.Spec.taggedPoint_ne_nat",
    "PSKernelFast.Spec.taggedPoint_not_prop",
    "PSKernelFast.Spec.taggedProp_exactly_two",
    "PSKernelFast.Spec.taggedPoint_is_arbitrary_image",
    "PSKernelFast.Spec.empty_ne_modelSingleton_empty",
    "PSKernelFast.Spec.empty_ne_doubleSingleton_empty",
    "PSKernelFast.Spec.singleton_ne_doubleSingleton_empty",
    "PSKernelFast.Spec.universe_modelPair_closed",
    "PSKernelFast.Spec.taggedPointTag_mem_typeOne",
    "PSKernelFast.Spec.taggedPoint_mem_typeOne",
    "PSKernelFast.Spec.taggedTrue_mem_typeOne",
    "PSKernelFast.Spec.taggedProp_mem_typeOne",
    "PSKernelFast.Spec.taggedSort_member_succ",
    "PSKernelFast.Spec.taggedPropPi_member_prop",
    "PSKernelFast.Spec.taggedPropPi_true_iff",
    "PSKernelFast.Spec.taggedPropPi_false_of_counterexample",
    "PSKernelFast.Spec.taggedPropPi_exact_truth_range",
    "PSKernelFast.Spec.interpTaggedProp_pi_member",
    "PSKernelFast.Spec.tagged_forallPropProp_fibres_valid",
    "PSKernelFast.Spec.tagged_forallPropProp_member_prop",
    "PSKernelFast.Spec.tagged_forallPropProp_is_false",
    "PSKernelFast.Spec.tagged_imp_self_true",
    "PSKernelFast.Spec.tagged_forallPropIdentity_fibres_valid",
    "PSKernelFast.Spec.tagged_forallPropIdentity_member_prop",
    "PSKernelFast.Spec.tagged_forallPropIdentity_is_true",
    "PSKernelFast.Spec.tagged_forallPropProp_uninhabited",
    "PSKernelFast.Spec.tagged_forallPropIdentity_only_point",
    "PSKernelFast.Proof.checkedTaggedPropAnnotation_pi_model_member",
    "PSKernelFast.Proof.forallPropProp_tagged_checked_annotation_model",
    "PSKernelFast.Proof.forallPropIdentity_tagged_checked_annotation_model",
    "PSKernelFast.Proof.forallPropProp_tagged_checked_set_denotation",
    "PSKernelFast.Proof.forallPropIdentity_tagged_checked_set_denotation",
    "PSKernelFast.Proof.taggedSort_nat_member_succ",
    "PSKernelFast.Proof.taggedWellDenoted_sound",
    "PSKernelFast.Proof.taggedWellDenoted_pi_fibres",
    "PSKernelFast.Proof.forallPropProp_tagged_wellDenoted",
    "PSKernelFast.Proof.forallPropIdentity_tagged_wellDenoted",
    "PSKernelFast.Proof.forallPropProp_tagged_checked_via_wellDenoted",
    "PSKernelFast.Proof.forallPropIdentity_tagged_checked_via_wellDenoted",
    "PSKernelFast.Spec.sort_member_succ",
    "PSKernelFast.Spec.numericIMax_zero_iff_codomain_zero",
    "PSKernelFast.Spec.piLevel_isProp_iff_codomain_isProp",
    "PSKernelFast.Spec.piLevel_positive_bounds",
    "PSKernelFast.Proof.checked_sort_exact_result",
    "PSKernelFast.Proof.inferred_sort_model_member",
    "PSKernelFast.Proof.checked_pi_extract_sorts",
    "PSKernelFast.Proof.checked_pi_prop_regime",
    "PSKernelFast.Proof.inferred_closed_pi_prop_regime",
    "PSKernelFast.Proof.liftBVars_add",
    "PSKernelFast.Proof.liftBVars_comm",
    "PSKernelFast.Proof.checked_bound_variable_weakens",
}


def audit(content: str) -> None:
    if "sorryAx" in content or "native_decide" in content:
        raise ValueError("Unreviewed proof assumption token detected")
    records = {}
    for result in REPORTED.finditer(content):
        name = result.group("theorem")
        ax = {
            item.strip() for item in (result.group("axioms") or "").split(",")
            if item.strip()
        }
        if name in records:
            raise ValueError(f"Duplicate theorem-assumption record: {name}")
        records[name] = ax

    if records.keys() != THEOREMS:
        missing = sorted(THEOREMS - records.keys())
        extra = sorted(records.keys() - THEOREMS)
        raise ValueError(f"Missing/extra theorem receipts: missing={missing} extra={extra}")
    for name, axioms in records.items():
        unknown = axioms - ALLOWED
        if unknown:
            raise ValueError(f"{name} imported unreviewed axioms: {sorted(unknown)}")
    print(f"G4.3b P1 theorem-assumptions gate PASS: {len(records)} exact theorems")
    print(f"Reviewed possible assumptions: {sorted(ALLOWED)}")


def test_fail_closed() -> None:
    valid = "\n".join(
        f"'{name}' depends on axioms: [propext, Quot.sound]"
        for name in sorted(THEOREMS)
    )
    audit(valid)
    # Lean prints a DIFFERENT format for axiom-free theorems.
    axiom_free = valid.replace(
        "depends on axioms: [propext, Quot.sound]",
        "does not depend on any axioms", 1)
    audit(axiom_free)
    for bad in (
        valid.replace("Quot.sound", "sorryAx", 1),
        valid.replace("Quot.sound", "Axiom.ofUnchecked", 1),
        valid.replace("depends on axioms:", "not-an-audit:", 1),
        valid + "\n'PSKernelFast.Proof.Fake' depends on axioms: []",
    ):
        try:
            audit(bad)
        except ValueError:
            pass
        else:
            raise ValueError("Proof-assumption audit fails open on synthetic bad input")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_axioms.py <lean-axiom-log>")
    try:
        test_fail_closed()
        audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"G4.3b proof-assumptions gate FAILED: {error}")
