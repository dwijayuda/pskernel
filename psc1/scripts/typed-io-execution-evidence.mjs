// Consolidates actual execution, never source admission authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {checkTypedIoExecution} from './check-typed-io-execution.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
const contract=read('docs/PSC1_TYPED_IO_EXECUTION_CONTRACT.json');
const commit=process.env.GITHUB_SHA,head=process.env.PSC1_HEAD_SHA;
const dispatcher=read('dist/scoped-correctness/typed-io-dispatcher/results.json');
const wasm=read('dist/scoped-correctness/wasm-string/results.json');
for(const receipt of [dispatcher,wasm]){
 assert.equal(receipt.testedCommit,commit);assert.equal(receipt.branchHeadCommit,head);
 assert.equal(receipt.passed,true);assert.deepEqual(receipt.failures,[]);
}
const records=[...dispatcher.records,...wasm.records];
const policies={node:read('dist/scoped-correctness/typed-io/policy.json'),
 ...Object.fromEntries(['rust','python','php'].map(provider=>[provider,
  read('dist/scoped-correctness/typed-io-standalone/'+provider+'-policy.json')]))};
const receipt={schema:'psc1-typed-io-execution/1',contract:contract.id,
 testedCommit:commit,branchHeadCommit:head,checkerCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
 passed:true,failures:[],completeApplications:false,targets:contract.targets,records,policies};
checkTypedIoExecution(contract,receipt,{commit,head,checkerCommit:receipt.checkerCommit});
const folder=path.join(root,'dist/scoped-correctness/typed-io-execution');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(folder,'results.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_TYPED_IO_EXECUTION: '+JSON.stringify(receipt));
