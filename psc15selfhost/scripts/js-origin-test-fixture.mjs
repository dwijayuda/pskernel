import { uniformJsRepresentationProfile, uniformSpecializationArtifact } from './uniform-specialization.mjs';
import { artifactId, artifactKey, canonicalBytes } from './artifact-evidence.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { createDeclarationOriginGraph } from './declaration-origins.mjs';
import { createErasureDeclarationMap } from './erasure-declarations.mjs';
import { createSpecializationInstanceMap } from './specialization-correspondence.mjs';
import { createJsGeneratedPositionMap } from './js-generated-positions.mjs';

const name = v => ({ k: 's', p: { k: 'a' }, v });
const nat = ['primitive', 'nat'], ref = n => ['var', n];
const module = declarations => ['psc-runtime-ir-json/1', [], [], [], declarations];
function record(value, domain, contract = 'psc-runtime-ir-json/1') {
  const bytes = canonicalBytes(value); return { bytes, identity: artifactId(bytes, domain, contract) };
}
export function fixture({ parameter = 'x', uniform = false } = {}) {
  const lines = ['def forward (A : Type) (x : A) : A := x', 'def answer : Nat := forward Nat 7'];
  const sources = [lines.join('\n')];
  const genericType = { k: 'forall', n: name('A'), bi: 'default', t: { k: 'sort', l: { k: 's', o: { k: 'z' } } },
    b: { k: 'forall', n: name('x'), bi: 'default', t: { k: 'b', i: 0 }, b: { k: 'b', i: 1 } } };
  const publicApi = publicApiArtifact(canonicalBytes(['psc-public-api-ir/1', 'all-prepared-declarations', [
    ['constant', 'definition', name('forward'), [], genericType],
    ['constant', 'definition', name('answer'), [], { k: 'const', n: name('Nat'), ls: [] }],
  ]]));
  const sourceTable = canonicalBytes(['psc-declaration-origins/1', 'declaration-batch', 1, [
    [0, name('forward'), [0, 1, 1], [lines[0].length, 1, lines[0].length + 1]],
    [0, name('answer'), [lines[0].length + 1, 2, 1], [sources[0].length, 2, lines[1].length + 1]],
  ]]);
  const runtime = module([
    ['g', ['A'], [['x', ['typeParameter', 'A']]], ['typeParameter', 'A'], ref('x')],
    ['answer', [], [], nat, ['call', ref('g'), [nat], [['literal', ['natural', '7']]]]],
  ]);
  const specialized = module([
    ['chosen', [], [['x', nat]], nat, ref('x')],
    ['answer', [], [], nat, ['call', ref('chosen'), [], [['literal', ['natural', '7']]]]],
  ]);
  const runtimeIr = record(runtime, 'runtime-ir'), verifiedIr = record(runtime, 'verified-ir');
  const specializedIr = record(specialized, 'specialized-ir');
  const emittedName = uniform ? 'g' : 'chosen';
  const uniformSpecializedIr = uniform ? uniformSpecializationArtifact(canonicalBytes(['psc-uniform-specialized-ir/1', uniformJsRepresentationProfile, runtime])) : undefined;
  const jsIr = record(['psc-js-ir-json/1', [], [
    [emittedName, [parameter], ref(parameter)],
    ['answer', [], ['call', ref(emittedName), [['literal', ['natural', '7']]]]],
  ]], 'js-ir', 'psc-js-ir-json/1');
  const erasureTable = canonicalBytes(['psc-erasure-declarations/1', 'declaration-inventory', [
    [name('forward'), ['runtime', 'g']], [name('answer'), ['runtime', 'answer']],
  ]]);
  const chunks = ['// synthetic runtime\n', 'export function ' + emittedName + '(x) {\n  return x;\n}\n', 'export const answer = ' + emittedName + '(7n);\n'];
  const javaScript = chunks.join('');
  const generatedTable = canonicalBytes(['psc-js-generated-positions/1', 'declaration-emission-chunk', [
    [emittedName, [chunks[0].length, 1, 0], [chunks[0].length + chunks[1].length, 4, 0]],
    ['answer', [chunks[0].length + chunks[1].length, 4, 0], [javaScript.length, 5, 0]],
  ]]);
  const origin = createDeclarationOriginGraph({ table: sourceTable, sources, publicApi });
  const erasure = createErasureDeclarationMap({ table: erasureTable, publicApi, runtimeIr });
  const specialization = uniform ? undefined : createSpecializationInstanceMap(verifiedIr, specializedIr);
  const positions = createJsGeneratedPositionMap({ table: generatedTable, javaScript, jsIr });
  const records = [...origin.artifacts, origin.graph, ...erasure.artifacts, erasure.map,
    verifiedIr, ...(uniform ? [uniformSpecializedIr] : [specializedIr, specialization.map]), ...positions.artifacts, positions.map];
  const artifacts = new Map(records.map(item => [artifactKey(item.identity), item.bytes]));
  const parents = { originGraphId: origin.graph.identity, erasureMapId: erasure.map.identity,
    ...(uniform ? { uniformSpecializedIrId: uniformSpecializedIr.identity } : { specializationMapId: specialization.map.identity }),
    generatedPositionMapId: positions.map.identity,
    verifiedIrId: verifiedIr.identity };
  return { ...(uniform ? { profile: uniformJsRepresentationProfile, uniformSpecializedIr } : {}), parents, artifacts, resolveArtifact: id => artifacts.get(artifactKey(id)),
    origin, erasure, specialization, positions, sources, publicApi, sourceTable, erasureTable, generatedTable,
    runtimeIr, verifiedIr, specializedIr, jsIr, javaScript };
}

