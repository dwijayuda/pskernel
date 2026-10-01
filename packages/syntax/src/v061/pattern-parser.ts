import {SyntaxError,type SourceSpan} from '../source.js';
import {V061ParseContext} from './context.js';

export type V061Pattern =
  | {readonly kind:'bool';readonly value:boolean;readonly span:SourceSpan}
  | {readonly kind:'wildcard';readonly span:SourceSpan}
  | {readonly kind:'constructor';readonly name:string;readonly binders:readonly string[];readonly span:SourceSpan};

export function parseV061Pattern(context:V061ParseContext):V061Pattern {
  const first=context.cursor.peek();
  if(first.text==='true'||first.text==='false'){
    context.cursor.consume();
    return {kind:'bool',value:first.text==='true',span:first.span};
  }
  if(first.text==='_'){
    context.cursor.consume();
    return {kind:'wildcard',span:first.span};
  }

  let name:string;
  let start=first.span.start;
  let end=first.span.end;
  if(first.text==='.'){
    context.cursor.consume();
    const ctor=context.cursor.expectKind('identifier','constructor pattern');
    name='.'+ctor.text;
    end=ctor.span.end;
  }else if(first.kind==='identifier'){
    context.cursor.consume();
    name=first.text;
  }else{
    throw new SyntaxError("unsupported match pattern starting with '"+first.text+"'",first.span);
  }

  const binders:string[]=[];
  while(context.cursor.peek().kind==='identifier'&&!context.cursor.at('=>')){
    const binder=context.cursor.consume();
    binders.push(binder.text);
    end=binder.span.end;
  }
  return {kind:'constructor',name,binders,span:{start,end}};
}

export function lowerV061PatternToLean(pattern:V061Pattern):string {
  switch(pattern.kind){
    case 'bool':return pattern.value?'true':'false';
    case 'wildcard':return '_';
    case 'constructor':return pattern.binders.length===0
      ? pattern.name
      : pattern.name+' '+pattern.binders.join(' ');
  }
}
