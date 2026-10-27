import Ps.Foundation.Name

def pilotSeed : PsName := PsName.anonymous

def pilotApply (fn : PsName -> Nat) (name : PsName) : Nat :=
  fn name

def pilotDepth (name : PsName) : Nat :=
  pilotApply psNameDepth name

def pilotDescribe (name : PsName) : String :=
  String.Internal.append (psNameToString name) "!"

def pilotRecursiveDescribe (name : PsName) : String :=
  match name with
  | PsName.anonymous => "root"
  | PsName.str parent value =>
      String.Internal.append
        (String.Internal.append (pilotRecursiveDescribe parent) "/")
        (psNameToString (psNameAppendStr PsName.anonymous value))
  | PsName.num parent value =>
      String.Internal.append
        (String.Internal.append (pilotRecursiveDescribe parent) "/")
        (psNameToString (psNameAppendNum PsName.anonymous value))

def pilotSame (left right : PsName) : Bool :=
  psNameEq left right
