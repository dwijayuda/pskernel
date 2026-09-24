import Ps.Foundation.Name

def psRootName (value : String) : PsName :=
  PsName.str PsName.anonymous value

def psNatName : PsName :=
  psRootName "Nat"

def psNatAddName : PsName :=
  psNameAppendStr psNatName "add"

def psNatSubName : PsName :=
  psNameAppendStr psNatName "sub"

def psNatMulName : PsName :=
  psNameAppendStr psNatName "mul"

def psNatDivName : PsName :=
  psNameAppendStr psNatName "div"

def psNatModName : PsName :=
  psNameAppendStr psNatName "mod"

def psNatBeqName : PsName :=
  psNameAppendStr psNatName "beq"

def psIntName : PsName :=
  psRootName "Int"

def psIntOfNatName : PsName :=
  psNameAppendStr psIntName "ofNat"

def psIntNegSuccName : PsName :=
  psNameAppendStr psIntName "negSucc"

def psIntNegName : PsName :=
  psNameAppendStr psIntName "neg"

def psIntAddName : PsName :=
  psNameAppendStr psIntName "add"

def psIntSubName : PsName :=
  psNameAppendStr psIntName "sub"

def psIntMulName : PsName :=
  psNameAppendStr psIntName "mul"

def psArrayName : PsName :=
  psRootName "Array"

def psArrayEmptyWithCapacityName : PsName :=
  psNameAppendStr psArrayName "emptyWithCapacity"

def psArraySizeName : PsName :=
  psNameAppendStr psArrayName "size"

def psArrayPushName : PsName :=
  psNameAppendStr psArrayName "push"

def psArrayGetInternalName : PsName :=
  psNameAppendStr psArrayName "getInternal"

def psArrayGetDName : PsName :=
  psNameAppendStr psArrayName "getD"

def psArraySetName : PsName :=
  psNameAppendStr psArrayName "set"

def psArraySetIfInBoundsName : PsName :=
  psNameAppendStr psArrayName "setIfInBounds"

def psArrayMapName : PsName :=
  psNameAppendStr psArrayName "map"

def psArrayFoldlName : PsName :=
  psNameAppendStr psArrayName "foldl"

def psStringName : PsName :=
  psRootName "String"

def psBoolName : PsName :=
  psRootName "Bool"

def psUnitName : PsName :=
  psRootName "Unit"

def psBoolTrueName : PsName :=
  psNameAppendStr psBoolName "true"

def psBoolFalseName : PsName :=
  psNameAppendStr psBoolName "false"

def psEqName : PsName :=
  psRootName "Eq"

def psDecidableName : PsName :=
  psRootName "Decidable"

def psBoolDecEqName : PsName :=
  psNameAppendStr psBoolName "decEq"

def psIteName : PsName :=
  psRootName "ite"

def psUnitUnitName : PsName :=
  psNameAppendStr psUnitName "unit"

def psCharName : PsName :=
  psRootName "Char"

def psCharOfNatName : PsName :=
  psNameAppendStr psCharName "ofNat"

def psCharToNatName : PsName :=
  psNameAppendStr psCharName "toNat"

def psStringPushName : PsName :=
  psNameAppendStr psStringName "push"

def psStringSingletonName : PsName :=
  psNameAppendStr psStringName "singleton"

def psStringInternalName : PsName :=
  psNameAppendStr psStringName "Internal"

def psStringLengthName : PsName :=
  psNameAppendStr psStringInternalName "length"

def psStringAppendName : PsName :=
  psNameAppendStr psStringInternalName "append"

def psStringUtf8ByteSizeName : PsName :=
  psNameAppendStr psStringName "utf8ByteSize"

def psStringNextName : PsName :=
  psNameAppendStr psStringInternalName "next"

def psStringGetName : PsName :=
  psNameAppendStr psStringInternalName "get"

def psStringAtEndName : PsName :=
  psNameAppendStr psStringInternalName "atEnd"

def psStringExtractName : PsName :=
  psNameAppendStr psStringInternalName "extract"
