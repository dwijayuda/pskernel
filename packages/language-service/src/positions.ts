import type {Position,Range} from './model.js';

export function positionAt(text:string,offset:number):Position {
  if(!Number.isSafeInteger(offset)||offset<0||offset>text.length){
    throw new RangeError('offset out of bounds');
  }
  let line=0;
  let lastBreak=-1;
  for(let i=0;i<offset;i++){
    if(text.charCodeAt(i)===10){
      line+=1;
      lastBreak=i;
    }
  }
  return {line,character:offset-lastBreak-1};
}

export function offsetAt(text:string,position:Position):number {
  if(
    !Number.isSafeInteger(position.line)
    ||!Number.isSafeInteger(position.character)
    ||position.line<0
    ||position.character<0
  )throw new RangeError('invalid position');

  let line=0;
  let start=0;
  while(line<position.line){
    const next=text.indexOf('\n',start);
    if(next<0)throw new RangeError('line out of bounds');
    start=next+1;
    line+=1;
  }
  const lineEnd=text.indexOf('\n',start);
  const end=lineEnd<0?text.length:lineEnd;
  const offset=start+position.character;
  if(offset>end)throw new RangeError('character out of bounds');
  return offset;
}

export function rangeFromOffsets(
  text:string,
  start:number,
  end:number,
):Range {
  return {start:positionAt(text,start),end:positionAt(text,end)};
}
