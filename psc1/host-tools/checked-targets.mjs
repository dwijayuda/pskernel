// Independent target consumers. No parser/elaborator/IR transform is implemented here.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
const fail = (code) => {
  throw Error('PSC1_SERVICE_' + code);
};
const ownWasmTransport = fileURLToPath(new URL('./generated-wasm-transport.mjs', import.meta.url));
export function prepareCheckedTarget(stage, candidate, { target, typescript, rust }, run) {
  if (target === 'js') {
    fs.writeFileSync(path.join(stage, 'target.mjs'), candidate.source);
    return {
      targetFile: 'target.mjs',
      runtimeFile: 'target.mjs',
      files: ['target.mjs'],
      consumer: 'node22.23.3',
    };
  }
  if (target === 'ts') {
    if (!typescript || !path.isAbsolute(typescript.entry || ''))
      fail('TYPESCRIPT_CONSUMER_UNAVAILABLE');
    fs.writeFileSync(path.join(stage, 'target.ts'), candidate.source);
    const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-ts-consumer-'));
    try {
      fs.writeFileSync(path.join(work, 'target.ts'), candidate.source);
      const config = {
        compilerOptions: {
          target: 'ES2022',
          module: 'ES2022',
          moduleResolution: 'Bundler',
          strict: true,
          noEmitOnError: true,
          declaration: true,
          skipLibCheck: false,
          types: [],
          lib: ['ES2022', 'DOM'],
          outDir: './out',
        },
        files: ['./target.ts'],
      };
      fs.writeFileSync(path.join(work, 'tsconfig.json'), JSON.stringify(config));
      run('target-typescript', [typescript.entry, '--project', path.join(work, 'tsconfig.json')]);
      for (const [from, to] of [
        ['target.js', 'target.mjs'],
        ['target.d.ts', 'target.d.ts'],
      ])
        fs.copyFileSync(path.join(work, 'out', from), path.join(stage, to));
      fs.writeFileSync(path.join(stage, 'target-config.json'), JSON.stringify(config));
      return {
        targetFile: 'target.ts',
        runtimeFile: 'target.mjs',
        files: ['target.ts', 'target.mjs', 'target.d.ts', 'target-config.json'],
        consumer: 'typescript7.0.2-strict-noEmitOnError',
      };
    } finally {
      fs.rmSync(work, { recursive: true, force: true });
    }
  }
  if (target === 'rust') {
    if (!rust || !path.isAbsolute(rust.rustc || '') || !path.isAbsolute(rust.inspector || ''))
      fail('RUST_CONSUMER_UNAVAILABLE');
    const file = path.join(stage, 'target.rs');
    fs.writeFileSync(file, candidate.source);
    const names = run('target-rust-api', [file], rust.inspector)
      .trim()
      .split('\\n')
      .filter(Boolean)
      .sort();
    if (JSON.stringify(names) !== JSON.stringify([...candidate.publicNames].sort()))
      fail('TARGET_API_MISMATCH');
    const args = [
      '--edition=2021',
      '--crate-name',
      'proofscript_generated',
      '--crate-type',
      'rlib',
      '--sysroot',
      rust.sysroot,
      '-L',
      'dependency=' + rust.dependencyDirectory,
      ...rust.externs.flatMap((row) => ['--extern', row.name + '=' + row.file]),
      file,
      '-o',
      path.join(stage, 'libproofscript.rlib'),
    ];
    run('target-rust-typecheck', args, rust.rustc);
    fs.writeFileSync(
      path.join(stage, 'target-consumer.json'),
      JSON.stringify({
        schema: 'psc1-rust-target-consumer-receipt/1',
        rustVersion: '1.90.0',
        platform: 'linux-x64',
        crateType: 'rlib',
        publicNames: candidate.publicNames,
        dependencyFiles: rust.externs.map((row) => ({
          name: row.name,
          file: path.basename(row.file),
        })),
      }),
    );
    return {
      targetFile: 'target.rs',
      runtimeFile: 'libproofscript.rlib',
      files: ['target.rs', 'libproofscript.rlib', 'target-consumer.json'],
      consumer: 'rust1.90.0-locked-dependencies-syn2.0.106-public-values',
    };
  }
  if (target === 'wasm-core') {
    if (candidate.outputAbi) fail('WASM_ABI_UNSUPPORTED');
    const declarations = candidate.specializedIr[4];
    const publicTypes = candidate.publicNames.map((name) => {
      const rows = declarations.filter((row) => Array.isArray(row) && row[0] === name);
      if (rows.length !== 1 || rows[0].length !== 5 || rows[0][1].length)
        fail('WASM_ABI_UNSUPPORTED');
      const row = rows[0];
      const primitive = (type) => {
        if (
          !Array.isArray(type) ||
          type.length !== 2 ||
          type[0] !== 'primitive' ||
          !['nat', 'int', 'bool', 'string', 'unit'].includes(type[1])
        )
          fail('WASM_ABI_UNSUPPORTED');
        return type;
      };
      return {
        name,
        parameters: row[2].map((parameter) => {
          if (!Array.isArray(parameter) || parameter.length !== 2) fail('WASM_ABI_UNSUPPORTED');
          return primitive(parameter[1]);
        }),
        result: primitive(row[3]),
      };
    });
    // Copy the already qualified typed transport into the immutable generation.
    fs.copyFileSync(ownWasmTransport, path.join(stage, 'target-wasm-transport.mjs'));
    fs.writeFileSync(path.join(stage, 'target.wasm.hex'), candidate.source);
    const prefix = 'psc1-wasm-hex/1:',
      hex = candidate.source.slice(prefix.length);
    if (
      !candidate.source.startsWith(prefix) ||
      !hex.length ||
      hex.length % 2 ||
      !/^[a-f0-9]+$/.test(hex)
    )
      fail('WASM_SOURCE_ENCODING');
    fs.writeFileSync(path.join(stage, 'target.wasm'), Buffer.from(hex, 'hex'));
    fs.writeFileSync(
      path.join(stage, 'target-api.json'),
      JSON.stringify({ publicTypes, publicNames: candidate.publicNames }),
    );
    fs.writeFileSync(
      path.join(stage, 'target.mjs'),
      "import fs from 'node:fs';import {loadWasmApi} from './target-wasm-transport.mjs';" +
        "const meta=JSON.parse(fs.readFileSync(new URL('./target-api.json',import.meta.url)));" +
        "export default loadWasmApi(fs.readFileSync(new URL('./target.wasm',import.meta.url)),meta.publicTypes,meta.publicNames);\n",
    );
    return {
      targetFile: 'target.wasm',
      runtimeFile: 'target.mjs',
      files: [
        'target.wasm.hex',
        'target.wasm',
        'target-api.json',
        'target-wasm-transport.mjs',
        'target.mjs',
      ],
      consumer: 'node22.23.3-WebAssembly-GC-import-free-typed-transport',
    };
  }
  fail('CHECKED_TARGET_UNSUPPORTED');
}
