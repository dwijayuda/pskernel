import {readFileSync,existsSync} from 'node:fs';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('..',import.meta.url));
const editor=join(root,'editors','vscode');
for(const file of [
  'package.json',
  'src/extension.js',
  'server/run-lsp.mjs',
  'language-configuration.json',
  'syntaxes/proofscript.tmLanguage.json',
  'test/smoke.mjs',
]){
  if(!existsSync(join(editor,file))){
    throw new Error('VS Code integration missing '+file);
  }
}
const source=readFileSync(join(editor,'src','extension.js'),'utf8');
if(!source.includes('EXPECTED_PROTOCOL=1')){
  throw new Error('VS Code integration protocol guard drift');
}
if(!source.includes('proofscript/proofState')){
  throw new Error('VS Code integration proof-state wiring drift');
}
if(!source.includes('Proof authority: pskernel')){
  throw new Error('VS Code integration trust-boundary text drift');
}
console.log('vscode-shape: PASS');
