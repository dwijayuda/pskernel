import {SyntaxError} from '../source.js';
import type {
  V061ClassDeclaration,
  V061Declaration,
  V061InductiveConstructor,
  V061InductiveDeclaration,
  V061InstanceDeclaration,
  V061StructureDeclaration,
  V061StructureField,
} from './ast.js';
import {V061ParseContext} from './context.js';
import type {V061LeanSubsetExpressionParser} from './lean-subset-expression-parser.js';
import {parseV061ParameterSequence} from './parameter-parser.js';
import {parseV061Type} from './type-parser.js';

const TOP_LEVEL_COMMANDS=new Set([
  'def','theorem','structure','class','instance','inductive',
]);

const UNSUPPORTED_COMMANDS=new Set([
  'namespace','section','open','variable','axiom','opaque','abbrev',
  'example','macro','syntax','elab','attribute','noncomputable',
  'private','protected',
]);

function requireExplicitParams(
  params:ReturnType<typeof parseV061ParameterSequence>['params'],
  owner:string,
):void {
  const unsupported=params.find(
    (parameter)=>(parameter.binderInfo??'default')!=='default',
  );
  if(unsupported!==undefined){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_BINDER_UNSUPPORTED: '+owner+
      ' currently accepts explicit binders only',
      unsupported.span,
    );
  }
}

function parseLeanField(context:V061ParseContext):V061StructureField {
  const first=context.cursor.peek();
  if(first.text==='{'){
    const open=context.cursor.consume();
    const name=context.cursor.expectKind('identifier','implicit field name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    const close=context.cursor.expect('}');
    return {
      name:name.text,
      type,
      binderKind:'implicit',
      span:{start:open.span.start,end:close.span.end},
    };
  }
  if(first.text==='['){
    const open=context.cursor.consume();
    const name=context.cursor.expectKind('identifier','instance field name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    const close=context.cursor.expect(']');
    return {
      name:name.text,
      type,
      binderKind:'instance',
      span:{start:open.span.start,end:close.span.end},
    };
  }
  const name=context.cursor.expectKind('identifier','field name');
  context.cursor.expect(':');
  const type=parseV061Type(context,{stopAtLineBreak:true});
  return {
    name:name.text,
    type,
    binderKind:'explicit',
    span:{start:name.span.start,end:type.span.end},
  };
}

function parseLeanFields(
  context:V061ParseContext,
):readonly V061StructureField[] {
  const fields:V061StructureField[]=[];
  while(
    !context.cursor.done
    &&!TOP_LEVEL_COMMANDS.has(context.cursor.peek().text)
  ){
    fields.push(parseLeanField(context));
  }
  if(fields.length===0){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_FIELDS: structure/class requires at least one field',
      context.cursor.peek().span,
    );
  }
  return fields;
}

function parseStructure(
  context:V061ParseContext,
):V061StructureDeclaration {
  const first=context.cursor.expect('structure');
  const name=context.cursor.expectKind('identifier','structure name');
  const {params}=parseV061ParameterSequence(context);
  context.cursor.expect('where');
  const fields=parseLeanFields(context);
  return {
    kind:'structure',
    name:name.text,
    params,
    fields,
    terminatedBySemicolon:false,
    span:{start:first.span.start,end:fields[fields.length-1]!.span.end},
  };
}

function parseClass(
  context:V061ParseContext,
):V061ClassDeclaration {
  const first=context.cursor.expect('class');
  const name=context.cursor.expectKind('identifier','class name');
  const {params}=parseV061ParameterSequence(context);
  requireExplicitParams(params,'class');
  context.cursor.expect('where');
  const fields=parseLeanFields(context);
  return {
    kind:'class',
    name:name.text,
    params,
    fields,
    terminatedBySemicolon:false,
    span:{start:first.span.start,end:fields[fields.length-1]!.span.end},
  };
}

function parseInstance(
  context:V061ParseContext,
  expressions:V061LeanSubsetExpressionParser,
):V061InstanceDeclaration {
  const first=context.cursor.expect('instance');
  const nameToken=context.cursor.atKind('identifier')
    ?context.cursor.consume()
    :undefined;
  const anonymous=nameToken===undefined;
  const name=nameToken?.text??'__ps_inst_'+first.span.start.offset;
  const {params}=parseV061ParameterSequence(context);
  context.cursor.expect(':');
  const resultType=parseV061Type(context);
  context.cursor.expect(':=');
  const body=expressions.parse();
  return {
    kind:'instance',
    name,
    anonymous,
    params,
    resultType,
    body,
    terminatedBySemicolon:false,
    span:{start:first.span.start,end:body.span.end},
  };
}

function parseConstructor(
  context:V061ParseContext,
):V061InductiveConstructor {
  const first=context.cursor.expect('|');
  const name=context.cursor.expectKind('identifier','constructor name');
  const {params}=parseV061ParameterSequence(context);
  requireExplicitParams(params,'inductive constructor');
  if(context.cursor.at(':')){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_CONSTRUCTOR_RESULT: explicit constructor result types are not in DS2.2',
      context.cursor.peek().span,
    );
  }
  return {
    name:name.text,
    params,
    span:{
      start:first.span.start,
      end:params.length===0?name.span.end:params[params.length-1]!.span.end,
    },
  };
}

function parseInductive(
  context:V061ParseContext,
):V061InductiveDeclaration {
  const first=context.cursor.expect('inductive');
  const name=context.cursor.expectKind('identifier','inductive name');
  const {params}=parseV061ParameterSequence(context);
  requireExplicitParams(params,'inductive');
  const resultType=context.cursor.consumeIf(':')
    ?parseV061Type(context)
    :undefined;
  context.cursor.expect('where');
  const constructors:V061InductiveConstructor[]=[];
  while(context.cursor.at('|')){
    constructors.push(parseConstructor(context));
  }
  if(constructors.length===0){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_INDUCTIVE: inductive requires at least one constructor',
      context.cursor.peek().span,
    );
  }
  return {
    kind:'inductive',
    name:name.text,
    params,
    ...(resultType===undefined?{}:{resultType}),
    constructors,
    terminatedBySemicolon:false,
    span:{
      start:first.span.start,
      end:constructors[constructors.length-1]!.span.end,
    },
  };
}

export function parseV061LeanSubsetDeclaration(
  context:V061ParseContext,
  expressions:V061LeanSubsetExpressionParser,
):V061Declaration {
  const token=context.cursor.peek();
  if(UNSUPPORTED_COMMANDS.has(token.text)){
    throw new SyntaxError(
      "PS_LEAN_SUBSET_UNSUPPORTED_COMMAND: '"+token.text+
      "' is outside the current DS2 subset",
      token.span,
    );
  }
  if(token.text==='structure')return parseStructure(context);
  if(token.text==='class')return parseClass(context);
  if(token.text==='instance')return parseInstance(context,expressions);
  if(token.text==='inductive')return parseInductive(context);
  throw new SyntaxError(
    "PS_LEAN_SUBSET_COMMAND: unsupported declaration '"+token.text+"'",
    token.span,
  );
}
