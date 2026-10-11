// One fixture corpus for native and generated v7 parser qualification.
import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const cases=JSON.parse(await readFile('scripts/pscv0-m1-cases.json','utf8'));
if(process.argv[2]==='--native'){
  const q=JSON.stringify;
  let source=await readFile('scripts/Pscv0M1Harness.lean','utf8');
  source+='\ndef main : IO Unit := do\n';
  for(const c of cases.good)source+='  m1Good '+[c.name,c.source,c.result].map(q).join(' ')+' ['+c.locals.map(q).join(', ')+']\n';
  for(const c of cases.bad)source+='  m1Bad '+[c.name,c.source,c.error].map(q).join(' ')+'\n';
  source+='  IO.println "PSCV0_M1_NATIVE: PASS '+cases.good.length+' AST/replay cases, '+cases.bad.length+' refusals"\n';
  await writeFile('dist/Pscv0M1Generated.lean',source);
}else{
  const B=await import(pathToFileURL(path.resolve(process.argv[2])).href);
  const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(k=>o[k]).find(v=>typeof v==='string'):undefined;
  const ok=r=>{assert.equal(tag(r),'ok',String(r?.error));return r.value;};
  const list=x=>{const out=[];while(tag(x)==='cons'){out.push(x.head);x=x.tail;}assert.equal(tag(x),'nil');return out;};
  const shape=t=>{
    switch(tag(t)){
      case 'reference':return list(t.name.segments).join('.');
      case 'app':return 'app('+shape(t.fn)+';'+list(t.args).map(shape).join(', ')+')';
      case 'forallE':return 'pi('+list(t.binders).map(b=>shape(b.snd)).join(', ')+';'+shape(t.body)+')';
      case 'letE':return 'let('+(tag(t.type)==='some'?shape(t.type.value):'_')+';'+shape(t.value)+';'+shape(t.body)+')';
      default:return 'other';
    }
  };
  const children=t=>list(B.psPscv0TermChildren(t));
  const locals=t=>[...(tag(t)==='letE'&&tag(t.type)==='some'?[shape(t.type.value)]:[]),...children(t).flatMap(locals)];
  const spans=(t,source)=>{
    const s=B.psSyntaxTermSpan(t);
    assert(s.start.byteOffset>=0n&&s.start.byteOffset<=s.stop.byteOffset&&s.stop.byteOffset<=BigInt(Buffer.byteLength(source)));
    children(t).forEach(c=>spans(c,source));
  };
  for(const c of cases.good){
    const surface=ok(B.psPscv0ParseSource(true,c.source));
    assert.equal(B.psPscv0ReplayOriginal(surface),c.source,c.name);
    const [decl,...rest]=list(surface.declarations);assert.equal(rest.length,0,c.name);
    assert(['definition','theoremDecl'].includes(tag(decl.declaration)));
    const {type,value}=decl.declaration;
    assert.equal(shape(type),c.result,c.name);
    const extra=tag(decl.doBody)==='some'?list(decl.doBody.value.items).flatMap(item=>{
      if(tag(item)==='letValue')return [...(tag(item.type)==='some'?[shape(item.type.value)]:[]),...locals(item.value)];
      return locals(item.action||item.value);
    }):[];
    assert.deepEqual([...locals(value),...extra],c.locals,c.name);
    spans(type,c.source);spans(value,c.source);
    console.log('PSCV0_M1_GENERATED_CASE: PASS '+c.name);
  }
  for(const c of cases.bad){
    const r=B.psPscv0ParseSource(true,c.source);
    assert.equal(tag(r),'error',c.name);assert(r.error.startsWith(c.error),c.name+': '+r.error);
    console.log('PSCV0_M1_GENERATED_REFUSAL: PASS '+c.name);
  }
  console.log('PSCV0_M1_GENERATED: PASS '+cases.good.length+' AST/replay cases, '+cases.bad.length+' refusals');
}
