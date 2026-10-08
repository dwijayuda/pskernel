import {createHash} from 'node:crypto';
import {
  existsSync,
  readFileSync,
} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

export const supportedLeanKernelProviderTargets=Object.freeze([
  'linux-x64',
  'linux-arm64',
  'darwin-x64',
  'darwin-arm64',
  'win32-x64',
]);

const expectedManifestIdentity=Object.freeze({
  schema:1,
  package:'@proofscript/pskernel-lean',
  packageVersion:'4.34.0',
  protocol:'pskernel-lean/1',
  provider:'lean4-cpp',
  leanVersion:'4.34.0',
  leanCommit:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  profile:'lean4.34-core',
});

const defaultPackageRoot=path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);

function executableName(platform){
  return platform==='win32'
    ? 'psc2_lean_kernel_provider.exe'
    : 'psc2_lean_kernel_provider';
}

function expectedExecutableNameForTarget(target){
  return executableName(target.startsWith('win32-')?'win32':'linux');
}

function assertInsidePackageRoot(packageRoot,relativePath){
  if(typeof relativePath!=='string'||relativePath.length===0){
    throw new Error('Lean kernel prebuilt manifest path must be a non-empty string');
  }
  const root=path.resolve(packageRoot);
  const resolved=path.resolve(root,relativePath);
  const relative=path.relative(root,resolved);
  if(relative.startsWith('..')||path.isAbsolute(relative)){
    throw new Error(`Lean kernel prebuilt path escapes package root: ${relativePath}`);
  }
  return resolved;
}

export function leanKernelProviderTargetKey({
  platform=process.platform,
  arch=process.arch,
}={}){
  const key=`${platform}-${arch}`;
  if(!supportedLeanKernelProviderTargets.includes(key)){
    throw new Error(
      `@proofscript/pskernel-lean@4.34.0 has no bundled provider for ${key}; `+
      `supported targets: ${supportedLeanKernelProviderTargets.join(', ')}`,
    );
  }
  return key;
}

export function loadLeanKernelPrebuiltManifest({
  packageRoot=defaultPackageRoot,
}={}){
  const manifestPath=path.join(packageRoot,'PREBUILT_MANIFEST.json');
  const manifest=JSON.parse(readFileSync(manifestPath,'utf8'));

  for(const [key,value] of Object.entries(expectedManifestIdentity)){
    if(manifest?.[key]!==value){
      throw new Error(
        `Lean kernel prebuilt manifest ${key} mismatch: ${String(manifest?.[key])}`,
      );
    }
  }

  if(!manifest.targets||typeof manifest.targets!=='object'||Array.isArray(manifest.targets)){
    throw new Error('Lean kernel prebuilt manifest targets must be an object');
  }
  const actualTargets=Object.keys(manifest.targets).sort();
  const expectedTargets=[...supportedLeanKernelProviderTargets].sort();
  if(JSON.stringify(actualTargets)!==JSON.stringify(expectedTargets)){
    throw new Error(
      `Lean kernel prebuilt manifest target set mismatch: ${actualTargets.join(', ')}`,
    );
  }

  for(const target of supportedLeanKernelProviderTargets){
    const entry=manifest.targets[target];
    if(!entry||typeof entry!=='object'){
      throw new Error(`Lean kernel prebuilt manifest missing target ${target}`);
    }
    const resolved=assertInsidePackageRoot(packageRoot,entry.path);
    const normalizedRelative=path.relative(path.resolve(packageRoot),resolved)
      .split(path.sep).join('/');
    const expectedPrefix=`prebuilt/${target}/`;
    if(!normalizedRelative.startsWith(expectedPrefix)){
      throw new Error(
        `Lean kernel prebuilt path for ${target} must live under ${expectedPrefix}`,
      );
    }
    if(path.basename(resolved)!==expectedExecutableNameForTarget(target)){
      throw new Error(`Lean kernel prebuilt executable name mismatch for ${target}`);
    }
    if(typeof entry.sha256!=='string'||!/^[0-9a-f]{64}$/u.test(entry.sha256)){
      throw new Error(`Lean kernel prebuilt sha256 is invalid for ${target}`);
    }
  }

  return manifest;
}

export function verifyLeanKernelPrebuiltBinary({
  binaryPath,
  target,
  manifest,
  packageRoot=defaultPackageRoot,
}){
  const entry=manifest?.targets?.[target];
  if(!entry){
    throw new Error(`Lean kernel prebuilt manifest missing target ${target}`);
  }
  const expectedPath=assertInsidePackageRoot(packageRoot,entry.path);
  if(path.resolve(binaryPath)!==expectedPath){
    throw new Error(`Lean kernel prebuilt path mismatch for ${target}`);
  }
  const actual=createHash('sha256')
    .update(readFileSync(binaryPath))
    .digest('hex');
  if(actual!==entry.sha256){
    throw new Error(
      `Lean kernel prebuilt checksum mismatch for ${target}: expected ${entry.sha256}, got ${actual}`,
    );
  }
}

export function resolveLeanKernelProviderBinary({
  platform=process.platform,
  arch=process.arch,
  env=process.env,
  packageRoot=defaultPackageRoot,
  allowSourceCheckoutFallback=true,
}={}){
  if(env?.PSC_LEAN_KERNEL_PROVIDER_BIN){
    return {
      binaryPath:env.PSC_LEAN_KERNEL_PROVIDER_BIN,
      source:'override',
    };
  }

  const target=leanKernelProviderTargetKey({platform,arch});
  let manifest=null;
  try{
    manifest=loadLeanKernelPrebuiltManifest({packageRoot});
  }catch(error){
    if(error?.code!=='ENOENT'){
      throw error;
    }
  }

  if(manifest){
    const bundledPath=assertInsidePackageRoot(
      packageRoot,
      manifest.targets[target].path,
    );
    if(existsSync(bundledPath)){
      return {
        binaryPath:bundledPath,
        source:'bundled',
        target,
        manifest,
      };
    }
  }

  const workspaceRoot=path.resolve(packageRoot,'../..');
  const lakeBinary=path.join(
    workspaceRoot,
    '.lake',
    'build',
    'bin',
    executableName(platform),
  );
  if(allowSourceCheckoutFallback&&existsSync(lakeBinary)){
    return {
      binaryPath:lakeBinary,
      source:'source-checkout',
      target,
    };
  }

  throw new Error(
    `bundled Lean kernel provider is missing for ${target}`+
    (allowSourceCheckoutFallback?'; no source-checkout Lake binary is available':''),
  );
}
