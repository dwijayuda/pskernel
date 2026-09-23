import {
  existsSync,
  readFileSync,
  readdirSync,
} from 'node:fs';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('..',import.meta.url));
const editor=join(root,'editors','vscode');
for(const file of [
  'package.json',
  'src/extension.js',
  'src/rpc-client.js',
  'src/infoview.js',
  'src/protocol.js',
  'server/run-lsp.mjs',
  'language-configuration.json',
  'syntaxes/proofscript.tmLanguage.json',
  'test/smoke.mjs',
]){
  if(!existsSync(join(editor,file))){
    throw new Error('VS Code integration missing '+file);
  }
}

const sourceFiles=readdirSync(join(editor,'src'))
  .filter((name)=>name.endsWith('.js'))
  .sort();
const sources=sourceFiles.map((name)=>({
  name,
  text:readFileSync(join(editor,'src',name),'utf8'),
}));
for(const source of sources){
  const lines=source.text.split(/\r?\n/u);
  if(lines.length>300){
    throw new Error(
      'VS Code source-shape: '+source.name+
      ' has '+lines.length+' lines > 300',
    );
  }
  const longest=Math.max(...lines.map((line)=>line.length),0);
  if(longest>180){
    throw new Error(
      'VS Code source-shape: '+source.name+
      ' max line '+longest+' > 180',
    );
  }
}
const all=sources.map((source)=>source.text).join('\n');
if(!all.includes('EXPECTED_PROTOCOL=1')){
  throw new Error('VS Code integration protocol guard drift');
}
if(!all.includes('proofscript/proofState')){
  throw new Error('VS Code integration proof-state wiring drift');
}
if(!all.includes('Proof authority: pskernel')){
  throw new Error('VS Code integration trust-boundary text drift');
}
console.log(
  'vscode-shape: PASS ('+
  sourceFiles.length+' modules; <=300 lines each)',
);
