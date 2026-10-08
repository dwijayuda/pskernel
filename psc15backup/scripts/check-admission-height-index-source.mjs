import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
const source=await readFile(new URL('../packages/bridge/src/Ps/Bridge/CheckedAdmissions.lean',import.meta.url),'utf8');
const required=[
  'if psNameEq (Prod.fst entry) name then',
  'inductive PsBridgeHeightIndex where',
  'psBridgeHeightInsertWorker 16 index (psEnvironmentNameHash name) name height',
  'psBridgeFindRegularHeightInBucket (psBridgeHeightBucket 16 index (psEnvironmentNameHash name)) name',
  'heights : PsBridgeHeightIndex',
  'heights := psBridgeHeightInsert state.heights name height',
  'heights := PsBridgeHeightIndex.empty',
];
const verify=text=>{for(const marker of required)assert(text.includes(marker),'missing collision-safe declaration-height index guard: '+marker);};
verify(source);
for(const marker of required)assert.throws(()=>verify(source.replaceAll(marker,'removed')));
console.log('PSC2_ADMISSION_HEIGHT_INDEX_SOURCE: PASS (persistent buckets, full names, bounded depth)');
