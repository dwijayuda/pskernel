// Current PSC0 v7.2 canonical-admissions /2 contracts. No unchecked
// admission or fake checker responses: the actual official Lean 4.35 kernel
// decides accept/reject. Shared verbatim by native and wasm32 parity checks.
const name=v=>({k:'s',p:{k:'a'},v});
const constant=v=>({k:'const',ls:[],n:name(v)});
const nat=constant('Nat'),sort0={k:'sort',l:{k:'z'}};
const request=admissions=>JSON.stringify({
  format:'proofscript-checked-admissions',version:2,admissions,
});
const good=(id,body={k:'nat',v:'42'})=>({
  kind:'constant',
  declaration:{k:'definition',lp:[],n:name(id),t:nat,v:body,h:{k:'regular',h:'1'},s:'safe'},
});
export const corpus=[
  {id:'good-nat-definition',input:request([good('PSC0.TestGood',{k:'nat',v:'1'})]),accept:true},
  {id:'ill-typed-definition',input:request([good('PSC0.TestBad',sort0)]),accept:false,errorKind:'kernel-rejection'},
  {id:'malformed-json',input:'{',accept:false,errorKind:'malformed-request'},
  {id:'wrong-version',input:JSON.stringify({format:'proofscript-checked-admissions',version:999,admissions:[]}),accept:false,errorKind:'protocol-version'},
  {id:'empty-batch',input:request([]),accept:true},
  {id:'duplicate-defined-name',input:request([
    good('PSC0.TestDuplicate'),good('PSC0.TestDuplicate')
  ]),accept:false,errorKind:'kernel-rejection',declarationIndex:1},
  {id:'missing-constant-type',input:request([
    {kind:'constant',declaration:{
      k:'definition',lp:[],n:name('PSC0.TestUnknownType'),
      t:constant('PSC0.UnknownType'),v:{k:'nat',v:'0'},
      h:{k:'regular',h:'1'},s:'safe'}}
  ]),accept:false,errorKind:'kernel-rejection'},
  {id:'theorem-type-not-proposition',input:request([
    {kind:'constant',declaration:{
      k:'theorem',lp:[],n:name('PSC0.InvalidTheorem'),
      t:nat,v:{k:'nat',v:'0'}}}
  ]),accept:false,errorKind:'kernel-rejection'},
  {id:'opaque-ill-typed-body',input:request([
    {kind:'constant',declaration:{
      k:'opaque',lp:[],n:name('PSC0.InvalidOpaque'),
      t:nat,v:sort0}}
  ]),accept:false,errorKind:'kernel-rejection'},
  {id:'axiom-injection-not-admitted',input:request([
    {kind:'constant',declaration:{
      k:'axiom',lp:[],n:name('PSC0.UnauthorizedAxiom'),t:sort0}}
  ]),accept:false,errorKind:'malformed-request'},
  {id:'unknown-admission-kind',input:request([
    {kind:'unchecked',declaration:{k:'definition'}}
  ]),accept:false,errorKind:'malformed-request'},
];
export const corpusSchemaVersion=2;
