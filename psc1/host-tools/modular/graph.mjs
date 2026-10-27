// Static module/resource validation; this code never interprets source or IR.
import {createRequire} from 'node:module';
import assert from 'node:assert/strict';
const require=createRequire(new URL('../package.json',import.meta.url));
const {parse}=require('@babel/parser');
export function inspectModule(source){
  const tree=parse(source,{sourceType:'module',createImportExpressions:true});
  const imports=[],exports=[],state={weakMaps:0,symbols:0};
  for(const node of tree.program.body){
    if(node.type==='ImportDeclaration'){
      assert.equal(node.importKind,'value');
      assert.ok(node.specifiers.every(s=>s.type==='ImportSpecifier'),'PSC1_MODULAR_NAMESPACE_IMPORT');
      imports.push({source:node.source.value,names:node.specifiers.map(s=>s.imported.name).sort()});
    }
    if(node.type==='ExportAllDeclaration'||(node.type==='ExportNamedDeclaration'&&node.source))
      throw Error('PSC1_MODULAR_FACADE_OR_REEXPORT');
    if(node.type==='ExportDefaultDeclaration')throw Error('PSC1_MODULAR_DEFAULT_EXPORT');
    if(node.type==='ExportNamedDeclaration'){
      if(node.declaration?.type==='FunctionDeclaration')exports.push(node.declaration.id.name);
      else if(node.declaration?.type==='VariableDeclaration')
        for(const d of node.declaration.declarations){assert.equal(d.id.type,'Identifier');exports.push(d.id.name);}
      for(const spec of node.specifiers)exports.push(spec.exported.name);
    }
  }
  const visit=node=>{
    if(!node||typeof node!=='object')return;
    if(node.type==='ImportExpression'||node.type==='MetaProperty')throw Error('PSC1_MODULAR_DYNAMIC_AUTHORITY');
    if((node.type==='CallExpression'||node.type==='NewExpression')&&node.callee?.type==='Identifier'){
      if(['eval','Function','require'].includes(node.callee.name))throw Error('PSC1_MODULAR_DYNAMIC_AUTHORITY');
      if(node.callee.name==='Symbol')state.symbols++;
      if(node.type==='NewExpression'&&node.callee.name==='WeakMap')state.weakMaps++;
    }
    for(const[key,value]of Object.entries(node)){
      if(['loc','start','end','extra','comments','tokens'].includes(key))continue;
      if(Array.isArray(value))value.forEach(visit);else if(value&&typeof value==='object')visit(value);
    }
  };visit(tree.program);
  assert.equal(new Set(exports).size,exports.length,'PSC1_MODULAR_DUPLICATE_EXPORT');
  assert.ok(!exports.includes('then'),'PSC1_MODULAR_THENABLE_EXPORT');
  return{imports,exports:exports.sort(),...state};
}
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
