import Ps.Project.ModuleGraph
import Ps.Project.ModuleInterface
import Ps.Foundation.List

structure PsModuleDependencyInterface where
  name : PsName
  interfaceFingerprint : PsModuleInterfaceFingerprint

structure PsModuleQueryRecord where
  name : PsName
  sourceKey : String
  interfaceFingerprint : PsModuleInterfaceFingerprint
  dependencyInterfaces : List PsModuleDependencyInterface

structure PsModuleQueryInput where
  name : PsName
  imports : List PsName
  sourceKey : String

structure PsQuerySnapshot where
  records : List PsModuleQueryRecord

inductive PsQueryInvalidation where
  | missingPrevious
  | sourceChanged
  | importsChanged
  | dependencyUnavailable (name : PsName)
  | dependencyInterfaceChanged (name : PsName)

inductive PsQueryDecision where
  | green (record : PsModuleQueryRecord)
  | red (reason : PsQueryInvalidation)

inductive PsQueryGraphError where
  | duplicateRecord (name : PsName)
  | missingDependencyInterface
      (owner : PsName)
      (dependency : PsName)

def psQuerySnapshotEmpty : PsQuerySnapshot :=
  PsQuerySnapshot.mk List.nil

def psFindModuleQueryRecord
    (target : PsName)
    (records : List PsModuleQueryRecord) :
    Option PsModuleQueryRecord :=
  match records with
  | List.nil =>
      Option.none
  | List.cons record rest =>
      if psNameEq record.name target then
        Option.some record
      else
        psFindModuleQueryRecord target rest

def psQuerySnapshotFind
    (snapshot : PsQuerySnapshot)
    (target : PsName) :
    Option PsModuleQueryRecord :=
  psFindModuleQueryRecord target snapshot.records

def psQuerySnapshotInsert
    (snapshot : PsQuerySnapshot)
    (record : PsModuleQueryRecord) :
    Except PsQueryGraphError PsQuerySnapshot :=
  match psQuerySnapshotFind snapshot record.name with
  | Option.some _ =>
      Except.error
        (PsQueryGraphError.duplicateRecord record.name)
  | Option.none =>
      Except.ok (PsQuerySnapshot.mk (psListAppend snapshot.records (List.cons record List.nil)))

def psQueryDependencyInvalidation
    (current : PsQuerySnapshot)
    (imports : List PsName) :
    List PsModuleDependencyInterface -> Option PsQueryInvalidation :=
  match imports with
  | List.nil =>
      fun (previousDependencies : List PsModuleDependencyInterface) =>
        match previousDependencies with
        | List.nil => Option.none
        | List.cons _ _ => Option.some PsQueryInvalidation.importsChanged
  | List.cons dependency restImports =>
      let smaller := psQueryDependencyInvalidation current restImports;
      fun (previousDependencies : List PsModuleDependencyInterface) =>
        match previousDependencies with
        | List.nil => Option.some PsQueryInvalidation.importsChanged
        | List.cons previous restPrevious =>
            if psNameEq dependency previous.name then
              match psQuerySnapshotFind current dependency with
              | Option.none => Option.some (PsQueryInvalidation.dependencyUnavailable dependency)
              | Option.some currentDependency =>
                  if psModuleInterfaceFingerprintEq currentDependency.interfaceFingerprint previous.interfaceFingerprint then
                    smaller restPrevious
                  else Option.some (PsQueryInvalidation.dependencyInterfaceChanged dependency)
            else Option.some PsQueryInvalidation.importsChanged

def psQueryEvaluateModule
    (previous : PsQuerySnapshot)
    (current : PsQuerySnapshot)
    (input : PsModuleQueryInput) :
    PsQueryDecision :=
  match psQuerySnapshotFind previous input.name with
  | Option.none =>
      PsQueryDecision.red
        PsQueryInvalidation.missingPrevious
  | Option.some previousRecord =>
      if
          psStringEq
            previousRecord.sourceKey
            input.sourceKey then
        match
            psQueryDependencyInvalidation
              current
              input.imports
              previousRecord.dependencyInterfaces with
        | Option.none =>
            PsQueryDecision.green previousRecord
        | Option.some reason =>
            PsQueryDecision.red reason
      else
        PsQueryDecision.red
          PsQueryInvalidation.sourceChanged

def psQueryCaptureDependencyInterfaces
    (owner : PsName)
    (current : PsQuerySnapshot)
    (imports : List PsName) :
    Except
      PsQueryGraphError
      (List PsModuleDependencyInterface) :=
  match imports with
  | List.nil =>
      Except.ok List.nil
  | List.cons dependency rest =>
      match psQuerySnapshotFind current dependency with
      | Option.none =>
          Except.error
            (PsQueryGraphError.missingDependencyInterface
              owner
              dependency)
      | Option.some dependencyRecord =>
          match
              psQueryCaptureDependencyInterfaces
                owner
                current
                rest with
          | Except.error error =>
              Except.error error
          | Except.ok dependencyInterfaces =>
              Except.ok
                (List.cons
                  (PsModuleDependencyInterface.mk dependency dependencyRecord.interfaceFingerprint)
                  dependencyInterfaces)

def psQueryCommitRebuilt
    (current : PsQuerySnapshot)
    (input : PsModuleQueryInput)
    (interfaceFingerprint : PsModuleInterfaceFingerprint) :
    Except PsQueryGraphError PsQuerySnapshot :=
  match
      psQueryCaptureDependencyInterfaces
        input.name
        current
        input.imports with
  | Except.error error =>
      Except.error error
  | Except.ok dependencyInterfaces =>
      psQuerySnapshotInsert
        current
        (PsModuleQueryRecord.mk input.name input.sourceKey interfaceFingerprint dependencyInterfaces)

def psQueryCommitReused
    (current : PsQuerySnapshot)
    (record : PsModuleQueryRecord) :
    Except PsQueryGraphError PsQuerySnapshot :=
  psQuerySnapshotInsert current record

def psQueryInterfaceChanged
    (previous : PsQuerySnapshot)
    (name : PsName)
    (interfaceFingerprint : PsModuleInterfaceFingerprint) :
    Bool :=
  match psQuerySnapshotFind previous name with
  | Option.none =>
      true
  | Option.some previousRecord =>
      if
          psModuleInterfaceFingerprintEq
            previousRecord.interfaceFingerprint
            interfaceFingerprint then
        false
      else
        true
