import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const cases = [
  ['Module', [
    'Generator<__ps$Request, R, unknown>',
    'new WeakMap<Function, Function>()',
    'while (pending.length !== 0)',
    'pending[pending.length - 1].next(value)',
    'if (next.done) { pending.pop(); value = next.value; }',
    'pending.push(Reflect.apply(implementation, undefined, args))',
    'else value = Reflect.apply(fn, undefined, args)',
    'return (yield { fn, args }) as R;',
    'let __ps$lastUtf8: __ps$Utf8View | undefined;',
    'if (__ps$lastUtf8?.text === text) return __ps$lastUtf8;',
    'if (__ps$previousUtf8?.text === text) return __ps$previousUtf8;',
    '__ps$previousUtf8 = __ps$lastUtf8;',
    'new Uint32Array(size + 1)',
    'position < 0n || position >= view.size',
    'positions[size] = text.length + 1;',
  ]],
  ['Expr', [
    'psTsEmitLetStatements emit body',
    'match psTsEmitLetStatements smaller expr with',
    '["(yield* __ps$invoke(", callable, generic, suffix, "))"]',
    '["__ps$utf8(", value, ").size"]',
    '["__ps$stringNext(", value, ", ", position, ")"]',
    '["__ps$stringGet(", value, ", ", position, ")"]',
  ]],
];
for (const [name, markers] of cases) {
  const source = await readFile(new URL(`../packages/backend-ts/src/Ps/BackendTs/${name}.lean`, import.meta.url), 'utf8');
  const validate = text => {
    for (const marker of markers) assert(text.includes(marker), `${name}: missing stack/runtime guard ${marker}`);
  };
  validate(source);
  for (const marker of markers) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
}
console.log('PSC2_STACK_SAFE_TS_SOURCE: PASS (explicit work stack, typed calls, flat let blocks and bounded UTF-8 cache)');
