// Candidate loading only. Source/project data never selects this graph or tools.
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { requireSupportedRuntime } from '../runtime-policy.mjs';
import { readManifestBytes, verify } from './verify.mjs';

const MAX_BYTES = 128 * 1024 * 1024;
const refuse = (code) => {
  throw Error('PSC1_EXECUTABLE_' + code);
};

export async function loadExecutableCompiler({ root, manifestFile, manifestSha256, variant }) {
  requireSupportedRuntime();
  if (
    !['js', 'ts'].includes(variant) ||
    !path.isAbsolute(root || '') ||
    !path.isAbsolute(manifestFile || '') ||
    !/^[a-f0-9]{64}$/.test(manifestSha256 || '')
  )
    refuse('LOAD_ARGUMENTS');
  if (fs.realpathSync(root) !== root || fs.realpathSync(manifestFile) !== manifestFile)
    refuse('LOAD_SYMLINK');
  const check = () => {
    return verify(root, readManifestBytes(manifestFile), manifestSha256);
  };
  const manifest = check();
  const module = await import(pathToFileURL(path.join(root, manifest.entry[variant])).href);
  if (typeof module.psCompilerServiceCandidate !== 'function') refuse('ENTRY_EXPORT');
  check();
  return Object.freeze({
    identity: Object.freeze({
      protocol: manifest.protocol,
      manifestSha256,
      sourceClosureDigest: manifest.sourceClosureDigest,
      variant,
      candidateOnly: true,
    }),
    verify: check,
    candidate(input) {
      if (typeof input !== 'string' || Buffer.byteLength(input) > MAX_BYTES) refuse('INPUT_BOUND');
      check();
      const output = module.psCompilerServiceCandidate(input);
      if (typeof output !== 'string' || Buffer.byteLength(output) > MAX_BYTES)
        refuse('OUTPUT_BOUND');
      check();
      return output;
    },
  });
}
