import fs from 'node:fs';
import path from 'node:path';

const root=path.resolve(import.meta.dirname,'..');
const pkg=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'));
const source=fs.readFileSync(path.join(root,'src/extension.js'),'utf8');
const runner=fs.readFileSync(path.join(root,'server/run-lsp.mjs'),'utf8');

function assert(value,message){
  if(!value)throw new Error(message);
}

assert(pkg.contributes.languages[0].extensions.includes('.ps'),'missing .ps language');
for(const command of [
  'proofscript.showInfoview',
  'proofscript.restartServer',
  'proofscript.serverInfo',
]){
  assert(pkg.contributes.commands.some((item)=>item.command===command),'missing command '+command);
  assert(source.includes("registerCommand('"+command+"'"),'command not implemented '+command);
}
assert(source.includes('EXPECTED_PROTOCOL=1'),'protocol guard missing');
assert(source.includes('proofscript/proofState'),'proof-state request missing');
assert(source.includes('Goals accomplished!')===false,'editor must not fabricate proof success text');
assert(source.includes('pskernel'),'editor trust-boundary text missing');
assert(runner.includes('packages/lsp/dist/src/bin.js'),'dogfood LSP runner drift');

console.log('vscode-shape: PASS');
