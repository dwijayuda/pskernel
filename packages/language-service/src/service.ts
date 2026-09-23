import type {
  DocumentAnalysis,
  Position,
  ProofState,
  TextDocumentSnapshot,
} from './model.js';
import {analyzeDocument,type AnalysisOptions} from './analyzer.js';
import {offsetAt} from './positions.js';
import {completionItems,definitionLocation,referenceLocations} from './navigation.js';

export interface LanguageServiceOptions extends AnalysisOptions {}

export class ProofScriptLanguageService {
  private readonly docs=new Map<string,TextDocumentSnapshot>();
  private readonly analyses=new Map<string,DocumentAnalysis>();
  private generation=0;

  constructor(readonly options:LanguageServiceOptions={}){}

  openDocument(uri:string,version:number,text:string):TextDocumentSnapshot {
    const snapshot={uri,version,generation:++this.generation,text};
    this.docs.set(uri,snapshot);
    this.analyses.delete(uri);
    return snapshot;
  }

  replaceDocument(uri:string,version:number,text:string):TextDocumentSnapshot {
    return this.openDocument(uri,version,text);
  }

  closeDocument(uri:string):void {
    this.docs.delete(uri);
    this.analyses.delete(uri);
  }

  getDocument(uri:string):TextDocumentSnapshot|undefined {
    return this.docs.get(uri);
  }

  analyze(uri:string):DocumentAnalysis {
    const snapshot=this.docs.get(uri);
    if(snapshot===undefined)throw new Error('document is not open: '+uri);
    const cached=this.analyses.get(uri);
    if(
      cached!==undefined
      &&cached.generation===snapshot.generation
      &&cached.version===snapshot.version
    )return cached;
    const analysis=analyzeDocument(snapshot,this.options);
    this.analyses.set(uri,analysis);
    return analysis;
  }

  diagnostics(uri:string){
    return this.analyze(uri).diagnostics;
  }

  completions(uri:string,_position:Position){
    return completionItems(this.analyze(uri));
  }

  definition(uri:string,position:Position){
    return definitionLocation(this.analyze(uri),position);
  }

  references(
    uri:string,
    position:Position,
    includeDeclaration=true,
  ){
    return referenceLocations(
      this.analyze(uri),
      position,
      includeDeclaration,
    );
  }

  documentSymbols(uri:string){
    return this.analyze(uri).declarations.map((declaration)=>({
      name:declaration.name,
      detail:declaration.kernel,
      kind:declaration.kind==='theorem'?12:13,
      range:declaration.range,
      selectionRange:declaration.selectionRange,
    }));
  }

  hover(uri:string,position:Position){
    const analysis=this.analyze(uri);
    const offset=offsetAt(analysis.text,position);
    const declaration=analysis.declarations.find((item)=>{
      const start=offsetAt(analysis.text,item.range.start);
      const end=offsetAt(analysis.text,item.range.end);
      return offset>=start&&offset<=end;
    });
    if(declaration===undefined)return null;
    const status=declaration.kernel==='verified'
      ?'kernel verified'
      :declaration.kernel;
    return {
      contents:{
        kind:'markdown',
        value:
          '**'+declaration.kind+' '+declaration.name+'** — '+status+
          '\n\nLean:\n\n    '+
          declaration.canonicalLean.replaceAll('\n','\n    '),
      },
      range:declaration.selectionRange,
    };
  }

  proofState(uri:string,position:Position):ProofState {
    const analysis=this.analyze(uri);
    const offset=offsetAt(analysis.text,position);
    const declaration=analysis.declarations.find((item)=>{
      const start=offsetAt(analysis.text,item.range.start);
      const end=offsetAt(analysis.text,item.range.end);
      return offset>=start&&offset<=end&&item.kind==='theorem';
    });
    if(declaration===undefined){
      return {status:'none',message:'No theorem at the current cursor.',goals:[]};
    }
    if(declaration.kernel==='verified'){
      return {
        status:'closed',
        declaration:declaration.name,
        message:'Goals accomplished!',
        goals:[],
        ...(declaration.initialGoal===undefined
          ?{}
          :{initialGoal:declaration.initialGoal}),
      };
    }
    if(declaration.kernel==='rejected'){
      return {
        status:'rejected',
        declaration:declaration.name,
        message:declaration.message??'The kernel rejected this theorem.',
        goals:[],
        ...(declaration.initialGoal===undefined
          ?{}
          :{initialGoal:declaration.initialGoal}),
      };
    }
    return {
      status:'unavailable',
      declaration:declaration.name,
      message:
        'Proof state unavailable because this declaration is outside the '+
        'current kernel-facing elaboration subset.',
      goals:[],
      ...(declaration.initialGoal===undefined
        ?{}
        :{initialGoal:declaration.initialGoal}),
    };
  }

  documentStatus(uri:string){
    const analysis=this.analyze(uri);
    return {
      uri,
      version:analysis.version,
      generation:analysis.generation,
      frontend:analysis.frontend,
      kernel:analysis.kernel,
      declarations:analysis.declarations.length,
      verifiedDeclarations:analysis.declarations.filter(
        (item)=>item.kernel==='verified',
      ).length,
      unsupportedDeclarations:analysis.declarations.filter(
        (item)=>item.kernel==='unsupported',
      ).length,
      rejectedDeclarations:analysis.declarations.filter(
        (item)=>item.kernel==='rejected',
      ).length,
    };
  }
}
