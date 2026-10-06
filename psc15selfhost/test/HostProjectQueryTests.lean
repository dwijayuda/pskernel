import Ps.Host.ProjectQuery

def psHostProjectQueryFixtureEntry : String :=
  "test/fixtures/project-query/B.lean"

def psHostProjectQueryCanonical
    (declarations : List PsDeclaration) :
    Option String :=
  match psEncodeCheckedAdmissionsCanonical declarations with
  | Except.error _ =>
      Option.none
  | Except.ok encoded =>
      Option.some encoded

def psTestHostProjectQueryColdWarm : IO Bool := do
  let cold ←
    psHostLoadProjectIncremental
      psBootstrapPreludeEnvironment
      psHostProjectQueryFixtureEntry
      psHostProjectSnapshotEmpty
  let warm ←
    psHostLoadProjectIncremental
      psBootstrapPreludeEnvironment
      psHostProjectQueryFixtureEntry
      cold.snapshot
  let coldHasA :=
    psHostListContainsString
      cold.rebuiltPaths
      (psHostJoinPath "test/fixtures/project-query" "A.lean")
  let coldHasB :=
    psHostListContainsString
      cold.rebuiltPaths
      "test/fixtures/project-query/B.lean"
  let warmHasA :=
    psHostListContainsString
      warm.reusedPaths
      (psHostJoinPath "test/fixtures/project-query" "A.lean")
  let warmHasB :=
    psHostListContainsString
      warm.reusedPaths
      "test/fixtures/project-query/B.lean"
  let sameDeclarations :=
    match
        psHostProjectQueryCanonical cold.elaborated.declarations,
        psHostProjectQueryCanonical warm.elaborated.declarations with
    | Option.some coldKey, Option.some warmKey =>
        psStringEq coldKey warmKey
    | _, _ =>
        false
  pure
    (coldHasA &&
      coldHasB &&
      warmHasA &&
      warmHasB &&
      sameDeclarations)

def main : IO Unit := do
  let passed ← psTestHostProjectQueryColdWarm
  if passed then
    IO.println
      "PSC1_HOST_PROJECT_QUERY_TESTS: PASS"
  else
    throw
      (IO.userError
        "PSC1_HOST_PROJECT_QUERY_TESTS: FAIL")
