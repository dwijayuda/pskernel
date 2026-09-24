import type {V061ParseContext} from './context.js';

export function startsV061DependentArrow(
  context:V061ParseContext,
):boolean {
  if(
    !context.cursor.at('(')
    ||context.cursor.peek(1).kind!=='identifier'
    ||context.cursor.peek(2).text!==':'
  )return false;

  let depth=0;
  for(let offset=0;;offset+=1){
    const token=context.cursor.peek(offset);
    if(token.kind==='eof')return false;
    if(token.text==='('){
      depth+=1;
      continue;
    }
    if(token.text!==')')continue;
    depth-=1;
    if(depth!==0)continue;
    const next=context.cursor.peek(offset+1);
    return next.text==='->'||next.text==='→';
  }
}
