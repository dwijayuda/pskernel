import Ps.Host.DirectBackend

def psRequirePublication (condition : Bool) (caseName : String) : IO Unit := do
  if !condition then
    throw (IO.userError ("PSC1_ARTIFACT_PUBLICATION_REGRESSION_FAILED: " ++ caseName))

def main : IO Unit := do
  let directory ← IO.FS.createTempDir
  try
    let publicJs := directory / "sample.js"
    let publicTypes := directory / "sample.d.ts"
    IO.FS.writeFile publicJs "previous-js"
    IO.FS.writeFile publicTypes "previous-types"
    let stage ← psHostDirectStageDirectory publicJs.toString
    try
      let stagedJs := stage / "module.js"
      let stagedTypes := stage / "module.d.ts"
      let files : List PsHostPublicationFile := [
        { staged := stagedJs, destination := publicJs,
          backup := stage / "previous.js" },
        { staged := stagedTypes, destination := publicTypes,
          backup := stage / "previous.d.ts" }
      ]
      IO.FS.writeFile stagedJs "updated-js"
      IO.FS.writeFile stagedTypes "updated-types"
      let mut caught := false
      try
        psHostPublishPreparedFilesWithFailureAfter files (some 1)
      catch _ =>
        caught := true
      psRequirePublication caught "injected failure rejected"
      psRequirePublication ((← IO.FS.readFile publicJs) == "previous-js")
        "first file rolled back byte-for-byte"
      psRequirePublication ((← IO.FS.readFile publicTypes) == "previous-types")
        "second file rolled back byte-for-byte"
      psRequirePublication (!(← (stage / "previous.js").pathExists))
        "first backup restored"
      psRequirePublication (!(← (stage / "previous.d.ts").pathExists))
        "second backup restored"
      IO.FS.writeFile stagedJs "updated-js"
      IO.FS.writeFile stagedTypes "updated-types"
      psHostPublishPreparedFiles files
      psRequirePublication ((← IO.FS.readFile publicJs) == "updated-js")
        "successful JS install"
      psRequirePublication ((← IO.FS.readFile publicTypes) == "updated-types")
        "successful declaration install"
    finally
      IO.FS.removeDirAll stage
    IO.println "PSC1_ARTIFACT_PUBLICATION_ROLLBACK: PASS"
  finally
    IO.FS.removeDirAll directory
