import type {ProofScriptFeatureId} from './features.js';
import type {Token} from './source.js';

export function hasTriviaBefore(token:Token):boolean { return token.leadingTrivia.length>0; }
export function isAdjacentCallOpen(token:Token):boolean { return token.kind==='symbol'&&token.text==='('&&token.adjacentToPrevious; }

export interface SurfaceOwnership {
  readonly owner:'proofscript'|'defer';
  readonly feature?:ProofScriptFeatureId;
}

/**
 * Lexical ownership precheck only. Grammar/context still decides whether the
 * preceding parsed term is a callable D-CALL head.
 */
export function classifyCallOpen(token:Token):SurfaceOwnership {
  return isAdjacentCallOpen(token)
    ? {owner:'proofscript',feature:'D-CALL'}
    : {owner:'defer'};
}
