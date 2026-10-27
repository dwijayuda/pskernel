import OperationalFoundation
import Ps.Environment.Order

namespace Ps.MinKernel.OperationalSource
open Ps.MinKernel.RegularModel

-- These equalities bind the symbolic model to the actual source-owned declarations.
-- CI also checks their complete exported structured contracts against this pin.
def expectedIteType : PsExpr := (PsExpr.forallE (PsName.str PsName.anonymous "α") (PsExpr.sortE (PsLevel.param (PsName.str PsName.anonymous "u"))) (PsExpr.forallE (PsName.str PsName.anonymous "c") (PsExpr.sortE PsLevel.zero) (PsExpr.forallE (PsName.str PsName.anonymous "h") (PsExpr.app (PsExpr.constE (PsName.str PsName.anonymous "Decidable") []) (PsExpr.bvar 0)) (PsExpr.forallE (PsName.str PsName.anonymous "t") (PsExpr.bvar 2) (PsExpr.forallE (PsName.str PsName.anonymous "e") (PsExpr.bvar 3) (PsExpr.bvar 4) PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.instanceImplicit) PsBinderInfo.explicit) PsBinderInfo.implicit)
def expectedIteValue : PsExpr := (PsExpr.lam (PsName.str PsName.anonymous "α") (PsExpr.sortE (PsLevel.param (PsName.str PsName.anonymous "u"))) (PsExpr.lam (PsName.str PsName.anonymous "c") (PsExpr.sortE PsLevel.zero) (PsExpr.lam (PsName.str PsName.anonymous "h") (PsExpr.app (PsExpr.constE (PsName.str PsName.anonymous "Decidable") []) (PsExpr.bvar 0)) (PsExpr.lam (PsName.str PsName.anonymous "t") (PsExpr.bvar 2) (PsExpr.lam (PsName.str PsName.anonymous "e") (PsExpr.bvar 3) (PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.constE (PsName.str (PsName.str PsName.anonymous "Decidable") "rec") [(PsLevel.param (PsName.str PsName.anonymous "u"))]) (PsExpr.bvar 3)) (PsExpr.lam (PsName.str PsName.anonymous "major") (PsExpr.app (PsExpr.constE (PsName.str PsName.anonymous "Decidable") []) (PsExpr.bvar 3)) (PsExpr.bvar 5) PsBinderInfo.explicit)) (PsExpr.lam (PsName.str PsName.anonymous "proof") (PsExpr.forallE (PsName.str PsName.anonymous "proof") (PsExpr.bvar 3) (PsExpr.constE (PsName.str PsName.anonymous "_psc1OrderFalse") []) PsBinderInfo.explicit) (PsExpr.bvar 1) PsBinderInfo.explicit)) (PsExpr.lam (PsName.str PsName.anonymous "proof") (PsExpr.bvar 3) (PsExpr.bvar 2) PsBinderInfo.explicit)) (PsExpr.bvar 2)) PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.explicit)
def expectedDecisionRecType : PsExpr := (PsExpr.forallE (PsName.str PsName.anonymous "proposition") (PsExpr.sortE PsLevel.zero) (PsExpr.forallE (PsName.str PsName.anonymous "motive") (PsExpr.forallE (PsName.str PsName.anonymous "major") (PsExpr.app (PsExpr.constE (PsName.str PsName.anonymous "Decidable") []) (PsExpr.bvar 0)) (PsExpr.sortE (PsLevel.param (PsName.str PsName.anonymous "u"))) PsBinderInfo.explicit) (PsExpr.forallE (PsName.str PsName.anonymous "failure") (PsExpr.forallE (PsName.str PsName.anonymous "proof") (PsExpr.forallE (PsName.str PsName.anonymous "proof") (PsExpr.bvar 1) (PsExpr.constE (PsName.str PsName.anonymous "_psc1OrderFalse") []) PsBinderInfo.explicit) (PsExpr.app (PsExpr.bvar 1) (PsExpr.app (PsExpr.app (PsExpr.constE (PsName.str (PsName.str PsName.anonymous "Decidable") "isFalse") []) (PsExpr.bvar 2)) (PsExpr.bvar 0))) PsBinderInfo.explicit) (PsExpr.forallE (PsName.str PsName.anonymous "success") (PsExpr.forallE (PsName.str PsName.anonymous "proof") (PsExpr.bvar 2) (PsExpr.app (PsExpr.bvar 2) (PsExpr.app (PsExpr.app (PsExpr.constE (PsName.str (PsName.str PsName.anonymous "Decidable") "isTrue") []) (PsExpr.bvar 3)) (PsExpr.bvar 0))) PsBinderInfo.explicit) (PsExpr.forallE (PsName.str PsName.anonymous "major") (PsExpr.app (PsExpr.constE (PsName.str PsName.anonymous "Decidable") []) (PsExpr.bvar 3)) (PsExpr.app (PsExpr.bvar 3) (PsExpr.bvar 0)) PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.explicit)

theorem actual_ite_declaration :
    psOrderIteDeclaration = PsDeclaration.definitionDecl psIteName [psPreludeUName]
      expectedIteType expectedIteValue := by rfl

theorem actual_decision_recursor :
    psOrderDecisionRecDeclaration = PsDeclaration.recursorDecl
      (PsRecursorInfo.mk psOrderDecisionRecName [psPreludeUName] expectedDecisionRecType
        [psDecidableName] 1 0 1 2) := by rfl

-- Constructive model of the exact two-minor Decidable.rec implementation above.
def decisionBody {R : Type} (p : Prop) (decision : Decidable p) (yes no : R) : R :=
  match decision with
  | .isFalse _ => no
  | .isTrue _ => yes

theorem decisionBody_eq_ite {R : Type} (p : Prop) (decision : Decidable p) (yes no : R) :
    decisionBody p decision yes no = @ite R p decision yes no := by
  cases decision <;> rfl

theorem source_boolEqIte (data : List Type) (result : PsMinRegTy)
    (left right : Bool) (yes no : Denote data result) :
    decisionBody (Eq left right) (Bool.decEq left right) yes no =
      OperationalFoundation.primitiveValue data (.boolEqIte result) left right yes no := by
  exact decisionBody_eq_ite _ _ _ _

#print axioms actual_ite_declaration
#print axioms actual_decision_recursor
#print axioms decisionBody_eq_ite
#print axioms source_boolEqIte
end Ps.MinKernel.OperationalSource
