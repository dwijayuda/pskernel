import {
  SyntaxError as ProofScriptSyntaxError,
  createDefaultSourceFrontendRegistry,
  lowerV061ModuleToLean,
  type V061Declaration,
  type V061Module,
} from '@proofscript/syntax';
import {
  elaborateV061Declarations,
  elaborateV061ValueHeader,
  type V061ElaborationSeed,
} from '@proofscript/elab';
import {
  Environment,
  constant,
  exprToString,
  levelToString,
  normalizesToZero,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {
  DeclarationKernelStatus,
  DeclarationStatus,
  DocumentAnalysis,
  ProofGoal,
  ServiceDiagnostic,
  TextDocumentSnapshot,
} from './model.js';
import {rangeFromOffsets} from './positions.js';

export interface AnalysisOptions {
  readonly environmentFactory?:()=>Environment;
  readonly environment?:Environment;
  readonly seed?:V061ElaborationSeed;
  readonly project?:{
    readonly entryModule:string;
    readonly moduleOrder:readonly string[];
  };
}

const sourceFrontends=createDefaultSourceFrontendRegistry();

function displayCoreExpr(
  expr:Expr,
  ids:ReadonlyMap<string,string>,
):string {
  if(expr.kind==='sort'){
    return normalizesToZero(expr.level)
      ?'Prop'
      :'Sort '+levelToString(expr.level);
  }
  let rendered=exprToString(expr);
  const replacements=[...ids.entries()]
    .sort((a,b)=>b[0].length-a[0].length);
  for(const [id,name] of replacements){
    rendered=rendered.split(id).join(name);
  }
  return rendered;
}

function initialTheoremGoal(
  declaration:V061Declaration,
  environment:Environment,
  seed:V061ElaborationSeed,
):ProofGoal|undefined {
  if(declaration.kind!=='theorem')return undefined;
  try{
    const structures=new Map(
      seed.structures.map((item)=>[nameToString(item.name),item]),
    );
    const classes=new Set(
      seed.classes.map((item)=>nameToString(item.name)),
    );
    const globalInstances=seed.instances
      .slice()
      .reverse()
      .map((item)=>constant(item.name));
    const header=elaborateV061ValueHeader(
      declaration,
      environment,
      structures,
      classes,
      globalInstances,
    );
    const ids=new Map(
      header.parameters.map((parameter)=>[
        parameter.id,
        parameter.sourceName,
      ] as const),
    );
    return {
      locals:header.parameters.map((parameter)=>({
        name:parameter.sourceName,
        type:displayCoreExpr(parameter.type,ids),
        binderInfo:parameter.binderInfo,
      })),
      target:displayCoreExpr(header.resultType,ids),
    };
  }catch{
    return undefined;
  }
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
    module=sourceFrontends.require(snapshot.sourceKind).parse(snapshot.text);
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
  let environment=(
    options.environment
    ??options.environmentFactory?.()
    ??new Environment()
  ).clone();
  let seed:V061ElaborationSeed=options.seed??{
    structures:[],
    classes:[],
    instances:[],
  };
  const declarations:DeclarationStatus[]=[];
  const diagnostics:ServiceDiagnostic[]=[];

  for(const declaration of module.declarations){
    const initialGoal=initialTheoremGoal(declaration,environment,seed);
    let kernel:DeclarationKernelStatus='not-run';
    let message:string|undefined;
    try{
      const checked=elaborateV061Declarations(
        singleDeclarationModule(module,declaration),
        environment,
        seed,
      );
      environment=checked.environment;
      seed={
        structures:[...seed.structures,...checked.structures],
        classes:[...seed.classes,...checked.classes],
        instances:[...seed.instances,...checked.instances],
      };
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
      ...(initialGoal===undefined?{}:{initialGoal}),
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
    ...(options.project===undefined?{}:{project:options.project}),
  };
}
