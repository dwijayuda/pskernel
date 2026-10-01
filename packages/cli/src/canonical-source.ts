import {createHash} from 'node:crypto';
import {
  lowerV061ModuleToProofScript,
  type V061Module,
} from '@proofscript/syntax';

export interface CanonicalSourceIdentity {
  readonly canonicalSource:string;
  readonly canonicalSourceHash:string;
}

function normalizeCanonicalSurface(
  surface:V061Module,
):V061Module {
  return {
    ...surface,
    declarations:surface.declarations.map((declaration)=>{
      if(declaration.kind!=='const'&&declaration.kind!=='function'){
        return declaration;
      }
      // ProofScript's const/function spellings are surface aliases for
      // ordinary definitions. Lean prints both as `def`, so retaining the
      // alias here would make semantic identity depend on source syntax.
      return {...declaration,kind:'def' as const};
    }),
  };
}

export function canonicalSourceIdentity(
  surface:V061Module,
):CanonicalSourceIdentity {
  const canonicalSource=lowerV061ModuleToProofScript(
    normalizeCanonicalSurface(surface),
  );
  const digest=createHash('sha256')
    .update(canonicalSource,'utf8')
    .digest('hex');
  return {
    canonicalSource,
    canonicalSourceHash:'sha256:'+digest,
  };
}
