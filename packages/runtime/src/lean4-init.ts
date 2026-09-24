import {
  constant,
  nameFromDotted,
  nameToString,
  type Name,
} from 'lean-ts-kernel';
import {
  Lean434EvaluationError,
  Lean434Evaluator,
  type Lean434RuntimeValue,
} from './lean4-eval.js';
import type {
  Lean434MetadataInitializer,
  Lean434RuntimeMetadataIndex,
} from './lean4-metadata.js';

export interface Lean434InitializerExecution {
  readonly module:string;
  readonly kind:'builtin'|'regular';
  readonly declaration:string;
  readonly initFunction:string|null;
  readonly storedValue:boolean;
}

export interface Lean434InitializerReport {
  readonly executed:readonly Lean434InitializerExecution[];
  readonly skipped:readonly Lean434InitializerExecution[];
}

function executionOf(
  entry:Lean434MetadataInitializer,
):Lean434InitializerExecution{
  return {
    module:entry.module,
    kind:entry.kind,
    declaration:entry.declaration,
    initFunction:entry.initFunction,
    storedValue:!entry.ioUnit,
  };
}

function entryKey(entry:Lean434MetadataInitializer):string{
  return [
    entry.moduleIndex,
    entry.kind,
    entry.declaration,
    entry.initFunction??'',
  ].join('\u0000');
}

/**
 * Executes Lean module initializer metadata in exported order.
 *
 * This runner is outside the logical TCB. All declaration bodies consumed by
 * it come from a pskernel-admitted Environment; the runner only establishes
 * the executable global state that native Lean would establish at module
 * initialization/import time.
 */
export class Lean434InitializerRunner {
  private readonly executedKeys=new Set<string>();

  constructor(
    readonly evaluator:Lean434Evaluator,
    readonly metadata:Lean434RuntimeMetadataIndex,
  ){}

  runAll():Lean434InitializerReport{
    return this.runEntries(this.metadata.document.initializers);
  }

  runModule(module:string):Lean434InitializerReport{
    return this.runEntries(
      this.metadata.initializersForModule(module),
    );
  }

  private runEntries(
    entries:readonly Lean434MetadataInitializer[],
  ):Lean434InitializerReport{
    const executed:Lean434InitializerExecution[]=[];
    const skipped:Lean434InitializerExecution[]=[];

    for(const entry of entries){
      const execution=executionOf(entry);
      const key=entryKey(entry);
      if(this.executedKeys.has(key)){
        skipped.push(execution);
        continue;
      }
      this.runEntry(entry);
      this.executedKeys.add(key);
      executed.push(execution);
    }

    return {executed,skipped};
  }

  private resolveDeclarationName(name:string,role:string):Name{
    const parsed=nameFromDotted(name);
    if(
      this.evaluator.environment.has(parsed)
      &&nameToString(parsed)===name
    ){
      return parsed;
    }
    for(const info of this.evaluator.environment.entries()){
      if(nameToString(info.name)===name)return info.name;
    }
    throw new Lean434EvaluationError(
      role+" declaration is missing from pskernel environment: '"+
      name+"'",
    );
  }

  private runEntry(entry:Lean434MetadataInitializer):void{
    this.resolveDeclarationName(
      entry.declaration,
      'initializer target',
    );

    const actionName=entry.ioUnit
      ?entry.declaration
      :entry.initFunction;
    if(actionName===null){
      throw new Lean434EvaluationError(
        "initializer '"+entry.declaration+
        "' has no executable action",
      );
    }

    const actionKernelName=this.resolveDeclarationName(
      actionName,
      'initializer action',
    );
    const action=this.evaluator.evaluate(
      constant(actionKernelName),
    );
    const result=this.evaluator.runInitializerAction(action);

    if(!entry.ioUnit){
      this.evaluator.setRuntimeGlobal(
        entry.declaration,
        result.value as Lean434RuntimeValue,
      );
    }
  }
}
