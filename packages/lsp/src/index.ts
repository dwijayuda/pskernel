export interface Position {readonly line:number;readonly character:number}
export interface Range {readonly start:Position;readonly end:Position}
export interface OffsetDiagnostic {
  readonly severity:'error'|'warning'|'info';
  readonly message:string;
  readonly start:number;
  readonly end:number;
}
export interface LspDiagnostic {readonly severity:1|2|3;readonly message:string;readonly range:Range}

export function positionAt(text:string,offset:number):Position{
  if(!Number.isSafeInteger(offset)||offset<0||offset>text.length)throw new RangeError('offset out of bounds');
  let line=0,lastBreak=-1;
  for(let i=0;i<offset;i++)if(text.charCodeAt(i)===10){line+=1;lastBreak=i;}
  return {line,character:offset-lastBreak-1};
}
export function offsetAt(text:string,position:Position):number{
  if(!Number.isSafeInteger(position.line)||!Number.isSafeInteger(position.character)||position.line<0||position.character<0)throw new RangeError('invalid position');
  let line=0,start=0;
  while(line<position.line){
    const next=text.indexOf('\n',start);
    if(next<0)throw new RangeError('line out of bounds');
    start=next+1;line+=1;
  }
  const lineEnd=text.indexOf('\n',start);
  const end=lineEnd<0?text.length:lineEnd;
  const offset=start+position.character;
  if(offset>end)throw new RangeError('character out of bounds');
  return offset;
}
const severity={error:1,warning:2,info:3} as const;
export function toLspDiagnostics(text:string,diagnostics:readonly OffsetDiagnostic[]):readonly LspDiagnostic[]{
  return diagnostics.map(d=>({
    severity:severity[d.severity],
    message:d.message,
    range:{start:positionAt(text,d.start),end:positionAt(text,d.end)},
  }));
}
