// Retained pilot regression wrapper; shared syntax audit has unchanged rules.
import assert from 'node:assert/strict';
import {inspectModule} from '../module-graph-inspection.mjs';
export {inspectModule};
export function verifyPrintedGraph(candidate,target,sources){
  const rows=sources.map(inspectModule);
  rows.forEach((row,index)=>{
    const emitted=candidate[target][index];
    assert.deepEqual(row.exports,[...emitted.exports].sort(),'PSC1_MODULAR_EXPORT_IDENTITY');
    const expected=emitted.imports.filter(i=>!i.typeOnly).map(i=>({source:i.source,names:[...i.names].sort()}));
    assert.deepEqual(row.imports,expected,'PSC1_MODULAR_IMPORT_IDENTITY');
    assert.equal(row.weakMaps,index===0?1:0,'PSC1_MODULAR_RUNTIME_SINGLETON');
    if(index>0)assert.equal(row.symbols,0,'PSC1_MODULAR_NOMINAL_SINGLETON');
  });
  return rows;
}
