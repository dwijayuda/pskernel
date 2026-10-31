#!/usr/bin/env node
// Development-only native Rust PSC + official native Lean kernel.
// This is a genuine generated compiler behind the existing checked host,
// not a replacement frontend, unchecked compiler or released npm entry point.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createGeneratedJsCompilerSession} from '../host-tools/generated-compiler-session.mjs';
import {runGeneratedRustCompiler} from '../host-tools/generated-rust-transport.mjs';
import {readInput} from '../npm-cli/cli-project.mjs';
import {verifyArtifact} from '../host-tools/generated-target-tools.mjs';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const digest=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const usage='Usage: node scripts/native-psc-preview.mjs compile Main.ps | build Main.ps DIST_DIR\n'
 +'Developer preview: genuine native Rust PSC G1 plus official Lean 4.35 native kernel; JS output only.\n'
 +'Requires a successful current-source Rust unified G1 CI generation and the pinned Lake checker.\n';
function pin(file){
  const stat=fs.lstatSync(file);
  assert.ok(stat.isFile()&&!stat.isSymbolicLink(),'PSC1_NATIVE_FILE_KIND: '+file);
  return {path:file,sha256:digest(fs.readFileSync(file))};
}
function resources(){
  const dir=path.join(root,'dist/generated-unified-rust-compiler');
  const file=path.join(dir,'G1-service/artifact.json');
  const qualified=path.join(dir,'qualification.json');
  const receipt=JSON.parse(fs.readFileSync(qualified,'utf8'));
  const artifactPin=pin(file);
  const artifact=verifyArtifact(file,artifactPin.sha256);
  assert.equal(receipt.schema,'psc1-generated-target-qualification/1');
  assert.equal(receipt.status,'passed');
  assert.equal(receipt.target,'rust');
  assert.equal(receipt.serviceKind,'unified');
  assert.equal(receipt.mode,'--g1-only');
  assert.equal(receipt.correctnessQualification,'G1-only');
  assert.equal(receipt.fixedPoint,'not-requested');
  assert.equal(receipt.generations?.length,1);
  assert.equal(receipt.generations[0].generation,1);
  assert.equal(receipt.generations[0].artifactSha256,artifactPin.sha256);
  assert.equal(receipt.serviceArtifact?.sha256,artifactPin.sha256);
  assert.equal(artifact.service,true);
  assert.equal(artifact.serviceKind,'unified');
  assert.equal(artifact.target,'rust');
  assert.deepEqual(artifact.publicNames,['psCompilerServiceCandidate']);
  const executable=path.join(path.dirname(file),artifact.executable);
  const binaryPin=pin(executable);
  assert.equal(binaryPin.sha256,artifact.files.find(row=>row.path===artifact.executable)?.sha256);
  const checker=pin(path.join(root,'.lake/build/bin/psc1_independent_checker'));
  const runner=pin(path.join(root,'host-tools/execution/unified-candidate-runner.mjs'));
  const dependent=[
    artifactPin,pin(qualified),
    pin(path.join(root,'host-tools/generated-rust-guard.mjs')),
    pin(path.join(root,'host-tools/generated-rust-transport.mjs'))
  ];
  return {executable,binaryPin,checker,runner,dependent,receipt};
}
export function nativePreview({operation,sourceFile,out}){
  assert.ok(['compile','build'].includes(operation),'PSC1_NATIVE_OPERATION');
  const absolute=path.resolve(sourceFile);
  const kind=path.extname(absolute).slice(1);
  const entryModule=path.basename(absolute,'.'+kind);
  assert.ok(['ps','lean'].includes(kind),'PSC1_NATIVE_GRAMMAR');
  assert.match(entryModule,/^[A-Za-z_][A-Za-z0-9_]*$/);
  const captured=readInput(absolute);
  const sources=[{module:entryModule,kind,text:captured.text}];
  const native=resources();
  const scratch=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-native-preview-'));
  const publicationRoot=operation==='build'?path.resolve(out):path.join(scratch,'store');
  try {
    const serviceExecute=request=>runGeneratedRustCompiler({
      executable:native.executable,
      executableSha256:native.binaryPin.sha256,
      request,
      timeoutMs:240000,
    });
    const session=createGeneratedJsCompilerSession({
      requestId:'psc1-native-preview-'+crypto.randomUUID(),
      sources,
      entryModule,
      assurance:'checked',
      outputAbi:'scalar',
      target:'js',
      publicationProtocol:'portable-file',
      evidence:'minimal',
      operation:'compile',
      serviceKind:'unified-bundle',
      serviceFile:native.executable,
      serviceSha256:native.binaryPin.sha256,
      serviceExecute,
      runnerFile:native.runner.path,
      runnerSha256:native.runner.sha256,
      checkerExecutable:native.checker.path,
      checkerSha256:native.checker.sha256,
      publicationRoot,
      serviceDependencies:native.dependent,
    });
    const receipt=session.execute();
    assert.equal(receipt.logicalAdmission,'accepted');
    assert.equal(receipt.target,'js');
    assert.equal(typeof receipt.targetArtifact.consumer,'string');
    const summary={
      schema:'psc1-native-rust-lean435-preview/1',
      status:'accepted',
      compiler:'generated-rust-native-G1',
      kernel:'official-Lean-4.35.0-native',
      sourceClosureDigest:receipt.sourceClosureDigest,
      nativeCompilerSha256:native.binaryPin.sha256,
      nativeCheckerSha256:native.checker.sha256,
      target:'js',
      timings:receipt.timings,
      irValidation:'original-and-transformed-by-existing-checked-host',
      fixedPoint:'not-claimed-for-this-G1-source',
      preservationProof:'not-provided',
    };
    if(operation==='build'){
      const published=session.publish();
      return {...summary,operation,publication:published,receipt};
    }
    const name=receipt.targetArtifact.sourceFile||'target.mjs';
    const source=fs.readFileSync(path.join(session.stagingDirectory,name),'utf8');
    assert.equal(digest(source),receipt.sourceSha256);
    return {...summary,operation,source,receipt};
  } finally {
    fs.rmSync(scratch,{recursive:true,force:true});
  }
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  try{
    const [operation,sourceFile,out,...extra]=process.argv.slice(2);
    if(operation==='--help'||operation==='-h'){process.stdout.write(usage);}
    else{
      assert.ok(['compile','build'].includes(operation)&&sourceFile&&!extra.length&&
        (operation==='compile'?out===undefined:typeof out==='string'&&out.length>0),usage);
      const response=nativePreview({operation,sourceFile,out});
      process.stdout.write(JSON.stringify(response)+'\n');
    }
  }catch(error){
    console.error('PSC1_NATIVE_PREVIEW_REFUSED: '+error.message);
    process.exitCode=1;
  }
}
