import type {
  SoftwareIrExpr,
  SoftwareIrInductive,
  SoftwareIrModule,
} from '@proofscript/compiler-ir';
import {
  brandIdentifier,
  plainMember,
  property,
  propertyAccess,
  tagIdentifier,
  typeScriptType,
} from './software-emitter-support.js';

const PRECEDENCE:Readonly<Record<string,number>>={
  '||':1,'&&':2,'==':3,'!=':3,'<':4,'<=':4,'>':4,'>=':4,'+':5,'-':5,'*':6,'/':6,'%':6,
};

function emitNatTotalBinary(operator:string,left:string,right:string):string|undefined {
  if(operator==='-'){
    return '((__a, __b) => __a >= __b ? __a - __b : 0n)('+left+', '+right+')';
  }
  if(operator==='/'){
    return '((__a, __b) => __b === 0n ? 0n : __a / __b)('+left+', '+right+')';
  }
  if(operator==='%'){
    return '((__a, __b) => __b === 0n ? __a : __a % __b)('+left+', '+right+')';
  }
  return undefined;
}

function emitConstructorMatch(expr:Extract<SoftwareIrExpr,{kind:'match'}>):string {
  const type=expr.scrutinee.type;
  if(typeof type==='string'||type.kind!=='nominal'){
    throw new Error('PS_TS_MATCH_TYPE: constructor match requires nominal scrutinee');
  }
  const tag=tagIdentifier(type.name);
  const matchVar='__ps$match';
  const cases:string[]=[];
  let defaultBody:string|undefined;

  for(const alternative of expr.alternatives){
    if(alternative.pattern.kind==='wildcard'){
      defaultBody='return '+emitSoftwareIrExpression(alternative.body)+';';
      continue;
    }
    if(alternative.pattern.kind!=='constructor')continue;
    const statements=alternative.pattern.binders.map(
      (binder)=>'const '+binder.name+' = '+matchVar+'['+property(binder.field)+'];',
    );
    statements.push('return '+emitSoftwareIrExpression(alternative.body)+';');
    cases.push(
      'case '+JSON.stringify(alternative.pattern.constructor)+': { '+
      statements.join(' ')+' }',
    );
  }

  const fallback=defaultBody??'throw new Error("PS_RUNTIME_IMPOSSIBLE_CONSTRUCTOR");';
  return '(('+matchVar+') => { switch ('+matchVar+'['+tag+']) { '+
    cases.join(' ')+' default: '+fallback+' } })('+emitSoftwareIrExpression(expr.scrutinee)+')';
}

function emitBoolMatch(expr:Extract<SoftwareIrExpr,{kind:'match'}>):string {
  const wildcard=expr.alternatives.find((alt)=>alt.pattern.kind==='wildcard');
  const trueAlt=expr.alternatives.find(
    (alt)=>alt.pattern.kind==='bool'&&alt.pattern.value,
  );
  const falseAlt=expr.alternatives.find(
    (alt)=>alt.pattern.kind==='bool'&&!alt.pattern.value,
  );
  if(trueAlt===undefined&&falseAlt===undefined&&wildcard!==undefined){
    return '((__ps$match) => '+emitSoftwareIrExpression(wildcard.body)+')('+
      emitSoftwareIrExpression(expr.scrutinee)+')';
  }
  const onTrue=trueAlt??wildcard;
  const onFalse=falseAlt??wildcard;
  if(onTrue===undefined||onFalse===undefined){
    throw new Error('PS_TS_MATCH_UNSUPPORTED: non-exhaustive Bool match reached backend');
  }
  return '('+emitSoftwareIrExpression(expr.scrutinee)+' ? '+
    emitSoftwareIrExpression(onTrue.body)+' : '+emitSoftwareIrExpression(onFalse.body)+')';
}

export function emitSoftwareIrExpression(expr:SoftwareIrExpr,parentPrecedence=0):string {
  switch(expr.kind){
    case 'literal':
      if(expr.type==='Unit')return 'undefined';
      if(expr.type==='Nat'||expr.type==='Int')return String(expr.value)+'n';
      return JSON.stringify(expr.value);
    case 'var':return expr.name;
    case 'projection':
      return emitSoftwareIrExpression(expr.target)+propertyAccess(expr.field);
    case 'record':{
      const brand=brandIdentifier(expr.structure);
      const fields=[
        '['+brand+']: true',
        ...expr.fields.map(
          (field)=>plainMember(field.name)+': '+emitSoftwareIrExpression(field.value),
        ),
      ];
      return '{ '+fields.join(', ')+' }';
    }
    case 'constructor':{
      const access=expr.inductive+'['+property(expr.constructor)+']';
      if(expr.fields.length===0)return access;
      return access+'('+expr.fields.map(
        (field)=>emitSoftwareIrExpression(field.value),
      ).join(', ')+')';
    }
    case 'call':{
      if(expr.callStyle==='direct'){
        return expr.callee+'('+expr.args.map((arg)=>emitSoftwareIrExpression(arg)).join(', ')+')';
      }
      return expr.args.reduce(
        (callee,arg)=>callee+'('+emitSoftwareIrExpression(arg)+')',
        expr.callee,
      );
    }
    case 'match':{
      const hasConstructor=expr.alternatives.some(
        (alternative)=>alternative.pattern.kind==='constructor',
      );
      return hasConstructor?emitConstructorMatch(expr):emitBoolMatch(expr);
    }
    case 'lambda':{
      return [...expr.binders].reverse().reduce(
        (body,binder)=>'('+binder.name+': '+typeScriptType(binder.type)+') => '+body,
        emitSoftwareIrExpression(expr.body),
      );
    }
    case 'unary':return '!'+emitSoftwareIrExpression(expr.operand,7);
    case 'if':
      return '('+emitSoftwareIrExpression(expr.condition)+' ? '+
        emitSoftwareIrExpression(expr.thenBranch)+' : '+
        emitSoftwareIrExpression(expr.elseBranch)+')';
    case 'let':
      return '(() => { const '+expr.name+': '+typeScriptType(expr.bindingType)+' = '+
        emitSoftwareIrExpression(expr.value)+'; return '+
        emitSoftwareIrExpression(expr.body)+'; })()';
    case 'binary':{
      const left=emitSoftwareIrExpression(expr.left);
      const right=emitSoftwareIrExpression(expr.right);
      if(expr.type==='Nat'){
        const total=emitNatTotalBinary(expr.operator,left,right);
        if(total!==undefined)return total;
      }
      const operator=expr.operator==='=='?'===':expr.operator==='!='?'!==':expr.operator;
      const precedence=PRECEDENCE[expr.operator]??0;
      const rendered=emitSoftwareIrExpression(expr.left,precedence)+' '+operator+' '+
        emitSoftwareIrExpression(expr.right,precedence+1);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
  }
}

function emitInductive(lines:string[],inductive:SoftwareIrInductive):void {
  const tag=tagIdentifier(inductive.name);
  lines.push(
    'const '+tag+': unique symbol = Symbol('+
    JSON.stringify('ProofScript.'+inductive.name+'.tag')+');',
  );

  const variants=inductive.constructors.map((constructor)=>{
    const fields=constructor.fields.map(
      (field)=>'readonly '+plainMember(field.name)+': '+typeScriptType(field.type)+';',
    );
    return '{ readonly ['+tag+']: '+JSON.stringify(constructor.name)+'; '+
      fields.join(' ')+' }';
  });
  lines.push(
    'export type '+inductive.name+' =\n  | '+variants.join('\n  | ')+';',
  );

  lines.push('export const '+inductive.name+' = {');
  for(const constructor of inductive.constructors){
    if(constructor.fields.length===0){
      lines.push(
        '  '+property(constructor.name)+': { ['+tag+']: '+
        JSON.stringify(constructor.name)+' } as '+inductive.name+',',
      );
      continue;
    }
    const params=constructor.fields.map(
      (field,index)=>'__field'+index+': '+typeScriptType(field.type),
    ).join(', ');
    const fields=constructor.fields.map(
      (field,index)=>plainMember(field.name)+': __field'+index,
    );
    lines.push(
      '  '+property(constructor.name)+': ('+params+'): '+inductive.name+
      ' => ({ ['+tag+']: '+JSON.stringify(constructor.name)+', '+
      fields.join(', ')+' } as '+inductive.name+'),',
    );
  }
  lines.push('} as const;');
}

function emitLocalDeclarations(
  locals:readonly import('@proofscript/compiler-ir').SoftwareIrLocalDeclaration[],
):string[] {
  return locals.map((local)=>{
    if(local.params.length===0){
      return 'const '+local.name+': '+typeScriptType(local.resultType)+' = '+
        emitSoftwareIrExpression(local.body)+';';
    }
    const params=local.params.map(
      (param)=>param.name+': '+typeScriptType(param.type),
    ).join(', ');
    return 'function '+local.name+'('+params+'): '+typeScriptType(local.resultType)+
      ' { return '+emitSoftwareIrExpression(local.body)+'; }';
  });
}

export function emitV061TypeScript(module:SoftwareIrModule):string {
  if(module.kind!=='proofscript-software-ir')throw new Error('PS_TS_EXPECTS_SOFTWARE_IR');
  const lines=['// generated by ProofScript; edit the .ps source instead'];

  for(const structure of module.structures){
    const brand=brandIdentifier(structure.name);
    lines.push(
      'const '+brand+': unique symbol = Symbol('+JSON.stringify('ProofScript.'+structure.name)+');',
    );
    lines.push('export interface '+structure.name+' {');
    lines.push('  readonly ['+brand+']: true;');
    for(const field of structure.fields){
      lines.push('  readonly '+plainMember(field.name)+': '+typeScriptType(field.type)+';');
    }
    lines.push('}');
  }

  for(const inductive of module.inductives)emitInductive(lines,inductive);

  for(const decl of module.declarations){
    const localLines=emitLocalDeclarations(decl.whereDeclarations??[]);
    if(decl.params.length===0){
      if(localLines.length===0){
        lines.push(
          'export const '+decl.name+': '+typeScriptType(decl.resultType)+' = '+
          emitSoftwareIrExpression(decl.body)+';',
        );
      }else{
        lines.push(
          'export const '+decl.name+': '+typeScriptType(decl.resultType)+' = (() => { '+
          localLines.join(' ')+' return '+emitSoftwareIrExpression(decl.body)+'; })();',
        );
      }
      continue;
    }
    const params=decl.params.map(
      (param)=>param.name+': '+typeScriptType(param.type),
    ).join(', ');
    const statements=[
      ...localLines,
      'return '+emitSoftwareIrExpression(decl.body)+';',
    ].join(' ');
    lines.push(
      'export function '+decl.name+'('+params+'): '+typeScriptType(decl.resultType)+
      ' { '+statements+' }',
    );
  }
  return lines.join('\n')+'\n';
}
