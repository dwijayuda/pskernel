import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import * as path from 'node:path';
import { compileTypeScript } from '../src/typescript-compiler.js';

const directory=mkdtempSync(path.join(tmpdir(),'proofscript-ts7-contract-'));
const logicalFile=path.join(directory,'logical source.ts');
const unchanged=new Map<string,string>([
  [logicalFile,'export const stale: string = "disk source must stay";\n'],
  [path.join(directory,'logical source.js'),'original JavaScript\n'],
  [path.join(directory,'logical source.d.ts'),'original declaration\n'],
  [path.join(directory,'logical source.js.map'),'original source map\n'],
]);
const assertPreserved=():void=>{
  for(const [file,content] of unchanged)assert.equal(readFileSync(file,'utf8'),content);
  assert.deepEqual(readdirSync(directory).filter((name)=>name.startsWith('.psc-ts-')),[]);
};

try {
  for(const [file,content] of unchanged)writeFileSync(file,content);
  // A caller's unrelated config cannot redirect positional virtual compilation.
  writeFileSync(path.join(directory,'tsconfig.json'),JSON.stringify({
    compilerOptions:{noEmit:true,types:['a-type-package-that-does-not-exist']},
  }));
  const basic=compileTypeScript('export const fresh: number = 42;\n',logicalFile);
  assert.equal(basic.typescriptVersion,'7.0.2');
  assert.deepEqual(basic.diagnostics,[]);
  assert.match(basic.javascript,/export const fresh = 42;/);
  assert.match(basic.declaration,/export declare const fresh: number;/);
  assert.ok(!basic.javascript.includes('stale'));
  assert.ok(basic.javascript.endsWith('//# sourceMappingURL=logical%20source.js.map\n')||
    basic.javascript.endsWith('//# sourceMappingURL=logical%20source.js.map\r\n'));
  assert.ok(basic.sourceMap!==undefined);
  const map=JSON.parse(basic.sourceMap) as {
    version:number;file:string;sources:string[];sourceRoot:string;mappings:string;
  };
  assert.equal(map.version,3);
  assert.equal(map.file,'logical source.js');
  assert.deepEqual(map.sources,['logical%20source.ts']);
  assert.equal(map.sourceRoot,'');
  assert.ok(map.mappings.length>0);
  assert.ok(!JSON.stringify(basic).includes('.psc-ts-'));
  assertPreserved();

  // Resolution uses the virtual root's logical directory, including a TS sibling
  // and a package export's declaration. Only the root products are returned.
  writeFileSync(path.join(directory,'dependency.ts'),'export const relativeValue: number = 11;\n');
  const packageDirectory=path.join(directory,'node_modules','host-fixture');
  mkdirSync(packageDirectory,{recursive:true});
  writeFileSync(path.join(packageDirectory,'package.json'),JSON.stringify({
    name:'host-fixture',version:'1.0.0',type:'module',
    exports:{'.':{types:'./index.d.ts',import:'./index.js'}},
  }));
  writeFileSync(path.join(packageDirectory,'index.d.ts'),'export declare const packageValue: number;\n');
  writeFileSync(path.join(packageDirectory,'index.js'),'export const packageValue = 7;\n');
  const imported=compileTypeScript([
    'import { relativeValue } from "./dependency.js";',
    'import { packageValue } from "host-fixture";',
    'export const combined: number = relativeValue + packageValue;',
    '',
  ].join('\n'),logicalFile);
  assert.match(imported.javascript,/from ["']\.\/dependency\.js["']/);
  assert.match(imported.javascript,/from ["']host-fixture["']/);
  assert.match(imported.javascript,/export const combined/);
  assert.match(imported.declaration,/combined: number/);
  assert.ok(!imported.declaration.includes('declare const relativeValue'));
  assertPreserved();

  // The diagnostic keeps the public root name and TypeScript's own position/code.
  assert.throws(()=>compileTypeScript(
    'export const good = 1;\nexport const bad: number = "wrong";\n',logicalFile,
  ),(error:unknown)=>{
    assert.ok(error instanceof Error);
    assert.ok(error.message.startsWith('PS_TS_COMPILE_FAILED:\n'));
    assert.ok(error.message.includes(logicalFile+':2:14 TS2322:'));
    assert.ok(!error.message.includes('.psc-ts-'));
    return true;
  });
  assertPreserved();

  // Existing disk content must never stand in for the supplied virtual root in
  // an import cycle. This bounded CLI adapter refuses that basename dependence.
  assert.throws(()=>compileTypeScript(
    'import { stale } from "./logical source.js";\nexport const cycle = stale;\n',logicalFile,
  ),/PS_TS_VIRTUAL_SELF_REFERENCE_UNSUPPORTED/);
  assertPreserved();

  assert.throws(()=>compileTypeScript('export const value = 1;','virtual.d.ts'),
    /PS_TS_SOURCE_NAME_UNSUPPORTED/);
  assert.throws(()=>compileTypeScript('export const value = 1;',path.join(directory,'missing','value.ts')),
    /PS_TS_SOURCE_DIRECTORY_UNAVAILABLE/);
  assertPreserved();
  console.log('PS_ROOT_TYPESCRIPT7_CONTRACT '+JSON.stringify({
    schema:'psc-root-typescript7-contract-v1',typescript:'7.0.2',passed:true,
    cases:['virtual-source-and-existing-products','logical-map-name','config-independent-positional',
      'relative-typescript-import','package-export-import','root-output-selection',
      'logical-diagnostic-position','self-reference-refusal','declaration-input-refusal',
      'missing-directory-refusal','stage-cleanup'],
  }));
} finally {
  rmSync(directory,{recursive:true,force:true});
}
