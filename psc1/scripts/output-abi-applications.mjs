// Authored application fixtures and existing bounded IO consumers.
// No compiler, parser, JSON transform or IO implementation is reproduced here.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { boundedRun, sha } from '../host-tools/generated-target-tools.mjs';

export function applicationFixtures(convertToPs) {
  const fixtures = [];
  for (const grammar of ['lean', 'ps']) for (const application of ['cli-json', 'compiler-like']) {
    const entry = application === 'cli-json' ? 'PracticalCli.Run' : 'MiniCompiler.Run';
    const sources = [], seen = new Set(), active = new Set();
    function visit(module) {
      if (seen.has(module)) return;
      assert.equal(active.has(module), false, 'authored fixture import cycle');
      active.add(module);
      const relative = module.replaceAll('.', '/') + '.lean';
      const file = ['test/applications', 'stdlib'].map(base => path.join(base, relative))
        .find(candidate => fs.existsSync(candidate));
      assert.ok(file, 'authored application module ' + module);
      const text = fs.readFileSync(file, 'utf8');
      for (const match of text.matchAll(/^import\s+(.+)$/gm))
        for (const dependency of match[1].trim().split(/\s+/)) visit(dependency);
      active.delete(module); seen.add(module); sources.push({ module, kind: 'lean', text });
    }
    visit(entry);
    const contractPath = application === 'cli-json'
      ? 'docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json'
      : 'docs/PSC1_COMPILER_APPLICATION_CONTRACT.json';
    const bytes = fs.readFileSync(contractPath), contract = JSON.parse(bytes);
    fixtures.push({ id: grammar + '-' + application, grammar, application, entry,
      sources: grammar === 'ps' ? convertToPs(sources, entry) : sources, contract, contractSha256: sha(bytes) });
  }
  return fixtures;
}

export function executeApplication(fixture, moduleFile, directory) {
  const compiler = fixture.application === 'compiler-like';
  const valid = '[{"text":"A","count":2},{"text":"\\uD83D\\uDE00","count":-4}]';
  const cliInputs = {
    help: { args: ['--help'] },
    'invalid-command': { args: ['bad'] },
    'invalid-arity': { args: ['transform', 'input.json'] },
    'invalid-help-arity': { args: ['--help', 'extra'] },
    'unicode-records': { input: valid },
    'argv-unicode-quote': { input: valid, inputName: 'in "Ω😀.json',
      args: ['transform', 'in "Ω😀.json', 'output.json'] },
    'bounded-output': { input: JSON.stringify([{ text: 'a'.repeat(480), count: 0 }]) },
    'empty-records': { input: '[]' },
    'array-trailing-comma': { input: '[{"text":"A","count":1}, ]' },
    'object-trailing-comma': { input: '[{"text":"A","count":1, }]' },
    'malformed-json': { input: '{' },
    'isolated-surrogate': { input: '[{"text":"\\uD800","count":1}]' },
    'duplicate-key': { input: '[{"text":"A","text":"B","count":1}]' },
    'wrong-shape': { input: '[{"text":false,"count":1}]' },
    'missing-input': { missing: true },
    'path-denied': { args: ['transform', '../input.json', 'output.json'] },
    'read-permission': { input: valid, readMode: 0 },
    'invalid-utf8': { input: Buffer.from([0xff]) },
    'bounded-file': { input: ' '.repeat(513) },
    'write-permission': { input: valid, writeMode: 0o500 },
    'denied-capability': { denied: true },
  };
  fs.mkdirSync(directory, { recursive: true });
  const records = [];
  for (const expected of fixture.contract.cases) {
    const test = compiler ? { ...expected, input: expected.repeat
      ? expected.repeat.repeat(expected.count) : expected.input } : cliInputs[expected.id];
    assert.ok(test, 'exact application fixture ' + expected.id);
    const folder = path.join(directory, expected.id); fs.mkdirSync(folder);
    const input = path.join(folder, test.inputName || (compiler ? 'input.mini' : 'input.json'));
    const output = path.join(folder, 'output.json'), config = path.join(directory, expected.id + '.json');
    if (!test.missing) fs.writeFileSync(input, test.input ?? valid);
    fs.writeFileSync(output, 'previous');
    if (test.readMode !== undefined) fs.chmodSync(input, test.readMode);
    if (test.writeMode !== undefined) fs.chmodSync(folder, test.writeMode);
    fs.writeFileSync(config, JSON.stringify({
      abi: 'psc1-node-linux-string-io/1',
      capabilities: test.denied ? [] : ['readUtf8', 'writeUtf8', 'writeLine'],
      required: ['readUtf8', 'writeUtf8', 'writeLine'], root: folder,
      maxFileBytes: compiler ? 1048576 : 512, maxLineBytes: 128, inputFd: 0, outputFd: 1,
    }));
    let result;
    try {
      result = boundedRun(process.execPath, [path.resolve('scripts/practical-application-node.mjs'),
        'js', test.denied ? '/missing-guest' : moduleFile, config,
        ...(test.args || ['transform', compiler ? 'input.mini' : 'input.json', 'output.json'])],
        { logDirectory: path.join(directory, expected.id + '-process'),
          timeoutMs: test.performance ? 120000 : 240000, timeoutPolicy: 'standard-240s' });
    } finally {
      fs.chmodSync(folder, 0o700);
      if (fs.existsSync(input)) fs.chmodSync(input, 0o600);
    }
    assert.equal(result.error, null, fixture.id + '/' + expected.id + ':' + result.stderr);
    assert.equal(result.status, expected.exitCode ?? expected.code,
      fixture.id + '/' + expected.id + ':' + result.stdout + result.stderr);
    assert.equal(result.stdout, expected.stdout, fixture.id + '/' + expected.id);
    assert.equal(fs.readFileSync(output, 'utf8'), expected.output ?? 'previous');
    assert.deepEqual(fs.readdirSync(folder).filter(name => name.startsWith('.psc1-')), []);
    if (test.performance) {
      assert.ok(result.elapsedMs <= 120000, 'actual compiler application deadline');
      assert.ok(result.maxRssKiB <= fixture.contract.performance.maxRssKiB,
        'actual compiler application memory policy');
    }
    records.push({ id: expected.id, exitCode: result.status, stdoutSha256: sha(result.stdout),
      outputSha256: sha(fs.readFileSync(output)), preservedPrevious: expected.output === undefined,
      elapsedMs: result.elapsedMs, maxRssKiB: result.maxRssKiB });
  }
  return records;
}
