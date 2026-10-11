import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
const output = await import(pathToFileURL(path.resolve(process.argv[2])).href);
assert.equal(output.answer, 42n);
assert.equal(output.keep(7n), 7n);
console.log('PSCV0_NATIVE_RUNTIME: PASS checked current-source v7 application -> TypeScript -> JavaScript');
