/**
 * TRANSITIONAL LEGACY SOFTWARE PIPELINE.
 *
 * New foundational work must target verified-pipeline.ts:
 * source -> Lean-compatible elaboration -> checked core -> erasure -> IR.
 * Do not add proof/type-theory semantics here.
 */
import {
  LEAN_SEMANTICS_VERSION,
  PROOFSCRIPT_SPEC_VERSION,
  createDefaultSourceFrontendRegistry,
  lowerV061ModuleToLean,
  sourceKindFromFileName,
} from '@proofscript/syntax';
import {checkV061SoftwareModule} from '@proofscript/language';
import {lowerCheckedSoftwareModule} from '@proofscript/compiler-ir';
import {compileTypeScript,emitV061TypeScript} from '@proofscript/backend-ts';
import {canonicalSourceIdentity} from './canonical-source.js';

const sourceFrontends=createDefaultSourceFrontendRegistry();

export function checkSource(
  source:string,
  sourceFileName='input.ps',
){
  const surface=sourceFrontends.forFile(sourceFileName).parse(source);
  if((surface.imports?.length??0)>0){
    throw new Error(
      'PS_PROJECT_IMPORTS_REQUIRE_VERIFIED: imports currently require --verified',
    );
  }
  const canonical=canonicalSourceIdentity(surface);
  const checked=checkV061SoftwareModule(surface);
  return {
    surface,
    ...canonical,
    checked,
    lean:lowerV061ModuleToLean(surface),
  };
}

export function compileSource(
  source:string,
  fileName:string,
  sourceFileName='input.ps',
){
  const checkedResult=checkSource(source,sourceFileName);
  const executableIr=lowerCheckedSoftwareModule(checkedResult.checked);
  const typeScript=emitV061TypeScript(executableIr);
  const emitted=compileTypeScript(typeScript,fileName);
  return {
    ...checkedResult,
    executableIr,
    typeScript,
    emitted,
  };
}

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
    proofStatus:'software-typechecked-only',
    sourceKind:sourceKindFromFileName(sourcePath),
    canonicalSourceHash,
  } as const;
}
