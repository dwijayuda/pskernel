import {
  LEAN_SEMANTICS_VERSION,
  PROOFSCRIPT_SPEC_VERSION,
  sourceKindFromFileName,
} from '@proofscript/syntax';

export function baseReport(
  sourcePath:string,
  declarations:number,
  featureIds:readonly string[],
  canonicalSourceHash:string,
){
  return {
    source:sourcePath,
    declarations,
    featureIds,
    languageVersion:PROOFSCRIPT_SPEC_VERSION,
    surfaceBaseline:'0.6.1-compiler-ready',
    leanSemantics:LEAN_SEMANTICS_VERSION,
    sourceKind:sourceKindFromFileName(sourcePath),
    canonicalSourceHash,
  } as const;
}
