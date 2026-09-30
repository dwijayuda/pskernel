import {writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createWasmPrebuiltManifest} from '../host/prebuilt.mjs';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const sourceCommit=
  process.env.PSC_LEAN_WASM_SOURCE_COMMIT ??
  process.env.GITHUB_SHA ??
  'package-local-source';

const manifest=createWasmPrebuiltManifest({packageRoot,sourceCommit});
await writeFile(
  path.join(packageRoot,'PREBUILT_WASM_MANIFEST.json'),
  JSON.stringify(manifest,null,2)+'\n',
  'utf8',
);
console.log(
  `PSC2_LEAN_KERNEL_WASM_PREBUILT_MANIFEST: PASS ${manifest.artifacts.wasm.bytes} bytes`,
);
