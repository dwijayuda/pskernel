import type {V061Module} from './ast.js';
import {lowerV061ModuleToLean} from './lean-lowering.js';
import {lowerV061ModuleToProofScript} from './proofscript-lowering.js';

export type TranslationTarget='ps'|'lean';

export interface TranslationTargetPrinter {
  readonly target:TranslationTarget;
  readonly extension:'.ps'|'.lean';
  print(module:V061Module):string;
}

export class TranslationTargetPrinterRegistry {
  private readonly printers=
    new Map<TranslationTarget,TranslationTargetPrinter>();

  register(printer:TranslationTargetPrinter):this {
    if(this.printers.has(printer.target)){
      throw new Error(
        "PS_TRANSLATION_TARGET_DUPLICATE: printer already registered for '"+
        printer.target+"'",
      );
    }
    this.printers.set(printer.target,printer);
    return this;
  }

  get(
    target:TranslationTarget,
  ):TranslationTargetPrinter|undefined {
    return this.printers.get(target);
  }

  require(target:TranslationTarget):TranslationTargetPrinter {
    const printer=this.get(target);
    if(printer===undefined){
      throw new Error(
        "PS_TRANSLATION_TARGET_UNAVAILABLE: no printer registered for '"+
        target+"'",
      );
    }
    return printer;
  }
}

export const proofScriptTranslationTarget:TranslationTargetPrinter={
  target:'ps',
  extension:'.ps',
  print:lowerV061ModuleToProofScript,
};

export const leanTranslationTarget:TranslationTargetPrinter={
  target:'lean',
  extension:'.lean',
  print:lowerV061ModuleToLean,
};

export function createDefaultTranslationTargetPrinterRegistry():
TranslationTargetPrinterRegistry {
  return new TranslationTargetPrinterRegistry()
    .register(proofScriptTranslationTarget)
    .register(leanTranslationTarget);
}
