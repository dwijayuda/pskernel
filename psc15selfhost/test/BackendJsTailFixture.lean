import Ps.BackendJs.Print

def psJsTailFixtureNat (value : Nat) : PsJsIrExpr := .literal (.natural value)

def psJsTailFixtureNext : PsJsIrExpr := .binary .bigintSub (.var "count") (psJsTailFixtureNat 1)

def psJsTailFixtureIncrement : PsJsIrExpr := .binary .bigintAdd (.var "value") (psJsTailFixtureNat 1)

def psJsTailFixtureDone : PsJsIrExpr := .binary .bigintEq (.var "count") (psJsTailFixtureNat 0)

def psJsTailFixtureAlias (name aliasName shadowName : String) : PsJsIrDeclaration :=
  .mk name [.mk "count", .mk "value"]
    (.ifE psJsTailFixtureDone (.var "value")
      (.letE "remaining" psJsTailFixtureNext
        (.letE aliasName (.lambda ["next"] (.call (.var name) [.var "remaining", .var "next"]))
          (.letE shadowName (psJsTailFixtureNat 0)
            (.call (.var aliasName) [psJsTailFixtureIncrement])))))

def psJsTailFixtureShadow : PsJsIrDeclaration :=
  .mk "tailShadow" [.mk "count", .mk "value"]
    (.ifE psJsTailFixtureDone (.var "value")
      (.letE "value" psJsTailFixtureIncrement
        (.call (.var "tailShadow") [psJsTailFixtureNext, .var "value"])))

def psJsTailFixtureSwap : PsJsIrDeclaration :=
  .mk "tailSwap" [.mk "count", .mk "left", .mk "right"]
    (.ifE psJsTailFixtureDone (.var "left")
      (.call (.var "tailSwap") [psJsTailFixtureNext, .var "right", .var "left"]))

def psJsTailFixtureClosures : PsJsIrDeclaration :=
  .mk "tailClosures" [.mk "count", .mk "values"]
    (.ifE psJsTailFixtureDone (.var "values")
      (.call (.var "tailClosures") [psJsTailFixtureNext,
        .runtime .arrayPush [.var "values", .lambda [] (.var "count")]]))

def psJsTailFixtureEscaped : PsJsIrDeclaration :=
  .mk "escapedAlias" [.mk "count", .mk "value"]
    (.ifE psJsTailFixtureDone (.var "value")
      (.letE "remaining" psJsTailFixtureNext
        (.letE "smaller" (.lambda ["next"] (.call (.var "escapedAlias") [.var "remaining", .var "next"]))
          (.letE "escaped" (.call (.var "identity") [.var "smaller"])
            (.call (.var "escaped") [psJsTailFixtureIncrement])))))

def psJsTailFixtureNonTailShadow : PsJsIrDeclaration :=
  .mk "nonTailShadow" [.mk "count", .mk "value"]
    (.ifE psJsTailFixtureDone (.var "value")
      (.letE "value" psJsTailFixtureIncrement
        (.binary .bigintAdd (psJsTailFixtureNat 1)
          (.call (.var "nonTailShadow") [psJsTailFixtureNext, .var "value"]))))

def psJsTailFixtureStateCollision : PsJsIrDeclaration :=
  .mk "stateCollision" [.mk "count", .mk "__ps$tail$state"]
    (.ifE psJsTailFixtureDone (.var "__ps$tail$state")
      (.call (.var "stateCollision") [psJsTailFixtureNext, .var "__ps$tail$state"]))

def psJsTailFixtureMatchShadow : PsJsIrDeclaration :=
  .mk "matchAliasShadow" [.mk "count", .mk "value"]
    (.letE "smaller" (.lambda ["next"] (.call (.var "matchAliasShadow") [.var "count", .var "next"]))
      (.matchE (.constructor "box" [("fn", .lambda ["x"] (.binary .bigintAdd (.var "x") (psJsTailFixtureNat 7)))])
        [("box", [.mk "fn" "smaller"], .call (.var "smaller") [.var "value"])]))

def psJsTailFixtureModule : PsJsIrModule :=
  .mk [] [
    .mk "identity" [.mk "value"] (.var "value"),
    .mk "ordinaryShadow" [.mk "value"] (.letE "value" psJsTailFixtureIncrement (.var "value")),
    psJsTailFixtureAlias "tailAlias" "smaller" "remaining",
    psJsTailFixtureAlias "tailAliasBeforeBinder" "remaining" "count",
    psJsTailFixtureShadow, psJsTailFixtureSwap, psJsTailFixtureClosures,
    psJsTailFixtureEscaped, psJsTailFixtureNonTailShadow, psJsTailFixtureStateCollision,
    psJsTailFixtureMatchShadow
  ]

def psJsTailFixtureCapturedAliasDeclined : Bool :=
  let decl := PsJsIrDeclaration.mk "worker" [.mk "prefixValue", .mk "value"]
    (.letE "first" (.lambda ["next"] (.call (.var "worker") [.var "prefixValue", .var "next"]))
      (.letE "second" (.lambda ["next"] (.call (.var "worker") [.var "first", .var "next"]))
        (.call (.var "second") [.var "value"])));
  (psJsPrintTailLoop decl).isNone
