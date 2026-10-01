import {SyntaxError} from '../source.js';
import type {V061Parameter} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Type} from './type-parser.js';

export function parseV061ExplicitParameters(
  context:V061ParseContext,
):V061Parameter[] {
  const params:V061Parameter[]=[];
  const open=context.cursor.expect('(');
  context.own('D-EXPLICIT-PARAMS');

  if(context.cursor.at(')')){
    throw new SyntaxError(
      'D-EXPLICIT-PARAMS requires at least one explicit binding',
      open.span,
    );
  }

  while(true){
    const name=context.cursor.expectKind('identifier','parameter name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    params.push({
      name:name.text,
      type,
      binderInfo:'default',
      span:{start:name.span.start,end:type.span.end},
    });
    if(!context.cursor.consumeIf(','))break;
  }
  context.cursor.expect(')');
  return params;
}


export interface V061ParameterSequence {
  readonly params:readonly V061Parameter[];
  readonly explicitGroups:number;
}

function parseNativeBinder(
  context:V061ParseContext,
):V061Parameter {
  const first=context.cursor.peek();
  let binderInfo:NonNullable<V061Parameter['binderInfo']>;
  let close:string;

  if(first.text==='{'){
    const open=context.cursor.consume();
    if(context.cursor.at('{')){
      context.cursor.consume();
      binderInfo='strictImplicit';
      close='}}';
    }else{
      binderInfo='implicit';
      close='}';
    }
    const name=context.cursor.expectKind('identifier','binder name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    if(close==='}}'){
      context.cursor.expect('}');
      const last=context.cursor.expect('}');
      return {
        name:name.text,type,binderInfo,
        span:{start:open.span.start,end:last.span.end},
      };
    }
    const last=context.cursor.expect('}');
    return {
      name:name.text,type,binderInfo,
      span:{start:open.span.start,end:last.span.end},
    };
  }

  const open=context.cursor.expect('[');
  binderInfo='instImplicit';
  const name=context.cursor.expectKind('identifier','instance binder name');
  if(!context.cursor.consumeIf(':')){
    throw new SyntaxError(
      'unnamed instance binders are not yet represented by the v0.6.1 parameter AST',
      name.span,
    );
  }
  const type=parseV061Type(context);
  const last=context.cursor.expect(']');
  return {
    name:name.text,type,binderInfo,
    span:{start:open.span.start,end:last.span.end},
  };
}

export function parseV061ParameterSequence(
  context:V061ParseContext,
):V061ParameterSequence {
  const params:V061Parameter[]=[];
  let explicitGroups=0;
  while(true){
    if(context.cursor.at('(')){
      params.push(...parseV061ExplicitParameters(context).map(
        (parameter)=>({...parameter,binderInfo:'default' as const}),
      ));
      explicitGroups+=1;
      continue;
    }
    if(context.cursor.at('{')||context.cursor.at('[')){
      params.push(parseNativeBinder(context));
      continue;
    }
    break;
  }
  return {params,explicitGroups};
}
