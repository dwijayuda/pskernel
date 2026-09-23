import type {CheckedCoreModule} from '@proofscript/checked-core';
import {eraseCheckedCoreModule} from '@proofscript/erasure';
import {validateVerifiedIrModule} from '@proofscript/compiler-ir/verified';
import {
  compileTypeScript,
  emitVerifiedTypeScript,
  type TypeScriptCompileResult,
} from '@proofscript/backend-ts/verified';

export interface VerifiedCompileResult {
  readonly checkedCore:CheckedCoreModule;
  readonly ir:ReturnType<typeof eraseCheckedCoreModule>;
  readonly typeScript:string;
  readonly emitted:TypeScriptCompileResult;
}

export function compileCheckedCore(
  checkedCore:CheckedCoreModule,
  fileName='module.ts',
):VerifiedCompileResult {
  const ir=eraseCheckedCoreModule(checkedCore);
  validateVerifiedIrModule(ir);
  const typeScript=emitVerifiedTypeScript(ir);
  const emitted=compileTypeScript(typeScript,fileName);
  return {checkedCore,ir,typeScript,emitted};
}
