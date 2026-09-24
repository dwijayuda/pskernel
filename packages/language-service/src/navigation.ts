import {lex,type V061Declaration} from '@proofscript/syntax';
import type {
  DocumentAnalysis,
  Position,
  Range,
} from './model.js';
import type {ProjectAnalysisContext} from './project-context.js';
import {offsetAt,rangeFromOffsets} from './positions.js';

export interface EditorLocation {
  readonly uri:string;
  readonly range:Range;
}
export interface EditorCompletionItem {
  readonly label:string;
  readonly kind:3|7|14;
  readonly detail:string;
  readonly source:'document'|'project'|'foundational'|'syntax';
}

function identifierAt(
  analysis:DocumentAnalysis,
  position:Position,
):string|undefined {
  const offset=offsetAt(analysis.text,position);
  const token=lex(analysis.text).find((item)=>
    item.kind==='identifier'
    &&offset>=item.span.start.offset
    &&offset<=item.span.end.offset
  );
  return token?.text;
}

function declarationNameOffset(
  text:string,
  declaration:V061Declaration,
):number {
  const start=declaration.span.start.offset;
  const end=declaration.span.end.offset;
  const index=text.slice(start,end).indexOf(declaration.name);
  return index<0?start:start+index;
}

function projectDefinitionLocations(
  project:ProjectAnalysisContext|undefined,
  name:string,
):readonly EditorLocation[] {
  if(project===undefined)return [];
  const out:EditorLocation[]=[];
  for(const module of project.moduleOrder){
    const source=project.sources.get(module);
    if(source===undefined)continue;
    for(const declaration of source.surface.declarations){
      if(declaration.name!==name)continue;
      const start=declarationNameOffset(source.text,declaration);
      out.push({
        uri:source.uri,
        range:rangeFromOffsets(
          source.text,
          start,
          start+declaration.name.length,
        ),
      });
    }
  }
  return out;
}

export function completionItems(
  analysis:DocumentAnalysis,
  project?:ProjectAnalysisContext,
):readonly EditorCompletionItem[] {
  const items:EditorCompletionItem[]=[];
  const seen=new Set<string>();
  const add=(item:EditorCompletionItem):void=>{
    if(seen.has(item.label))return;
    seen.add(item.label);
    items.push(item);
  };

  for(const declaration of analysis.declarations){
    add({
      label:declaration.name,
      kind:3,
      detail:declaration.kind+' · '+declaration.kernel,
      source:'document',
    });
  }
  if(project!==undefined){
    for(const module of project.moduleOrder){
      if(module===project.entryModule)continue;
      const source=project.sources.get(module);
      if(source===undefined)continue;
      for(const declaration of source.surface.declarations){
        add({
          label:declaration.name,
          kind:3,
          detail:declaration.kind+' · imported from '+module,
          source:'project',
        });
      }
    }
  }
  for(const label of ['Prop','Type','Nat','Int','Bool','String','Unit']){
    add({label,kind:7,detail:'Lean foundational type',source:'foundational'});
  }
  for(const label of [
    'theorem','def','const','function','extern','structure','class','inductive',
    'fun','let','match','if','by','exact','assumption','apply','intro',
  ]){
    add({label,kind:14,detail:'ProofScript / inherited Lean syntax',source:'syntax'});
  }
  return items.sort((a,b)=>a.label.localeCompare(b.label));
}

export function definitionLocation(
  analysis:DocumentAnalysis,
  position:Position,
  project?:ProjectAnalysisContext,
):EditorLocation|null {
  const name=identifierAt(analysis,position);
  if(name===undefined)return null;
  const local=analysis.declarations.find((item)=>item.name===name);
  if(local!==undefined){
    return {uri:analysis.uri,range:local.selectionRange};
  }
  const imported=projectDefinitionLocations(project,name)
    .filter((item)=>item.uri!==analysis.uri);
  return imported.length===1?imported[0]!:null;
}

export function referenceLocations(
  analysis:DocumentAnalysis,
  position:Position,
  includeDeclaration=true,
  project?:ProjectAnalysisContext,
):readonly EditorLocation[] {
  const name=identifierAt(analysis,position);
  if(name===undefined)return [];
  const sources=project===undefined
    ?[{
        uri:analysis.uri,
        text:analysis.text,
        declarations:analysis.declarations.map((item)=>({
          name:item.name,
          start:offsetAt(analysis.text,item.selectionRange.start),
        })),
      }]
    :project.moduleOrder.flatMap((module)=>{
        const source=project.sources.get(module);
        if(source===undefined)return [];
        return [{
          uri:source.uri,
          text:source.text,
          declarations:source.surface.declarations.map((declaration)=>({
            name:declaration.name,
            start:declarationNameOffset(source.text,declaration),
          })),
        }];
      });

  return sources.flatMap((source)=>{
    const declarationStarts=new Set(
      source.declarations
        .filter((item)=>item.name===name)
        .map((item)=>item.start),
    );
    return lex(source.text)
      .filter((token)=>
        token.kind==='identifier'
        &&token.text===name
        &&(
          includeDeclaration
          ||!declarationStarts.has(token.span.start.offset)
        )
      )
      .map((token)=>({
        uri:source.uri,
        range:rangeFromOffsets(
          source.text,
          token.span.start.offset,
          token.span.end.offset,
        ),
      }));
  });
}
