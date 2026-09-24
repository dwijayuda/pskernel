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
