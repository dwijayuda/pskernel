import Ps.Environment.Basic

-- Pinned RC4 definition statuses, checked against the native environment by
-- PrimitiveAudit. Portable helper identities default to semireducible; actual
-- registered instance definitions receive the instance-command status.
def psStandardReducibility : List (String × PsReducibility) := [
  ("repr", .reducible),
  ("reprArg", .reducible),
  ("reprStr", .reducible),
  ("Int.toNat", .implicitReducible),
  ("Array.get!Internal", .implicitReducible),
  ("List.toArray", .reducible),
  ("Array.getInternal", .implicitReducible),
  ("Array.getD", .reducible),
  ("Array.push", .implicitReducible),
  ("Array.size", .instanceReducible),
  ("Array.emptyWithCapacity", .implicitReducible),
  ("Array.toList", .reducible),
  ("List.get?Internal", .implicitReducible),
  ("List.get", .implicitReducible),
  ("Fin.val", .reducible),
  ("Nat.decLt", .instanceReducible),
  ("Nat.decLe", .instanceReducible),
  ("Nat.pred", .implicitReducible),
  ("Nat.add", .instanceReducible),
  ("Nat.sub", .instanceReducible),
  ("Nat.mul", .instanceReducible),
  ("GetElem?.toGetElem", .instanceReducible),
  ("Except.isOk", .reducible),
  ("List.beq", .implicitReducible),
  ("List.append", .implicitReducible),
  ("List.map", .implicitReducible),
  ("List.length", .instanceReducible),
  ("Option.filter", .implicitReducible),
  ("Option.isNone", .implicitReducible),
  ("Option.isSome", .implicitReducible),
  ("Option.bind", .implicitReducible),
  ("Option.map", .implicitReducible),
  ("Option.getD", .implicitReducible),
  ("dite", .implicitReducible),
  ("ite", .implicitReducible),
  ("DecidableEq", .reducible),
  ("Decidable.isFalse", .reducible),
  ("Decidable.isTrue", .reducible),
  ("Decidable.decide", .implicitReducible),
  ("Bool.Reflects", .reducible),
  ("outParam", .reducible),
  ("Not", .implicitReducible),
  ("Nat.lt", .implicitReducible),
  ("Id", .implicitReducible),
  ("optParam", .reducible)]

def psStandardReducibilityExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := environment.instances.entries.foldl (fun env entry =>
    match entry.value with
    | .constE name _ => psEnvironmentSetReducibility env name .instanceReducible
    | _ => env) environment
  psStandardReducibility.foldl (fun env (text, status) =>
    let name := (text.splitOn ".").foldl psNameAppendStr .anonymous
    psEnvironmentSetReducibility env name status) environment
