import { ConstantInfo, DefinitionInfo, DefinitionSafety, OpaqueInfo, TheoremInfo } from '../core/declaration.js';
import { ensureClosed } from '../core/checks.js';
import { Environment, KernelError } from '../core/environment.js';
import { Expr, exprToString } from '../core/expr.js';
import { LocalContext } from '../core/local-context.js';
import { Name, nameEq, nameToString } from '../core/name.js';
import { TypeChecker } from './type-checker.js';
import { NativeEvaluator } from './reduction/native.js';
import { isPrimitiveName } from './primitive-names.js';

function uniqueNames(xs:readonly Name[]):boolean{return xs.every((x,i)=>xs.findIndex(y=>nameEq(x,y))===i);}
function tcFor(env:Environment,lparams:readonly Name[],safety:DefinitionSafety='safe',nativeEvaluator?:NativeEvaluator):TypeChecker{return new TypeChecker(env,new LocalContext(),undefined,undefined,safety,lparams,false,nativeEvaluator);}

export class Kernel {
  readonly env:Environment;
  constructor(env=new Environment(),readonly nativeEvaluator?:NativeEvaluator){this.env=env;}
  private pre(name:Name,lparams:readonly Name[],type:Expr,safety:DefinitionSafety='safe'):TypeChecker{
    if(isPrimitiveName(name))throw new KernelError(`primitive '${nameToString(name)}' must go through primitive recognition`);
    if(this.env.has(name))throw new KernelError(`already declared '${nameToString(name)}'`);
    if(!uniqueNames(lparams))throw new KernelError(`duplicate universe parameter at '${nameToString(name)}'`);
    ensureClosed(type,`type of ${nameToString(name)}`);const tc=tcFor(this.env,lparams,safety,this.nativeEvaluator);tc.ensureSort(tc.check(type),type);return tc;
  }
  addAxiom(info:Extract<ConstantInfo,{kind:'axiom'}>):void{this.pre(info.name,info.levelParams,info.type,info.isUnsafe?'unsafe':'safe');this.env.add(info);}
  addDefinition(info:DefinitionInfo):void{
    const checkingSafety:DefinitionSafety=info.safety==='unsafe'?'unsafe':'safe';
    const tc=this.pre(info.name,info.levelParams,info.type,checkingSafety);ensureClosed(info.value,`value of ${nameToString(info.name)}`);
    if(info.safety==='unsafe'){
      // Lean permits unsafe/meta definitions to be recursive: add to a transactional clone before checking the body.
      const work=this.env.clone();work.add(info);const bodyTc=tcFor(work,info.levelParams,'unsafe',this.nativeEvaluator);const vt=bodyTc.check(info.value);if(!bodyTc.isDefEq(vt,info.type))throw new KernelError(`definition '${nameToString(info.name)}' value has type ${exprToString(vt)}, expected ${exprToString(info.type)}`);
    }else{
      const vt=tc.check(info.value);if(!tc.isDefEq(vt,info.type))throw new KernelError(`definition '${nameToString(info.name)}' value has type ${exprToString(vt)}, expected ${exprToString(info.type)}`);
    }
    this.env.add(info);
  }

  /** Lean 4.34 mutual definition admission. Mutual blocks are reserved for unsafe or partial definitions. */
  addMutualDefinitions(defs:readonly DefinitionInfo[]):void{
    if(defs.length===0)throw new KernelError('invalid empty mutual definition');
    const safety=defs[0]!.safety;if(safety==='safe')throw new KernelError('invalid mutual definition, declaration is not tagged as unsafe/partial');
    const lparams=defs[0]!.levelParams;
    const seen:Name[]=[];
    // Headers are checked against the pre-block environment, exactly as Lean does.
    for(const v of defs){
      if(v.safety!==safety)throw new KernelError('invalid mutual definition, declarations must have the same safety annotation');
      if(v.levelParams.length!==lparams.length||!v.levelParams.every((x,i)=>nameEq(x,lparams[i]!)))throw new KernelError('invalid mutual definition, declarations must have the same universe level parameters');
      if(seen.some(n=>nameEq(n,v.name)))throw new KernelError(`invalid mutual definition, duplicate declaration name '${nameToString(v.name)}'`);
      seen.push(v.name);this.pre(v.name,v.levelParams,v.type,safety);
    }
    const work=this.env.clone();for(const v of defs)work.add(v);
    const tc=tcFor(work,lparams,safety,this.nativeEvaluator);
    for(const v of defs){ensureClosed(v.value,`value of ${nameToString(v.name)}`);const vt=tc.check(v.value);if(!tc.isDefEq(vt,v.type))throw new KernelError(`definition '${nameToString(v.name)}' value has type ${exprToString(vt)}, expected ${exprToString(v.type)}`);}
    // Commit only after the entire block has checked, keeping admission transactional.
    for(const v of defs)this.env.add(v);
  }
  addTheorem(info:TheoremInfo):void{const tc=this.pre(info.name,info.levelParams,info.type,'safe');if(!tc.isProp(info.type))throw new KernelError(`theorem '${nameToString(info.name)}' type is not a proposition`);ensureClosed(info.value,`proof of ${nameToString(info.name)}`);const vt=tc.check(info.value);if(!tc.isDefEq(vt,info.type))throw new KernelError(`theorem '${nameToString(info.name)}' proof type mismatch`);this.env.add(info);}
  addOpaque(info:OpaqueInfo):void{const tc=this.pre(info.name,info.levelParams,info.type,'safe');ensureClosed(info.value,`opaque value of ${nameToString(info.name)}`);const vt=tc.check(info.value);if(!tc.isDefEq(vt,info.type))throw new KernelError(`opaque '${nameToString(info.name)}' value type mismatch`);this.env.add(info);}
}
