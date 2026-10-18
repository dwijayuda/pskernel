import Ps.Compiler.RuntimeOwnership
import Ps.Elab.WellFoundedRuntime

/-!
Executable ownership for total mutual WF components.
All inputs remain the original prepared, kernel-checkable logical graph.
The only allowed substitution is the independently recovered actual functional
body. Numeric private names nominate candidates; they do not authorize code.
-/

private def psCompilerWellFoundedCandidates (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    Except PsElabError (List (PsName × PsName)) := do
  let mut candidates := []
  for declaration in declarations do
    if let .definitionDecl (.num owner 0) _ _ _ := declaration then
      if let some (.definitionDecl _ levels type value) :=
          psCompilerRuntimeUnique declarations owner then
        let opened ← psElabPreDefinitionOpen (psElabWellFoundedRawArity value)
          (psElabContextEmpty environment levels) type value
        let entry := psReduceAppView
          (psWhnfCore psMetaEmpty opened.context.localContext opened.value)
        if let .constE auxiliary _ := entry.head then
          if let .str _ "_mutual" := auxiliary then
            candidates := candidates ++ [(owner, auxiliary)]
  return candidates

def psCompilerWellFoundedRuntimeView (environment : PsEnvironment)
    (declarations runtime : List PsDeclaration) :
    Except PsElabError (List PsDeclaration × List PsName) := do
  let candidates ← psCompilerWellFoundedCandidates environment declarations
  let auxiliaries := candidates.foldl (fun names (_, auxiliary) =>
    if names.any (psNameEq auxiliary) then names else names ++ [auxiliary]) ([] : List PsName)
  let mut implementations : List PsDeclaration := []
  for auxiliary in auxiliaries do
    let some (.definitionDecl _ levels type value) :=
        psCompilerRuntimeUnique declarations auxiliary
      | throw (psElabWellFoundedRuntimeError "missing unique logical auxiliary")
    let restored ← (psCompilerRuntimeRestore 4096 declarations auxiliary value).mapError
      PsElabError.data
    let restoredDeclaration := PsDeclaration.definitionDecl auxiliary levels type restored
    let restoredEnvironment := { environment with
      declarations := restoredDeclaration :: psEnvironmentRemoveName auxiliary environment.declarations
      index := psEnvironmentIndexInsert environment.index restoredDeclaration }
    let names := (candidates.filter fun (_, owner) => psNameEq owner auxiliary).map Prod.fst
    let expected ← psElabWellFoundedRuntimeBodies restoredEnvironment auxiliary names
    for declaration in expected do
      let .definitionDecl privateName expectedLevels expectedType expectedValue := declaration
        | throw (psElabWellFoundedRuntimeError "recovery produced a nondefinition")
      let some (.definitionDecl _ actualLevels actualType actualValue) :=
          psCompilerRuntimeUnique declarations privateName
        | throw (psElabWellFoundedRuntimeError "missing unique ordinary private implementation")
      if !psCompilerRuntimeLevelsEq expectedLevels actualLevels ||
          !psExprAlphaEq expectedType actualType ||
          !psCompilerRuntimeClosed actualType || !psCompilerRuntimeClosed actualValue then
        throw (psElabWellFoundedRuntimeError "private implementation changed its closed type or universes")
      let actualBody ← (psCompilerRuntimeRestore 4096 declarations privateName actualValue).mapError
        PsElabError.data
      let expectedBody ← (psCompilerRuntimeRestore 4096 declarations privateName expectedValue).mapError
        PsElabError.data
      if !psExprAlphaEq actualBody expectedBody then
        throw (psElabWellFoundedRuntimeError "private implementation differs from the checked functional")
      implementations := implementations ++
        [.definitionDecl privateName actualLevels actualType actualValue]
  let result := runtime.filterMap fun declaration =>
    let name := psDeclarationName declaration
    let omitted := auxiliaries.any (fun auxiliary =>
      psNameEq auxiliary name || psCompilerRuntimeHelperOwned auxiliary name) ||
      implementations.any (fun implementation => psNameEq (psDeclarationName implementation) name)
    if omitted then none else
      match declaration with
      | .definitionDecl name levels type _ =>
        match implementations.find? (fun implementation =>
            psNameEq (psDeclarationName implementation) (PsName.num name 0)) with
        | some (.definitionDecl _ _ _ body) => some (.definitionDecl name levels type body)
        | _ => some declaration
      | _ => some declaration
  return (result, auxiliaries)
