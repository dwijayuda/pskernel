import {
  Environment,
  TypeChecker,
  instantiateExprLevels,
  nameToString,
  type Expr,
  type Name,
  type Level,
  type RecursorInfo,
} from 'lean-ts-kernel';
import {
  findLean434EvaluatorExternForDeclaration,
  findLean434EvaluatorIntrinsicForDeclaration,
  findLean434JsExternForDeclaration,
  findLean434JsImplementedBy,
  findLean434JsIntrinsic,
  invokeLean434JsExtern,
  invokeLean434JsImplementedBy,
  invokeLean434JsIntrinsic,
  type Lean434DeclarationExternBinding,
  type Lean434EvaluatorExternBinding,
  type Lean434EvaluatorIntrinsicBinding,
  LeanRef,
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
  /**
   * Optional bootstrap/debug guard. Normal runtime execution is unbounded.
   * When set, fail closed if expression/application evaluation exceeds the
   * supplied number of evaluator steps.
   */
  readonly maxSteps?:number;
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

function describeRuntimeValue(
  value:Lean434RuntimeValue,
):string{
  if(value===undefined)return 'undefined';
  if(typeof value==='bigint')return 'bigint('+String(value)+')';
  if(typeof value==='string')return 'string';
  if(typeof value==='boolean')return 'boolean('+String(value)+')';
  if(Array.isArray(value))return 'array(length='+String(value.length)+')';
  if(isTaggedRuntimeValue(value)){
    if(value.kind==='constructor'){
      return "constructor("+value.name+", fields="+String(value.fields.length)+")";
    }
    if(value.kind==='primitive-function'){
      return "primitive-function("+value.name+", args="+
        String(value.args.length)+"/"+String(value.arity)+")";
    }
    if(value.kind==='constructor-function'){
      return "constructor-function("+value.name+", args="+
        String(value.args.length)+"/"+String(value.arity)+")";
    }
    if(value.kind==='recursor-function'){
      return "recursor-function("+value.name+", args="+
        String(value.args.length)+"/"+String(value.arity)+")";
    }
    if(value.kind==='closure')return 'closure';
    if(value.kind==='type')return 'type';
    if(value.kind==='proof')return "proof("+value.theorem+")";
    if(value.kind==='world-token')return 'world-token';
  }
  if(value instanceof LeanRef)return 'LeanRef';
  return 'unknown-runtime-value';
}

function runtimeArrayToLogicalList(
  array:readonly Lean434RuntimeValue[],
):Lean434ConstructorValue{
  let out:Lean434ConstructorValue={
    kind:'constructor',
    name:'List.nil',
    fields:[],
  };
  for(let i=array.length-1;i>=0;i--){
    out={
      kind:'constructor',
      name:'List.cons',
      fields:[array[i]!,out],
    };
  }
  return out;
}

function typeValue(expr:Expr):Lean434TypeValue {
  return {kind:'type',expr};
}

function adaptExternResult(
  declaration:string,
  binding:Lean434DeclarationExternBinding,
  value:unknown,
):Lean434RuntimeValue{
  switch(binding.resultAdapter??'identity'){
    case 'identity':
      return value as Lean434RuntimeValue;
    case 'decidable':
      if(typeof value!=='boolean'){
        throw new Lean434EvaluationError(
          "Decidable extern adapter expected boolean for '"+declaration+"'",
        );
      }
      return {
        kind:'constructor',
        name:value?'Decidable.isTrue':'Decidable.isFalse',
        // Runtime evidence is deliberately opaque. It is never admitted into
        // pskernel; the source declaration's logical model remains the proof
        // authority.
        fields:[{
          kind:'proof',
          theorem:'runtime-extern:'+declaration,
        }],
      };
  }
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
  private readonly checker:TypeChecker;
  private readonly constantStack:string[]=[];
  private evaluationSteps=0;
  private initializationDepth=0;

  constructor(
    readonly environment:Environment,
    readonly options:Lean434EvaluatorOptions={},
  ){
    this.checker=new TypeChecker(environment);
  }

  get isInitializing():boolean{
    return this.initializationDepth>0;
  }

  private findEnvironmentName(exact:string):Name|undefined{
    for(const info of this.environment.entries()){
      if(nameToString(info.name)===exact)return info.name;
    }
    return undefined;
  }

  evaluate(expr:Expr):Lean434RuntimeValue {
    return this.evaluateWithLocals(expr,[]);
  }

  private consumeStep(where:string):void{
    const max=this.options.maxSteps;
    if(max===undefined)return;
    this.evaluationSteps+=1;
    if(this.evaluationSteps<=max)return;
    const trace=this.constantStack.length===0
      ?''
      :' via '+this.constantStack.join(' -> ');
    throw new Lean434EvaluationError(
      'Lean runtime evaluation step budget exceeded at '+where+
      ' after '+String(max)+' steps'+trace,
    );
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

  runInitializerAction(
    action:Lean434RuntimeValue,
    state:Lean434RuntimeValue=LEAN434_WORLD_TOKEN,
  ):{
    readonly value:Lean434RuntimeValue;
    readonly state:Lean434RuntimeValue;
  }{
    this.initializationDepth++;
    try{
      return this.runIOAction(action,state);
    }finally{
      this.initializationDepth--;
    }
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
    this.consumeStep('expr:'+expr.kind);
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

  private applyLeanConstant(
    exact:string,
    args:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue{
    const name=this.findEnvironmentName(exact);
    if(name===undefined){
      throw new Lean434EvaluationError(
        "required Lean runtime declaration is missing: '"+exact+"'",
      );
    }
    let value=this.evaluateConstant(
      {kind:'const',name,levels:[]},
      [],
    );
    for(const arg of args)value=this.apply(value,arg);
    return value;
  }

  private optionPayload(
    value:Lean434RuntimeValue,
    where:string,
  ):Lean434RuntimeValue|undefined{
    if(
      !isTaggedRuntimeValue(value)
      ||value.kind!=='constructor'
    ){
      throw new Lean434EvaluationError(
        where+' did not return a Lean Option constructor',
      );
    }
    if(value.name==='Option.none'){
      if(value.fields.length!==0){
        throw new Lean434EvaluationError(
          where+' returned malformed Option.none',
        );
      }
      return undefined;
    }
    if(value.name==='Option.some'){
      if(value.fields.length!==1){
        throw new Lean434EvaluationError(
          where+' returned malformed Option.some',
        );
      }
      return value.fields[0]!;
    }
    throw new Lean434EvaluationError(
      where+" returned unexpected constructor '"+value.name+"'",
    );
  }

  private instantiateLevelMVarsNative(
    initialMctx:Lean434RuntimeValue,
    initialLevel:Lean434RuntimeValue,
  ):Lean434ConstructorValue{
    const visit=(
      mctx:Lean434RuntimeValue,
      level:Lean434RuntimeValue,
    ):{
      readonly mctx:Lean434RuntimeValue;
      readonly level:Lean434RuntimeValue;
    }=>{
      if(
        !isTaggedRuntimeValue(level)
        ||level.kind!=='constructor'
      ){
        throw new Lean434EvaluationError(
          'lean_instantiate_level_mvars received a non-Level runtime value',
        );
      }
      switch(level.name){
        case 'Lean.Level.zero':
        case 'Lean.Level.param':
          return {mctx,level};
        case 'Lean.Level.succ':{
          if(level.fields.length!==1){
            throw new Lean434EvaluationError(
              'Lean.Level.succ field count mismatch',
            );
          }
          const child=visit(mctx,level.fields[0]!);
          return {
            mctx:child.mctx,
            level:child.level===level.fields[0]
              ?level
              :{
                  kind:'constructor',
                  name:'Lean.Level.succ',
                  fields:[child.level],
                },
          };
        }
        case 'Lean.Level.max':
        case 'Lean.Level.imax':{
          if(level.fields.length!==2){
            throw new Lean434EvaluationError(
              level.name+' field count mismatch',
            );
          }
          const left=visit(mctx,level.fields[0]!);
          const right=visit(left.mctx,level.fields[1]!);
          return {
            mctx:right.mctx,
            level:
              left.level===level.fields[0]
              &&right.level===level.fields[1]
                ?level
                :{
                    kind:'constructor',
                    name:level.name,
                    fields:[left.level,right.level],
                  },
          };
        }
        case 'Lean.Level.mvar':{
          if(level.fields.length!==1){
            throw new Lean434EvaluationError(
              'Lean.Level.mvar field count mismatch',
            );
          }
          const mvarId=level.fields[0]!;
          const assigned=this.optionPayload(
            this.applyLeanConstant(
              'Lean.getLevelMVarAssignmentExp',
              [mctx,mvarId],
            ),
            'Lean.getLevelMVarAssignmentExp',
          );
          if(assigned===undefined)return {mctx,level};
          const normalized=visit(mctx,assigned);
          if(normalized.level===assigned)return normalized;
          const updated=this.applyLeanConstant(
            'Lean.assignLevelMVarExp',
            [normalized.mctx,mvarId,normalized.level],
          );
          return {mctx:updated,level:normalized.level};
        }
        default:
          throw new Lean434EvaluationError(
            "unexpected Lean.Level constructor '"+level.name+"'",
          );
      }
    };

    const result=visit(initialMctx,initialLevel);
    return {
      kind:'constructor',
      name:'Prod.mk',
      fields:[result.mctx,result.level],
    };
  }

  private liftRuntimeExprLooseBVars(
    expr:Lean434RuntimeValue,
    amount:bigint,
    cutoff:bigint=0n,
  ):Lean434RuntimeValue{
    if(amount===0n)return expr;
    if(!isTaggedRuntimeValue(expr)||expr.kind!=='constructor')return expr;
    switch(expr.name){
      case 'Lean.Expr.bvar':{
        if(expr.fields.length!==1)return expr;
        const index=expr.fields[0];
        if(typeof index!=='bigint')return expr;
        return index<cutoff
          ?expr
          :{
              kind:'constructor',
              name:'Lean.Expr.bvar',
              fields:[index+amount],
            };
      }
      case 'Lean.Expr.fvar':
      case 'Lean.Expr.mvar':
      case 'Lean.Expr.sort':
      case 'Lean.Expr.const':
      case 'Lean.Expr.lit':
        return expr;
      case 'Lean.Expr.app':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            this.liftRuntimeExprLooseBVars(expr.fields[0]!,amount,cutoff),
            this.liftRuntimeExprLooseBVars(expr.fields[1]!,amount,cutoff),
          ],
        };
      case 'Lean.Expr.mdata':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.liftRuntimeExprLooseBVars(expr.fields[1]!,amount,cutoff),
          ],
        };
      case 'Lean.Expr.proj':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            expr.fields[1]!,
            this.liftRuntimeExprLooseBVars(expr.fields[2]!,amount,cutoff),
          ],
        };
      case 'Lean.Expr.lam':
      case 'Lean.Expr.forallE':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.liftRuntimeExprLooseBVars(expr.fields[1]!,amount,cutoff),
            this.liftRuntimeExprLooseBVars(
              expr.fields[2]!,
              amount,
              cutoff+1n,
            ),
            expr.fields[3]!,
          ],
        };
      case 'Lean.Expr.letE':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.liftRuntimeExprLooseBVars(expr.fields[1]!,amount,cutoff),
            this.liftRuntimeExprLooseBVars(expr.fields[2]!,amount,cutoff),
            this.liftRuntimeExprLooseBVars(
              expr.fields[3]!,
              amount,
              cutoff+1n,
            ),
            expr.fields[4]!,
          ],
        };
      default:
        return expr;
    }
  }

  private instantiateRuntimeExprBVar(
    expr:Lean434RuntimeValue,
    value:Lean434RuntimeValue,
    depth:bigint=0n,
  ):Lean434RuntimeValue{
    if(!isTaggedRuntimeValue(expr)||expr.kind!=='constructor')return expr;
    switch(expr.name){
      case 'Lean.Expr.bvar':{
        if(expr.fields.length!==1)return expr;
        const index=expr.fields[0];
        if(typeof index!=='bigint')return expr;
        if(index<depth)return expr;
        if(index===depth){
          return this.liftRuntimeExprLooseBVars(value,depth);
        }
        return {
          kind:'constructor',
          name:'Lean.Expr.bvar',
          fields:[index-1n],
        };
      }
      case 'Lean.Expr.fvar':
      case 'Lean.Expr.mvar':
      case 'Lean.Expr.sort':
      case 'Lean.Expr.const':
      case 'Lean.Expr.lit':
        return expr;
      case 'Lean.Expr.app':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            this.instantiateRuntimeExprBVar(expr.fields[0]!,value,depth),
            this.instantiateRuntimeExprBVar(expr.fields[1]!,value,depth),
          ],
        };
      case 'Lean.Expr.mdata':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.instantiateRuntimeExprBVar(expr.fields[1]!,value,depth),
          ],
        };
      case 'Lean.Expr.proj':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            expr.fields[1]!,
            this.instantiateRuntimeExprBVar(expr.fields[2]!,value,depth),
          ],
        };
      case 'Lean.Expr.lam':
      case 'Lean.Expr.forallE':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.instantiateRuntimeExprBVar(expr.fields[1]!,value,depth),
            this.instantiateRuntimeExprBVar(
              expr.fields[2]!,
              value,
              depth+1n,
            ),
            expr.fields[3]!,
          ],
        };
      case 'Lean.Expr.letE':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.instantiateRuntimeExprBVar(expr.fields[1]!,value,depth),
            this.instantiateRuntimeExprBVar(expr.fields[2]!,value,depth),
            this.instantiateRuntimeExprBVar(
              expr.fields[3]!,
              value,
              depth+1n,
            ),
            expr.fields[4]!,
          ],
        };
      default:
        return expr;
    }
  }

  private betaApplyRuntimeExpr(
    fn:Lean434RuntimeValue,
    args:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue{
    let result=fn;
    let index=0;
    while(
      index<args.length
      &&isTaggedRuntimeValue(result)
      &&result.kind==='constructor'
      &&result.name==='Lean.Expr.lam'
      &&result.fields.length===4
    ){
      result=this.instantiateRuntimeExprBVar(
        result.fields[2]!,
        args[index]!,
      );
      index+=1;
    }
    while(index<args.length){
      result={
        kind:'constructor',
        name:'Lean.Expr.app',
        fields:[result,args[index]!],
      };
      index+=1;
    }
    return result;
  }

  private runtimeNameStructuralKey(
    value:Lean434RuntimeValue,
  ):string{
    if(
      !isTaggedRuntimeValue(value)
      ||value.kind!=='constructor'
    ){
      throw new Lean434EvaluationError(
        'runtime Lean.Name is not a constructor',
      );
    }
    switch(value.name){
      case 'Lean.Name.anonymous':
        if(value.fields.length!==0){
          throw new Lean434EvaluationError(
            'Lean.Name.anonymous field count mismatch',
          );
        }
        return 'a';
      case 'Lean.Name.str':{
        if(value.fields.length!==2||typeof value.fields[1]!=='string'){
          throw new Lean434EvaluationError(
            'Lean.Name.str runtime shape mismatch',
          );
        }
        const suffix=value.fields[1] as string;
        return this.runtimeNameStructuralKey(value.fields[0]!)+
          '/s:'+String(suffix.length)+':'+suffix;
      }
      case 'Lean.Name.num':{
        if(value.fields.length!==2||typeof value.fields[1]!=='bigint'){
          throw new Lean434EvaluationError(
            'Lean.Name.num runtime shape mismatch',
          );
        }
        return this.runtimeNameStructuralKey(value.fields[0]!)+
          '/n:'+String(value.fields[1]);
      }
      default:
        throw new Lean434EvaluationError(
          "unexpected runtime Lean.Name constructor '"+value.name+"'",
        );
    }
  }

  private runtimeIdStructuralKey(
    value:Lean434RuntimeValue,
    ctorName:string,
  ):string{
    if(
      !isTaggedRuntimeValue(value)
      ||value.kind!=='constructor'
      ||value.name!==ctorName
      ||value.fields.length!==1
    ){
      throw new Lean434EvaluationError(
        "runtime id is not '"+ctorName+"'",
      );
    }
    return this.runtimeNameStructuralKey(value.fields[0]!);
  }

  private runtimeExprHasMVar(
    expr:Lean434RuntimeValue,
  ):boolean{
    if(!isTaggedRuntimeValue(expr)||expr.kind!=='constructor')return false;
    switch(expr.name){
      case 'Lean.Expr.mvar':
        return true;
      case 'Lean.Expr.app':
        return this.runtimeExprHasMVar(expr.fields[0]!)
          ||this.runtimeExprHasMVar(expr.fields[1]!);
      case 'Lean.Expr.mdata':
        return this.runtimeExprHasMVar(expr.fields[1]!);
      case 'Lean.Expr.proj':
        return this.runtimeExprHasMVar(expr.fields[2]!);
      case 'Lean.Expr.lam':
      case 'Lean.Expr.forallE':
        return this.runtimeExprHasMVar(expr.fields[1]!)
          ||this.runtimeExprHasMVar(expr.fields[2]!);
      case 'Lean.Expr.letE':
        return this.runtimeExprHasMVar(expr.fields[1]!)
          ||this.runtimeExprHasMVar(expr.fields[2]!)
          ||this.runtimeExprHasMVar(expr.fields[3]!);
      default:
        return false;
    }
  }

  private runtimeExprAppView(
    expr:Lean434RuntimeValue,
  ):{
    readonly fn:Lean434RuntimeValue;
    readonly args:readonly Lean434RuntimeValue[];
  }{
    const reversed:Lean434RuntimeValue[]=[];
    let current=expr;
    while(
      isTaggedRuntimeValue(current)
      &&current.kind==='constructor'
      &&current.name==='Lean.Expr.app'
      &&current.fields.length===2
    ){
      reversed.push(current.fields[1]!);
      current=current.fields[0]!;
    }
    return {fn:current,args:reversed.reverse()};
  }

  private runtimeExprMkAppN(
    fn:Lean434RuntimeValue,
    args:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue{
    let result=fn;
    for(const arg of args){
      result={
        kind:'constructor',
        name:'Lean.Expr.app',
        fields:[result,arg],
      };
    }
    return result;
  }

  private substituteRuntimeExprFVars(
    expr:Lean434RuntimeValue,
    substitution:ReadonlyMap<string,Lean434RuntimeValue>,
    depth:bigint=0n,
  ):Lean434RuntimeValue{
    if(!isTaggedRuntimeValue(expr)||expr.kind!=='constructor')return expr;
    switch(expr.name){
      case 'Lean.Expr.fvar':{
        if(expr.fields.length!==1)return expr;
        const key=this.runtimeIdStructuralKey(
          expr.fields[0]!,
          'Lean.FVarId.mk',
        );
        const replacement=substitution.get(key);
        return replacement===undefined
          ?expr
          :this.liftRuntimeExprLooseBVars(replacement,depth);
      }
      case 'Lean.Expr.bvar':
      case 'Lean.Expr.mvar':
      case 'Lean.Expr.sort':
      case 'Lean.Expr.const':
      case 'Lean.Expr.lit':
        return expr;
      case 'Lean.Expr.app':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            this.substituteRuntimeExprFVars(
              expr.fields[0]!,
              substitution,
              depth,
            ),
            this.substituteRuntimeExprFVars(
              expr.fields[1]!,
              substitution,
              depth,
            ),
          ],
        };
      case 'Lean.Expr.mdata':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.substituteRuntimeExprFVars(
              expr.fields[1]!,
              substitution,
              depth,
            ),
          ],
        };
      case 'Lean.Expr.proj':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            expr.fields[1]!,
            this.substituteRuntimeExprFVars(
              expr.fields[2]!,
              substitution,
              depth,
            ),
          ],
        };
      case 'Lean.Expr.lam':
      case 'Lean.Expr.forallE':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.substituteRuntimeExprFVars(
              expr.fields[1]!,
              substitution,
              depth,
            ),
            this.substituteRuntimeExprFVars(
              expr.fields[2]!,
              substitution,
              depth+1n,
            ),
            expr.fields[3]!,
          ],
        };
      case 'Lean.Expr.letE':
        return {
          kind:'constructor',
          name:expr.name,
          fields:[
            expr.fields[0]!,
            this.substituteRuntimeExprFVars(
              expr.fields[1]!,
              substitution,
              depth,
            ),
            this.substituteRuntimeExprFVars(
              expr.fields[2]!,
              substitution,
              depth,
            ),
            this.substituteRuntimeExprFVars(
              expr.fields[3]!,
              substitution,
              depth+1n,
            ),
            expr.fields[4]!,
          ],
        };
      default:
        return expr;
    }
  }

  private instantiateExprMVarsNative(
    initialMctx:Lean434RuntimeValue,
    initialExpr:Lean434RuntimeValue,
  ):Lean434ConstructorValue{
    const visitLevelList=(
      mctx:Lean434RuntimeValue,
      levels:Lean434RuntimeValue,
    ):{
      readonly mctx:Lean434RuntimeValue;
      readonly levels:Lean434RuntimeValue;
    }=>{
      this.consumeStep('lean_instantiate_expr_mvars.levels');
      if(
        !isTaggedRuntimeValue(levels)
        ||levels.kind!=='constructor'
      ){
        throw new Lean434EvaluationError(
          'Lean Expr.const level list is not a constructor',
        );
      }
      if(levels.name==='List.nil'){
        if(levels.fields.length!==0){
          throw new Lean434EvaluationError(
            'Lean Expr.const level List.nil field count mismatch',
          );
        }
        return {mctx,levels};
      }
      if(levels.name!=='List.cons'||levels.fields.length!==2){
        throw new Lean434EvaluationError(
          "unexpected Lean level-list constructor '"+levels.name+"'",
        );
      }
      const headResult=this.instantiateLevelMVarsNative(
        mctx,
        levels.fields[0]!,
      );
      const headMctx=headResult.fields[0]!;
      const head=headResult.fields[1]!;
      const tail=visitLevelList(headMctx,levels.fields[1]!);
      return {
        mctx:tail.mctx,
        levels:
          head===levels.fields[0]
          &&tail.levels===levels.fields[1]
            ?levels
            :{
                kind:'constructor',
                name:'List.cons',
                fields:[head,tail.levels],
              },
      };
    };

    const visit=(
      mctx:Lean434RuntimeValue,
      expr:Lean434RuntimeValue,
    ):{
      readonly mctx:Lean434RuntimeValue;
      readonly expr:Lean434RuntimeValue;
    }=>{
      this.consumeStep('lean_instantiate_expr_mvars.expr');
      if(
        !isTaggedRuntimeValue(expr)
        ||expr.kind!=='constructor'
      ){
        throw new Lean434EvaluationError(
          'lean_instantiate_expr_mvars received a non-Expr runtime value',
        );
      }
      switch(expr.name){
        case 'Lean.Expr.bvar':
        case 'Lean.Expr.fvar':
        case 'Lean.Expr.lit':
          return {mctx,expr};
        case 'Lean.Expr.sort':{
          if(expr.fields.length!==1){
            throw new Lean434EvaluationError(
              'Lean.Expr.sort field count mismatch',
            );
          }
          const result=this.instantiateLevelMVarsNative(
            mctx,
            expr.fields[0]!,
          );
          const level=result.fields[1]!;
          return {
            mctx:result.fields[0]!,
            expr:level===expr.fields[0]
              ?expr
              :{
                  kind:'constructor',
                  name:'Lean.Expr.sort',
                  fields:[level],
                },
          };
        }
        case 'Lean.Expr.const':{
          if(expr.fields.length!==2){
            throw new Lean434EvaluationError(
              'Lean.Expr.const field count mismatch',
            );
          }
          const levels=visitLevelList(mctx,expr.fields[1]!);
          return {
            mctx:levels.mctx,
            expr:levels.levels===expr.fields[1]
              ?expr
              :{
                  kind:'constructor',
                  name:'Lean.Expr.const',
                  fields:[expr.fields[0]!,levels.levels],
                },
          };
        }
        case 'Lean.Expr.mvar':{
          if(expr.fields.length!==1){
            throw new Lean434EvaluationError(
              'Lean.Expr.mvar field count mismatch',
            );
          }
          const mvarId=expr.fields[0]!;
          const assigned=this.optionPayload(
            this.applyLeanConstant(
              'Lean.MetavarContext.getExprAssignmentExp',
              [mctx,mvarId],
            ),
            'Lean.MetavarContext.getExprAssignmentExp',
          );
          if(assigned===undefined){
            // Pass 1 of Lean's native instantiate_mvars leaves unassigned and
            // delayed-assigned bare metavariables in place. Delayed
            // assignments are resolved only when encountered as a sufficiently
            // applied function in the application case below.
            return {mctx,expr};
          }
          const normalized=visit(mctx,assigned);
          let nextMctx=normalized.mctx;
          if(normalized.expr!==assigned){
            nextMctx=this.applyLeanConstant(
              'Lean.assignExp',
              [nextMctx,mvarId,normalized.expr],
            );
          }
          return {mctx:nextMctx,expr:normalized.expr};
        }
        case 'Lean.Expr.mdata':{
          if(expr.fields.length!==2){
            throw new Lean434EvaluationError(
              'Lean.Expr.mdata field count mismatch',
            );
          }
          const body=visit(mctx,expr.fields[1]!);
          return {
            mctx:body.mctx,
            expr:body.expr===expr.fields[1]
              ?expr
              :{
                  kind:'constructor',
                  name:'Lean.Expr.mdata',
                  fields:[expr.fields[0]!,body.expr],
                },
          };
        }
        case 'Lean.Expr.proj':{
          if(expr.fields.length!==3){
            throw new Lean434EvaluationError(
              'Lean.Expr.proj field count mismatch',
            );
          }
          const target=visit(mctx,expr.fields[2]!);
          return {
            mctx:target.mctx,
            expr:target.expr===expr.fields[2]
              ?expr
              :{
                  kind:'constructor',
                  name:'Lean.Expr.proj',
                  fields:[expr.fields[0]!,expr.fields[1]!,target.expr],
                },
          };
        }
        case 'Lean.Expr.app':{
          if(expr.fields.length!==2){
            throw new Lean434EvaluationError(
              'Lean.Expr.app field count mismatch',
            );
          }

          const spine=this.runtimeExprAppView(expr);
          if(
            isTaggedRuntimeValue(spine.fn)
            &&spine.fn.kind==='constructor'
            &&spine.fn.name==='Lean.Expr.mvar'
            &&spine.fn.fields.length===1
          ){
            const mvarId=spine.fn.fields[0]!;
            const directAssignment=this.optionPayload(
              this.applyLeanConstant(
                'Lean.MetavarContext.getExprAssignmentExp',
                [mctx,mvarId],
              ),
              'Lean.MetavarContext.getExprAssignmentExp',
            );
            if(directAssignment===undefined){
              const delayed=this.optionPayload(
                this.applyLeanConstant(
                  'Lean.MetavarContext.getDelayedMVarAssignmentExp',
                  [mctx,mvarId],
                ),
                'Lean.MetavarContext.getDelayedMVarAssignmentExp',
              );
              if(delayed!==undefined){
                let nextMctx=mctx;
                const normalizedArgs:Lean434RuntimeValue[]=[];
                for(const argExpr of spine.args){
                  const normalized=visit(nextMctx,argExpr);
                  nextMctx=normalized.mctx;
                  normalizedArgs.push(normalized.expr);
                }

                if(
                  !isTaggedRuntimeValue(delayed)
                  ||delayed.kind!=='constructor'
                  ||delayed.name!=='Lean.DelayedMetavarAssignment.mk'
                  ||delayed.fields.length!==2
                ){
                  throw new Lean434EvaluationError(
                    'delayed metavariable assignment has malformed runtime shape',
                  );
                }
                const fvars=delayed.fields[0]!;
                const pendingId=delayed.fields[1]!;
                if(!Array.isArray(fvars)){
                  throw new Lean434EvaluationError(
                    'delayed metavariable fvars are not a runtime Array',
                  );
                }

                if(fvars.length<=normalizedArgs.length){
                  const pendingAssignment=this.optionPayload(
                    this.applyLeanConstant(
                      'Lean.MetavarContext.getExprAssignmentExp',
                      [nextMctx,pendingId],
                    ),
                    'Lean.MetavarContext.getExprAssignmentExp',
                  );
                  if(pendingAssignment!==undefined){
                    const normalizedPending=visit(
                      nextMctx,
                      pendingAssignment,
                    );
                    nextMctx=normalizedPending.mctx;
                    if(normalizedPending.expr!==pendingAssignment){
                      nextMctx=this.applyLeanConstant(
                        'Lean.assignExp',
                        [nextMctx,pendingId,normalizedPending.expr],
                      );
                    }

                    // The native implementation crosses into delayed
                    // substitution only when the pending assignment is
                    // resolvable. For the first JS slice, "resolvable" means
                    // normalization leaves no expression metavariables. Nested
                    // delayed applications that can be resolved are normalized
                    // recursively by visit above.
                    if(!this.runtimeExprHasMVar(normalizedPending.expr)){
                      const substitution=
                        new Map<string,Lean434RuntimeValue>();
                      for(let index=0;index<fvars.length;index+=1){
                        const fvarExpr=fvars[index]!;
                        if(
                          !isTaggedRuntimeValue(fvarExpr)
                          ||fvarExpr.kind!=='constructor'
                          ||fvarExpr.name!=='Lean.Expr.fvar'
                          ||fvarExpr.fields.length!==1
                        ){
                          throw new Lean434EvaluationError(
                            'delayed metavariable fvar list contains a non-fvar',
                          );
                        }
                        const key=this.runtimeIdStructuralKey(
                          fvarExpr.fields[0]!,
                          'Lean.FVarId.mk',
                        );
                        substitution.set(key,normalizedArgs[index]!);
                      }
                      const substituted=this.substituteRuntimeExprFVars(
                        normalizedPending.expr,
                        substitution,
                      );
                      const reduced=this.betaApplyRuntimeExpr(
                        substituted,
                        normalizedArgs.slice(fvars.length),
                      );
                      return visit(nextMctx,reduced);
                    }
                  }
                }

                return {
                  mctx:nextMctx,
                  expr:this.runtimeExprMkAppN(
                    spine.fn,
                    normalizedArgs,
                  ),
                };
              }
            }
          }

          const originalFn=expr.fields[0]!;
          const fn=visit(mctx,originalFn);
          const arg=visit(fn.mctx,expr.fields[1]!);
          if(
            isTaggedRuntimeValue(originalFn)
            &&originalFn.kind==='constructor'
            &&originalFn.name==='Lean.Expr.mvar'
            &&isTaggedRuntimeValue(fn.expr)
            &&fn.expr.kind==='constructor'
            &&fn.expr.name==='Lean.Expr.lam'
          ){
            const reduced=this.betaApplyRuntimeExpr(
              fn.expr,
              [arg.expr],
            );
            return visit(arg.mctx,reduced);
          }
          return {
            mctx:arg.mctx,
            expr:
              fn.expr===originalFn
              &&arg.expr===expr.fields[1]
                ?expr
                :{
                    kind:'constructor',
                    name:'Lean.Expr.app',
                    fields:[fn.expr,arg.expr],
                  },
          };
        }
        case 'Lean.Expr.lam':
        case 'Lean.Expr.forallE':{
          if(expr.fields.length!==4){
            throw new Lean434EvaluationError(
              expr.name+' field count mismatch',
            );
          }
          const domain=visit(mctx,expr.fields[1]!);
          const body=visit(domain.mctx,expr.fields[2]!);
          return {
            mctx:body.mctx,
            expr:
              domain.expr===expr.fields[1]
              &&body.expr===expr.fields[2]
                ?expr
                :{
                    kind:'constructor',
                    name:expr.name,
                    fields:[
                      expr.fields[0]!,
                      domain.expr,
                      body.expr,
                      expr.fields[3]!,
                    ],
                  },
          };
        }
        case 'Lean.Expr.letE':{
          if(expr.fields.length!==5){
            throw new Lean434EvaluationError(
              'Lean.Expr.letE field count mismatch',
            );
          }
          const type=visit(mctx,expr.fields[1]!);
          const value=visit(type.mctx,expr.fields[2]!);
          const body=visit(value.mctx,expr.fields[3]!);
          return {
            mctx:body.mctx,
            expr:
              type.expr===expr.fields[1]
              &&value.expr===expr.fields[2]
              &&body.expr===expr.fields[3]
                ?expr
                :{
                    kind:'constructor',
                    name:'Lean.Expr.letE',
                    fields:[
                      expr.fields[0]!,
                      type.expr,
                      value.expr,
                      body.expr,
                      expr.fields[4]!,
                    ],
                  },
          };
        }
        default:
          throw new Lean434EvaluationError(
            "unexpected Lean.Expr constructor '"+expr.name+"'",
          );
      }
    };

    const result=visit(initialMctx,initialExpr);
    return {
      kind:'constructor',
      name:'Prod.mk',
      fields:[result.mctx,result.expr],
    };
  }

  private invokeEvaluatorIntrinsic(
    binding:Lean434EvaluatorIntrinsicBinding,
    args:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue{
    if(args.length!==binding.arity){
      throw new Lean434EvaluationError(
        "evaluator intrinsic arity mismatch for '"+
        binding.leanDeclaration+"'",
      );
    }
    switch(binding.adapter){
      case 'instantiate-mvars-core':{
        const native=this.instantiateExprMVarsNative(args[0]!,args[1]!);
        if(
          !isTaggedRuntimeValue(native)
          ||native.kind!=='constructor'
          ||native.name!=='Prod.mk'
          ||native.fields.length!==2
        ){
          throw new Lean434EvaluationError(
            'instantiateExprMVars native adapter returned malformed pair',
          );
        }
        return {
          kind:'constructor',
          name:'Prod.mk',
          fields:[native.fields[1]!,native.fields[0]!],
        };
      }
    }
  }

  private invokeEvaluatorExtern(
    binding:Lean434EvaluatorExternBinding,
    args:readonly Lean434RuntimeValue[],
  ):Lean434RuntimeValue{
    if(args.length!==binding.arity){
      throw new Lean434EvaluationError(
        "evaluator extern arity mismatch for '"+
        binding.leanDeclaration+"'",
      );
    }
    switch(binding.adapter){
      case 'instantiate-level-mvars':
        return this.instantiateLevelMVarsNative(args[0]!,args[1]!);
      case 'instantiate-expr-mvars':
        return this.instantiateExprMVarsNative(args[0]!,args[1]!);
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

    const evaluatorIntrinsic=
      findLean434EvaluatorIntrinsicForDeclaration(name);
    if(evaluatorIntrinsic!==undefined){
      return primitive(
        name,
        evaluatorIntrinsic.arity,
        (args)=>this.invokeEvaluatorIntrinsic(
          evaluatorIntrinsic,
          args,
        ),
      );
    }

    const intrinsic=findLean434JsIntrinsic(name);
    if(intrinsic!==undefined){
      return primitive(
        name,
        intrinsic.arity,
        (args)=>invokeLean434JsIntrinsic(
          intrinsic,
          args,
        ) as Lean434RuntimeValue,
      );
    }

    const metadataImplementedBy=
      this.options.metadata?.implementedByFor(name);
    const metadataRuntimeTarget=
      this.options.metadata?.runtimeTargetFor(name);
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

    const compilerRuntimeTarget=
      metadataRuntimeTarget
      ??(metadataImplementedBy===undefined
        ?undefined
        :{
            declaration:name,
            kind:'implemented_by' as const,
            implementation:metadataImplementedBy.implementation,
          });
    if(compilerRuntimeTarget!==undefined){
      if(compilerRuntimeTarget.implementation===name){
        throw new Lean434EvaluationError(
          "compiler runtime metadata self-cycle for '"+name+"'",
        );
      }
      const implName=this.findEnvironmentName(
        compilerRuntimeTarget.implementation,
      );
      if(implName===undefined){
        throw new Lean434EvaluationError(
          "compiler runtime target is missing from the replayed environment: '"+
          name+"' -> '"+compilerRuntimeTarget.implementation+
          "' ("+compilerRuntimeTarget.kind+")",
        );
      }
      // Lean has already checked the logical declaration independently.
      // Runtime execution follows the compiler target exactly as Lean does;
      // this does not make the implementation proof evidence.
      return this.evaluateConstant(
        {
          kind:'const',
          name:implName,
          levels:expr.levels,
        },
        locals,
      );
    }

    const evaluatorExtern=
      findLean434EvaluatorExternForDeclaration(name);
    if(evaluatorExtern!==undefined){
      const metadataExtern=this.options.metadata?.externFor(name);
      if(metadataExtern!==undefined){
        const selected=metadataExtern.entries.find(
          (entry)=>entry.kind==='standard'&&entry.backend==='all',
        );
        if(
          selected===undefined
          ||selected.kind!=='standard'
          ||selected.symbol!==evaluatorExtern.leanSymbol
        ){
          throw new Lean434EvaluationError(
            "evaluator extern metadata mismatch for '"+name+"': expected '"+
            evaluatorExtern.leanSymbol+"'",
          );
        }
      }
      return primitive(
        name,
        evaluatorExtern.arity,
        (args)=>this.invokeEvaluatorExtern(evaluatorExtern,args),
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
      if(runtimeBinding.leanSymbol==='lean_io_initializing'){
        return primitive(
          name+'#state',
          1,
          (stateArgs)=>({
            kind:'constructor',
            name:'ST.Out.mk',
            fields:[this.isInitializing,stateArgs[0]!],
          }),
        );
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
                const value=adaptExternResult(
                  name,
                  runtimeBinding,
                  invokeLean434JsExtern(
                    runtimeBinding.leanSymbol,
                    runtimeArgs,
                  ),
                );
                return {
                  kind:'constructor',
                  name:'ST.Out.mk',
                  fields:[value,state],
                };
              },
            );
          }
          return adaptExternResult(
            name,
            runtimeBinding,
            invokeLean434JsExtern(
              runtimeBinding.leanSymbol,
              runtimeArgs,
            ),
          );
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
      &&this.checker.isProp(info.type)
    ){
      // All proof terms are erased from executable code. This includes
      // ordinary theorems as well as unsafe proof placeholders such as
      // lcProof that appear in compiler-oriented Array/List operations.
      return {kind:'proof',theorem:name};
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
        this.constantStack.push(name);
        try{
          return this.evaluateWithLocals(body,locals);
        }finally{
          this.constantStack.pop();
        }
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
        this.constantStack.push(name);
        try{
          return this.evaluateWithLocals(body,locals);
        }finally{
          this.constantStack.pop();
        }
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
      case 'axiom':{
        const trace=this.constantStack.length===0
          ?''
          :' via '+this.constantStack.join(' -> ');
        throw new Lean434EvaluationError(
          "axiom has no JavaScript runtime implementation: '"+name+"'"+trace,
        );
      }
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
    this.consumeStep('apply');
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

    if(
      isTaggedRuntimeValue(value)
      &&value.kind==='proof'
      &&info.rules.length===1
      &&info.rules[0]!.nFields===0
    ){
      // Executable Lean erases proof objects. For proof recursors whose only
      // constructor carries no runtime fields (notably Eq.rec), the erased
      // major premise can therefore be represented by that sole constructor.
      return {
        kind:'constructor',
        name:nameToString(info.rules[0]!.ctor),
        fields:[],
      };
    }

    if(Array.isArray(value)){
      const arrayCtor=info.rules.find(
        (rule)=>nameToString(rule.ctor)==='Array.mk',
      );
      if(arrayCtor!==undefined){
        // Lean's logical Array is a one-field structure around List. Native
        // execution stores arrays compactly; nested inductive recursors such
        // as T.rec_1 are generated against the logical Array.mk shape.
        return {
          kind:'constructor',
          name:'Array.mk',
          fields:[runtimeArrayToLogicalList(value)],
        };
      }
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
      "' major premise is not a supported constructor value: "+
      describeRuntimeValue(value),
    );
  }

  private materializeComputedFieldMajor(
    major:Lean434ConstructorValue,
    info:RecursorInfo,
    fn:Lean434RecursorFunction,
    args:readonly Lean434RuntimeValue[],
  ):Lean434ConstructorValue|undefined{
    const expectedCtor=major.name+'._impl';
    if(
      !info.rules.some(
        (rule)=>nameToString(rule.ctor)===expectedCtor,
      )
    ){
      return undefined;
    }

    const runtimeTarget=
      this.options.metadata?.runtimeTargetFor(major.name)
      ??this.options.metadata?.implementedByFor(major.name);
    if(runtimeTarget===undefined)return undefined;

    const implName=this.findEnvironmentName(runtimeTarget.implementation);
    if(implName===undefined){
      throw new Lean434EvaluationError(
        "computed-field constructor runtime target is missing: '"+
        major.name+"' -> '"+runtimeTarget.implementation+"'",
      );
    }
    const implInfo=this.environment.find(implName);
    if(implInfo===undefined||!('levelParams' in implInfo)){
      throw new Lean434EvaluationError(
        "computed-field constructor runtime target has no declaration info: '"+
        runtimeTarget.implementation+"'",
      );
    }
    const levelCount=implInfo.levelParams.length;
    if(levelCount>fn.levels.length){
      throw new Lean434EvaluationError(
        "computed-field constructor runtime target has incompatible universe arity: '"+
        runtimeTarget.implementation+"'",
      );
    }

    let value=this.evaluateConstant(
      {
        kind:'const',
        name:implName,
        levels:fn.levels.slice(0,levelCount),
      },
      [],
    );
    for(const param of args.slice(0,info.numParams)){
      value=this.apply(value,param);
    }
    for(const field of major.fields){
      value=this.apply(value,field);
    }
    if(
      !isTaggedRuntimeValue(value)
      ||value.kind!=='constructor'
      ||value.name!==expectedCtor
    ){
      throw new Lean434EvaluationError(
        "computed-field constructor runtime target did not materialize '"+
        expectedCtor+"' from '"+major.name+"'",
      );
    }
    return value;
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
    let major=this.normalizeMajor(args[majorIndex]!,info);
    let rule=info.rules.find(
      (candidate)=>nameToString(candidate.ctor)===major.name,
    );
    if(rule===undefined){
      const materialized=this.materializeComputedFieldMajor(
        major,
        info,
        fn,
        args,
      );
      if(materialized!==undefined){
        major=materialized;
        rule=info.rules.find(
          (candidate)=>nameToString(candidate.ctor)===major.name,
        );
      }
    }
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
