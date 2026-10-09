import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, mkdir, writeFile, readFile, readdir, rm, symlink, chmod } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { checkedOutputPath, publishCheckedArtifacts } from './checked-artifact-publication.mjs';

// Orchestration fixtures only: these strings/receipts are not compiler proofs.
async function fixture(fn) {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc0 publication λ '));
  const entryPath = path.join(directory, 'Main.ps');
  await writeFile(entryPath, 'source');
  const publish = (artifacts, options = {}) => publishCheckedArtifacts({
    entryPath, outputPath: path.join(directory, 'answer.ts'),
    artifacts: new Map(Object.entries(artifacts)), receipt: { fixture: true },
    ...options,
  });
  try { await fn({ directory, entryPath, publish }); }
  finally { await rm(directory, { recursive: true, force: true }); }
}
const hash = value => createHash('sha256').update(value).digest('hex');
test('accepted bytes and completion receipt match, including a subsequent owned update', () => fixture(async ({ directory, publish }) => {
  const first = await publish({ 'answer.ts': 'first' });
  assert.equal(first.outputOwner, 'Main.ps');
  assert.equal(first.artifacts[0].sha256, hash('first'));
  assert.deepEqual(JSON.parse(await readFile(path.join(directory, 'answer.checked.json'), 'utf8')), first);
  const second = await publish({ 'answer.ts': 'second' });
  assert.notEqual(second.transactionId, first.transactionId);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'second');
  assert.equal(second.artifacts[0].sha256, hash('second'));
  assert.equal(existsSync(path.join(directory, '.psc-output-lock')), false);
}));
test('handwritten output is preserved and receives no ownership receipt', () => fixture(async ({ directory, publish }) => {
  await writeFile(path.join(directory, 'answer.ts'), 'handwritten');
  await assert.rejects(publish({ 'answer.ts': 'generated' }), /OUTPUT_UNOWNED/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'handwritten');
  assert.equal(existsSync(path.join(directory, 'answer.checked.json')), false);
  assert.equal(existsSync(path.join(directory, '.psc-output-lock')), false);
}));
test('manual edits to previously generated output are never overwritten', () => fixture(async ({ directory, publish }) => {
  await publish({ 'answer.ts': 'first' });
  const receipt = await readFile(path.join(directory, 'answer.checked.json'));
  await writeFile(path.join(directory, 'answer.ts'), 'user edit');
  await assert.rejects(publish({ 'answer.ts': 'second' }), /OUTPUT_MODIFIED/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'user edit');
  assert.deepEqual(await readFile(path.join(directory, 'answer.checked.json')), receipt);
}));
test('freshness or cancellation failure leaves the previous completed generation intact', () => fixture(async ({ directory, publish }) => {
  await publish({ 'answer.ts': 'first' });
  const receipt = await readFile(path.join(directory, 'answer.checked.json'));
  await assert.rejects(publish({ 'answer.ts': 'second' }, {
    beforeCommit() { throw new Error('source superseded'); },
  }), /source superseded/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'first');
  assert.deepEqual(await readFile(path.join(directory, 'answer.checked.json')), receipt);
}));
test('one publisher owns an output while validation yields', () => fixture(async ({ directory, publish }) => {
  let release, entered;
  const ready = new Promise(resolve => { entered = resolve; });
  const held = new Promise(resolve => { release = resolve; });
  const first = publish({ 'answer.ts': 'first' }, { beforeCommit: async () => { entered(); await held; } });
  await ready;
  try { await assert.rejects(publish({ 'answer.ts': 'second' }), /OUTPUT_BUSY/); }
  finally { release(); }
  await first;
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'first');
}));
test('TS-only publication retires only owned old JavaScript siblings', () => fixture(async ({ directory, publish }) => {
  await publish({ 'answer.ts': 'first', 'answer.js': 'old js', 'answer.js.map': '{}' }, {
    outputPath: path.join(directory, 'answer.js'),
  });
  await publish({ 'answer.ts': 'second' });
  assert.equal(existsSync(path.join(directory, 'answer.js')), false);
  assert.equal(existsSync(path.join(directory, 'answer.js.map')), false);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'second');
}));
test('changed ownership during validation is detected without discarding the user edit', () => fixture(async ({ directory, publish }) => {
  await publish({ 'answer.ts': 'first' });
  await assert.rejects(publish({ 'answer.ts': 'second' }, {
    beforeCommit: () => writeFile(path.join(directory, 'answer.ts'), 'concurrent edit'),
  }), /OUTPUT_CHANGED_DURING_BUILD/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'concurrent edit');
}));
test('a real partial rename failure restores the complete preceding generation', () => fixture(async ({ directory, publish }) => {
  await publish({ 'answer.ts': 'first', 'answer.js': 'first js' }, {
    outputPath: path.join(directory, 'answer.js'),
  });
  const receipt = await readFile(path.join(directory, 'answer.checked.json'));
  await assert.rejects(publish({ 'answer.ts': 'second', 'answer.js': 'second js' }, {
    outputPath: path.join(directory, 'answer.js'),
    beforeCommit: async () => {
      // Model an I/O failure after the first rename by withdrawing the second
      // staged file. This uses the real filesystem, not a replaceable fs adapter.
      const [stage] = (await readdir(directory)).filter(name => name.startsWith('.psc-stage-'));
      assert.ok(stage);
      await rm(path.join(directory, stage, 'answer.js'));
    },
  }), /ENOENT/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'first');
  assert.equal(await readFile(path.join(directory, 'answer.js'), 'utf8'), 'first js');
  assert.deepEqual(await readFile(path.join(directory, 'answer.checked.json')), receipt);
  assert.equal(existsSync(path.join(directory, '.psc-output-lock')), false);
}));
test('a first-generation partial failure leaves no new output or completion receipt', () => fixture(async ({ directory, publish }) => {
  await assert.rejects(publish({ 'answer.ts': 'new', 'answer.js': 'new js' }, {
    outputPath: path.join(directory, 'answer.js'),
    beforeCommit: async () => {
      const [stage] = (await readdir(directory)).filter(name => name.startsWith('.psc-stage-'));
      await rm(path.join(directory, stage, 'answer.js'));
    },
  }), /ENOENT/);
  assert.equal(existsSync(path.join(directory, 'answer.ts')), false);
  assert.equal(existsSync(path.join(directory, 'answer.js')), false);
  assert.equal(existsSync(path.join(directory, 'answer.checked.json')), false);
  assert.equal(existsSync(path.join(directory, '.psc-output-lock')), false);
}));
test('output names cannot escape the selected stem and symbolic links are refused', () => fixture(async ({ directory, publish }) => {
  await assert.rejects(publish({ 'answer.ts': 'safe', '../other.ts': 'bad' }), /OUTPUT_ARTIFACT_NAME/);
  const outside = path.join(directory, 'user');
  await mkdir(outside);
  const userFile = path.join(outside, 'user.ts');
  await writeFile(userFile, 'user');
  // Windows junctions exercise the reparse-point boundary without requiring
  // elevated file-symlink privileges; POSIX retains the regular-file symlink.
  await symlink(process.platform === 'win32' ? outside : userFile,
    path.join(directory, 'answer.ts'), process.platform === 'win32' ? 'junction' : 'file');
  await assert.rejects(publish({ 'answer.ts': 'generated' }), /OUTPUT_NOT_REGULAR/);
  assert.equal(await readFile(userFile, 'utf8'), 'user');
}));

test('invalidation observed after artifact writes restores the previous completed set', () => fixture(async ({ directory, publish }) => {
  await publish({ 'answer.ts': 'first', 'answer.js': 'old js' }, {
    outputPath: path.join(directory, 'answer.js'),
  });
  const receipt = await readFile(path.join(directory, 'answer.checked.json'));
  let eligibilityChecks = 0;
  await assert.rejects(publish({ 'answer.ts': 'second' }, {
    beforeCommit() { if (++eligibilityChecks === 2) throw new Error('source superseded before receipt'); },
  }), /source superseded before receipt/);
  assert.equal(eligibilityChecks, 2);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'first');
  assert.equal(await readFile(path.join(directory, 'answer.js'), 'utf8'), 'old js');
  assert.deepEqual(await readFile(path.join(directory, 'answer.checked.json')), receipt);
}));
test('incomplete rollback retains backups and never restores a stale receipt', () => fixture(async ({ directory, publish }) => {
  await publish({ 'answer.ts': 'first', 'answer.js': 'unchanged js' }, {
    outputPath: path.join(directory, 'answer.js'),
  });
  let eligibilityChecks = 0;
  await assert.rejects(publish({ 'answer.ts': 'second', 'answer.js': 'unchanged js' }, {
    outputPath: path.join(directory, 'answer.js'),
    beforeCommit: async () => {
      if (++eligibilityChecks === 2) {
        await writeFile(path.join(directory, 'answer.js'), 'concurrent user edit');
        throw new Error('superseded with an independently modified sibling');
      }
    },
  }), /OUTPUT_RECOVERY_REQUIRED/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'first');
  assert.equal(await readFile(path.join(directory, 'answer.js'), 'utf8'), 'concurrent user edit');
  assert.equal(existsSync(path.join(directory, 'answer.checked.json')), false);
  const lock = path.join(directory, '.psc-output-lock');
  const journal = JSON.parse(await readFile(path.join(lock, 'journal.json'), 'utf8'));
  assert.equal(existsSync(path.join(journal.staging, 'previous', 'answer.checked.json')), true);
  assert.equal(existsSync(path.join(lock, 'recovery.json')), true);
}));
test('a previously absent destination appearing during validation is preserved', () => fixture(async ({ directory, publish }) => {
  await assert.rejects(publish({ 'answer.ts': 'generated' }, {
    beforeCommit: () => writeFile(path.join(directory, 'answer.ts'), 'new user file'),
  }), /OUTPUT_CHANGED_DURING_BUILD/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'new user file');
  assert.equal(existsSync(path.join(directory, 'answer.checked.json')), false);
}));

test('overlapping stems share the output directory lease', () => fixture(async ({ directory, publish }) => {
  let release, entered;
  const ready = new Promise(resolve => { entered = resolve; });
  const held = new Promise(resolve => { release = resolve; });
  const first = publish({ 'answer.ts': 'first', 'answer.d.ts': 'declaration' }, {
    beforeCommit: async () => { entered(); await held; },
  });
  await ready;
  try {
    await assert.rejects(publish({ 'answer.d.ts': 'competing' }, {
      outputPath: path.join(directory, 'answer.d.ts'),
    }), /OUTPUT_BUSY/);
  } finally { release(); }
  await first;
  assert.equal(await readFile(path.join(directory, 'answer.d.ts'), 'utf8'), 'declaration');
}));
test('final artifact edits cannot acquire a completed receipt', () => fixture(async ({ directory, publish }) => {
  let checks = 0;
  await assert.rejects(publish({ 'answer.ts': 'generated' }, {
    beforeCommit: async () => {
      if (++checks === 2) await writeFile(path.join(directory, 'answer.ts'), 'late user edit');
    },
  }), /OUTPUT_RECOVERY_REQUIRED/);
  assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'late user edit');
  assert.equal(existsSync(path.join(directory, 'answer.checked.json')), false);
  assert.equal(existsSync(path.join(directory, '.psc-output-lock/recovery.json')), true);
}));
test('a receipt created after artifact writes is preserved and never overwritten', () => fixture(async ({ directory, publish }) => {
  let checks = 0;
  const external = 'user-created receipt bytes';
  await assert.rejects(publish({ 'answer.ts': 'generated' }, {
    beforeCommit: async () => {
      if (++checks === 2) await writeFile(path.join(directory, 'answer.checked.json'), external);
    },
  }), /OUTPUT_CHANGED_DURING_BUILD/);
  assert.equal(existsSync(path.join(directory, 'answer.ts')), false);
  assert.equal(await readFile(path.join(directory, 'answer.checked.json'), 'utf8'), external);
}));

test('cleanup failure is disclosed after commitment without rolling back valid outputs', {
  skip: process.platform === 'win32' ? 'Unix directory write permissions do not model Windows ACLs'
    : process.getuid?.() === 0 ? 'root bypasses the Unix directory permission fixture' : false,
}, () => fixture(async ({ directory, publish }) => {
  const lock = path.join(directory, '.psc-output-lock');
  const warnings = [];
  const originalWrite = process.stderr.write;
  let checks = 0;
  process.stderr.write = function (chunk, ...rest) {
    if (String(chunk).startsWith('PSC0_OUTPUT_COMMITTED_CLEANUP_REQUIRED: ')) {
      warnings.push(String(chunk));
      return true;
    }
    return originalWrite.call(this, chunk, ...rest);
  };
  try {
    const receipt = await publish({ 'answer.ts': 'committed' }, {
      beforeCommit: async () => { if (++checks === 2) await chmod(lock, 0o500); },
    });
    assert.equal(await readFile(path.join(directory, 'answer.ts'), 'utf8'), 'committed');
    assert.deepEqual(JSON.parse(await readFile(path.join(directory, 'answer.checked.json'), 'utf8')), receipt);
    assert.equal(warnings.length, 1);
    const detail = JSON.parse(warnings[0].slice('PSC0_OUTPUT_COMMITTED_CLEANUP_REQUIRED: '.length));
    assert.equal(detail.committed, true);
    assert.equal(detail.transactionId, receipt.transactionId);
    assert.equal(detail.lock, lock);
    assert(detail.paths.includes(lock));
  } finally {
    process.stderr.write = originalWrite;
    if (existsSync(lock)) await chmod(lock, 0o700);
  }
}));

test('ordinary output paths retain spaces, Unicode, and native path normalization', () => fixture(async ({ directory, entryPath, publish }) => {
  const outputPath = path.join(directory, 'nested space λ', 'answer.ts');
  const receipt = await publish({ 'answer.ts': 'unicode path' }, { outputPath });
  assert.equal(checkedOutputPath(outputPath), path.resolve(outputPath));
  assert.equal(receipt.outputOwner, '../Main.ps');
  assert.equal(await readFile(outputPath, 'utf8'), 'unicode path');
  assert.equal(await readFile(entryPath, 'utf8'), 'source');
}));

// These cases require native Windows pathname and case-insensitive filesystem
// semantics. They are additional Windows gates; no shared publication test is skipped.
if (process.platform === 'win32') {
  test('Windows output validation permits drive, UNC, and extended filesystem roots', () => {
    for (const output of [
      'C:\\Project Folder\\λ\\answer.ts',
      'c:/Project Folder/λ/answer.ts',
      '\\\\server\\Build Share\\λ\\answer.ts',
      '\\\\?\\C:\\Project Folder\\λ\\answer.ts',
      '\\\\?\\UNC\\server\\Build Share\\λ\\answer.ts',
    ]) assert.equal(checkedOutputPath(output), path.resolve(output), output);
  });
  test('Windows device aliases, streams, and ambiguous components fail before filesystem writes', () => fixture(async ({ directory, entryPath, publish }) => {
    const { buildChecked } = await import('./checked-build.mjs');
    const child = path.join(directory, 'must-not-be-created');
    const invalid = [
      ...['NUL.ts', 'con.data.js', 'AuX.ts', 'COM1.ts', 'lpt9.ts', 'COM¹.ts',
        'LPT².extra.js', 'stream:answer.ts', 'name|part.ts', 'tab\tname.ts']
        .map(name => path.join(child, name)),
      path.join(child, 'trailing.', 'answer.ts'),
      path.join(child, 'trailing ', 'answer.ts'),
      path.join(child, 'NUL', 'answer.ts'),
      path.join(child, 'CONOUT$', 'answer.ts'),
      '\\\\.\\C:\\answer.ts',
      '\\\\?\\GLOBALROOT\\Device\\HarddiskVolume1\\answer.ts',
    ];
    for (const outputPath of invalid) {
      assert.throws(() => checkedOutputPath(outputPath), /PSC0_OUTPUT_WINDOWS_PATH/, outputPath);
      await assert.rejects(publish({ [path.basename(outputPath)]: 'refused' }, { outputPath }),
        /PSC0_OUTPUT_WINDOWS_PATH/, outputPath);
      // A missing compiler makes validation order observable: these paths must
      // fail before compiler loading or target-staging writes can happen.
      await assert.rejects(buildChecked({ entryPath, outputPath,
        compilerPath: path.join(directory, 'missing-compiler.js') }),
        /PSC0_OUTPUT_WINDOWS_PATH/, outputPath);
    }
    assert.equal(existsSync(child), false);
    assert.deepEqual(await readdir(directory), ['Main.ps']);
  }));
  test('Windows directory-case and drive-case aliases cannot acquire a second publication lease', () => fixture(async ({ directory, publish }) => {
    const outputDirectory = path.join(directory, 'Owned Output');
    let release, entered;
    const ready = new Promise(resolve => { entered = resolve; });
    const held = new Promise(resolve => { release = resolve; });
    const first = publish({ 'answer.ts': 'first' }, {
      outputPath: path.join(outputDirectory, 'answer.ts'),
      beforeCommit: async () => { entered(); await held; },
    });
    await ready;
    try {
      const alias = path.join(directory, 'owned output', 'answer.ts')
        .replace(/^[A-Z]:/u, drive => drive.toLowerCase());
      await assert.rejects(publish({ 'answer.ts': 'second' }, { outputPath: alias }), /OUTPUT_BUSY/);
    } finally { release(); }
    await first;
    assert.equal(await readFile(path.join(outputDirectory, 'answer.ts'), 'utf8'), 'first');
  }));
}
