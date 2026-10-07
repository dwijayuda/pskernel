import assert from 'node:assert/strict';
import { test } from 'node:test';
import { decodePublicApi, publicApiArtifact } from './public-api-artifact.mjs';
import { canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';

const name = v => ({ k: 's', p: { k: 'a' }, v });
const variable = i => ({ k: 'b', i });
const forall = (n, t, b, bi = 'default') => ({ k: 'forall', n: name(n), t, b, bi });
const sort = { k: 'sort', l: { k: 's', o: { k: 'z' } } };
const generic = forall('A', sort, forall('value', variable(0), variable(1)));
const declaration = ['constant', 'definition', name('forward'), [], generic];
const root = entries => ['psc-public-api-ir/1', 'all-prepared-declarations', entries];
const bytes = entries => canonicalBytes(root(entries));

test('source generics and binder visibility survive exact body-free encoding', () => {
  const item = publicApiArtifact(bytes([declaration]));
  assert.deepEqual(decodePublicApi(item.bytes), root([declaration]));
  assert.equal(item.identity.domain, 'public-api');
  verifyArtifact(item.bytes, item.identity);
  const implicit = structuredClone(declaration); implicit[4].bi = 'implicit';
  assert.notEqual(publicApiArtifact(bytes([implicit])).identity.digest, item.identity.digest);
  const numerical = structuredClone(declaration); numerical[2] = { k: 'n', p: { k: 'a' }, v: '1' };
  const textual = structuredClone(numerical); textual[2] = name('1');
  assert.equal(decodePublicApi(bytes([numerical, textual]))[2].length, 2);
});

test('decoder rejects bodies, unresolved or escaping variables and duplicate declarations', () => {
  const withBody = [...declaration, { k: 'nat', v: '3' }];
  assert.throws(() => decodePublicApi(bytes([withBody])), /PUBLIC_API_SCHEMA/);
  assert.throws(() => decodePublicApi(bytes([declaration, declaration])), /DUPLICATE_DECLARATION/);
  for (const type of [{ k: 'mvar', i: 0 }, variable(0), forall('A', sort, variable(1))]) {
    assert.throws(() => decodePublicApi(bytes([[...declaration.slice(0, 4), type]])), /PUBLIC_API_/);
  }
  assert.throws(() => decodePublicApi(bytes([[...declaration.slice(0, 4), { k: 'nat', v: '1\n' }]])), /DECIMAL/);
});

test('universe binders and inductive metadata are retained without target layout', () => {
  const u = name('u'), type = { k: 'sort', l: { k: 'p', n: u } };
  const inductive = ['inductive', name('Box'), [u], type, 1, 0, [name('Box.make')], true];
  assert.deepEqual(decodePublicApi(bytes([inductive]))[2][0], inductive);
  assert.throws(() => decodePublicApi(bytes([[...inductive.slice(0, 2), [], ...inductive.slice(3)]])), /UNBOUND_LEVEL/);
  assert.throws(() => decodePublicApi(bytes([[...inductive.slice(0, 2), [u, u], ...inductive.slice(3)]])), /DUPLICATE_NAME/);
  const invalid = structuredClone(inductive); invalid[4] = -1;
  assert.throws(() => decodePublicApi(bytes([invalid])), /NATURAL/);
});

test('decoding enforces byte, depth and node budgets', () => {
  const input = bytes([declaration]);
  assert.throws(() => decodePublicApi(input, { maxBytes: 8 }));
  assert.throws(() => decodePublicApi(input, { maxDepth: 2 }));
  assert.throws(() => decodePublicApi(input, { maxNodes: 3 }));
});
