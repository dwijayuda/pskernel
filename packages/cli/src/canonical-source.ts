import {createHash} from 'node:crypto';
import {
  lowerV061ModuleToProofScript,
  type V061Module,
} from '@proofscript/syntax';

export interface CanonicalSourceIdentity {
  readonly canonicalSource:string;
  readonly canonicalSourceHash:string;
}

export function canonicalSourceIdentity(
  surface:V061Module,
):CanonicalSourceIdentity {
  const canonicalSource=lowerV061ModuleToProofScript(surface);
  const digest=createHash('sha256')
    .update(canonicalSource,'utf8')
    .digest('hex');
  return {
    canonicalSource,
    canonicalSourceHash:'sha256:'+digest,
  };
}
