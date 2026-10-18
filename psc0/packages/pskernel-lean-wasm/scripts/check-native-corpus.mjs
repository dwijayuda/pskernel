// Independently qualify the *native*, same-source official Lean kernel
// admission endpoint before spending time on a Wasm differential run.
// Do not bypass errors or reclassify transport failures as invalid proofs.
import assert from 'node:assert/strict';
import {corpus} from './corpus.mjs';
import {runJsonProvider} from './run-provider.mjs';

const native=process.argv[2];
if(!native)throw Error('usage: node check-native-corpus.mjs <native-lean4-executable>');
const health=runJsonProvider(native,['--health']);
assert.deepEqual(health,{
  protocol:'pskernel-lean-wasm/2',
  provider:'lean4-cpp',
  leanVersion:'4.35.0',
  leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  profile:'pscv0-v7.2',status:'ok',
},'native oracle must be pinned official Lean 4.35.0 and current v7.2');

const name=v=>({k:'s',p:{k:'a'},v});
const constant=v=>({k:'const',ls:[],n:name(v)});
const nat=constant('Nat'),sort0={k:'sort',l:{k:'z'}};
const good=(id,body={k:'nat',v:'42'})=>({
  kind:'constant',
  declaration:{k:'definition',lp:[],n:name(id),t:nat,v:body,h:{k:'regular',h:'1'},s:'safe'},
});
const request=admissions=>JSON.stringify({
  format:'proofscript-checked-admissions',version:2,admissions,
});
const extra=[
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
for(const fixture of [...corpus,...extra]){
  const result=runJsonProvider(native,['--check'],fixture.input);
  assert.equal(result.protocol,health.protocol,fixture.id+' protocol');
  assert.equal(result.provider,health.provider,fixture.id+' provider');
  assert.equal(result.leanVersion,health.leanVersion,fixture.id+' version');
  assert.equal(result.leanCommit,health.leanCommit,fixture.id+' commit');
  assert.equal(result.profile,health.profile,fixture.id+' profile');
  assert.equal(result.accepted,fixture.accept,fixture.id+' admission');
  if(!fixture.accept){
    assert.equal(result.errorKind,fixture.errorKind,fixture.id+' rejection kind');
    assert.equal(typeof result.message,'string',fixture.id+' rejection message');
    assert.ok(result.message.length>0,fixture.id+' informative rejection');
  }
  if(fixture.declarationIndex!==undefined)
    assert.equal(result.declarationIndex,fixture.declarationIndex,
      fixture.id+' exact failed admission index');
  console.log('PSC0_LEAN435_NATIVE_CORPUS: PASS '+fixture.id);
}
console.log('PSC0_LEAN435_NATIVE_CORPUS_PASSED '+(corpus.length+extra.length));
