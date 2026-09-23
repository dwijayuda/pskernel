import {
  createDefaultSourceFrontendRegistry,
  createDefaultTranslationTargetPrinterRegistry,
  type TranslationTarget,
} from '@proofscript/syntax';
import type {TextDocumentSnapshot} from './model.js';

const frontends=createDefaultSourceFrontendRegistry();
const targets=createDefaultTranslationTargetPrinterRegistry();

export interface DocumentTranslation {
  readonly target:TranslationTarget;
  readonly extension:'.ps'|'.lean';
  readonly text:string;
}

export function translateDocumentSnapshot(
  snapshot:TextDocumentSnapshot,
  target:TranslationTarget,
):DocumentTranslation {
  const surface=frontends.require(snapshot.sourceKind).parse(snapshot.text);
  const printer=targets.require(target);
  return {
    target,
    extension:printer.extension,
    text:printer.print(surface),
  };
}
