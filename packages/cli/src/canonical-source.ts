import {createHash} from 'node:crypto';
import {
  lowerV061ModuleToProofScript,
  type V061Declaration,
  type V061Module,
} from '@proofscript/syntax';

export interface CanonicalSourceIdentity {
  readonly canonicalSource:string;
  readonly canonicalSourceHash:string;
}

function normalizeDeclarationAlias(
  declaration:V061Declaration,
):V061Declaration {
  if(
    declaration.kind==='const'
    ||declaration.kind==='function'
  ){
    return {...declaration,kind:'def'};
  }
  return declaration;
}

export function canonicalSourceIdentity(
  surface:V061Module,
):CanonicalSourceIdentity {
  const canonicalSurface:V061Module={
    ...surface,
    declarations:surface.declarations.map(normalizeDeclarationAlias),
  };
  const canonicalSource=lowerV061ModuleToProofScript(canonicalSurface);
  const digest=createHash('sha256')
    .update(canonicalSource,'utf8')
    .digest('hex');
  return {
    canonicalSource,
    canonicalSourceHash:'sha256:'+digest,
  };
}
