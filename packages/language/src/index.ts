export interface LanguageDiagnostic {
  readonly severity:'error'|'warning'|'info';
  readonly message:string;
  readonly start:number;
  readonly end:number;
}
export interface ProcessResult<State> {
  readonly state:State;
  readonly diagnostics:readonly LanguageDiagnostic[];
}
export interface DocumentProcessor<State> {
  process(text:string,previous:State|undefined):ProcessResult<State>;
}
export interface DocumentSnapshot<State> {
  readonly uri:string;
  readonly version:number;
  readonly text:string;
  readonly state:State;
  readonly diagnostics:readonly LanguageDiagnostic[];
  readonly reused:boolean;
}
export interface CancellationLike {readonly aborted:boolean}

export function processDocument<State>(
  uri:string,
  version:number,
  text:string,
  processor:DocumentProcessor<State>,
  previous?:DocumentSnapshot<State>,
  signal?:CancellationLike,
):DocumentSnapshot<State>{
  if(signal?.aborted)throw new Error('language processing cancelled');
  if(previous!==undefined&&previous.uri===uri&&previous.text===text){
    return {...previous,version,reused:true};
  }
  const result=processor.process(text,previous?.state);
  if(signal?.aborted)throw new Error('language processing cancelled');
  return {uri,version,text,state:result.state,diagnostics:[...result.diagnostics],reused:false};
}

export interface TextEdit {readonly start:number;readonly end:number;readonly text:string}
export function applyTextEdits(source:string,edits:readonly TextEdit[]):string{
  const sorted=[...edits].sort((a,b)=>b.start-a.start||b.end-a.end);
  let result=source;
  let previousStart=source.length;
  for(const edit of sorted){
    if(!Number.isSafeInteger(edit.start)||!Number.isSafeInteger(edit.end)||edit.start<0||edit.end<edit.start||edit.end>source.length){
      throw new RangeError('invalid text edit range');
    }
    if(edit.end>previousStart)throw new Error('overlapping text edits');
    result=result.slice(0,edit.start)+edit.text+result.slice(edit.end);
    previousStart=edit.start;
  }
  return result;
}

export * from './v061-software.js';
