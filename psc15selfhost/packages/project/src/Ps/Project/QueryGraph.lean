import Ps.Project.ModuleGraph
import Ps.Foundation.List

structure PsModuleDependencyInterface where
  name : PsName
  interfaceKey : String

structure PsModuleQueryRecord where
  name : PsName
  sourceKey : String
  interfaceKey : String
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
  {
    records := List.nil
  }

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
      Except.ok {
        records :=
          psListAppend
            snapshot.records
            (List.cons record List.nil)
      }

def psQueryDependencyInvalidation
    (current : PsQuerySnapshot)
    (imports : List PsName)
    (previousDependencies :
      List PsModuleDependencyInterface) :
    Option PsQueryInvalidation :=
  match imports with
  | List.nil =>
      match previousDependencies with
      | List.nil =>
          Option.none
      | List.cons _ _ =>
          Option.some PsQueryInvalidation.importsChanged
  | List.cons dependency restImports =>
      match previousDependencies with
      | List.nil =>
          Option.some PsQueryInvalidation.importsChanged
      | List.cons previous restPrevious =>
          if psNameEq dependency previous.name then
            match psQuerySnapshotFind current dependency with
            | Option.none =>
                Option.some
                  (PsQueryInvalidation.dependencyUnavailable
                    dependency)
            | Option.some currentDependency =>
                if
                    psStringEq
                      currentDependency.interfaceKey
                      previous.interfaceKey then
                  psQueryDependencyInvalidation
                    current
                    restImports
                    restPrevious
                else
                  Option.some
                    (PsQueryInvalidation.dependencyInterfaceChanged
                      dependency)
          else
            Option.some PsQueryInvalidation.importsChanged

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
                  {
                    name := dependency
                    interfaceKey :=
                      dependencyRecord.interfaceKey
                  }
                  dependencyInterfaces)

def psQueryCommitRebuilt
    (current : PsQuerySnapshot)
    (input : PsModuleQueryInput)
    (interfaceKey : String) :
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
        {
          name := input.name
          sourceKey := input.sourceKey
          interfaceKey := interfaceKey
          dependencyInterfaces := dependencyInterfaces
        }

def psQueryCommitReused
    (current : PsQuerySnapshot)
    (record : PsModuleQueryRecord) :
    Except PsQueryGraphError PsQuerySnapshot :=
  psQuerySnapshotInsert current record

def psQueryInterfaceChanged
    (previous : PsQuerySnapshot)
    (name : PsName)
    (interfaceKey : String) :
    Bool :=
  match psQuerySnapshotFind previous name with
  | Option.none =>
      true
  | Option.some previousRecord =>
      if
          psStringEq
            previousRecord.interfaceKey
            interfaceKey then
        false
      else
        true
