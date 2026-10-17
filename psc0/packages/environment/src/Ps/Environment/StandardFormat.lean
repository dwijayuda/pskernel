import Ps.Environment.StandardFormatRender

-- The pure document/rendering foundation of Std.Format. ToFormat, Repr and
-- the effectful prettyM API are separate capabilities, not formatting axioms.
def psStandardFormatDeclarations : List PsDeclaration :=
  psStandardFormatDataDeclarations ++ psFormatBasicDeclarations ++
    psFormatTextScanDeclarations ++ psFormatSpaceDeclarations ++
    [psFormatMeasureDeclaration] ++ psFormatWorkDataDeclarations ++
    [psFormatMeasureItemsDeclaration, psFormatMeasureGroupsDeclaration,
     psFormatPushGroupDeclaration] ++ psFormatRenderStateDeclarations ++
    [psFormatRenderItemDeclaration, psFormatRenderStepDeclaration,
     psFormatRenderWorkerDeclaration, psFormatPrettyDeclaration]

def psStandardFormatExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardFormatDeclarations.foldl psPreludeAdd environment
