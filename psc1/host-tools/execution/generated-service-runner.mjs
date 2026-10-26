// Host transport only: the approved generated module owns compiler semantics.
import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
const [servicePath, expectedServiceHash, requestPath, outputPath] = process.argv.slice(2);
if (!servicePath || !expectedServiceHash || !requestPath || !outputPath)
  throw new Error('PSC1_GENERATED_RUNNER_ARGUMENTS');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const started = Date.now();
const serviceBytes = fs.readFileSync(servicePath);
if (sha(serviceBytes) !== expectedServiceHash) throw new Error('PSC1_SERVICE_IDENTITY_MISMATCH');
const requestBytes = fs.readFileSync(requestPath);
const service = await import(pathToFileURL(servicePath).href);
if (Object.keys(service).join(',') !== 'psCompilerJsServiceCandidate' ||
    typeof service.psCompilerJsServiceCandidate !== 'function')
  throw new Error('PSC1_SERVICE_EXPORT_MISMATCH');
const response = service.psCompilerJsServiceCandidate(requestBytes.toString('utf8'));
if (typeof response !== 'string' || Buffer.byteLength(response) > 128 * 1024 * 1024)
  throw new Error('PSC1_SERVICE_RESPONSE_LIMIT');
if (sha(fs.readFileSync(servicePath)) !== expectedServiceHash ||
    sha(fs.readFileSync(requestPath)) !== sha(requestBytes))
  throw new Error('PSC1_SERVICE_INPUT_CHANGED');
fs.writeFileSync(outputPath + '.tmp', response, { flag: 'wx' });
fs.renameSync(outputPath + '.tmp', outputPath);
console.log(JSON.stringify({ protocol: 'psc1-generated-service-run/1',
  serviceSha256: expectedServiceHash, requestSha256: sha(requestBytes),
  responseSha256: sha(response), responseUtf8Bytes: Buffer.byteLength(response),
  elapsedMs: Date.now() - started, maxRssKiB: process.resourceUsage().maxRSS }));
