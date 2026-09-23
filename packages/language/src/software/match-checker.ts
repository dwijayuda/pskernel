import type {V061Expr,V061Pattern} from '@proofscript/syntax';
import type {CheckSoftwareExpr,SoftwareExpressionContext} from './check-context.js';
import {withSoftwareLocal} from './check-context.js';
import type {
  CheckedSoftwareExpr,
  CheckedSoftwareMatchAlternative,
  CheckedSoftwarePattern,
  CheckedSoftwareInductive,
  SoftwareType,
} from './types.js';
import {softwareTypeEquals} from './types.js';

function checkBranchType(
  body:CheckedSoftwareExpr,
  current:SoftwareType|undefined,
):SoftwareType {
  if(current!==undefined&&!softwareTypeEquals(body.resultType,current)){
    throw new Error('PS_CHECK_MATCH_BRANCH: match alternatives must have the same type');
  }
  return body.resultType;
}

function checkBoolMatch(
  expr:Extract<V061Expr,{kind:'match'}>,
  scrutinee:CheckedSoftwareExpr,
  context:SoftwareExpressionContext,
  expected:SoftwareType|undefined,
  check:CheckSoftwareExpr,
):CheckedSoftwareExpr {
  const alternatives:CheckedSoftwareMatchAlternative[]=[];
  let seenTrue=false;
  let seenFalse=false;
  let seenWildcard=false;
  let branchType:SoftwareType|undefined;

  for(let index=0;index<expr.alternatives.length;index+=1){
    const source=expr.alternatives[index]!;
    let pattern:CheckedSoftwarePattern;
    if(source.pattern.kind==='constructor'){
      throw new Error('PS_CHECK_MATCH_PATTERN: constructor pattern cannot match Bool');
    }
    if(source.pattern.kind==='wildcard'){
      if(seenWildcard)throw new Error('PS_CHECK_MATCH_DUPLICATE: duplicate wildcard alternative');
      if(index!==expr.alternatives.length-1){
        throw new Error('PS_CHECK_MATCH_PATTERN: wildcard must be the final alternative');
      }
      seenWildcard=true;
      pattern={kind:'wildcard'};
    }else{
      if(source.pattern.value){
        if(seenTrue)throw new Error('PS_CHECK_MATCH_DUPLICATE: duplicate true alternative');
        seenTrue=true;
      }else{
        if(seenFalse)throw new Error('PS_CHECK_MATCH_DUPLICATE: duplicate false alternative');
        seenFalse=true;
      }
      pattern={kind:'bool',value:source.pattern.value};
    }

    const body=check(source.body,context,branchType??expected);
    branchType=checkBranchType(body,branchType);
    alternatives.push({pattern,body});
  }

  if(!seenWildcard&&(!seenTrue||!seenFalse)){
    throw new Error('PS_CHECK_MATCH_EXHAUSTIVE: Bool match requires true and false alternatives');
  }
  if(branchType===undefined)throw new Error('PS_CHECK_MATCH_EMPTY: match has no alternatives');
  return {kind:'match',scrutinee,alternatives,resultType:branchType};
}

function normalizeConstructorPattern(
  pattern:Extract<V061Pattern,{kind:'constructor'}>,
  inductive:CheckedSoftwareInductive,
):string {
  if(pattern.name.startsWith('.'))return inductive.name+pattern.name;
  if(pattern.name.includes('.'))return pattern.name;
  return inductive.name+'.'+pattern.name;
}

function checkInductiveMatch(
  expr:Extract<V061Expr,{kind:'match'}>,
  scrutinee:CheckedSoftwareExpr,
  inductive:CheckedSoftwareInductive,
  context:SoftwareExpressionContext,
  expected:SoftwareType|undefined,
  check:CheckSoftwareExpr,
):CheckedSoftwareExpr {
  const alternatives:CheckedSoftwareMatchAlternative[]=[];
  const seen=new Set<string>();
  let seenWildcard=false;
  let branchType:SoftwareType|undefined;

  for(let index=0;index<expr.alternatives.length;index+=1){
    const source=expr.alternatives[index]!;
    let pattern:CheckedSoftwarePattern;
    let branchContext=context;

    if(source.pattern.kind==='bool'){
      throw new Error('PS_CHECK_MATCH_PATTERN: Bool pattern cannot match '+inductive.name);
    }
    if(source.pattern.kind==='wildcard'){
      if(seenWildcard)throw new Error('PS_CHECK_MATCH_DUPLICATE: duplicate wildcard alternative');
      if(index!==expr.alternatives.length-1){
        throw new Error('PS_CHECK_MATCH_PATTERN: wildcard must be the final alternative');
      }
      seenWildcard=true;
      pattern={kind:'wildcard'};
    }else{
      const qualified=normalizeConstructorPattern(source.pattern,inductive);
      const ref=context.constructors.get(qualified);
      if(ref===undefined||ref.inductive.name!==inductive.name){
        throw new Error(
          "PS_CHECK_MATCH_CONSTRUCTOR: '"+source.pattern.name+
          "' is not a constructor of "+inductive.name,
        );
      }
      if(seen.has(ref.constructor.name)){
        throw new Error(
          "PS_CHECK_MATCH_DUPLICATE: duplicate constructor '"+ref.constructor.name+"'",
        );
      }
      seen.add(ref.constructor.name);
      if(source.pattern.binders.length!==ref.constructor.fields.length){
        throw new Error(
          "PS_CHECK_MATCH_ARITY: constructor '"+ref.constructor.qualifiedName+
          "' binds "+ref.constructor.fields.length+' fields, got '+
          source.pattern.binders.length,
        );
      }

      const binderNames=new Set<string>();
      const binders=source.pattern.binders.map((name,binderIndex)=>{
        if(binderNames.has(name)){
          throw new Error("PS_CHECK_MATCH_BINDER: duplicate binder '"+name+"'");
        }
        binderNames.add(name);
        const field=ref.constructor.fields[binderIndex]!;
        branchContext=withSoftwareLocal(branchContext,name,field.type);
        return {name,field:field.name,type:field.type};
      });
      pattern={
        kind:'constructor',
        inductive:inductive.name,
        constructor:ref.constructor.name,
        binders,
      };
    }

    const body=check(source.body,branchContext,branchType??expected);
    branchType=checkBranchType(body,branchType);
    alternatives.push({pattern,body});
  }

  if(!seenWildcard&&seen.size!==inductive.constructors.length){
    const missing=inductive.constructors
      .filter((constructor)=>!seen.has(constructor.name))
      .map((constructor)=>constructor.name);
    throw new Error(
      'PS_CHECK_MATCH_EXHAUSTIVE: missing constructors '+missing.join(', ')+
      ' for '+inductive.name,
    );
  }
  if(branchType===undefined)throw new Error('PS_CHECK_MATCH_EMPTY: match has no alternatives');
  return {kind:'match',scrutinee,alternatives,resultType:branchType};
}

export function checkMatchExpression(
  expr:Extract<V061Expr,{kind:'match'}>,
  context:SoftwareExpressionContext,
  expected:SoftwareType|undefined,
  check:CheckSoftwareExpr,
):CheckedSoftwareExpr {
  const scrutinee=check(expr.scrutinee,context);
  if(scrutinee.resultType==='Bool'){
    return checkBoolMatch(expr,scrutinee,context,expected,check);
  }
  const type=scrutinee.resultType;
  if(typeof type!=='string'&&type.kind==='nominal'){
    const inductive=context.inductives.get(type.name);
    if(inductive!==undefined){
      return checkInductiveMatch(expr,scrutinee,inductive,context,expected,check);
    }
  }
  throw new Error('PS_CHECK_MATCH_SCRUTINEE: executable match requires Bool or an inductive type');
}
