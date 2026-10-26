// Read-only navigation and finite migration correspondence. No admission authority.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
process.chdir(root);
const baseline="b426f9763ed2a576135ed2089671d48e21f1ff32";
const moves=[
  {
    "from": "scripts/bounded-process.py",
    "to": "host-tools/process/bounded-process.py",
    "kind": "python"
  },
  {
    "from": "scripts/selfhost-qualification-profiles.mjs",
    "to": "host-tools/process/resource-profiles.mjs",
    "kind": "exports"
  },
  {
    "from": "scripts/compiler-closure-contract.mjs",
    "to": "host-tools/contracts/compiler-closure.mjs",
    "kind": "exports"
  },
  {
    "from": "scripts/generated-compiler-runner.mjs",
    "to": "host-tools/execution/generated-service-runner.mjs",
    "kind": "command"
  },
  {
    "from": "scripts/universal-candidate-runner.mjs",
    "to": "host-tools/execution/unified-candidate-runner.mjs",
    "kind": "command"
  },
  {
    "from": "npm-cli/psc.js",
    "to": "npm-cli/native-workspace-cli.mjs",
    "kind": "command"
  },
  {
    "from": "npm-cli/universal-cli.mjs",
    "to": "npm-cli/checked-command-cli.mjs",
    "kind": "command"
  },
  {
    "from": "npm-cli/universal.mjs",
    "to": "npm-cli/compiler-api.mjs",
    "kind": "exports"
  },
  {
    "from": "scripts/cli-package.mjs",
    "to": "scripts/packaging/cli.mjs",
    "kind": "command"
  },
  {
    "from": "scripts/cli-source-tests.mjs",
    "to": "test/host/cli.test.mjs",
    "kind": "command"
  },
  {
    "from": "scripts/cli-installed.mjs",
    "to": "test/installed/cli.test.mjs",
    "kind": "command"
  },
  {
    "from": "scripts/cli-application-regressions.mjs",
    "to": "test/installed/applications.mjs",
    "kind": "command"
  }
];
const literalMoves={
  "../scripts/selfhost-qualification-profiles.mjs": "./process/resource-profiles.mjs",
  "../scripts/compiler-closure-contract.mjs": "./contracts/compiler-closure.mjs",
  "../scripts/bounded-process.py": "./process/bounded-process.py",
  "scripts/bounded-process.py": "host-tools/process/bounded-process.py",
  "scripts/generated-compiler-runner.mjs": "host-tools/execution/generated-service-runner.mjs",
  "scripts/universal-candidate-runner.mjs": "host-tools/execution/unified-candidate-runner.mjs"
};
const read=file=>fs.readFileSync(file,'utf8');
function historical(file){
 const r=spawnSync('git',['show',baseline+':psc1/'+file],{encoding:'utf8',timeout:10000,maxBuffer:2*1024*1024});
 assert.equal(r.status,0,r.stderr);return r.stdout;
}
function relative(from,to){
 const result=path.posix.relative(path.posix.dirname(from),to);
 return result.startsWith('.')?result:'./'+result;
}
function relocated(source,from,to){
 const destinations=new Map(moves.map(m=>[m.from,m.to]));
 return source.replace(/((?:from\s+|import\s*|new URL\()\s*)(['"])(\.[^'"]+)\2/g,(_all,prefix,quote,value)=>{
  const target=path.posix.normalize(path.posix.join(path.posix.dirname(from),value));
  return prefix+quote+relative(to,destinations.get(target)??target)+quote;
 });
}
const compared=[];
for(const m of moves){
 const header=m.kind==='command'&&historical(m.from).startsWith('#!')?historical(m.from).split('\n')[0]+'\n':'';
 const wrapper=m.kind==='python'
  ? '# Compatibility command; canonical bounded supervisor lives with host runtime policy.\nfrom pathlib import Path\nimport runpy\nrunpy.run_path(str(Path(__file__).resolve().parent.parent / "host-tools/process/bounded-process.py"), run_name="__main__")\n'
  : header+'// Compatibility entry point. Canonical implementation: '+m.to+'.\n'+(m.kind==='exports'?'export * from ':'import ')+JSON.stringify(relative(m.from,m.to))+';\n';
 assert.equal(read(m.from),wrapper,'compatibility entry must only delegate: '+m.from);
 if(m.from==='scripts/cli-package.mjs')continue; // Intentional packaging overlays have installed qualification.
 let expected=historical(m.from);
 if(m.from.startsWith('scripts/cli-'))expected=relocated(expected,m.from,m.to);
 if(m.from==='npm-cli/universal.mjs')
  for(const [before,after] of Object.entries(literalMoves))expected=expected.split(before).join(after);
 if(m.from==='npm-cli/universal.mjs')expected=expected.replace("        : d.hostFiles.find((row) => row.path === 'host-tools/execution/unified-candidate-runner.mjs').sha256,","        : d.hostFiles.find(\n            (row) => row.path === 'host-tools/execution/unified-candidate-runner.mjs',\n          ).sha256,");
 if(m.from==='scripts/cli-installed.mjs')expected=expected.replace('proofscript 0.1.0-psc1.8','proofscript 0.1.0-psc1.9');
 assert.equal(read(m.to),expected,'moved implementation bytes changed: '+m.to);
 compared.push({from:m.from,to:m.to,relation:'exact-bytes-except-enumerated-paths-or-package-version'});
}
for(const file of ['host-tools/source-refactoring.mjs','host-tools/generated-target-tools.mjs','host-tools/generated-compiler-session.mjs']){
 let expected=historical(file);
 for(const [before,after] of Object.entries(literalMoves))expected=expected.split(before).join(after);
 assert.equal(read(file),expected,'host relocation changed non-path bytes: '+file);
 compared.push({from:file,to:file,relation:'only-enumerated-runtime-path-literals'});
}
for(const name of ['STATUS','NPM_PACKAGE_WORK_STATE'])
 assert.equal(read('docs/history/'+name+'_BEFORE_LAYOUT_2026-10-26.md'),historical(name+'.md'));
assert.equal(read('docs/history/ROADMAP_BEFORE_LAYOUT_2026-10-26.md'),historical('docs/PSC1_DEVELOPMENT_ROADMAP.md'));

const listed=spawnSync('git',['ls-files','-z','.'],{encoding:'utf8',timeout:10000,maxBuffer:4*1024*1024});
assert.equal(listed.status,0,listed.stderr);
const files=listed.stdout.split('\0').filter(Boolean).sort();
const nodes=[],edges=[],modules=new Map();
function category(file){
 if(file.startsWith('legacy/'))return 'historical-code';
 if(file.startsWith('docs/history/'))return 'historical-record';
 if(file.startsWith('docs/')&&/\d{4}-\d{2}-\d{2}/.test(file))return 'dated-evidence';
 if(file.startsWith('docs/'))return 'documentation-or-contract';
 if(file.startsWith('packages/pskernel-core/'))return 'independent-kernel-research';
 if(/^packages\/pskernel-lean/.test(file))return 'official-independent-checker';
 if(file.startsWith('test/'))return 'test-or-reference';
 if(file.startsWith('host-tools/')||file.startsWith('npm-cli/')||file.startsWith('host/src/'))return 'host-source';
 if(file.startsWith('packages/'))return 'compiler-or-library-source';
 if(file.startsWith('scripts/'))return 'automation-or-retained-guard';
 return 'workspace-config-or-entry';
}
for(const file of files){
 const node={path:file,category:category(file)};
 if(file.endsWith('.lean')&&!file.startsWith('legacy/')){
  const matched=file.match(/^(?:packages\/[^/]+|host)\/src\/(.+)\.lean$/);
  if(matched){node.module=matched[1].replaceAll('/','.');modules.set(node.module,file);}
 }
 nodes.push(node);
}
for(const node of nodes){
 if(!/\.(mjs|js|lean)$/.test(node.path)||node.path.startsWith('legacy/')||
    node.path.startsWith('packages/pskernel-lean')||node.path.startsWith('packages/pskernel-core/'))continue;
 const text=read(node.path);
 if(node.path.endsWith('.lean')){
  for(const match of text.matchAll(/^import (Ps\.[A-Za-z0-9_.]+)\s*$/gm))
   edges.push({from:node.path,to:modules.get(match[1])??null,module:match[1],kind:'lean-import'});
 }else{
  for(const match of text.matchAll(/(?:from\s+|import\s*)['"](\.[^'"]+)['"]/g)){
   const target=path.posix.normalize(path.posix.join(path.posix.dirname(node.path),match[1]));
   edges.push({from:node.path,to:target,kind:'relative-js-import'});
   if(node.category==='host-source')assert.ok(!target.startsWith('scripts/'),'production host imports development automation: '+node.path);
  }
 }
}
// Isolated executable copies must use implementations, never path-relative delegates.
for(const file of files.filter(f=>f.startsWith('scripts/')&&f.endsWith('.mjs'))){
 assert.ok(!/(?:const runner(?:Source)?\\s*=|runnerFile:|runnerSha256:)[^\\n]*scripts\\/generated-compiler-runner\\.mjs/.test(read(file)),
  'controller must pin/copy the canonical implementation: '+file);
}
for(const file of ['scripts/generated-compiler-diagnostic.mjs','scripts/generated-target-qualification.mjs'])
 assert.ok(read(file).includes('host-tools/contracts/compiler-closure.mjs'),'canonical validator missing from protected tool inventory: '+file);
for(const file of ['host-tools/process/resource-profiles.mjs','host-tools/process/bounded-process.py'])
 assert.ok(read('scripts/generated-target-qualification.mjs').includes(file),'canonical process policy missing from protected tool inventory: '+file);

const ownDocs=[
 'README.md','ARCHITECTURE.md','CONTRIBUTING.md','docs/README.md',
 'docs/PSC1_DEVELOPMENT_ROADMAP.md',...files.filter(f=>/^docs\/(guides|architecture|reference|development|evidence)\/.+\.md$/.test(f)),
 ...files.filter(f=>/^packages\/[^/]+\/README\.md$/.test(f)&&!/^packages\/pskernel-/.test(f)),
 'npm-cli/README.md','scripts/README.md'
];
const checkedLinks=[];
for(const file of new Set(ownDocs)){
 for(const match of read(file).matchAll(/\]\(([^()\n]+)\)/g)){
  const url=match[1];if(/^(https?:|mailto:|codex:|#)/.test(url))continue;
  const target=path.resolve(path.dirname(file),url.split('#')[0]);
  assert.ok(target.startsWith(root+path.sep)||target===root,'documentation path escape: '+file+':'+url);
  assert.ok(fs.existsSync(target),'broken current link: '+file+':'+url);
  checkedLinks.push({from:file,to:path.relative(root,target)});
 }
}
const out=path.resolve('dist/readability');fs.mkdirSync(path.join(out,'runtime'),{recursive:true});
const runtime=read('packages/backend-ts/src/Ps/BackendTs/RuntimeSupport.lean');
const runtimeViews=[];
for(const match of runtime.matchAll(/^def (psTs(?:Stack|Utf8)RuntimeSupport) : String :=\n  ("(?:[^"\\]|\\.)*")/gm)){
 const text=JSON.parse(match[2]),file=match[1]+'.generated.ts';
 fs.writeFileSync(path.join(out,'runtime',file),text);runtimeViews.push({file,sourceDefinition:match[1],utf8Bytes:Buffer.byteLength(text)});
}
assert.equal(runtimeViews.length,2,'both runtime views must be derived from source');
const result={schema:'psc1-repository-layout/1',testedCommit:process.env.GITHUB_SHA,baseline,status:'passed',nodes,edges,compared,checkedLinks,runtimeViews,
 historicalRecords:'byte-identical',humanQualified:false,semanticPreservation:'not-claimed',frozenPayloadPromotion:'not-claimed'};
fs.writeFileSync(path.join(out,'repository-map.json'),JSON.stringify(result,null,2)+'\n');
const rows=nodes.filter(n=>n.module).map(n=>'| '+n.module+' | ['+n.path+'](../../'+n.path+') | '+n.category+' |').join('\n');
const receipts=nodes.filter(n=>n.category==='dated-evidence').map(n=>'- '+n.path).join('\n');
fs.writeFileSync(path.join(out,'repository-map.md'),'# Exact-source repository map\n\nGenerated from tracked paths and actual imports; no additional semantic authority.\n\n| Module | Source | Role |\n| --- | --- | --- |\n'+rows+'\n\n## Dated evidence\n\n'+receipts+'\n');
console.log('PSC1_REPOSITORY_LAYOUT: '+JSON.stringify({status:'passed',nodes:nodes.length,imports:edges.length,exactRelations:compared.length,links:checkedLinks.length,runtimeViews:runtimeViews.length,humanQualified:false}));
