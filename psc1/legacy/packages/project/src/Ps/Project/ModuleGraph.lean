import Ps.Foundation.Name

structure PsModuleNode where
  name : PsName
  imports : List PsName

inductive PsProjectError where
  | duplicateModule (name : PsName)
  | missingImport (owner : PsName) (dependency : PsName)
  | dependencyCycle

structure PsBuildPlan where
  order : List PsName

def psNameListContains (names : List PsName) (target : PsName) : Bool :=
  match names with
  | [] => false
  | name :: rest =>
      if psNameEq name target then
        true
      else
        psNameListContains rest target

def psFindModuleInList (target : PsName) : List PsModuleNode -> Option PsModuleNode
  | [] => none
  | node :: rest =>
      if psNameEq node.name target then
        some node
      else
        psFindModuleInList target rest

def psValidateUniqueModules (seen : List PsName) : List PsModuleNode -> Except PsProjectError Unit
  | [] => Except.ok ()
  | node :: rest =>
      if psNameListContains seen node.name then
        Except.error (PsProjectError.duplicateModule node.name)
      else
        psValidateUniqueModules (node.name :: seen) rest

def psValidateImportList
    (allNodes : List PsModuleNode)
    (owner : PsName) : List PsName -> Except PsProjectError Unit
  | [] => Except.ok ()
  | dependency :: rest =>
      match psFindModuleInList dependency allNodes with
      | none => Except.error (PsProjectError.missingImport owner dependency)
      | some _ => psValidateImportList allNodes owner rest

def psValidateImports
    (allNodes : List PsModuleNode) : List PsModuleNode -> Except PsProjectError Unit
  | [] => Except.ok ()
  | node :: rest =>
      match psValidateImportList allNodes node.name node.imports with
      | Except.error error => Except.error error
      | Except.ok _ => psValidateImports allNodes rest

def psImportsReady (ordered : List PsName) : List PsName -> Bool
  | [] => true
  | dependency :: rest =>
      psNameListContains ordered dependency && psImportsReady ordered rest

def psSelectReadyModule (ordered : List PsName) : List PsModuleNode -> Option PsModuleNode
  | [] => none
  | node :: rest =>
      if psImportsReady ordered node.imports then
        some node
      else
        psSelectReadyModule ordered rest

def psRemoveModule (target : PsName) : List PsModuleNode -> List PsModuleNode
  | [] => []
  | node :: rest =>
      if psNameEq node.name target then
        rest
      else
        node :: psRemoveModule target rest

def psBuildPlanWithFuel
    (allNodes : List PsModuleNode)
    (remaining : List PsModuleNode)
    (ordered : List PsName) : Nat -> Except PsProjectError PsBuildPlan
  | 0 =>
      match remaining with
      | [] => Except.ok { order := ordered.reverse }
      | _ => Except.error PsProjectError.dependencyCycle
  | fuel + 1 =>
      match remaining with
      | [] => Except.ok { order := ordered.reverse }
      | _ =>
          match psSelectReadyModule ordered remaining with
          | none => Except.error PsProjectError.dependencyCycle
          | some node =>
              psBuildPlanWithFuel
                allNodes
                (psRemoveModule node.name remaining)
                (node.name :: ordered)
                fuel

def psCreateBuildPlan (nodes : List PsModuleNode) : Except PsProjectError PsBuildPlan :=
  match psValidateUniqueModules [] nodes with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psValidateImports nodes nodes with
      | Except.error error => Except.error error
      | Except.ok _ => psBuildPlanWithFuel nodes nodes [] nodes.length
