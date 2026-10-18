// Shared native-vs-Wasm test cases. Existing canonical admission schema v2,
// derived from the current PSC0 bridge; no PSC2 kernel authority is copied.
const name=value=>({k:'s',p:{k:'a'},v:value});
const nat={k:'const',ls:[],n:name('Nat')};
const base=(kind,value)=>({format:'proofscript-checked-admissions',version:2,
  admissions:[{kind:'constant',declaration:{
    k:'definition',n:name(kind),lp:[],t:nat,v,
    h:{k:'regular',h:'1'},s:'safe'}}]});
export const corpus=[
  {id:'good-nat-definition',input:JSON.stringify(base('PSC0.TestGood',{k:'nat',v:'1'})),accept:true},
  {id:'ill-typed-definition',input:JSON.stringify(base('PSC0.TestBad',{k:'sort',l:{k:'z'}})),accept:false,errorKind:'kernel-rejection'},
  {id:'malformed-json',input:'{',accept:false,errorKind:'malformed-request'},
  {id:'wrong-version',input:JSON.stringify({format:'proofscript-checked-admissions',version:999,admissions:[]}),accept:false,errorKind:'protocol-version'},
];
