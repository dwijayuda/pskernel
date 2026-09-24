import {
  Environment,
  instantiateExprLevels,
  nameToString,
  type Expr,
  type Level,
  type RecursorInfo,
} from 'lean-ts-kernel';
import {
  findLean434JsExternForDeclaration,
  findLean434JsImplementedBy,
  invokeLean434JsExtern,
  invokeLean434JsImplementedBy,
  type LeanRef,
} from './lean4.js';
import type {
  Lean434RuntimeMetadataIndex,
} from './lean4-metadata.js';

export interface Lean434ConstructorValue {
  readonly kind:'constructor';
  readonly name:string;
  readonly fields:readonly Lean434RuntimeValue[];
}

export interface Lean434TypeValue {
  readonly kind:'type';
  readonly expr:Expr;
}

export interface Lean434ProofValue {
  readonly kind:'proof';
  readonly theorem:string;
}

export interface Lean434WorldTokenValue {
  readonly kind:'world-token';
}

export const LEAN434_WORLD_TOKEN:Lean434WorldTokenValue=
  Object.freeze({kind:'world-token'});

interface Lean434ClosureValue {
  readonly kind:'closure';
  readonly body:Expr;
  readonly locals:readonly Lean434RuntimeValue[];
}

interface Lean434PrimitiveFunction {
  readonly kind:'primitive-function';
  readonly name:string;
  readonly arity:number;
  readonly args:readonly Lean434RuntimeValue[];
  readonly invoke:(args:readonly Lean434RuntimeValue[])=>Lean434RuntimeValue;
}

interface Lean434ConstructorFunction {
  readonly kind:'constructor-function';
  readonly name:string;
  readonly numParams:number;
  readonly arity:number;
  readonly args:readonly Lean434RuntimeValue[];
}

interface Lean434RecursorFunction {
  readonly kind:'recursor-function';
  readonly name:string;
  readonly levels:readonly Level[];
  readonly info:RecursorInfo;
  readonly arity:number;
  readonly args:readonly Lean434RuntimeValue[];
}

export type Lean434CallableValue=
  |Lean434ClosureValue
  |Lean434PrimitiveFunction
  |Lean434ConstructorFunction
  |Lean434RecursorFunction;

export type Lean434RuntimeValue=
  |bigint|string|boolean|undefined
  |readonly Lean434RuntimeValue[]
  |LeanRef<Lean434RuntimeValue>
  |Lean434ConstructorValue
  |Lean434TypeValue
  |Lean434ProofValue
  |Lean434WorldTokenValue
  |Lean434CallableValue;

type Lean434TaggedRuntimeValue=
  |Lean434ConstructorValue
  |Lean434TypeValue
  |Lean434ProofValue
  |Lean434WorldTokenValue
  |Lean434CallableValue;

function isTaggedRuntimeValue(
  value:Lean434RuntimeValue,
):value is Lean434TaggedRuntimeValue{
  return typeof value==='object'
    &&value!==null
    &&!Array.isArray(value)
    &&'kind' in value;
}

export class Lean434EvaluationError extends Error {
  constructor(message:string){
    super(message);
    this.name='Lean434EvaluationError';
  }
}

export class Lean434IOError extends Lean434EvaluationError {
  constructor(readonly value:Lean434RuntimeValue){
    super('Lean IO action returned EST.Out.error');
    this.name='Lean434IOError';
  }
}

export interface Lean434EvaluatorOptions {
  readonly metadata?:Lean434RuntimeMetadataIndex;
}

function expectNat(value:Lean434RuntimeValue,owner:string):bigint {
  if(typeof value!=='bigint'){
    throw new Lean434EvaluationError(owner+' expected Nat');
  }
  return value;
}

function primitive(
  name:string,
  arity:number,
  invoke:(args:readonly Lean434RuntimeValue[])=>Lean434RuntimeValue,
  args:readonly Lean434RuntimeValue[]=[],
):Lean434PrimitiveFunction {
  return {kind:'primitive-function',name,arity,args,invoke};
}

function isCallable(value:Lean434RuntimeValue):value is Lean434CallableValue {
  return isTaggedRuntimeValue(value)
    &&(
      value.kind==='closure'
      ||value.kind==='primitive-function'
      ||value.kind==='constructor-function'
      ||value.kind==='recursor-function'
    );
}

function typeValue(expr:Expr):Lean434TypeValue {
  return {kind:'type',expr};
}

function declarationTypeReturnsSort(type:Expr):boolean{
  let current=type;
  while(current.kind==='forall'){
    current=current.body;
  }
  return current.kind==='sort';
}

/**
 * Bootstrap evaluator for pskernel-admitted Lean expressions.
 *
 * This is executable support, not part of the trusted kernel. It intentionally
 * starts small and fails closed on unsupported runtime constructs. pskernel
 * remains responsible for type/declaration checking before expressions reach
 * this evaluator.
 */
export class Lean434Evaluator {
  private readonly runtimeGlobals=
    new Map<string,Lean434RuntimeValue>();

  constructor(
    readonly environment:Environment,
    readonly options:Lean434EvaluatorOptions={},
  ){}

  evaluate(expr:Expr):Lean434RuntimeValue {
    return this.evaluateWithLocals(expr,[]);
  }

  applyRuntimeValue(
    fn:Lean434RuntimeValue,
    arg:Lean434RuntimeValue,
  ):Lean434RuntimeValue {
    return this.apply(fn,arg);
  }

  runStateAction(
    action:Lean434RuntimeValue,
    state:Lean434RuntimeValue=LEAN434_WORLD_TOKEN,
  ):{
    readonly value:Lean434RuntimeValue;
    readonly state:Lean434RuntimeValue;
  }{
    const result=this.apply(action,state);
    if(
      !isTaggedRuntimeValue(result)
      ||result.kind!=='constructor'
      ||result.name!=='ST.Out.mk'
      ||result.fields.length<2
    ){
      throw new Lean434EvaluationError(
        'Lean ST action did not return ST.Out.mk',
      );
    }
    return {
      value:result.fields[0]!,
      state:result.fields[1]!,
    };
  }

  runIOAction(
    action:Lean434RuntimeValue,
    state:Lean434RuntimeValue=LEAN434_WORLD_TOKEN,
  ):{
    readonly value:Lean434RuntimeValue;
    readonly state:Lean434RuntimeValue;
  }{
    const result=this.apply(action,state);
    if(
      !isTaggedRuntimeValue(result)
      ||result.kind!=='constructor'
      ||result.fields.length<2
    ){
      throw new Lean434EvaluationError(
        'Lean IO action did not return an ST/EST result',
      );
    }
    if(result.name==='ST.Out.mk'||result.name==='EST.Out.ok'){
      return {
        value:result.fields[0]!,
        state:result.fields[1]!,
      };
    }
    if(result.name==='EST.Out.error'){
      throw new Lean434IOError(result.fields[0]!);
    }
    throw new Lean434EvaluationError(
      "Lean IO action returned unsupported constructor '"+
      result.name+"'",
    );
  }

  setRuntimeGlobal(
    declaration:string,
    value:Lean434RuntimeValue,
  ):void{
    this.runtimeGlobals.set(declaration,value);
  }

  getRuntimeGlobal(
    declaration:string,
  ):Lean434RuntimeValue|undefined{
    return this.runtimeGlobals.get(declaration);
  }

  hasRuntimeGlobal(declaration:string):boolean{
    return this.runtimeGlobals.has(declaration);
  }

  private evaluateWithLocals(
    expr:Expr,
    locals:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue {
    switch(expr.kind){
      case 'bvar':{
        const value=locals[expr.index];
        if(value===undefined&&expr.index>=locals.length){
          throw new Lean434EvaluationError(
            'loose bound variable #'+expr.index,
          );
        }
        return value;
      }
      case 'fvar':
        throw new Lean434EvaluationError(
          'free variable '+expr.id+' is not executable in a closed term',
        );
      case 'mvar':
        throw new Lean434EvaluationError(
          'metavariable '+expr.id+' reached runtime',
        );
      case 'sort':
      case 'forall':
        return typeValue(expr);
      case 'lit':
        return expr.literal.kind==='nat'
          ?expr.literal.value
          :expr.literal.value;
      case 'mdata':
        return this.evaluateWithLocals(expr.expr,locals);
      case 'lam':
        return {kind:'closure',body:expr.body,locals:[...locals]};
      case 'let':{
        const value=this.evaluateWithLocals(expr.value,locals);
        return this.evaluateWithLocals(expr.body,[value,...locals]);
      }
      case 'proj':{
        const target=this.evaluateWithLocals(expr.expr,locals);
        if(
          !isTaggedRuntimeValue(target)
          ||target.kind!=='constructor'
        ){
          throw new Lean434EvaluationError(
            'projection target is not a constructor value',
          );
        }
        const field=target.fields[expr.index];
        if(field===undefined&&expr.index>=target.fields.length){
          throw new Lean434EvaluationError(
            'projection field '+expr.index+' is out of bounds',
          );
        }
        return field;
      }
      case 'app':{
        const fn=this.evaluateWithLocals(expr.fn,locals);
        if(isTaggedRuntimeValue(fn)){
          if(fn.kind==='type'){
            // Type applications are runtime-erased. Retain only a symbolic
            // token so polymorphic executable code can pass them through.
            return typeValue(expr);
          }
          if(fn.kind==='proof'){
            // Theorem/proof applications are erased at runtime. Once the head
            // has reduced to proof evidence, none of its remaining arguments
            // can affect executable behavior.
            return fn;
          }
        }
        const arg=this.evaluateWithLocals(expr.arg,locals);
        return this.apply(fn,arg);
      }
      case 'const':
        return this.evaluateConstant(expr,locals);
    }
  }

  private evaluateConstant(
    expr:Extract<Expr,{kind:'const'}>,
    locals:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue {
    const name=nameToString(expr.name);

    if(name==='Nat.zero')return 0n;
    if(name==='Bool.false')return false;
    if(name==='Bool.true')return true;
    if(name==='Unit.unit')return undefined;

    if(this.runtimeGlobals.has(name)){
      return this.runtimeGlobals.get(name)!;
    }

    const metadataImplementedBy=
      this.options.metadata?.implementedByFor(name);
    const implementedBy=findLean434JsImplementedBy(name);
    if(implementedBy!==undefined){
      if(
        metadataImplementedBy!==undefined
        &&metadataImplementedBy.implementation!==
          implementedBy.implementation
      ){
        throw new Lean434EvaluationError(
          "implemented_by metadata mismatch for '"+name+"': expected '"+
          implementedBy.implementation+"', got '"+
          metadataImplementedBy.implementation+"'",
        );
      }
      return primitive(
        name,
        implementedBy.arity,
        (args)=>invokeLean434JsImplementedBy(
          implementedBy,
          args,
        ) as Lean434RuntimeValue,
      );
    }

    const metadataExtern=this.options.metadata?.externFor(name);
    const runtimeBinding=findLean434JsExternForDeclaration(name);
    if(runtimeBinding!==undefined){
      if(metadataExtern!==undefined){
        const selected=metadataExtern.entries.find(
          (entry)=>entry.kind==='standard'&&entry.backend==='all',
        );
        if(
          selected===undefined
          ||selected.kind!=='standard'
          ||selected.symbol!==runtimeBinding.leanSymbol
        ){
          throw new Lean434EvaluationError(
            "extern metadata mismatch for '"+name+"': expected '"+
            runtimeBinding.leanSymbol+"'",
          );
        }
      }
      return primitive(
        name,
        runtimeBinding.arity,
        (args)=>{
          const runtimeArgs=runtimeBinding.runtimeArgs===undefined
            ?args
            :runtimeBinding.runtimeArgs.map((index)=>{
                if(index<0||index>=args.length){
                  throw new Lean434EvaluationError(
                    "runtime argument index out of range for '"+name+"'",
                  );
                }
                return args[index]!;
              });
          if(runtimeBinding.effect==='st-action'){
            return primitive(
              name+'#state',
              1,
              (stateArgs)=>{
                const state=stateArgs[0]!;
                const value=invokeLean434JsExtern(
                  runtimeBinding.leanSymbol,
                  runtimeArgs,
                ) as Lean434RuntimeValue;
                return {
                  kind:'constructor',
                  name:'ST.Out.mk',
                  fields:[value,state],
                };
              },
            );
          }
          return invokeLean434JsExtern(
            runtimeBinding.leanSymbol,
            runtimeArgs,
          ) as Lean434RuntimeValue;
        },
      );
    }

    if(metadataExtern!==undefined){
      throw new Lean434EvaluationError(
        "Lean extern declaration has no supported JS adapter: '"+name+"'",
      );
    }

    const info=this.environment.find(expr.name);
    if(info===undefined){
      throw new Lean434EvaluationError(
        "unknown runtime constant '"+name+"'",
      );
    }

    if(
      'type' in info
      &&declarationTypeReturnsSort(info.type)
    ){
      // Types and type families are erased from executable code. This also
      // covers defined aliases such as IO.RealWorld, ST, BaseIO and EIO
      // without unfolding their logical representations at runtime.
      return typeValue(expr);
    }

    switch(info.kind){
      case 'definition':{
        const body=instantiateExprLevels(
          info.value,
          info.levelParams,
          expr.levels,
        );
        return this.evaluateWithLocals(body,locals);
      }
      case 'opaque':{
        // Opaqueness controls kernel reduction. Lean still compiles the body
        // for runtime execution, so the JS evaluator may execute it after the
        // declaration itself has already been checked by pskernel.
        const body=instantiateExprLevels(
          info.value,
          info.levelParams,
          expr.levels,
        );
        return this.evaluateWithLocals(body,locals);
      }
      case 'theorem':
        return {kind:'proof',theorem:name};
      case 'inductive':
        return typeValue(expr);
      case 'constructor':{
        if(name==='Nat.succ'){
          return primitive('Nat.succ',1,(args)=>
            expectNat(args[0]!,'Nat.succ')+1n
          );
        }
        const arity=info.numParams+info.numFields;
        if(arity===0){
          return {kind:'constructor',name,fields:[]};
        }
        return {
          kind:'constructor-function',
          name,
          numParams:info.numParams,
          arity,
          args:[],
        };
      }
      case 'recursor':{
        const majorIndex=
          info.numParams+
          info.numMotives+
          info.numMinors+
          info.numIndices;
        return {
          kind:'recursor-function',
          name,
          levels:[...expr.levels],
          info,
          arity:majorIndex+1,
          args:[],
        };
      }
      case 'axiom':
        throw new Lean434EvaluationError(
          "axiom has no JavaScript runtime implementation: '"+name+"'",
        );
      case 'quot':
        throw new Lean434EvaluationError(
          "quotient runtime evaluation is not implemented yet: '"+name+"'",
        );
    }
  }

  private apply(
    fn:Lean434RuntimeValue,
    arg:Lean434RuntimeValue,
  ):Lean434RuntimeValue {
    if(!isCallable(fn)){
      let detail=typeof fn+':'+String(fn);
      if(isTaggedRuntimeValue(fn)){
        detail=fn.kind+
          (fn.kind==='constructor'?':'+fn.name:'');
      }else if(Array.isArray(fn)){
        detail='array[length='+fn.length+']';
      }else if(fn instanceof Object){
        detail='object';
      }
      throw new Lean434EvaluationError(
        'attempted to apply a non-function runtime value ('+detail+')',
      );
    }

    if(fn.kind==='closure'){
      return this.evaluateWithLocals(fn.body,[arg,...fn.locals]);
    }

    const args=[...fn.args,arg];
    if(args.length<fn.arity){
      return {...fn,args};
    }
    if(args.length>fn.arity){
      throw new Lean434EvaluationError(
        "runtime function '"+fn.name+"' received too many arguments",
      );
    }

    if(fn.kind==='primitive-function'){
      return fn.invoke(args);
    }

    if(fn.kind==='recursor-function'){
      return this.evaluateRecursor(fn,args);
    }

    return {
      kind:'constructor',
      name:fn.name,
      fields:args.slice(fn.numParams),
    };
  }

  private normalizeMajor(
    value:Lean434RuntimeValue,
    info:RecursorInfo,
  ):Lean434ConstructorValue {
    if(
      isTaggedRuntimeValue(value)
      &&value.kind==='constructor'
    ){
      return value;
    }

    if(typeof value==='bigint'){
      const zero=info.rules.find(
        (rule)=>nameToString(rule.ctor)==='Nat.zero',
      );
      const succ=info.rules.find(
        (rule)=>nameToString(rule.ctor)==='Nat.succ',
      );
      if(zero!==undefined&&succ!==undefined){
        return value===0n
          ?{kind:'constructor',name:'Nat.zero',fields:[]}
          :{
              kind:'constructor',
              name:'Nat.succ',
              fields:[value-1n],
            };
      }
    }

    if(typeof value==='boolean'){
      const ctor=value?'Bool.true':'Bool.false';
      if(info.rules.some((rule)=>nameToString(rule.ctor)===ctor)){
        return {kind:'constructor',name:ctor,fields:[]};
      }
    }

    throw new Lean434EvaluationError(
      "recursor '"+nameToString(info.name)+
      "' major premise is not a supported constructor value",
    );
  }

  private evaluateRecursor(
    fn:Lean434RecursorFunction,
    args:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue {
    const info=fn.info;
    const majorIndex=
      info.numParams+
      info.numMotives+
      info.numMinors+
      info.numIndices;
    const major=this.normalizeMajor(args[majorIndex]!,info);
    const rule=info.rules.find(
      (candidate)=>nameToString(candidate.ctor)===major.name,
    );
    if(rule===undefined){
      throw new Lean434EvaluationError(
        "recursor '"+fn.name+
        "' has no rule for constructor '"+major.name+"'",
      );
    }
    if(major.fields.length<rule.nFields){
      throw new Lean434EvaluationError(
        "recursor '"+fn.name+
        "' constructor field count mismatch for '"+major.name+"'",
      );
    }

    const firstIndex=
      info.numParams+
      info.numMotives+
      info.numMinors;
    let value=this.evaluateWithLocals(
      instantiateExprLevels(
        rule.rhs,
        info.levelParams,
        fn.levels,
      ),
      [],
    );

    for(const arg of args.slice(0,firstIndex)){
      value=this.apply(value,arg);
    }
    for(const field of major.fields.slice(
      major.fields.length-rule.nFields,
    )){
      value=this.apply(value,field);
    }
    return value;
  }
}
