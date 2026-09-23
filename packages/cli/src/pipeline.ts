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
  lowerV061ModuleToLean,
  parseV061Module,
} from '@proofscript/syntax';
import {checkV061SoftwareModule} from '@proofscript/language';
import {lowerCheckedSoftwareModule} from '@proofscript/compiler-ir';
import {compileTypeScript,emitV061TypeScript} from '@proofscript/backend-ts';

export function checkSource(source:string){
  const surface=parseV061Module(source);
  const checked=checkV061SoftwareModule(surface);
  return {
    surface,
    checked,
    lean:lowerV061ModuleToLean(surface),
  };
}

export function compileSource(source:string,fileName:string){
  const checkedResult=checkSource(source);
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

export function baseReport(source:string,declarations:number,featureIds:readonly string[]){
  return {
    source,
    declarations,
    featureIds,
    languageVersion:PROOFSCRIPT_SPEC_VERSION,
    surfaceBaseline:'0.6.1-compiler-ready',
    leanSemantics:LEAN_SEMANTICS_VERSION,
    proofStatus:'software-typechecked-only',
  } as const;
}
