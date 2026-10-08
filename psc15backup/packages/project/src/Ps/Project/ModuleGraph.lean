import Ps.Foundation.Name
import Ps.Foundation.List

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
  | List.nil => false
  | List.cons name rest =>
      if psNameEq name target then true else psNameListContains rest target

def psFindModuleInList (target : PsName) (nodes : List PsModuleNode) : Option PsModuleNode :=
  match nodes with
  | List.nil => Option.none
  | List.cons node rest =>
      if psNameEq node.name target then Option.some node else psFindModuleInList target rest

def psValidateUniqueModulesLoop (nodes : List PsModuleNode) : List PsName -> Except PsProjectError Unit :=
  match nodes with
  | List.nil => fun (_seen : List PsName) => Except.ok Unit.unit
  | List.cons node rest =>
      let smaller := psValidateUniqueModulesLoop rest;
      fun (seen : List PsName) =>
        if psNameListContains seen node.name then Except.error (PsProjectError.duplicateModule node.name)
        else smaller (List.cons node.name seen)

def psValidateUniqueModules (seen : List PsName) (nodes : List PsModuleNode) : Except PsProjectError Unit :=
  psValidateUniqueModulesLoop nodes seen

def psValidateImportList (allNodes : List PsModuleNode) (owner : PsName)
    (imports : List PsName) : Except PsProjectError Unit :=
  match imports with
  | List.nil => Except.ok Unit.unit
  | List.cons dependency rest =>
      match psFindModuleInList dependency allNodes with
      | Option.none => Except.error (PsProjectError.missingImport owner dependency)
      | Option.some _ => psValidateImportList allNodes owner rest

def psValidateImports (allNodes : List PsModuleNode) (nodes : List PsModuleNode) : Except PsProjectError Unit :=
  match nodes with
  | List.nil => Except.ok Unit.unit
  | List.cons node rest =>
      match psValidateImportList allNodes node.name node.imports with
      | Except.error error => Except.error error
      | Except.ok _ => psValidateImports allNodes rest

def psImportsReady (ordered : List PsName) (imports : List PsName) : Bool :=
  match imports with
  | List.nil => true
  | List.cons dependency rest =>
      if psNameListContains ordered dependency then psImportsReady ordered rest else false

def psSelectReadyModule (ordered : List PsName) (nodes : List PsModuleNode) : Option PsModuleNode :=
  match nodes with
  | List.nil => Option.none
  | List.cons node rest =>
      if psImportsReady ordered node.imports then Option.some node else psSelectReadyModule ordered rest

def psRemoveModule (target : PsName) (nodes : List PsModuleNode) : List PsModuleNode :=
  match nodes with
  | List.nil => List.nil
  | List.cons node rest =>
      if psNameEq node.name target then rest else List.cons node (psRemoveModule target rest)

def psBuildPlanLoop (fuel : Nat) : List PsModuleNode -> List PsName -> Except PsProjectError PsBuildPlan :=
  match fuel with
  | Nat.zero =>
      fun (remaining : List PsModuleNode) (ordered : List PsName) =>
        if psListIsEmpty remaining then Except.ok (PsBuildPlan.mk (psListReverse ordered))
        else Except.error PsProjectError.dependencyCycle
  | Nat.succ rest =>
      let smaller := psBuildPlanLoop rest;
      fun (remaining : List PsModuleNode) (ordered : List PsName) =>
        if psListIsEmpty remaining then Except.ok (PsBuildPlan.mk (psListReverse ordered))
        else
          match psSelectReadyModule ordered remaining with
          | Option.none => Except.error PsProjectError.dependencyCycle
          | Option.some node => smaller (psRemoveModule node.name remaining) (List.cons node.name ordered)

def psBuildPlanWithFuel (_allNodes : List PsModuleNode) (remaining : List PsModuleNode)
    (ordered : List PsName) (fuel : Nat) : Except PsProjectError PsBuildPlan :=
  psBuildPlanLoop fuel remaining ordered

def psCreateBuildPlan (nodes : List PsModuleNode) : Except PsProjectError PsBuildPlan :=
  match psValidateUniqueModules List.nil nodes with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psValidateImports nodes nodes with
      | Except.error error => Except.error error
      | Except.ok _ => psBuildPlanWithFuel nodes nodes List.nil (psListLength nodes)
