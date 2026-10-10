import { lstat, mkdir, readFile, readdir, open } from 'node:fs/promises';
import path from 'node:path';
import { checkedOutputPath } from './checked-artifact-publication.mjs';

const source = 'def answer : Nat := 42\n';
const launcher = 'node ./node_modules/proofscript/bin/psc.mjs';
const configuration = Object.freeze({
  profile: 'checked', entry: 'src/Main.ps', out: 'src/Main.ts', extensions: Object.freeze([]),
});

async function status(file) {
  try { return await lstat(file); }
  catch (error) { if (error.code === 'ENOENT') return undefined; throw error; }
}

async function ordinaryAncestors(directory) {
  const root = path.parse(directory).root;
  let current = root;
  for (const component of directory.slice(root.length).split(path.sep).filter(Boolean)) {
    current = path.join(current, component);
    const info = await status(current);
    if (!info) return;
    if (!info.isDirectory() || info.isSymbolicLink()) {
      throw new Error('PSC_INIT_DIRECTORY: require ordinary directories: ' + current);
    }
  }
}

function packageFragment(version) {
  return {
    scripts: {
      'ps:check': launcher + ' check src/Main.ps',
      'ps:build': launcher + ' build src/Main.ps --out src/Main.ts',
    },
    devDependencies: { proofscript: version },
    proofscript: configuration,
  };
}

function guide(version, existing) {
  const lines = [
    '# ProofScript starter', '',
    'The compiler checks this bounded ProofScript source through PSKernel Core,',
    'validates RuntimeIR, and checks generated TypeScript before publishing it.',
    'This does not claim full PSCV verification or a semantic-preservation theorem.', '',
    '## Install this exact compiler', '',
    'When this version is available on npm:', '', '```sh',
    existing
      ? 'npm install --save-dev --save-exact --ignore-scripts proofscript@' + version
      : 'npm install --ignore-scripts',
    '```', '',
    'For an unpublished preview, install its downloaded candidate tarball instead:',
    '', '```sh',
    'npm install --save-dev --save-exact --ignore-scripts "/absolute/path/proofscript-' + version + '.tgz"',
    '```', '',
    'Use the actual path to your extracted candidate. On Windows, use your drive path.',
    'Keep the resulting lockfile with the project. Init itself installs nothing.', '',
    '## Check and build', '', '```sh',
    launcher + ' check src/Main.ps',
    launcher + ' build src/Main.ps --out src/Main.ts',
    '```', '',
    'A successful build creates src/Main.ts and src/Main.checked.json.',
    'The receipt records the checks performed; it is not a portable proof.',
    'An invalid rebuild preserves the previous completed files.',
    'Do not edit generated files: the compiler refuses to overwrite user changes.', '',
  ];
  if (existing) {
    lines.push(
      '## Optional package.json additions', '',
      'Your existing package.json, scripts, dependencies, and tsconfig.json were preserved.',
      'Merge only the wanted entries below into the existing objects.',
      'Do not replace existing build scripts, dependencies, or enabled extensions.', '',
      '```json', JSON.stringify(packageFragment(version), null, 2), '```', '',
    );
  } else {
    lines.push(
      'The generated package.json also provides npm run check and npm run build.',
      'Its proofscript entry/out defaults allow psc check and psc build from this directory.', '',
    );
  }
  lines.push(
    '## Incremental TypeScript adoption', '',
    'The generated answer is a bigint. An ES2022 TypeScript consumer can import it',
    'with import { answer } from "./Main.js" under NodeNext module resolution.',
    'Run the checked ProofScript build before your TypeScript build.',
    'This starter covers one source module. For selected function/type exports',
    'and shared opaque values across two modules, use the checked-library example.',
    'Its proofscript.exports map selects neighboring facades from one checked bundle.',
    'Use psc examples --json to locate the installed examples, then copy them into your project.',
    'Richer FFI, general library resolution and LSP remain later work.', '',
    'The installed examples also include a simple TypeScript consumer and a rejected source.',
    'Optional development tooling is activated separately; this starter loads no extensions.', '',
    '## Optional psdev command demo', '',
    'Install the separately downloaded candidate in this project:', '', '```sh',
    'npm install --save-dev --save-exact --ignore-scripts "/absolute/path/psdev-' + version + '.tgz"',
    '```', '',
    'Merge this extensions entry into the existing package.json proofscript object,',
    'preserving its profile, entry, and out fields:', '', '```json',
    JSON.stringify({ extensions: [{ package: 'psdev', enable: ['command:dev'] }] }, null, 2),
    '```', '', '```sh',
    launcher + ' dev src/Main.ps --once --out src/Main.ts',
    '```', '',
    'Use dev --watch for source changes or dev --watch --tsc for the downstream TS project build.',
    'The isolated extension requests the build; the host still controls admission,',
    'validation, output publication, and extension reporting.',
    'Installing a package alone does not activate its commands.', '',
  );
  return lines.join('\n');
}

/**
 * Create only absent starter files. This command runs no npm or project code.
 * Preflight and exclusive creation protect existing files. It is not a multi-file
 * atomic filesystem operation: an I/O failure reports any files already created.
 */
export async function initProject({ directory = '.', cwd = process.cwd(), version } = {}) {
  if (typeof directory !== 'string' || directory.length === 0 ||
      typeof cwd !== 'string' || typeof version !== 'string' || version.trim() !== version ||
      !/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/u.test(version)) {
    throw new Error('PSC_INIT_ARGUMENT: require a directory and exact release version');
  }
  const projectRoot = checkedOutputPath(path.resolve(cwd, directory));
  await ordinaryAncestors(projectRoot);
  const packagePath = path.join(projectRoot, 'package.json');
  const packageStatus = await status(packagePath);
  const existing = packageStatus !== undefined;
  if (existing) {
    if (!packageStatus.isFile() || packageStatus.isSymbolicLink()) {
      throw new Error('PSC_INIT_PACKAGE_JSON: require an ordinary package.json');
    }
    let metadata;
    try { metadata = JSON.parse((await readFile(packagePath, 'utf8')).replace(/^\uFEFF/u, '')); }
    catch (cause) { throw new Error('PSC_INIT_PACKAGE_JSON: ' + packagePath, { cause }); }
    if (metadata === null || typeof metadata !== 'object' || Array.isArray(metadata)) {
      throw new Error('PSC_INIT_PACKAGE_JSON: require a JSON object');
    }
  } else if (await status(projectRoot) && (await readdir(projectRoot)).length > 0) {
    throw new Error('PSC_INIT_PACKAGE_REQUIRED: use an empty directory or an existing npm project');
  }

  const files = [];
  if (!existing) {
    files.push(['package.json', JSON.stringify({
      name: 'proofscript-project', private: true, type: 'module',
      scripts: {
        check: launcher + ' check src/Main.ps',
        build: launcher + ' build src/Main.ps --out src/Main.ts',
      },
      devDependencies: { proofscript: version },
      proofscript: configuration,
    }, null, 2) + '\n']);
  }
  files.push(['src/Main.ps', source], ['PROOFSCRIPT.md', guide(version, existing)]);
  const sourceDirectory = path.join(projectRoot, 'src');
  await ordinaryAncestors(sourceDirectory);
  for (const relative of ['src/Main.ps', 'src/Main.ts', 'src/Main.checked.json', 'PROOFSCRIPT.md']) {
    if (await status(path.join(projectRoot, relative))) {
      throw new Error('PSC_INIT_CONFLICT: preserve existing ' + relative);
    }
  }

  const createdFiles = [];
  try {
    await mkdir(projectRoot, { recursive: true });
    await mkdir(sourceDirectory, { recursive: true });
    await ordinaryAncestors(sourceDirectory);
    for (const [relative, content] of files) {
      const handle = await open(path.join(projectRoot, relative), 'wx');
      createdFiles.push(relative);
      try { await handle.writeFile(content, 'utf8'); }
      finally { await handle.close(); }
    }
  } catch (cause) {
    const code = cause.code === 'EEXIST' ? 'PSC_INIT_CONFLICT' : 'PSC_INIT_WRITE_FAILED';
    throw new Error(code + ': ' + cause.message + '; created files: ' +
      (createdFiles.join(', ') || 'none') + '. Existing files were not overwritten.', { cause });
  }
  return {
    projectRoot, mode: existing ? 'existing' : 'new', createdFiles,
    preservedFiles: existing ? ['package.json'] : [],
    nextSteps: [
      existing
        ? 'npm install --save-dev --save-exact --ignore-scripts proofscript@' + version
        : 'npm install --ignore-scripts',
      ...(existing
        ? [launcher + ' check src/Main.ps', launcher + ' build src/Main.ps --out src/Main.ts']
        : ['npm run check', 'npm run build']),
      'For an unpublished preview, install the exact candidate tarball as described in PROOFSCRIPT.md.',
    ],
    ...(existing ? { suggestedPackageChanges: packageFragment(version) } : {}),
  };
}
