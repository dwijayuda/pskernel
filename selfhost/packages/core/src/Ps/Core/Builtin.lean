import Ps.Foundation.Name

def psRootName (value : String) : PsName :=
  PsName.str PsName.anonymous value

def psNatName : PsName :=
  psRootName "Nat"

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
