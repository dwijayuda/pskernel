import Ps.Environment.Control

-- Recursive mathematical order, not a Bool equality. Every definition below is
-- replayed by the independent pinned kernel. Decisions are total Nat/Int folds;
-- runtime lowering uses the existing exact comparison intrinsics.
def psOrderFalseName : PsName := psRootName "_psc1OrderFalse"
def psOrderTrueName : PsName := psRootName "_psc1OrderTrue"
def psOrderIntroName : PsName := psNameAppendStr psOrderTrueName "intro"
def psOrderIsFalseName : PsName := psNameAppendStr psDecidableName "isFalse"
def psOrderIsTrueName : PsName := psNameAppendStr psDecidableName "isTrue"

def psOrderFalseDeclaration : PsDeclaration :=
  PsDeclaration.inductiveDecl (PsInductiveInfo.mk psOrderFalseName []
    psPreludePropType 0 0 [] false)
def psOrderTrueDeclaration : PsDeclaration :=
  PsDeclaration.inductiveDecl (PsInductiveInfo.mk psOrderTrueName []
    psPreludePropType 0 0 [psOrderIntroName] false)
def psOrderIntroDeclaration : PsDeclaration :=
  PsDeclaration.constructorDecl (PsConstructorInfo.mk psOrderIntroName []
    (PsExpr.constE psOrderTrueName []) psOrderTrueName 0 0 0 [])

def psOrderDecisionDeclaration : PsDeclaration :=
  PsDeclaration.inductiveDecl (PsInductiveInfo.mk psDecidableName []
    psPreludeDecidableType 1 0 [psOrderIsFalseName, psOrderIsTrueName] false)
def psOrderDecisionConstructor (positive : Bool) : PsDeclaration :=
  let proposition := PsExpr.fvar 0;
  let falseType := PsExpr.constE psOrderFalseName [];
  let proofType : PsExpr :=
    if positive then proposition
    else psControlClose false [PsControlBinder.mk 2 (psRootName "proof") proposition] falseType;
  let type := psControlClose false
    [PsControlBinder.mk 0 (psRootName "proposition") psPreludePropType,
      PsControlBinder.mk 1 (psRootName "proof") proofType]
    (PsExpr.app (PsExpr.constE psDecidableName []) proposition);
  let name : PsName := if positive then psOrderIsTrueName else psOrderIsFalseName;
  let tag : Nat := if positive then 1 else 0;
  PsDeclaration.constructorDecl (PsConstructorInfo.mk name [] type psDecidableName tag 1 1 [])

def psOrderIntDeclaration : PsDeclaration :=
  PsDeclaration.inductiveDecl (PsInductiveInfo.mk psIntName []
    psPreludeTypeType 0 0 [psIntOfNatName, psIntNegSuccName] false)
def psOrderIntConstructor (positive : Bool) : PsDeclaration :=
  let name : PsName := if positive then psIntOfNatName else psIntNegSuccName;
  let tag : Nat := if positive then 0 else 1;
  PsDeclaration.constructorDecl (PsConstructorInfo.mk name [] psPreludeIntOfNatType
    psIntName tag 0 1 [])
def psOrderIntRecDeclaration : PsDeclaration :=
  let motive := PsExpr.fvar 0;
  let motiveType := psControlClose false
    [PsControlBinder.mk 4 (psRootName "major") psPreludeIntType]
    (PsExpr.sortE (PsLevel.param psPreludeUName));
  let positiveType := psControlClose false
    [PsControlBinder.mk 4 (psRootName "n") psPreludeNatType]
    (PsExpr.app motive (PsExpr.app (PsExpr.constE psIntOfNatName []) (PsExpr.fvar 4)));
  let negativeType := psControlClose false
    [PsControlBinder.mk 4 (psRootName "n") psPreludeNatType]
    (PsExpr.app motive (PsExpr.app (PsExpr.constE psIntNegSuccName []) (PsExpr.fvar 4)));
  let type := psControlClose false
    [PsControlBinder.mk 0 (psRootName "motive") motiveType,
      PsControlBinder.mk 1 (psRootName "positive") positiveType,
      PsControlBinder.mk 2 (psRootName "negative") negativeType,
      PsControlBinder.mk 3 (psRootName "major") psPreludeIntType]
    (PsExpr.app motive (PsExpr.fvar 3));
  PsDeclaration.recursorDecl (PsRecursorInfo.mk psIntRecName [psPreludeUName]
    type [psIntName] 0 0 1 2)

def psNatLeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatLeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (psControlApply (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType] (psControlClose false [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] psPreludePropType)), (psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (PsExpr.constE psOrderTrueName [])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType, PsControlBinder.mk 3 (psRootName "x3") (psControlClose false [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] psPreludePropType)] (psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] psPreludePropType), (PsExpr.constE psOrderFalseName []), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType, PsControlBinder.mk 4 (psRootName "x4") psPreludePropType] (psControlApply (PsExpr.fvar 3) [(PsExpr.fvar 2)])), (PsExpr.fvar 1)]))), (PsExpr.fvar 0)]) [(PsExpr.fvar 1)]))

def psNatDecLeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatDecLeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psNatLeName []) [(PsExpr.fvar 0), (PsExpr.fvar 1)])]))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (psControlApply (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType] (psControlClose false [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psNatLeName []) [(PsExpr.fvar 0), (PsExpr.fvar 1)])]))), (psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psOrderIsTrueName []) [(PsExpr.constE psOrderTrueName []), (PsExpr.constE psOrderIntroName [])])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType, PsControlBinder.mk 3 (psRootName "x3") (psControlClose false [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psNatLeName []) [(PsExpr.fvar 2), (PsExpr.fvar 1)])]))] (psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psNatLeName []) [(psControlApply (PsExpr.constE psNatSuccName []) [(PsExpr.fvar 2)]), (PsExpr.fvar 1)])])), (psControlApply (PsExpr.constE psOrderIsFalseName []) [(PsExpr.constE psOrderFalseName []), (psControlClose true [PsControlBinder.mk 44 (psRootName "x44") (PsExpr.constE psOrderFalseName [])] (PsExpr.fvar 44))]), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType, PsControlBinder.mk 5 (psRootName "x5") (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psNatLeName []) [(psControlApply (PsExpr.constE psNatSuccName []) [(PsExpr.fvar 2)]), (PsExpr.fvar 4)])])] (psControlApply (PsExpr.fvar 3) [(PsExpr.fvar 4)])), (PsExpr.fvar 1)]))), (PsExpr.fvar 0)]) [(PsExpr.fvar 1)]))

def psNatLtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatLtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psNatLeName []) [(psControlApply (PsExpr.constE psNatSuccName []) [(PsExpr.fvar 0)]), (PsExpr.fvar 1)]))

def psNatDecLtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatDecLtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psNatLtName []) [(PsExpr.fvar 0), (PsExpr.fvar 1)])]))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeNatType, PsControlBinder.mk 1 (psRootName "x1") psPreludeNatType] (psControlApply (PsExpr.constE psNatDecLeName []) [(psControlApply (PsExpr.constE psNatSuccName []) [(PsExpr.fvar 0)]), (PsExpr.fvar 1)]))

def psIntLeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntLeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType] psPreludePropType), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] psPreludePropType), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatLeName []) [(PsExpr.fvar 2), (PsExpr.fvar 4)])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (PsExpr.constE psOrderFalseName [])), (PsExpr.fvar 1)])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] psPreludePropType), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (PsExpr.constE psOrderTrueName [])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatLeName []) [(PsExpr.fvar 4), (PsExpr.fvar 2)])), (PsExpr.fvar 1)])), (PsExpr.fvar 0)]))

def psIntDecLeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntDecLeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLeName []) [(PsExpr.fvar 0), (PsExpr.fvar 1)])]))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLeName []) [(PsExpr.fvar 0), (PsExpr.fvar 1)])])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLeName []) [(psControlApply (PsExpr.constE psIntOfNatName []) [(PsExpr.fvar 2)]), (PsExpr.fvar 1)])])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatDecLeName []) [(PsExpr.fvar 2), (PsExpr.fvar 4)])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psOrderIsFalseName []) [(PsExpr.constE psOrderFalseName []), (psControlClose true [PsControlBinder.mk 44 (psRootName "x44") (PsExpr.constE psOrderFalseName [])] (PsExpr.fvar 44))])), (PsExpr.fvar 1)])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLeName []) [(psControlApply (PsExpr.constE psIntNegSuccName []) [(PsExpr.fvar 2)]), (PsExpr.fvar 1)])])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psOrderIsTrueName []) [(PsExpr.constE psOrderTrueName []), (PsExpr.constE psOrderIntroName [])])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatDecLeName []) [(PsExpr.fvar 4), (PsExpr.fvar 2)])), (PsExpr.fvar 1)])), (PsExpr.fvar 0)]))

def psIntLtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntLtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType] psPreludePropType), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] psPreludePropType), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatLtName []) [(PsExpr.fvar 2), (PsExpr.fvar 4)])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (PsExpr.constE psOrderFalseName [])), (PsExpr.fvar 1)])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] psPreludePropType), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (PsExpr.constE psOrderTrueName [])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatLtName []) [(PsExpr.fvar 4), (PsExpr.fvar 2)])), (PsExpr.fvar 1)])), (PsExpr.fvar 0)]))

def psIntDecLtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntDecLtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLtName []) [(PsExpr.fvar 0), (PsExpr.fvar 1)])]))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType, PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 0 (psRootName "x0") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLtName []) [(PsExpr.fvar 0), (PsExpr.fvar 1)])])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLtName []) [(psControlApply (PsExpr.constE psIntOfNatName []) [(PsExpr.fvar 2)]), (PsExpr.fvar 1)])])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatDecLtName []) [(PsExpr.fvar 2), (PsExpr.fvar 4)])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psOrderIsFalseName []) [(PsExpr.constE psOrderFalseName []), (psControlClose true [PsControlBinder.mk 44 (psRootName "x44") (PsExpr.constE psOrderFalseName [])] (PsExpr.fvar 44))])), (PsExpr.fvar 1)])), (psControlClose true [PsControlBinder.mk 2 (psRootName "x2") psPreludeNatType] (psControlApply (PsExpr.constE psIntRecName [PsLevel.succ PsLevel.zero]) [(psControlClose true [PsControlBinder.mk 1 (psRootName "x1") psPreludeIntType] (psControlApply (PsExpr.constE psDecidableName []) [(psControlApply (PsExpr.constE psIntLtName []) [(psControlApply (PsExpr.constE psIntNegSuccName []) [(PsExpr.fvar 2)]), (PsExpr.fvar 1)])])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psOrderIsTrueName []) [(PsExpr.constE psOrderTrueName []), (PsExpr.constE psOrderIntroName [])])), (psControlClose true [PsControlBinder.mk 4 (psRootName "x4") psPreludeNatType] (psControlApply (PsExpr.constE psNatDecLtName []) [(PsExpr.fvar 4), (PsExpr.fvar 2)])), (PsExpr.fvar 1)])), (PsExpr.fvar 0)]))

def psNatGtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatGtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] (psControlApply (PsExpr.constE psNatLtName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psNatDecGtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatDecGtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] (PsExpr.app (PsExpr.constE psDecidableName []) (psControlApply (PsExpr.constE psNatGtName []) [PsExpr.fvar 0, PsExpr.fvar 1])))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] (psControlApply (PsExpr.constE psNatDecLtName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psNatGeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatGeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] (psControlApply (PsExpr.constE psNatLeName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psNatDecGeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psNatDecGeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] (PsExpr.app (PsExpr.constE psDecidableName []) (psControlApply (PsExpr.constE psNatGeName []) [PsExpr.fvar 0, PsExpr.fvar 1])))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeNatType, PsControlBinder.mk 1 (psRootName "right") psPreludeNatType] (psControlApply (PsExpr.constE psNatDecLeName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psIntGtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntGtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] (psControlApply (PsExpr.constE psIntLtName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psIntDecGtDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntDecGtName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] (PsExpr.app (PsExpr.constE psDecidableName []) (psControlApply (PsExpr.constE psIntGtName []) [PsExpr.fvar 0, PsExpr.fvar 1])))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] (psControlApply (PsExpr.constE psIntDecLtName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psIntGeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntGeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] psPreludePropType)
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] (psControlApply (PsExpr.constE psIntLeName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psIntDecGeDeclaration : PsDeclaration :=
  PsDeclaration.definitionDecl psIntDecGeName []
    (psControlClose false [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] (PsExpr.app (PsExpr.constE psDecidableName []) (psControlApply (PsExpr.constE psIntGeName []) [PsExpr.fvar 0, PsExpr.fvar 1])))
    (psControlClose true [PsControlBinder.mk 0 (psRootName "left") psPreludeIntType, PsControlBinder.mk 1 (psRootName "right") psPreludeIntType] (psControlApply (PsExpr.constE psIntDecLeName []) [PsExpr.fvar 1, PsExpr.fvar 0]))

def psOrderDeclarations : List PsDeclaration :=
  [psOrderFalseDeclaration, psOrderTrueDeclaration, psOrderIntroDeclaration,
    psOrderDecisionDeclaration, psOrderDecisionConstructor false,
    psOrderDecisionConstructor true, psOrderIntDeclaration,
    psOrderIntConstructor true, psOrderIntConstructor false, psOrderIntRecDeclaration,
    psNatLeDeclaration, psNatDecLeDeclaration, psNatLtDeclaration, psNatDecLtDeclaration,
    psIntLeDeclaration, psIntDecLeDeclaration, psIntLtDeclaration, psIntDecLtDeclaration,
    psNatGtDeclaration, psNatDecGtDeclaration, psNatGeDeclaration, psNatDecGeDeclaration, psIntGtDeclaration, psIntDecGtDeclaration, psIntGeDeclaration, psIntDecGeDeclaration]

def psOrderAddDeclarations (declarations : List PsDeclaration) :
    PsEnvironment -> PsEnvironment :=
  match declarations with
  | List.nil => fun (environment : PsEnvironment) => environment
  | List.cons declaration rest =>
      let smaller := psOrderAddDeclarations rest;
      fun (environment : PsEnvironment) =>
        smaller (psSelfHostReplacePreludeAxiom environment declaration)

def psOrderPreludeEnvironment (environment : PsEnvironment) : PsEnvironment :=
  psOrderAddDeclarations psOrderDeclarations environment
