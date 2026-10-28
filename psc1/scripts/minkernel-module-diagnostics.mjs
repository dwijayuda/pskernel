// Read-only queries of actual kernel translation functions; no admission authority.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const root='dist/pskernel-min/module-matrix';
const G=await import(pathToFileURL(path.resolve(root,'sdk/runtime/kernel.js')).href);
const matrix=JSON.parse(fs.readFileSync(path.join(root,'matrix.json')));
const row=matrix.rows.find(r=>r.module==='Ps.Foundation.List');
assert.equal(row.firstRefusal.names[0],'psListLengthAcc.$psc0SH.0');
const packet=JSON.parse(fs.readFileSync(row.firstRefusal.packet)),type=packet.admissions[0].declaration.t;
assert.equal(type.k,'forall');assert.equal(type.t.k,'sort');assert.equal(type.t.l.k,'s');assert.equal(type.t.l.o.k,'z');
const list=items=>{let out=G.List.nil();for(let i=items.length-1;i>=0;i--)out=G.List.cons(items[i],out);return out;};
const name=s=>G.PsMinCoreName.str(G.PsMinCoreName.anonymous,list([...s].map(c=>BigInt(c.codePointAt(0)))));
const E=G.PsMinCoreExpr,constant=s=>E.constant(name(s),G.List.nil());
const none=G.Option.none(),tag=Object.getOwnPropertySymbols(none)[0];
const translated=expression=>G.psMinRegCoreType(256n,0n,0n,G.List.nil(),expression)[tag]==='some';
const observations={sortType:translated(E.sort(1n)),typeVariable:translated(E.bvar(0n)),
 natural:translated(constant('Nat')),groundListNat:translated(E.app(constant('List'),constant('Nat')))};
assert.deepEqual(observations,{sortType:false,typeVariable:false,natural:true,groundListNat:true});
const impact=[...matrix.rows].map(r=>({module:r.module,dependentClosures:matrix.rows.filter(t=>t.dependencyClosure.includes(r.module)).length,
 declarationBytes:r.source.bytes,min:r.standalone?.min?.code||r.projectedMin.code})).sort((a,b)=>b.dependentClosures-a.dependentClosures);
const result={schema:'psc1-actual-module-kernel-blocker/1',head:process.env.GITHUB_SHA,module:row.module,
 actualFailingDeclaration:row.firstRefusal.names[0],actualPacketSha256:row.firstRefusal.sha256,sourceTypeBinder:type.t,
 actualKernelQueries:observations,
 reason:'The real first declaration quantifies over a type. The current proved translator has no sort/type-variable carrier and treats forall only as nondependent arrows. Ground List Nat support does not implement this polymorphic binder.',
 acceptanceAuthority:false,dependencyImpact:impact,boundary:'Diagnostic function calls do not grant acceptance; the public API refusal remains authoritative.'};
fs.writeFileSync(path.join(root,'kernel-blockers.json'),JSON.stringify(result,null,2)+'\n');
console.log('PSC1_ACTUAL_LIST_BLOCKER_CONFIRMED '+JSON.stringify(observations));
