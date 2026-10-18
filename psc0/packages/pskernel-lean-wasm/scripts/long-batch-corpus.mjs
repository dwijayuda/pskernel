// Regression workload with the same *number* of checked declarations as the
// historical 1205-admission Lean 4.34 Wasm compiler test. This is a generated
// dependency-chain workload, NOT a replay of the historical 9.9 MB compiler
// corpus and not a substitute for full PSC0 v7.2 compiler equivalence.
const name=v=>({k:'s',p:{k:'a'},v});
const nat={k:'const',ls:[],n:name('Nat')};
const constExpr=n=>({k:'const',ls:[],n:name(n)});
const natural=n=>({k:'nat',v:String(n)});
const stepName=i=>'PSC0.WasmBatch'+String(i).padStart(4,'0');
const definition=(i,value)=>({
  kind:'constant',
  declaration:{
    k:'definition',n:name(stepName(i)),lp:[],t:nat,v:value,
    h:{k:'regular',h:'1'},s:'safe',
  }
});
const request=admissions=>JSON.stringify({
  format:'proofscript-checked-admissions',version:2,admissions,
});
export const count=1205;
export function makeLongBatchCorpus(){
  const admissions=Array.from({length:count},(_,i)=>
    definition(i,i===0?natural(1):constExpr(stepName(i-1))));
  const rejected=[...admissions];
  rejected[count-1]=definition(count-1,{k:'sort',l:{k:'z'}});
  return [
    {id:'long-chain-1205-accepted',input:request(admissions),
      accepted:true,admissionCount:count},
    {id:'long-chain-1205-last-invalid',input:request(rejected),
      accepted:false,errorKind:'kernel-rejection',
      errorReason:'declaration-type-mismatch',
      declarationIndex:count-1,admissionCount:count},
  ];
}
