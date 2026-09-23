import {
  SyntaxError as ProofScriptSyntaxError,
  lowerV061ModuleToLean,
  parseV061Module,
  type V061Declaration,
  type V061Module,
} from '@proofscript/syntax';
import {elaborateV061Declarations} from '@proofscript/elab';
import {Environment} from 'lean-ts-kernel';
import type {
  DeclarationKernelStatus,
  DeclarationStatus,
  DocumentAnalysis,
  ServiceDiagnostic,
  TextDocumentSnapshot,
} from './model.js';
import {rangeFromOffsets} from './positions.js';

export interface AnalysisOptions {
  readonly environmentFactory?:()=>Environment;
}

function declarationNameOffset(
  text:string,
  declaration:V061Declaration,
):number {
  const start=declaration.span.start.offset;
  const end=declaration.span.end.offset;
  const slice=text.slice(start,end);
  const index=slice.indexOf(declaration.name);
  return index<0?start:start+index;
}

function classifyElaborationError(message:string):DeclarationKernelStatus {
  if(
    /PS_ELAB_.*UNSUPPORTED/.test(message)
    ||message.includes('PS_ELAB_UNKNOWN_NAME')
    ||message.includes('PS_ELAB_UNKNOWN_TYPE')
    ||message.includes('PS_ELAB_UNSOLVED_METAVARS')
  )return 'unsupported';
  return 'rejected';
}

function diagnosticForDeclaration(
  snapshot:TextDocumentSnapshot,
  declaration:V061Declaration,
  status:DeclarationKernelStatus,
  message:string,
):ServiceDiagnostic {
  return {
    range:rangeFromOffsets(
      snapshot.text,
      declaration.span.start.offset,
      declaration.span.end.offset,
    ),
    severity:status==='rejected'?1:2,
    code:status==='rejected'?'PS_KERNEL_REJECTED':'PS_KERNEL_UNSUPPORTED',
    source:'proofscript',
    phase:status==='rejected'?'kernel':'elaboration',
    message,
  };
}

function singleDeclarationModule(
  module:V061Module,
  declaration:V061Declaration,
):V061Module {
  return {...module,declarations:[declaration]};
}

export function analyzeDocument(
  snapshot:TextDocumentSnapshot,
  options:AnalysisOptions={},
):DocumentAnalysis {
  let module:V061Module;
  try{
    module=parseV061Module(snapshot.text);
  }catch(error){
    if(error instanceof ProofScriptSyntaxError){
      return {
        ...snapshot,
        frontend:'rejected',
        kernel:'not-run',
        declarations:[],
        diagnostics:[{
          range:rangeFromOffsets(
            snapshot.text,
            error.span.start.offset,
            error.span.end.offset,
          ),
          severity:1,
          code:'PS_PARSE_ERROR',
          source:'proofscript',
          phase:'parser',
          message:error.message,
        }],
      };
    }
    throw error;
  }

  const canonicalLean=lowerV061ModuleToLean(module);
  const environment=options.environmentFactory?.()??new Environment();
  const declarations:DeclarationStatus[]=[];
  const diagnostics:ServiceDiagnostic[]=[];

  for(const declaration of module.declarations){
    let kernel:DeclarationKernelStatus='not-run';
    let message:string|undefined;
    try{
      elaborateV061Declarations(
        singleDeclarationModule(module,declaration),
        environment,
      );
      kernel='verified';
    }catch(error){
      message=error instanceof Error?error.message:String(error);
      kernel=classifyElaborationError(message);
      diagnostics.push(
        diagnosticForDeclaration(snapshot,declaration,kernel,message),
      );
    }

    const nameOffset=declarationNameOffset(snapshot.text,declaration);
    const range=rangeFromOffsets(
      snapshot.text,
      declaration.span.start.offset,
      declaration.span.end.offset,
    );
    declarations.push({
      name:declaration.name,
      kind:declaration.kind,
      range,
      selectionRange:rangeFromOffsets(
        snapshot.text,
        nameOffset,
        nameOffset+declaration.name.length,
      ),
      kernel,
      ...(message===undefined?{}:{message}),
      canonicalLean:lowerV061ModuleToLean(
        singleDeclarationModule(module,declaration),
      ).trim(),
    });
  }

  const states=declarations.map((item)=>item.kernel);
  const kernel=
    states.length===0?'not-run':
    states.every((state)=>state==='verified')?'verified':
    states.some((state)=>state==='rejected')?'rejected':
    states.some((state)=>state==='verified')?'partial':
    'unsupported';

  return {
    ...snapshot,
    frontend:'parsed',
    kernel,
    diagnostics,
    declarations,
    canonicalLean,
  };
}
