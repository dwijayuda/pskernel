import type {OverlayDecision} from './parser-core.js';
import type {SourceSpan,Token} from './source.js';
import {isAdjacentCallOpen} from './ownership.js';

export interface DCallOpenNode {
  readonly kind:'d-call-open';
  readonly feature:'D-CALL';
  readonly open:Token;
  readonly span:SourceSpan;
}

/**
 * Lexical D-CALL ownership decision for an opening parenthesis. This does not
 * claim that the preceding token sequence is a well-formed callable term; the
 * term parser owns that contextual check. It only captures the v0.7 adjacency
 * discriminator that decides whether ProofScript may attempt D-CALL parsing.
 */
export function decideDCallOpen(open:Token):OverlayDecision<DCallOpenNode>{
  if(!isAdjacentCallOpen(open))return {kind:'defer'};
  return {
    kind:'proofscript',
    feature:'D-CALL',
    node:{kind:'d-call-open',feature:'D-CALL',open,span:open.span},
  };
}
