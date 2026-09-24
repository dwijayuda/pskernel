import Ps.Foundation.Name

def psRootName (value : String) : PsName :=
  PsName.str PsName.anonymous value

def psNatName : PsName :=
  psRootName "Nat"

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
