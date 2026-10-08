import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/meta/src/Ps/Meta/Context.lean', import.meta.url), 'utf8');
const markers = [
  'match psMetaFindAssignment context id with',
  '| Option.none => false',
  '| Option.some _ => true',
  '| PsExpr.app fn arg =>',
  '| PsExpr.lam _ type body _ =>',
  '| PsExpr.forallE _ type body _ =>',
  '| PsExpr.letE _ type value body =>',
  '| PsExpr.proj _ _ value => psMetaExprHasAssignedVar context value',
  'if psMetaExprHasAssignedVar context expr then\n          smaller (psMetaInstantiateStep context expr)\n        else expr',
  'psLevelInstantiateExpr context.levels value',
];
const relevant = source.slice(source.indexOf('def psMetaExprHasAssignedVar'), source.indexOf('structure PsMetaFreshLevelResult'));
const validate = text => { for (const marker of markers) assert(text.includes(marker), `missing substitution stop guard: ${marker}`); };
validate(relevant);
for (const marker of markers) assert.throws(() => validate(relevant.replaceAll(marker, 'removed')));
console.log('PSC2_META_INSTANTIATION_STOP_SOURCE: PASS (assigned-variable scan, unchanged fuel and level instantiation)');
