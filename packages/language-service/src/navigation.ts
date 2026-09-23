import {lex} from '@proofscript/syntax';
import type {
  DocumentAnalysis,
  Position,
  Range,
} from './model.js';
import {offsetAt,rangeFromOffsets} from './positions.js';

export interface EditorLocation {
  readonly uri:string;
  readonly range:Range;
}
export interface EditorCompletionItem {
  readonly label:string;
  readonly kind:3|7|14;
  readonly detail:string;
  readonly source:'document'|'foundational'|'syntax';
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

export function completionItems(
  analysis:DocumentAnalysis,
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
  for(const label of ['Prop','Type','Nat','Int','Bool','String','Unit']){
    add({label,kind:7,detail:'Lean foundational type',source:'foundational'});
  }
  for(const label of [
    'theorem','def','const','function','structure','class','inductive',
    'fun','let','match','if','by','exact','assumption','apply','intro',
  ]){
    add({label,kind:14,detail:'ProofScript / inherited Lean syntax',source:'syntax'});
  }
  return items.sort((a,b)=>a.label.localeCompare(b.label));
}

export function definitionLocation(
  analysis:DocumentAnalysis,
  position:Position,
):EditorLocation|null {
  const name=identifierAt(analysis,position);
  if(name===undefined)return null;
  const declaration=analysis.declarations.find((item)=>item.name===name);
  return declaration===undefined
    ?null
    :{uri:analysis.uri,range:declaration.selectionRange};
}

export function referenceLocations(
  analysis:DocumentAnalysis,
  position:Position,
  includeDeclaration=true,
):readonly EditorLocation[] {
  const name=identifierAt(analysis,position);
  if(name===undefined)return [];
  const declaration=analysis.declarations.find((item)=>item.name===name);
  return lex(analysis.text)
    .filter((token)=>
      token.kind==='identifier'
      &&token.text===name
      &&(
        includeDeclaration
        ||declaration===undefined
        ||token.span.start.offset!==offsetAt(
          analysis.text,
          declaration.selectionRange.start,
        )
      )
    )
    .map((token)=>({
      uri:analysis.uri,
      range:rangeFromOffsets(
        analysis.text,
        token.span.start.offset,
        token.span.end.offset,
      ),
    }));
}
