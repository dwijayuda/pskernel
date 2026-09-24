import fs from 'node:fs';
import path from 'node:path';

const root=path.resolve(import.meta.dirname,'..');
const pkg=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'));
const sourceFiles=fs.readdirSync(path.join(root,'src')).filter((name)=>name.endsWith('.js')).sort();
const source=sourceFiles.map((name)=>fs.readFileSync(path.join(root,'src',name),'utf8')).join('\n');
const runner=fs.readFileSync(path.join(root,'server/run-lsp.mjs'),'utf8');

function assert(value,message){
  if(!value)throw new Error(message);
}

assert(pkg.contributes.languages[0].extensions.includes('.ps'),'missing .ps language');
const leanMode=pkg.contributes.languages.find(
  (item)=>item.id==='proofscript-lean',
);
assert(leanMode!==undefined,'missing explicit ProofScript Lean-subset mode');
assert(
  Array.isArray(leanMode.extensions)===false
    ||leanMode.extensions.includes('.lean')===false,
  'ProofScript must not globally claim .lean extension ownership',
);
assert(
  pkg.contributes.configuration.properties['proofscript.leanSubset.enable']?.default===false,
  'Lean-subset provider must be opt-in by default',
);
assert(
  pkg.activationEvents.includes('workspaceContains:psconfig.json'),
  'ProofScript workspace activation missing',
);
for(const command of [
  'proofscript.showInfoview',
  'proofscript.restartServer',
  'proofscript.serverInfo',
  'proofscript.convertToLean',
  'proofscript.convertToProofScript',
]){
  assert(pkg.contributes.commands.some((item)=>item.command===command),'missing command '+command);
  assert(source.includes("registerCommand('"+command+"'"),'command not implemented '+command);
}
assert(source.includes('EXPECTED_PROTOCOL=2'),'protocol guard missing');
assert(source.includes('proofscript/proofState'),'proof-state request missing');
assert(source.includes('proofscript/translateDocument'),'translation request missing');
assert(source.includes('registerCodeActionsProvider'),'translation code-action provider missing');
assert(source.includes("{pattern:'**/*.lean'}"),'opt-in .lean provider selector missing');
assert(source.includes("languageId==='proofscript-lean'"),'Lean-subset protocol mode missing');
assert(source.includes('leanSubsetEnabled()'),'Lean-subset opt-in guard missing');
assert(source.includes('Goals accomplished!')===false,'editor must not fabricate proof success text');
assert(source.includes('pskernel'),'editor trust-boundary text missing');
assert(runner.includes('packages/lsp/dist/src/bin.js'),'dogfood LSP runner drift');

console.log('vscode-shape: PASS');
