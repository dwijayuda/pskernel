import {createHash} from 'node:crypto';
import {readFileSync,statSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const defaultPackageRoot=path.resolve(here,'..');

export const wasmPrebuiltManifestFile='PREBUILT_WASM_MANIFEST.json';
export const wasmPrebuiltLauncherPath='wasm/pskernel-lean.cjs';
export const wasmPrebuiltModulePath='wasm/pskernel-lean.wasm';

const expected={
  schemaVersion:1,
  packageName:'@proofscript/pskernel-lean-wasm',
  packageVersion:'4.34.0',
  protocol:'pskernel-lean/1',
  provider:'lean4-cpp',
  leanVersion:'4.34.0',
  leanCommit:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  emscriptenVersion:'6.0.9',
};

function sha256File(filePath){
  return createHash('sha256').update(readFileSync(filePath)).digest('hex');
}

function artifactRecord(packageRoot,relativePath){
  const filePath=path.resolve(packageRoot,...relativePath.split('/'));
  const stat=statSync(filePath);
  if(!stat.isFile()||stat.size<=0){
    throw new Error(`Lean WASM prebuilt artifact missing or empty: ${relativePath}`);
  }
  return Object.freeze({
    path:relativePath,
    bytes:stat.size,
    sha256:sha256File(filePath),
  });
}

export function createWasmPrebuiltManifest({
  packageRoot=defaultPackageRoot,
  sourceCommit,
}={}){
  if(typeof sourceCommit!=='string'||sourceCommit.length===0){
    throw new TypeError('Lean WASM prebuilt sourceCommit must be a non-empty string');
  }
  return {
    ...expected,
    sourceCommit,
    artifacts:{
      launcher:artifactRecord(packageRoot,wasmPrebuiltLauncherPath),
      wasm:artifactRecord(packageRoot,wasmPrebuiltModulePath),
    },
  };
}

function assertField(manifest,key,value){
  if(manifest?.[key]!==value){
    throw new Error(
      `Lean WASM prebuilt manifest ${key} mismatch: ${String(manifest?.[key])}`,
    );
  }
}

function verifyArtifact(packageRoot,record,expectedPath,label){
  if(record?.path!==expectedPath){
    throw new Error(`Lean WASM prebuilt ${label} path mismatch: ${String(record?.path)}`);
  }
  const filePath=path.resolve(packageRoot,...expectedPath.split('/'));
  const stat=statSync(filePath);
  if(stat.size!==record.bytes){
    throw new Error(
      `Lean WASM prebuilt ${label} size mismatch: expected ${String(record.bytes)}, got ${String(stat.size)}`,
    );
  }
  const digest=sha256File(filePath);
  if(digest!==record.sha256){
    throw new Error(
      `Lean WASM prebuilt ${label} digest mismatch: expected ${String(record.sha256)}, got ${digest}`,
    );
  }
}

export function verifyWasmPrebuiltManifest({packageRoot=defaultPackageRoot}={}){
  const manifestPath=path.join(packageRoot,wasmPrebuiltManifestFile);
  let manifest;
  try{
    manifest=JSON.parse(readFileSync(manifestPath,'utf8'));
  }catch(cause){
    throw new Error(`failed to load Lean WASM prebuilt manifest: ${manifestPath}`,{cause});
  }

  for(const [key,value] of Object.entries(expected)){
    assertField(manifest,key,value);
  }
  if(typeof manifest.sourceCommit!=='string'||manifest.sourceCommit.length===0){
    throw new Error('Lean WASM prebuilt manifest sourceCommit is missing');
  }
  verifyArtifact(packageRoot,manifest.artifacts?.launcher,wasmPrebuiltLauncherPath,'launcher');
  verifyArtifact(packageRoot,manifest.artifacts?.wasm,wasmPrebuiltModulePath,'module');
  return manifest;
}
