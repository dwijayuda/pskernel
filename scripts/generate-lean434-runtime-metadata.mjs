import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

const expectedVersion=/^Lean \(version 4\.34\.0(?:,|\)).*Release\)?$/;
const expectedGitHash='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';

function executableCandidates(){
  const exe=process.platform==='win32'?'lean.exe':'lean';
  const configured=process.env.LEAN434_BIN?.trim();
  const candidates=[];
  if(configured){
    candidates.push(configured);
    candidates.push(path.join(configured,exe));
  }
  candidates.push(
    path.resolve(
      'study','lean4-4.34.0','build','release','stage1','bin',exe,
    ),
  );
  candidates.push(exe);
  return [...new Set(candidates)];
}

function probe(candidate,args){
  return spawnSync(candidate,args,{
    cwd:process.cwd(),
    encoding:'utf8',
    windowsHide:true,
  });
}

function findLean(){
  for(const candidate of executableCandidates()){
    const version=probe(candidate,['--version']);
    if(version.error||version.status!==0)continue;
    const first=(version.stdout||version.stderr||'').trim().split(/\r?\n/u)[0]??'';
    if(!expectedVersion.test(first))continue;
    const hash=probe(candidate,['--githash']);
    if(hash.error||hash.status!==0)continue;
    const githash=(hash.stdout||hash.stderr||'').trim();
    if(githash!==expectedGitHash)continue;
    return {candidate,version:first,githash};
  }
  throw new Error(
    'Lean 4.34.0 Release at pinned commit not found. '+
    'Set LEAN434_BIN to the Lean executable or its bin directory.',
  );
}

const args=process.argv.slice(2);
let outputPath=null;
const outIndex=args.indexOf('--out');
if(outIndex>=0){
  if(outIndex+1>=args.length)throw new Error('--out requires a path');
  outputPath=args[outIndex+1];
  args.splice(outIndex,2);
}
const moduleName=args[0]??'Init.Prelude';
if(args.length>1){
  throw new Error(
    'usage: node scripts/generate-lean434-runtime-metadata.mjs '+
    '[Module.Name] [--out path]',
  );
}

const lean=findLean();
const run=probe(lean.candidate,[
  '--run',
  'oracle/replay-probe/RuntimeMetadataExport.lean',
  moduleName,
]);
if(run.error)throw run.error;
if(run.status!==0){
  process.stderr.write(run.stderr??'');
  throw new Error(
    'runtime metadata export failed with status '+String(run.status),
  );
}
const text=(run.stdout??'').trim();
const parsed=JSON.parse(text);
if(
  parsed?.format!=='proofscript-lean434-runtime-metadata'
  ||parsed?.formatVersion!==1
  ||parsed?.lean?.version!=='4.34.0'
  ||parsed?.lean?.githash!==expectedGitHash
){
  throw new Error('runtime metadata exporter returned an invalid document');
}

if(outputPath!==null){
  const absolute=path.resolve(outputPath);
  fs.mkdirSync(path.dirname(absolute),{recursive:true});
  fs.writeFileSync(absolute,JSON.stringify(parsed,null,2)+'\n');
  process.stdout.write(
    JSON.stringify({
      module:moduleName,
      output:absolute,
      externs:parsed.externs.length,
      implementedBy:parsed.implementedBy.length,
      initializers:parsed.initializers.length,
      lean:lean.version,
      githash:lean.githash,
    },null,2)+'\n',
  );
}else{
  process.stdout.write(JSON.stringify(parsed,null,2)+'\n');
}
