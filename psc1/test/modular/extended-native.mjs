// Real compiler source graph; no local or handwritten compiler implementation.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {compileSources} from '../../host-tools/modular/compiler.mjs';
const paths=[
 ['Ps.Foundation.List','packages/foundation/src/Ps/Foundation/List.lean'],
 ['Ps.Foundation.Name','packages/foundation/src/Ps/Foundation/Name.lean'],
 ['Ps.Foundation.Text','packages/foundation/src/Ps/Foundation/Text.lean'],
 ['Ps.Bridge.Json','packages/bridge/src/Ps/Bridge/Json.lean'],
 ['Pilot.Consumer','test/modular/Extended.lean']
];
const sources=paths.map(([module,path])=>({module,kind:'lean',text:fs.readFileSync(path,'utf8')}));
const compiled=compileSources({sources,profile:'extended',requestId:'extended-native'});
const c=compiled.candidate;
assert.equal(c.units.length,6);
assert.equal(compiled.receipt.accepted,true);
assert.ok(c.transformOrigins.specialization.some(row=>row.rule==='specialization'&&row.kind==='declaration'));
assert.ok(c.transformOrigins.workerFusion.some(row=>row.rule==='worker'));
fs.mkdirSync('dist/modular',{recursive:true});
fs.writeFileSync('dist/modular/extended-native.json',JSON.stringify(c));
fs.writeFileSync('dist/modular/extended-native-receipt.json',JSON.stringify({testedCommit:process.env.GITHUB_SHA,
 receipt:compiled.receipt,execution:compiled.execution,resources:compiled.resources},null,2)+'\n');
console.log('PSC1_EXTENDED_NATIVE '+JSON.stringify({status:'passed',sourceClosureDigest:c.sourceClosureDigest,
 original:c.originalIr[4].length,specialized:c.specializedIr[4].length,fused:c.transformedIr[4].length,
 specializationOrigins:c.transformOrigins.specialization.filter(row=>row.rule==='specialization').length,
 workerOrigins:c.transformOrigins.workerFusion.filter(row=>row.rule==='worker').length,units:c.units,execution:compiled.execution}));
