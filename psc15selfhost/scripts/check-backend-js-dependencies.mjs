import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { collectBackendJsClosure } from './backend-js-closure.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
console.log(`BACKEND_JS_DEPENDENCIES: PASS (${collectBackendJsClosure(root).length} source modules)`);
