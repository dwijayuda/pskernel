import Ps.Environment.StandardFormatBasic
import Ps.Environment.ReprExpr

-- Shared authoring vocabulary for the checked formatter. These helpers build
-- Core terms; they neither interpret source syntax nor run a host formatter.
def psFormatPrivateName (suffix : String) : PsName :=
  psNameAppendStr (psRootName "$psc0Format") suffix
def psFormatPrivateType (suffix : String) : PsExpr :=
  .constE (psFormatPrivateName suffix) []
def psFormatPrivateCall (suffix : String) (args : List PsExpr := []) : PsExpr :=
  psLogicApply (.constE (psFormatPrivateName suffix) []) args
def psFormatRecord (suffix : String) (args : List PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psFormatPrivateName suffix) "mk") []) args
def psFormatField (suffix : String) (index : Nat) (value : PsExpr) : PsExpr :=
  .proj (psFormatPrivateName suffix) index value
def psFormatLet (id : Nat) (name : String) (type value body : PsExpr) : PsExpr :=
  .letE (psRootName name) type value (psExprAbstractFVar id body)
def psFormatBool (b : Bool) : PsExpr := .constE (if b then psBoolTrueName else psBoolFalseName) []
def psFormatNot (b : PsExpr) : PsExpr :=
  psFormatIf (.constE psBoolName []) b (psFormatBool false) (psFormatBool true)
def psFormatAnd (a b : PsExpr) : PsExpr :=
  psFormatIf (.constE psBoolName []) a b (psFormatBool false)
def psFormatPositive (n : PsExpr) : PsExpr :=
  psOrderCall "Nat.blt" [psFormatNat 0, psOrderCall "Int.toNat" [n]]
def psFormatStringAppend (a b : PsExpr) : PsExpr :=
  psLogicApply (.constE psStringAppendName []) [a, b]
def psFormatPrivateDefinition (name : String) (params : List PsStandardDataField)
    (result body : PsExpr) : PsDeclaration :=
  psFormatDefinition ("$psc0Format." ++ name) params result body

-- One scan returns both the UTF-8 boundary and Unicode scalar width before LF.
-- No read occurs at rawEndPos. The traversal bound is derived from the source.
def psFormatTextScanDeclarations : List PsDeclaration :=
  let nat := psOrderNat
  let str := PsExpr.constE psStringName []
  let result := psFormatPrivateType "TextPrefix"
  let record := psStandardRecordDeclarations (psFormatPrivateName "TextPrefix")
    [{ name := "position", type := nat }, { name := "columns", type := nat }]
  let source := PsExpr.fvar 0
  let fuel := PsExpr.fvar 1
  let pos := PsExpr.fvar 2
  let col := PsExpr.fvar 3
  let done := psFormatRecord "TextPrefix" [pos, col]
  let bind := fun body => psLogicLam 2 "position" nat (psLogicLam 3 "columns" nat body)
  let arrow := psLogicPi 2 "position" nat (psLogicPi 3 "columns" nat result)
  let scalar := psLogicApply (.constE psStringGetName []) [source, pos]
  let isLF := psOrderCall "Nat.beq" [.app (.constE psCharToNatName []) scalar, psFormatNat 10]
  let recurse := psLogicApply (.fvar 5)
    [psLogicApply (.constE psStringNextName []) [source, pos], psOrderSucc col]
  let step := psFormatIf result
    (psLogicApply (.constE psStringAtEndName []) [source, pos]) done
    (psFormatIf result isLF done recurse)
  let body := psOrderNatRec (.succ .zero) (psLogicLam 4 "_" nat arrow)
    (bind done)
    (psLogicLam 4 "remaining" nat (psLogicLam 5 "ih" arrow (bind step))) fuel
  let worker := psFormatPrivateDefinition "textScan"
    [{ name := "source", type := str }, { name := "fuel", type := nat }] arrow body
  let scan := psFormatPrivateDefinition "textPrefix" [{ name := "source", type := str }] result
    (psFormatPrivateCall "textScan"
      [source, .app (.constE psStringUtf8ByteSizeName []) source, psFormatNat 0, psFormatNat 0])
  record ++ [worker, scan]
