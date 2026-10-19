#!/usr/bin/env python3
"""Pinned native module, scope, legacy import and exported-body oracle."""

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import time

PIN_VERSION = "4.35.0"
PIN_GITHASH = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
TIMEOUT_SECONDS = 45
PSC0 = Path(__file__).resolve().parents[1]
OUTPUT = PSC0 / "dist" / "core-first" / "seams" / "module-native-oracle"
KIND_ERROR = ("cannot import non-`module` LegacyProvider from `module`",)
BODY_ERROR = ("Tactic `rfl` failed", "not definitionally equal", "coreBodyOpaque")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source(text):
    return textwrap.dedent(text).lstrip()


def kind_client(provider, module, public_import=False):
    header = "module\n" if module else ""
    import_prefix = "public " if public_import else ""
    declaration_prefix = "public " if module else ""
    return (
        f"{header}{import_prefix}import {provider}\n\n"
        f"{declaration_prefix}def coreKindUse "
        "(A : Type) (x : A) : A := coreKindValue A x\n"
    )


def cases():
    identity = "def coreKindValue (A : Type) (x : A) : A := x\n"
    return [
        ("LegacyProvider", identity, ()),
        ("ModuleProvider", "module\n\npublic " + identity, ()),
        ("ModuleToModule", kind_client("ModuleProvider", True), ()),
        ("ModuleToLegacy", kind_client("LegacyProvider", True), KIND_ERROR),
        ("LegacyToModule", kind_client("ModuleProvider", False), ()),
        ("LegacyToLegacy", kind_client("LegacyProvider", False), ()),
        ("PublicModuleToModule", kind_client("ModuleProvider", True, True), ()),
        ("PublicModuleToLegacy", kind_client("LegacyProvider", True, True), KIND_ERROR),
        ("ModuleImportOnlyLegacy", "module\nimport LegacyProvider\n", KIND_ERROR),
        ("BodyProvider", source("""
            module

            public def coreBodyOpaque (A : Type) (x : A) : A := x
            public abbrev coreBodyExposed (A : Type) (x : A) : A := x

            public theorem coreBodySpec (A : Type) (x : A) :
                coreBodyOpaque A x = x := by
              rfl
            """), ()),
        ("BodyClientGood", source("""
            module
            public import BodyProvider

            public theorem coreBodyProof (A : Type) (x : A) :
                coreBodyExposed A x = x := by
              rfl

            public theorem coreBodyViaSpec (A : Type) (x : A) :
                coreBodyOpaque A x = x :=
              coreBodySpec A x
            """), ()),
        ("BodyClientHiddenRfl", source("""
            module
            public import BodyProvider

            public theorem coreBodyForbidden (A : Type) (x : A) :
                coreBodyOpaque A x = x := by
              rfl
            """), BODY_ERROR),
    ] + visibility_cases() + legacy_cases() + scope_refusal_cases() + where_helper_cases() + registered_value_cases() + exposed_proof_cases() + attribute_cases() + connective_attribute_cases() + escaped_identifier_cases() + declaration_universe_cases() + qualified_declaration_cases()


def visibility_cases():
    provider = source("""
        module

        public def coreImportType (A : Type) : Type := A
        public def coreImportValue (A : Type) (x : A) : A := x
        public theorem coreImportProof (A : Type) (x : A) :
            x = x := by
          rfl
        """)

    signature = source("""
        public def coreImportSignature
            (A : Type) (x : coreImportType A) (y : A) : A := y
        """)

    exposed = source("""
        public abbrev coreImportExposed
            (A : Type) (x : A) : A := coreImportValue A x
        """)

    facade = source("""
        module
        import ImportVisibilityProvider

        public def coreImportBridge (A : Type) (x : A) : A :=
          coreImportValue A x

        public theorem coreImportViaProof (A : Type) (x : A) :
            x = x :=
          coreImportProof A x
        """)

    bridge_client = source("""
        module
        public import ImportVisibilityFacade

        public abbrev coreImportAcrossBridge
            (A : Type) (x : A) : A :=
          coreImportBridge A x
        """)

    hidden_client = source("""
        module
        public import ImportVisibilityFacade

        public def coreImportHidden (A : Type) (x : A) : A :=
          coreImportValue A x
        """)

    def private_import_error(name):
        return (
            f"Unknown identifier `{name}`",
            f"A public declaration `{name}` exists but is imported privately",
            "public import ImportVisibilityProvider",
        )

    ordinary_header = "module\nimport ImportVisibilityProvider\n\n"
    public_header = "module\npublic import ImportVisibilityProvider\n\n"
    public_client = signature + "\n" + exposed
    legacy_client = (
        "import ImportVisibilityProvider\n\n"
        + signature.replace("public def ", "def ")
        + "\n"
        + exposed.replace("public abbrev ", "abbrev ")
    )

    return [
        ("ImportVisibilityProvider", provider, ()),
        ("ImportVisibilityFacade", facade, ()),
        ("ImportVisibilityOrdinarySignature", ordinary_header + signature,
         private_import_error("coreImportType")),
        ("ImportVisibilityOrdinaryExposed", ordinary_header + exposed,
         private_import_error("coreImportValue")),
        ("ImportVisibilityPublic", public_header + public_client, ()),
        ("ImportVisibilityBridgeClient", bridge_client, ()),
        ("ImportVisibilityHiddenClient", hidden_client,
         ("Unknown identifier `coreImportValue`",)),
        ("ImportVisibilityLeft",
         "module\npublic import ImportVisibilityProvider\n", ()),
        ("ImportVisibilityRight",
         "module\npublic import ImportVisibilityProvider\n", ()),
        ("ImportVisibilityPrivateTransitiveSignature",
         "module\nimport ImportVisibilityLeft\n\n" + signature,
         private_import_error("coreImportType")),
        ("ImportVisibilityDiamondPrivateFirst",
         "module\nimport ImportVisibilityLeft\npublic import ImportVisibilityRight\n\n"
         + public_client, ()),
        ("ImportVisibilityDiamondPublicFirst",
         "module\npublic import ImportVisibilityRight\nimport ImportVisibilityLeft\n\n"
         + public_client, ()),
        ("ImportVisibilityLegacy", legacy_client, ()),
    ]



def legacy_cases():
    library = source("""
        module

        public def coreLegacyDirect (A : Type) (x : A) : A := x
        private def coreLegacyHelper (A : Type) (x : A) : A := x
        public def coreLegacyViaPrivate (A : Type) (x : A) : A :=
          coreLegacyHelper A x
        public abbrev coreLegacyAlias (A : Type) (x : A) : A :=
          coreLegacyDirect A x
        public theorem coreLegacySpec (A : Type) (x : A) :
            coreLegacyViaPrivate A x = x := by
          rfl
        public opaque coreLegacyOpaque (A : Type) (x : A) : A := x

        public class CoreLegacyEcho (A : Type) where
          run : A -> A
        @[default_instance 700]
        private instance coreLegacyEcho {A : Type} : CoreLegacyEcho A where
          run := fun x => x
        public abbrev coreLegacyEchoAlias (A : Type) : Type := A
        """)
    direct_client = source("""
        import LegacyLibrary
        theorem coreLegacyDirectRfl (A : Type) (x : A) :
            coreLegacyDirect A x = x := by
          rfl
        theorem coreLegacyAliasRfl (A : Type) (x : A) :
            coreLegacyAlias A x = x := by
          rfl
        """)
    private_body_client = source("""
        import LegacyLibrary
        theorem coreLegacyPrivateRfl (A : Type) (x : A) :
            coreLegacyViaPrivate A x = x := by
          rfl
        """)
    opaque_client = source("""
        import LegacyLibrary
        theorem coreLegacyOpaqueRfl (A : Type) (x : A) :
            coreLegacyOpaque A x = x := by
          rfl
        """)
    private_source_client = source("""
        import LegacyLibrary
        def coreLegacyForbidden (A : Type) (x : A) : A :=
          coreLegacyHelper A x
        """)
    facade = source("""
        module
        import LegacyLibrary
        public def coreLegacyFacade (A : Type) (x : A) : A :=
          coreLegacyViaPrivate A x
        """)
    transitive_client = source("""
        import LegacyFacade
        theorem coreLegacyTransitiveRfl (A : Type) (x : A) :
            coreLegacyViaPrivate A x = x := by
          rfl
        """)
    local_legacy = source("""
        private def coreLegacyType (A : Type) : Type := A
        private def coreLegacyHelper (A : Type) (x : A) : A := x
        def coreLegacySignature
            (A : Type) (x : coreLegacyType A) (y : A) : A := y
        abbrev coreLegacyExposed (A : Type) (x : A) : A :=
          coreLegacyHelper A x
        theorem coreLegacyLocalRfl (A : Type) (x : A) :
            coreLegacyExposed A x = x := by
          rfl
        """)
    module_local_signature = source("""
        module
        private def coreLegacyType (A : Type) : Type := A
        public def coreLegacySignature
            (A : Type) (x : coreLegacyType A) (y : A) : A := y
        """)
    module_local_exposed = source("""
        module
        private def coreLegacyHelper (A : Type) (x : A) : A := x
        public abbrev coreLegacyExposed (A : Type) (x : A) : A :=
          coreLegacyHelper A x
        """)
    metadata_client = source("""
        import LegacyLibrary
        theorem coreLegacyEchoRfl (A : Type) (x : A) :
            CoreLegacyEcho.run x (A := A) = x := by
          rfl
        """)

    def local_private_error(name):
        return (
            f"Unknown identifier `{name}`",
            f"A private declaration `{name}` (from the current module)",
            "would need to be public to access here",
        )

    return [
        ("LegacyLibrary", library, ()),
        ("LegacyDirectBody", direct_client, ()),
        ("LegacyPrivateBody", private_body_client, ()),
        ("LegacyOpaqueBody", opaque_client,
         ("Tactic `rfl` failed", "not definitionally equal", "coreLegacyOpaque")),
        ("LegacyPrivateSourceName", private_source_client,
         ("Unknown identifier `coreLegacyHelper`",)),
        ("LegacyFacade", facade, ()),
        ("LegacyTransitiveBody", transitive_client, ()),
        ("LegacyLocalPrivate", local_legacy, ()),
        ("ModuleLocalPrivateSignature", module_local_signature,
         local_private_error("coreLegacyType")),
        ("ModuleLocalPrivateExposed", module_local_exposed,
         local_private_error("coreLegacyHelper")),
        ("LegacyPrivateInstanceMetadata", metadata_client, ()),
    ]


def where_helper_cases():
    provider = source("""
        public def coreLegacyWhere (A : Type) (x : A) : A :=
          helper x
        where
          helper (y : A) : A := y

        public def coreLegacyWhereLocal (A : Type) (x : A) : A :=
          coreLegacyWhere.helper A x
        """)

    helper_error = ("Unknown constant `coreLegacyWhere.helper`",)

    return [
        ("ModuleWhereLibrary", "module\n\n" + provider, ()),
        (
            "ModuleWhereLegacyRfl",
            source("""
                import ModuleWhereLibrary

                theorem coreLegacyWhereRfl (A : Type) (x : A) :
                    coreLegacyWhere A x = x := by
                  rfl

                theorem coreLegacyWhereLocalRfl (A : Type) (x : A) :
                    coreLegacyWhereLocal A x = x := by
                  rfl
                """),
            (),
        ),
        (
            "ModuleWhereLegacyName",
            source("""
                import ModuleWhereLibrary

                def coreLegacyWhereForbidden (A : Type) (x : A) : A :=
                  coreLegacyWhere.helper A x
                """),
            helper_error,
        ),
        ("LegacyWhereLibrary", provider, ()),
        (
            "LegacyWhereHelper",
            source("""
                import LegacyWhereLibrary

                def coreLegacyWhereHelperUse (A : Type) (x : A) : A :=
                  coreLegacyWhere.helper A x
                """),
            (),
        ),
        (
            "ModuleWhereModuleName",
            source("""
                module
                public import ModuleWhereLibrary

                public def coreLegacyWhereForbidden
                    (A : Type) (x : A) : A :=
                  coreLegacyWhere.helper A x
                """),
            helper_error,
        ),
    ]


def scope_refusal_cases():
    return [
        ("ScopeBareNamespaceEnd", "module\nnamespace A\nend\n",
         ("Missing name after `end`", "Expected the current scope name `A`")),
        ("ScopeBareSectionEnd", "module\nsection A\nend\n",
         ("Missing name after `end`", "Expected the current scope name `A`")),
        ("ScopeOuterNameWithoutInner", "module\nnamespace A\nnamespace B\nend A\n",
         ("Invalid name after `end`", "Expected `B`, but found `A`")),
        ("ScopeReversedDottedEnd", "module\nnamespace A.B\nend B.A\n",
         ("Invalid name after `end`", "Expected `A.B`, but found `B.A`")),
        ("ScopeAcrossUnnamedBarrier",
         "module\nnamespace A\nsection\nnamespace B\nend A.B\n",
         ("Invalid name after `end`", "Expected `B`, but found `A.B`")),
        ("ScopeNamedEndOnUnnamed", "module\nsection\nend A\n",
         ("Unexpected name `A` after `end`", "The current section is unnamed")),
        ("ScopeTooManyEndComponents", "module\nnamespace A\nend X.A\n",
         ("Invalid name after `end`", "`X.A` contains too many components")),
        ("ScopeEndWithoutScope", "module\nend\n",
         ("Invalid `end`", "There is no current scope to end")),
    ]


def registered_value_cases():
    return [
        ("RegisteredProvider", "module\npublic abbrev coreRegisteredIdentity (A : Type) (x : A) := x\npublic abbrev coreRegisteredWhere (A : Type) (x : A) : A := helper x\nwhere\n  helper (y : A) : A := y\npublic class CoreRegisteredEcho (A : Type) where\n  run : A -> A\npublic instance coreRegisteredEcho {A : Type} : CoreRegisteredEcho A where\n  run := fun (x : A) => x\npublic class CoreRegisteredLaw (A : Type) (x : A) : Prop where\n  selfEq : x = x\npublic instance coreRegisteredLaw {A : Type} (x : A) : CoreRegisteredLaw A x where\n  selfEq := by rfl\n@[default_instance 700] public def coreRegisteredDefault {A : Type} := ({ run := fun (x : A) => x } : CoreRegisteredEcho A)\n", ()),
        ("RegisteredClient", "module\npublic import RegisteredProvider\npublic theorem coreRegisteredIdentityRfl (A : Type) (x : A) : coreRegisteredIdentity A x = x := by rfl\npublic theorem coreRegisteredWhereRfl (A : Type) (x : A) : coreRegisteredWhere A x = x := by rfl\npublic theorem coreRegisteredHelperRfl (A : Type) (x : A) : coreRegisteredWhere.helper A x = x := by rfl\npublic theorem coreRegisteredEchoRfl (A : Type) (x : A) : CoreRegisteredEcho.run x (A := A) = x := by rfl\npublic theorem coreRegisteredProofValue (A : Type) (x : A) : CoreRegisteredLaw A x := coreRegisteredLaw x\npublic theorem coreRegisteredProofField (A : Type) (x : A) : x = x := CoreRegisteredLaw.selfEq (A := A) (x := x)\n", ()),
        ("RegisteredPrivateHelperLeak", "module\nprivate def coreRegisteredHidden (A : Type) (x : A) : A := x\npublic abbrev coreRegisteredLeak (A : Type) (x : A) : A := helper x\nwhere\n  helper (y : A) : A := coreRegisteredHidden A y\n", ("Unknown identifier `coreRegisteredHidden`", "private declaration",)),
        ("RegisteredNonClassDefault", "module\n@[default_instance] public def coreRegisteredBad (A : Type) (x : A) := x\n", ("invalid default instance `coreRegisteredBad`", "type must be of the form",)),
    ]


def exposed_proof_cases():
    return [
        ("ProofBoundaryProvider", "module\nprivate theorem coreSecretEq (A : Type) (x : A) : x = x := by rfl\npublic abbrev coreProofKeep (A : Type) (unused x : A) : A := (fun (_h : x = x) => x) (by exact coreSecretEq A x)\npublic abbrev coreProofLet (A : Type) (unused x : A) : A :=\n  let witness : A := x\n  (fun (_h : witness = witness) => x) (by exact coreSecretEq A witness)\npublic def coreProofSignature (A : Type) (x : A) : (fun (_h : x = x) => A) (by exact coreSecretEq A x) := x\n", ()),
        ("ProofBoundaryClient", "module\npublic import ProofBoundaryProvider\npublic theorem coreProofKeepRfl (A : Type) (unused x : A) : coreProofKeep A unused x = x := by rfl\npublic theorem coreProofLetRfl (A : Type) (unused x : A) : coreProofLet A unused x = x := by rfl\npublic def coreProofSignatureUse (A : Type) (x : A) : A := coreProofSignature A x\n", ()),
        ("ProofBoundaryDirectPrivate", "module\nprivate theorem coreSecretEq (A : Type) (x : A) : x = x := by rfl\npublic abbrev coreProofDirect (A : Type) (x : A) : A := (fun (_h : x = x) => x) (coreSecretEq A x)\n", ("coreSecretEq",)),
        ("ProofBoundaryData", "module\nprivate def coreSecretValue (A : Type) (x : A) : A := x\npublic abbrev coreProofData (A : Type) (x : A) : A := by exact coreSecretValue A x\n", ("coreSecretValue",)),
        ("ProofBoundaryHiddenType", "module\nprivate def CoreHiddenProp (A : Type) (x : A) : Prop := x = x\nprivate theorem coreHiddenProof (A : Type) (x : A) : CoreHiddenProp A x := by rfl\npublic abbrev coreProofHiddenType (A : Type) (x : A) : A := (fun (_h : CoreHiddenProp A x) => x) (by exact coreHiddenProof A x)\n", ("CoreHiddenProp",)),
        ("ProofBoundaryPrivateAlias", "module\npublic import ProofBoundaryProvider\npublic theorem coreProofPrivateAlias (A : Type) (x : A) : x = x := coreSecretEq A x\n", ("coreSecretEq",)),
        ("ProofBoundaryImportProvider", "module\npublic theorem coreImportedSecretEq (A : Type) (x : A) : x = x := by rfl\n", ()),
        ("ProofBoundaryImportLibrary", "module\nimport ProofBoundaryImportProvider\npublic abbrev coreImportedProofKeep (A : Type) (x : A) : A := (fun (_h : x = x) => x) (by exact coreImportedSecretEq A x)\n", ()),
        ("ProofBoundaryImportClient", "module\npublic import ProofBoundaryImportLibrary\npublic theorem coreImportedProofRfl (A : Type) (x : A) : coreImportedProofKeep A x = x := by rfl\n", ()),
        ("ProofBoundaryImportAlias", "module\npublic import ProofBoundaryImportLibrary\npublic theorem coreProofImportAlias (A : Type) (x : A) : x = x := coreImportedSecretEq A x\n", ("coreImportedSecretEq",)),
    ]


def attribute_cases():
    return [
        ("AttributeProvider", "module\npublic class CoreAttrEcho (A : Type) where\n  run : A -> A\n@[simp] public def coreAttrIdentity (A : Type) (x : A) : A := x\n@[simp] public theorem coreAttrIdentityEq (A : Type) (x : A) : coreAttrIdentity A x = x := by rfl\n@[simp] private theorem coreAttrPrivateEq (A : Type) (x : A) : coreAttrIdentity A x = x := by rfl\n@[instance] public def coreAttrInstance {A : Type} := ({ run := fun (x : A) => x } : CoreAttrEcho A)\n@[simp, instance, default_instance 700] public def coreAttrCombined {A : Type} : CoreAttrEcho A := helper\nwhere\n  helper : CoreAttrEcho A := { run := fun (x : A) => x }\n@[default_instance] public abbrev coreAttrAbbrev {A : Type} : CoreAttrEcho A := { run := fun (x : A) => x }\nmutual\n  @[simp] public def coreAttrFirst (A : Type) (x : A) : A := coreAttrSecond A x\n  @[simp] public def coreAttrSecond (A : Type) (x : A) : A := x\nend\n@[simp] public theorem coreAttrProposition (P : Prop) (h : P) : P := h\n", ()),
        ("AttributeClient", "module\npublic import AttributeProvider\npublic theorem coreAttrViaSpec (A : Type) (x : A) : coreAttrIdentity A x = x := coreAttrIdentityEq A x\npublic def coreAttrCall (A : Type) (x : A) : A := CoreAttrEcho.run x (A := A)\n", ()),
        ("AttributeLeft", "module\npublic import AttributeProvider\n", ()),
        ("AttributeRight", "module\npublic import AttributeProvider\n", ()),
        ("AttributeDiamond", "module\npublic import AttributeLeft\npublic import AttributeRight\npublic theorem coreAttrViaSpec (A : Type) (x : A) : coreAttrIdentity A x = x := coreAttrIdentityEq A x\npublic def coreAttrCall (A : Type) (x : A) : A := CoreAttrEcho.run x (A := A)\n", ()),
        ("AttributeReflexivity", "module\n@[simp] public theorem coreAttrBad (A : Type) (x : A) : x = x := by rfl\n", ("Invalid simp theorem:",)),
        ("AttributeEtaReflexivity", "module\n@[simp] public theorem coreAttrBad (A B : Type) (f : A -> B) : (fun (x : A) => f x) = f := by rfl\n", ("Invalid simp theorem:",)),
        ("AttributeAbbrevReflexivity", "module\npublic abbrev coreAttrAlias (A : Type) (x : A) : A := x\n@[simp] public theorem coreAttrBad (A : Type) (x : A) : coreAttrAlias A x = x := by rfl\n", ("Invalid simp theorem:",)),
        ("AttributeOpaqueValue", "module\n@[simp] public opaque coreAttrBad (A : Type) (x : A) : A := x\n", ("Cannot add `simp` attribute", "not a proposition nor a definition",)),
        ("AttributeNonClass", "module\n@[instance] public def coreAttrBad (A : Type) (x : A) := x\n", ("should not be an instance", "is not a type class",)),
        ("AttributeCombinedNonClass", "module\n@[simp, instance] public def coreAttrBad (A : Type) (x : A) : A := x\n", ("should not be an instance", "is not a type class",)),
        ("AttributePrivateAlias", "module\npublic import AttributeProvider\npublic theorem coreAttrLeak (A : Type) (x : A) : coreAttrIdentity A x = x := coreAttrPrivateEq A x\n", ("Unknown identifier `coreAttrPrivateEq`",)),
        ("AttributeOpaqueImport", "module\npublic import AttributeProvider\npublic theorem coreAttrOpaqueBad (A : Type) (x : A) : coreAttrIdentity A x = x := by rfl\n", ("Tactic `rfl` failed",)),
    ]


def connective_attribute_cases():
    return [
        ("AttributeConnectiveProvider", "module\npublic def coreAttrLogicalIdentity (A : Type) (x : A) : A := x\n@[simp] public theorem coreAttrGoodIff (P Q : Prop) (h : Iff P Q) : Iff P Q := h\n@[simp] public theorem coreAttrGoodAnd (P Q : Prop) (hp : P) (hq : Q) : And P Q := And.intro hp hq\n@[simp] public theorem coreAttrGoodAndEq (A : Type) (x y : A) : And (coreAttrLogicalIdentity A x = x) (coreAttrLogicalIdentity A y = y) := And.intro (Eq.refl x) (Eq.refl y)\n", ()),
        ("AttributeIffReflexive", "module\n@[simp] public theorem coreAttrBadIff (P : Prop) : Iff P P := Iff.intro (fun (h : P) => h) (fun (h : P) => h)\n", ("Invalid simp theorem:",)),
        ("AttributeAndLeftReflexive", "module\n@[simp] public theorem coreAttrBadAndLeft (A : Type) (x : A) (P : Prop) (hp : P) : And (x = x) P := And.intro (Eq.refl x) hp\n", ("Invalid simp theorem:",)),
        ("AttributeAndRightReflexive", "module\n@[simp] public theorem coreAttrBadAndRight (A : Type) (x : A) (P : Prop) (hp : P) : And P (x = x) := And.intro hp (Eq.refl x)\n", ("Invalid simp theorem:",)),
        ("AttributeAndNestedReflexive", "module\n@[simp] public theorem coreAttrBadAndNested (A : Type) (x : A) (P Q : Prop) (hp : P) (hq : Q) : And P (And Q (x = x)) := And.intro hp (And.intro hq (Eq.refl x))\n", ("Invalid simp theorem:",)),
    ]

def escaped_identifier_cases():
    return [
        ("EscapedNamesProvider", "module\nnamespace CoreEscaped\npublic def «if» (A : Type) («_» : A) : A := «_»\npublic def «Type» (A : Type) (x : A) : A := «if» A x\npublic def «Prop» (A : Type) (x : A) : A := «Type» A x\npublic def «a.b» (A : Type) (x : A) : A := x\nnamespace a\npublic def b (A : Type) (x : A) : A := x\nend a\npublic def «_root_.value» (A : Type) (x : A) : A := x\npublic def «unicode λ name» (A : Type) («two words» : A) : A := «two words»\npublic def «» (A : Type) (x : A) : A := x\npublic def rooted (A : Type) (x : A) : A := «_root_».CoreEscaped.«Type» A x\npublic structure «box.type» (A : Type) where\n  «value.dot» : A\npublic def boxed (A : Type) (x : A) : «box.type» A := { «value.dot» := x }\npublic def projected (A : Type) (box : «box.type» A) : A := box.«value.dot»\nprivate theorem «hidden proof» (A : Type) (x : A) : x = x := by rfl\npublic theorem «visible.proof» (A : Type) (x : A) : x = x := «hidden proof» A x\npublic def «with.local» (A : Type) (x : A) : A := «helper.dot» x\nwhere\n  «helper.dot» (y : A) : A := y\nuniverse «u.level»\npublic def universeIdentity (A : Type «u.level») (x : A) : A := x\nend CoreEscaped\n", ()),
        ("EscapedNamesClient", "module\npublic import EscapedNamesProvider\npublic def coreEscapedClient (A : Type) (x : A) : A := CoreEscaped.«Type» A (CoreEscaped.a.b A (CoreEscaped.«a.b» A x))\npublic theorem coreEscapedClientProof (A : Type) (x : A) : x = x := CoreEscaped.«visible.proof» A x\npublic def coreEscapedClientField (A : Type) (x : A) : A := CoreEscaped.projected A (CoreEscaped.boxed A x)\npublic def coreEscapedClientEmpty (A : Type) (x : A) : A := CoreEscaped.«» A x\n", ()),
        ("EscapedMarker", "module\npublic def «$psc0Private» (A : Type) (x : A) : A := helper x\nwhere\n  helper (y : A) : A := y\npublic def coreEscapedPublicMarker (A : Type) (x : A) : A := «$psc0Private» A x\n", ()),
        ("EscapeModules.Dot", "module\nprivate def coreEscapedModuleSecret (A : Type) (x : A) : A := x\npublic def coreEscapedSingle (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n", ()),
        ("EscapeModules/Dot", "module\nprivate def coreEscapedModuleSecret (A : Type) (x : A) : A := x\npublic def coreEscapedSeparate (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n", ()),
        ("if", "module\nprivate def coreEscapedModuleSecret (A : Type) (x : A) : A := x\npublic def coreEscapedKeyword (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n", ()),
        ("Type", "module\nprivate def coreEscapedModuleSecret (A : Type) (x : A) : A := x\npublic def coreEscapedTypeModule (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n", ()),
        ("EscapedModuleClient", "module\npublic import «EscapeModules.Dot»\npublic import EscapeModules.Dot\npublic import «if»\npublic import «Type»\npublic def coreEscapedModuleClient (A : Type) (x : A) : A := coreEscapedSeparate A (coreEscapedSingle A (coreEscapedKeyword A (coreEscapedTypeModule A x)))\n", ()),
        ("EscapedPrivateAlias", "module\npublic import EscapedNamesProvider\npublic theorem coreEscapedLeak (A : Type) (x : A) : x = x := CoreEscaped.«hidden proof» A x\n", ("Unknown", "hidden proof",)),
        ("EscapedCanonicalGuess", "module\npublic import EscapedNamesProvider\npublic theorem coreEscapedGuess (A : Type) (x : A) : x = x := «_private».EscapedNamesProvider.«0».CoreEscaped.«hidden proof» A x\n", ("Unknown", "_private",)),
        ("EscapedLegacyPrivateAlias", "import EscapedNamesProvider\npublic theorem coreEscapedLeak (A : Type) (x : A) : x = x := CoreEscaped.«hidden proof» A x\n", ("Unknown", "hidden proof",)),
        ("EscapedLegacyCanonicalGuess", "import EscapedNamesProvider\npublic theorem coreEscapedGuess (A : Type) (x : A) : x = x := «_private».EscapedNamesProvider.«0».CoreEscaped.«hidden proof» A x\n", ("Unknown", "_private",)),
        ("EscapedPrivateExposure", "module\nprivate def «hidden.value» (A : Type) (x : A) : A := x\npublic abbrev coreEscapedExposed (A : Type) (x : A) : A := «hidden.value» A x\n", ("hidden.value", "private declaration",)),
        ("EscapedPrivateSignature", "module\nprivate def «hidden.type» (A : Type) : Type := A\npublic def coreEscapedSignature (A : Type) (x : «hidden.type» A) (y : A) : A := y\n", ("hidden.type", "private declaration",)),
    ]


def declaration_universe_cases():
    return [
        ("UniverseProvider", "module\nnamespace CoreUniverses\npublic def identity.{a} (A : Type a) (x : A) : A := x\npublic def ordered.{v, u} (A : Type u) (B : Type v) (x : A) : A := x\nuniverse u\npublic def inherited.{v} (A : Type u) (B : Type v) (x : A) : A := x\npublic def scopeDrop.{w} (A : Type w) (x : A) : A := x\npublic def repeatA.{r} (A : Type r) (x : A) : A := x\npublic def repeatB.{r} (A : Type r) (x : A) : A := x\npublic def constant.{q} : (A : Type q) -> A -> A := fun (A : Type q) => fun (x : A) => x\npublic abbrev alias.{b} (A : Type b) (x : A) : A := x\npublic opaque sealed.{o} (A : Type o) (x : A) : A := x\npublic theorem reflexive.{p} (A : Sort p) (x : A) : x = x := by rfl\nprivate def hidden.{h} (A : Type h) (x : A) : A := x\npublic def fromHidden.{h} (A : Type h) (x : A) : A := hidden A x\npublic def withHelper.{k} (A : Type k) (x : A) : A := helper x\nwhere\n  helper (value : A) : A := value\npublic structure Box.{s} (A : Type s) where\n  value : A\npublic inductive Tag.{t} (A : Type t) where\n  | mk (value : A)\npublic class Picker.{c} (A : Type c) where\n  run : A -> A\npublic instance picker.{i} {A : Type i} : Picker A where\n  run := fun (x : A) => x\npublic def quoted.{first.level, «first.level»} (A : Sort first.level) (B : Sort «first.level») (x : A) : A := x\nuniverse command.level «command.level»\npublic def globalIdentity (A : Sort command.level) (B : Sort «command.level») (x : A) : A := x\nend CoreUniverses\n", ()),
        ("UniverseClient", "module\npublic import UniverseProvider\npublic def coreUniverseClient.{u} (A : Type u) (x : A) : A := CoreUniverses.identity A (CoreUniverses.fromHidden A x)\npublic theorem coreUniverseAlias.{u} (A : Type u) (x : A) : CoreUniverses.alias A x = x := by rfl\npublic theorem coreUniverseInstance.{u} (A : Type u) (x : A) : CoreUniverses.Picker.run x (A := A) = x := by rfl\npublic theorem coreUniverseProof.{u} (A : Sort u) (x : A) : x = x := CoreUniverses.reflexive A x\n", ()),
        ("UniverseMutual", "module\nmutual\npublic def universeLeft.{u} (A : Type u) (x : A) : A := universeRight A x\npublic def universeRight.{u} (A : Type u) (x : A) : A := x\nend\n", ()),
        ("UniverseMetadata", "module\npublic import UniverseProvider\npublic import UniverseMutual\nimport Lean\n\nrun_meta do\n  let checks : List (Lean.Name × List Lean.Name) := [\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"identity\", [Lean.Name.str (Lean.Name.anonymous) \"a\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"ordered\", [Lean.Name.str (Lean.Name.anonymous) \"v\", Lean.Name.str (Lean.Name.anonymous) \"u\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"inherited\", [Lean.Name.str (Lean.Name.anonymous) \"u\", Lean.Name.str (Lean.Name.anonymous) \"v\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"scopeDrop\", [Lean.Name.str (Lean.Name.anonymous) \"w\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"repeatA\", [Lean.Name.str (Lean.Name.anonymous) \"r\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"repeatB\", [Lean.Name.str (Lean.Name.anonymous) \"r\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"constant\", [Lean.Name.str (Lean.Name.anonymous) \"q\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"alias\", [Lean.Name.str (Lean.Name.anonymous) \"b\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"sealed\", [Lean.Name.str (Lean.Name.anonymous) \"o\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"reflexive\", [Lean.Name.str (Lean.Name.anonymous) \"p\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"fromHidden\", [Lean.Name.str (Lean.Name.anonymous) \"h\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"withHelper\", [Lean.Name.str (Lean.Name.anonymous) \"k\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"Box\", [Lean.Name.str (Lean.Name.anonymous) \"s\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"Tag\", [Lean.Name.str (Lean.Name.anonymous) \"t\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"Picker\", [Lean.Name.str (Lean.Name.anonymous) \"c\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"picker\", [Lean.Name.str (Lean.Name.anonymous) \"i\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"quoted\", [Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"first\") \"level\", Lean.Name.str (Lean.Name.anonymous) \"first.level\"]),\n    (Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"CoreUniverses\") \"globalIdentity\", [Lean.Name.str (Lean.Name.str (Lean.Name.anonymous) \"command\") \"level\", Lean.Name.str (Lean.Name.anonymous) \"command.level\"]),\n    (Lean.Name.str (Lean.Name.anonymous) \"universeLeft\", [Lean.Name.str (Lean.Name.anonymous) \"u\"]),\n    (Lean.Name.str (Lean.Name.anonymous) \"universeRight\", [Lean.Name.str (Lean.Name.anonymous) \"u\"])]\n  for (declName, expected) in checks do\n    let info ← Lean.getConstInfo declName\n    unless info.levelParams == expected do\n      throwError \"declaration universe order mismatch in {declName}: {info.levelParams}\"\n", ()),
        ("UniverseDuplicate", "module\npublic def bad.{u, u} (A : Type u) (x : A) : A := x\n", ("universe", "already", "u",)),
        ("UniverseScopeDuplicate", "module\nuniverse u\npublic def bad.{u} (A : Type u) (x : A) : A := x\n", ("universe", "already", "u",)),
        ("UniverseUnused", "module\npublic def bad.{u} (A : Type) (x : A) : A := x\n", ("unused universe parameter", "u",)),
        ("UniverseTheoremUnused", "module\npublic theorem bad.{u} (A : Type) (x : A) : x = x := by rfl\n", ("unused universe parameter", "u",)),
        ("UniverseDataUnused", "module\npublic structure Bad.{u} (A : Type) where\n  value : A\n", ("unused universe parameter", "u",)),
        ("UniverseInstanceUnused", "module\npublic class C (A : Type) where\n  run : A -> A\npublic instance bad.{u} {A : Type} : C A where\n  run := fun (x : A) => x\n", ("unused universe parameter", "u",)),
        ("UniverseMutualMismatch", "module\nmutual\npublic def left.{u} (A : Type u) (x : A) : A := x\npublic def right.{v} (A : Type v) (x : A) : A := x\nend\n", ("universe parameters mismatch",)),
        ("UniverseMutualOrder", "module\nmutual\npublic def left.{u, v} (A : Type u) (B : Type v) (x : A) : A := x\npublic def right.{v, u} (A : Type u) (B : Type v) (x : A) : A := x\nend\n", ("universe parameters mismatch",)),
        ("UniverseScopeLeak", "module\npublic def localOnly.{Private.level} (A : Sort Private.level) (x : A) : A := x\npublic def bad (A : Sort Private.level) (x : A) : A := x\n", ("unknown universe level", "Private.level",)),
    ]


def qualified_declaration_cases():
    return [
        ("QualifiedProvider", "module\nnamespace QualifiedHeads\npublic abbrev T.{u} (A : Type u) : Type u := A\npublic def choose.{u} (A : Type u) (x y : A) : A := x\nprivate def hidden.{u} (A : Type u) (x y : A) : A := x\nnamespace Inner\npublic abbrev Only.{u} (A : Type u) : Type u := A\nend Inner\nnamespace Left\npublic def choose.{u} (A : Type u) (x y : A) : A := y\nnamespace Deep\npublic def only.{u} (A : Type u) (x : A) : A := x\nend Deep\nend Left\nnamespace Right\npublic def choose.{u} (A : Type u) (x y : A) : A := y\nend Right\nend QualifiedHeads\npublic def QualifiedHeads.copy.{u} (A : Type u) (x y : T A) : T A := choose A x y\npublic def QualifiedHeads.withHelper.{u} (A : Type u) (x y : T A) : T A := helper x y\nwhere\n  helper (left right : T A) : T A := choose A left right\npublic theorem QualifiedHeads.law.{u} (A : Type u) (x y : T A) : choose A x y = x := by rfl\npublic structure QualifiedHeads.Box.{u} (A : Type u) where\n  value : T A\npublic class QualifiedHeads.Echo.{u} (A : Type u) where\n  run : T A -> T A\npublic instance QualifiedHeads.echo.{u} {A : Type u} : Echo A where\n  run := fun (x : T A) => x\nprivate def QualifiedHeads.secret.{u} (A : Type u) (x y : T A) : T A := hidden A x y\npublic def QualifiedHeads.fromSecret.{u} (A : Type u) (x y : T A) : T A := secret A x y\nmutual\npublic def QualifiedHeads.Left.common.{u} (A : Type u) (x y : T A) : T A := choose A x y\npublic def QualifiedHeads.Right.common.{u} (A : Type u) (x y : T A) : T A := choose A x y\nend\npublic theorem QualifiedHeads.commonLeftRfl.{u} (A : Type u) (x y : A) : Left.common A x y = x := by rfl\npublic theorem QualifiedHeads.commonRightRfl.{u} (A : Type u) (x y : A) : Right.common A x y = x := by rfl\nnamespace OuterQualified\npublic abbrev T.{u} (A : Type u) : Type u := A\npublic def outerOnly.{u} (A : Type u) (x : A) : A := x\npublic def _root_.QualifiedHeads.rooted.{u} (A : Type u) (x : T A) : T A := outerOnly A x\nend OuterQualified\npublic def qualifiedFollowing.{u} (A : Type u) (x y : A) : A := QualifiedHeads.copy A x y\n", ()),
        ("QualifiedClient", "module\npublic import QualifiedProvider\npublic def qualifiedClient.{u} (A : Type u) (x y : A) : A := QualifiedHeads.withHelper A (QualifiedHeads.fromSecret A x y) y\npublic theorem qualifiedClientProof.{u} (A : Type u) (x y : A) : QualifiedHeads.Left.common A x y = x := QualifiedHeads.commonLeftRfl A x y\npublic theorem qualifiedClientInstance.{u} (A : Type u) (x : A) : QualifiedHeads.Echo.run x (A := A) = x := by rfl\n", ()),
        ("QualifiedRooted", "module\npublic import QualifiedProvider\npublic def _root_.QualifiedHeads.bad (A : Type) (x : Inner.Only A) : A := x\n", ("Unknown", "Inner.Only",)),
        ("QualifiedMutualChildren", "module\npublic import QualifiedProvider\nmutual\npublic def QualifiedHeads.Left.bad (A : Type) (x : A) : A := Deep.only A x\npublic def QualifiedHeads.Right.bad (A : Type) (x : A) : A := x\nend\n", ("Unknown", "Deep.only",)),
        ("QualifiedMutualPlain", "module\npublic import QualifiedProvider\nmutual\npublic def QualifiedHeads.Left.bad (A : Type) (x : A) : A := Deep.only A x\npublic def qualifiedPlain (A : Type) (x : A) : A := x\nend\n", ("Unknown", "Deep.only",)),
        ("QualifiedMutualRooted", "module\npublic import QualifiedProvider\nmutual\npublic def QualifiedHeads.Left.bad (A : Type) (x : A) : A := Deep.only A x\npublic def _root_.QualifiedHeads.Right.bad (A : Type) (x : A) : A := x\nend\n", ("Unknown", "Deep.only",)),
    ]


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix="run-", dir=OUTPUT))
    inherited_env = dict(os.environ)
    report = {
        "schema": "psc0-core-module-native-oracle/1",
        "status": "RUNNING",
        "started_utc": utc_now(),
        "source_revision": os.environ.get("GITHUB_SHA"),
        "required_version": PIN_VERSION,
        "required_githash": PIN_GITHASH,
        "run_directory": str(run_dir),
        "commands": [],
        "cases": [],
    }
    (OUTPUT / "report.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )

    def invoke(tag, argv, cwd, env):
        stdout_path = run_dir / f"{tag}.stdout"
        stderr_path = run_dir / f"{tag}.stderr"
        record = {
            "tag": tag,
            "argv": [str(arg) for arg in argv],
            "cwd": str(cwd),
            "stdout": str(stdout_path.relative_to(run_dir)),
            "stderr": str(stderr_path.relative_to(run_dir)),
            "returncode": None,
            "timed_out": False,
        }
        report["commands"].append(record)
        started = time.monotonic()
        stdout = b""
        stderr = b""
        failure = None
        completed = None
        try:
            completed = subprocess.run(
                record["argv"], cwd=cwd, env=env, capture_output=True,
                timeout=TIMEOUT_SECONDS, check=False,
            )
            stdout = completed.stdout
            stderr = completed.stderr
            record["returncode"] = completed.returncode
        except subprocess.TimeoutExpired as exc:
            stdout = exc.stdout or b""
            stderr = exc.stderr or b""
            record["timed_out"] = True
            failure = f"{tag}: exceeded {TIMEOUT_SECONDS} seconds"
        except OSError as exc:
            failure = f"{tag}: could not launch compiler: {exc}"
        finally:
            stdout_path.write_bytes(stdout)
            stderr_path.write_bytes(stderr)
            record["elapsed_seconds"] = round(time.monotonic() - started, 3)
        if failure is not None:
            record["failure"] = failure
            raise RuntimeError(failure)
        return completed

    def probe(tag, argv, cwd, env):
        completed = invoke(tag, argv, cwd, env)
        require(completed.returncode == 0, f"{tag}: expected exit 0; see captured logs")
        require(completed.stderr == b"", f"{tag}: unexpected stderr")
        lines = completed.stdout.decode("utf-8").strip().splitlines()
        require(len(lines) == 1, f"{tag}: expected one output line")
        return lines[0]

    try:
        launcher = shutil.which("lean")
        require(launcher is not None, "lean not found; launch through lake env")
        # Resolve through sysroot, not through an elan symlink's argv[0].
        prefix = probe("toolchain-prefix", [launcher, "--print-prefix"],
                       Path.cwd(), inherited_env)
        lean = Path(prefix) / "bin" / "lean"
        require(lean.is_absolute() and lean.is_file(), f"native Lean binary missing: {lean}")
        env = dict(inherited_env)
        # Lean appends its builtin sysroot library after this fixture-only path.
        env["LEAN_PATH"] = str(run_dir)
        report["lean_binary"] = str(lean)
        report["lean_path"] = env["LEAN_PATH"]
        report["source_root"] = str(run_dir)
        version = probe("toolchain-version", [lean, "--short-version"], run_dir, env)
        githash = probe("toolchain-githash", [lean, "--githash"], run_dir, env)
        report["actual_version"] = version
        report["actual_githash"] = githash
        require(version == PIN_VERSION, f"wrong Lean version: {version!r}")
        require(githash == PIN_GITHASH, f"wrong Lean commit: {githash!r}")
        fixtures = cases()
        require(len(fixtures) == 115, "oracle must contain 115 compile cases")
        require(sum(not expected for _, _, expected in fixtures) == 55,
                "oracle must contain 55 expected successful compilations")

        for name, contents, expected_errors in fixtures:
            input_path = run_dir / f"{name}.lean"
            output_path = run_dir / f"{name}.olean"
            input_path.parent.mkdir(parents=True, exist_ok=True)
            input_path.write_text(contents, encoding="utf-8")
            case = {
                "name": name,
                "expectation": "refusal" if expected_errors else "acceptance",
                "expected_error_substrings": list(expected_errors),
                "source": str(input_path.relative_to(run_dir)),
                "source_sha256": sha256(input_path),
                "command_tag": name,
                "status": "FAIL",
            }
            report["cases"].append(case)
            completed = invoke(
                name, [lean, "--json", f"--root={run_dir}", "-o",
                       str(output_path.relative_to(run_dir)),
                       str(input_path.relative_to(run_dir))], run_dir, env,
            )
            case["returncode"] = completed.returncode
            case["olean_artifacts"] = sorted(
                str(path.relative_to(run_dir)) for path in run_dir.glob(f"{name}.olean*")
            )
            require(completed.stderr == b"", f"{name}: unexpected stderr")
            diagnostics = []
            for line in completed.stdout.decode("utf-8").splitlines():
                if not line.strip():
                    continue
                item = json.loads(line)
                require(
                    isinstance(item, dict)
                    and item.get("severity") in ("information", "warning", "error")
                    and isinstance(item.get("data"), str),
                    f"{name}: malformed native JSON diagnostic",
                )
                diagnostics.append(item)
            case["diagnostics"] = diagnostics
            errors = [item for item in diagnostics if item["severity"] == "error"]
            if expected_errors:
                require(completed.returncode == 1, f"{name}: refusal must exit exactly 1")
                require(len(errors) == 1,
                        f"{name}: expected one native error, received {len(errors)}")
                error = errors[0]
                filename = error.get("fileName")
                require(isinstance(filename, str) and Path(filename).name == input_path.name,
                        f"{name}: error did not originate in this fixture")
                require(all(fragment in error["data"] for fragment in expected_errors),
                        f"{name}: wrong semantic refusal; see diagnostics")
                require(not case["olean_artifacts"],
                        f"{name}: rejected source emitted an .olean artifact")
            else:
                require(completed.returncode == 0 and not errors,
                        f"{name}: expected successful native compilation")
                require(not any(item.get("kind") == "hasSorry"
                                or "declaration uses `sorry`" in item["data"]
                                for item in diagnostics),
                        f"{name}: native compilation reported a proof hole")
                require(output_path.is_file() and output_path.stat().st_size > 0,
                        f"{name}: successful compilation emitted no .olean")
            case["status"] = "PASS"
            print(f"PASS {name}: {case['expectation']}", flush=True)

        report["status"] = "PASS"
        report["successful_compilations"] = 55
        report["expected_refusals"] = 60
    except Exception as exc:
        report["status"] = "FAIL"
        report["failure"] = f"{type(exc).__name__}: {exc}"
        print(f"PSCV0_CORE_MODULE_NATIVE_ORACLE: FAIL: {report['failure']}",
              file=sys.stderr, flush=True)
    finally:
        report["finished_utc"] = utc_now()
        report["artifacts"] = [
            {"path": str(path.relative_to(run_dir)), "bytes": path.stat().st_size,
             "sha256": sha256(path)}
            for path in sorted(run_dir.rglob("*")) if path.is_file()
        ]
        payload = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
        (run_dir / "report.json").write_text(payload, encoding="utf-8")
        (OUTPUT / "report.json").write_text(payload, encoding="utf-8")

    if report["status"] != "PASS":
        return 1
    print("PSCV0_CORE_MODULE_NATIVE_RESULT " + json.dumps({
        "schema": "psc0-core-module-native-result/1",
        "source_revision": report["source_revision"],
        "version": report["actual_version"],
        "githash": report["actual_githash"],
        "status": report["status"],
        "successful_compilations": report["successful_compilations"],
        "expected_refusals": report["expected_refusals"],
        "cases": report["cases"],
    }, sort_keys=True), flush=True)
    print("PSCV0_CORE_MODULE_NATIVE_ORACLE: 115 cases passed "
          "(55 successful compilations, 60 expected refusals)", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
