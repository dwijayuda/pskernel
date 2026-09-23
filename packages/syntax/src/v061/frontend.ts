import type {V061Module} from './ast.js';
import {parseV061Module} from './declaration-parser.js';
import {lowerV061ModuleToProofScript} from './proofscript-lowering.js';

export type SourceKind='proofscript'|'lean-subset';

export interface SourceFrontend {
  readonly kind:SourceKind;
  parse(source:string):V061Module;
  print(module:V061Module):string;
}

export function sourceKindFromFileName(fileName:string):SourceKind {
  const normalized=fileName.toLowerCase();
  if(normalized.endsWith('.ps'))return 'proofscript';
  if(normalized.endsWith('.lean'))return 'lean-subset';
  throw new Error(
    "PS_FRONTEND_SOURCE_KIND: unsupported source extension for '"+fileName+"'",
  );
}

export class SourceFrontendRegistry {
  private readonly frontends=new Map<SourceKind,SourceFrontend>();

  register(frontend:SourceFrontend):this {
    if(this.frontends.has(frontend.kind)){
      throw new Error(
        "PS_FRONTEND_DUPLICATE: frontend already registered for '"+frontend.kind+"'",
      );
    }
    this.frontends.set(frontend.kind,frontend);
    return this;
  }

  get(kind:SourceKind):SourceFrontend|undefined {
    return this.frontends.get(kind);
  }

  require(kind:SourceKind):SourceFrontend {
    const frontend=this.get(kind);
    if(frontend===undefined){
      throw new Error(
        "PS_FRONTEND_UNAVAILABLE: no frontend registered for '"+kind+"'",
      );
    }
    return frontend;
  }

  forFile(fileName:string):SourceFrontend {
    return this.require(sourceKindFromFileName(fileName));
  }
}

export const proofScriptSourceFrontend:SourceFrontend={
  kind:'proofscript',
  parse:parseV061Module,
  print:lowerV061ModuleToProofScript,
};

export function createDefaultSourceFrontendRegistry():SourceFrontendRegistry {
  return new SourceFrontendRegistry()
    .register(proofScriptSourceFrontend);
}
