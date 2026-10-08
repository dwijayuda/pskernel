import { artifactId } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const publicApiContract = 'psc-public-api-ir/1';
const fail = code => { throw new Error('PSC_PUBLIC_API_' + code); };
const array = (value, length) => {
  if (!Array.isArray(value) || (length !== undefined && value.length !== length)) fail('SCHEMA');
  return value;
};
const fields = (value, keys) => {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== keys.split(',').sort().join(',')) fail('SCHEMA');
};
const natural = value => { if (!Number.isSafeInteger(value) || value < 0) fail('NATURAL'); };
const text = value => { if (typeof value !== 'string' || !value.isWellFormed()) fail('TEXT'); };
const decimal = value => { if (typeof value !== 'string' || !/^(?:0|[1-9][0-9]*)(?![\s\S])/u.test(value)) fail('DECIMAL'); };

/** Full structured names, including numerical components. No lossy flattening. */
export function publicApiNameKey(value) {
  const parts = [];
  for (let cursor = value; ; cursor = cursor.p) {
    if (cursor?.k === 'a') { fields(cursor, 'k'); break; }
    fields(cursor, 'k,p,v');
    if (cursor.k === 's') text(cursor.v);
    else if (cursor.k === 'n') decimal(cursor.v);
    else fail('NAME');
    parts.push([cursor.k, cursor.v]);
  }
  return JSON.stringify(parts.reverse());
}
function names(values) {
  const keys = array(values).map(publicApiNameKey);
  if (new Set(keys).size !== keys.length) fail('DUPLICATE_NAME');
  return keys;
}

/** Bounded encoding/scope checks only. This decoder never kernel-checks a type,
 * establishes projection fidelity, chooses exports, or mints a capability.
 * Core expressions preserve dependent types, source generic/universe binders
 * and binder visibility; declaration bodies are absent.
 */
export function decodePublicApi(bytes, limits = {}) {
  const root = decodeComparatorJson(bytes, { maxBytes: 128 * 1024 * 1024, maxDepth: 512, maxNodes: 2000000, ...limits });
  array(root, 3);
  if (root[0] !== publicApiContract || root[1] !== 'all-prepared-declarations') fail('CONTRACT');
  const declarations = array(root[2]), declared = new Set(), pending = [];
  for (const declaration of declarations) {
    array(declaration);
    const constant = declaration[0] === 'constant';
    let name, levels, type;
    if (constant) {
      array(declaration, 5);
      if (!['axiom', 'definition', 'theorem', 'partial', 'opaque'].includes(declaration[1])) fail('KIND');
      [, , name, levels, type] = declaration;
    } else {
      [, name, levels, type] = declaration;
      switch (declaration[0]) {
        case 'inductive':
          array(declaration, 8); natural(declaration[4]); natural(declaration[5]); names(declaration[6]);
          if (typeof declaration[7] !== 'boolean') fail('SCHEMA');
          break;
        case 'constructor':
          array(declaration, 9); publicApiNameKey(declaration[4]);
          declaration.slice(5, 8).forEach(natural); array(declaration[8]).forEach(natural);
          break;
        case 'recursor':
          array(declaration, 9); names(declaration[4]); declaration.slice(5).forEach(natural); break;
        default: fail('KIND');
      }
    }
    const key = publicApiNameKey(name);
    if (key === '[]' || declared.has(key)) fail('DUPLICATE_DECLARATION');
    declared.add(key);
    pending.push(['expr', type, 0, new Set(names(levels))]);
  }
  while (pending.length) {
    const [kind, value, depth, levels] = pending.pop();
    const push = (kind, child, childDepth = depth) => pending.push([kind, child, childDepth, levels]);
    if (kind === 'level') {
      switch (value?.k) {
        case 'z': fields(value, 'k'); break;
        case 's': fields(value, 'k,o'); push('level', value.o); break;
        case 'max': case 'imax':
          fields(value, 'k,l,r'); push('level', value.l); push('level', value.r); break;
        case 'p':
          fields(value, 'k,n'); if (!levels.has(publicApiNameKey(value.n))) fail('UNBOUND_LEVEL'); break;
        default: fail('LEVEL');
      }
      continue;
    }
    switch (value?.k) {
      case 'b':
        fields(value, 'k,i'); natural(value.i); if (value.i >= depth) fail('UNBOUND_VARIABLE'); break;
      case 'sort': fields(value, 'k,l'); push('level', value.l); break;
      case 'const':
        fields(value, 'k,n,ls'); publicApiNameKey(value.n); array(value.ls).forEach(level => push('level', level)); break;
      case 'app':
        fields(value, 'k,a,f'); push('expr', value.a); push('expr', value.f); break;
      case 'lam': case 'forall':
        fields(value, 'k,n,t,b,bi'); publicApiNameKey(value.n);
        if (!['default', 'implicit', 'strictImplicit', 'instImplicit'].includes(value.bi)) fail('BINDER');
        push('expr', value.t); push('expr', value.b, depth + 1); break;
      case 'let':
        fields(value, 'k,n,t,v,b'); publicApiNameKey(value.n);
        push('expr', value.t); push('expr', value.v); push('expr', value.b, depth + 1); break;
      case 'nat': fields(value, 'k,v'); decimal(value.v); break;
      case 'str': fields(value, 'k,v'); text(value.v); break;
      case 'proj':
        fields(value, 'k,n,i,e'); publicApiNameKey(value.n); natural(value.i); push('expr', value.e); break;
      default: fail('EXPRESSION');
    }
  }
  return root;
}

export function publicApiArtifact(value, limits = {}) {
  const bytes = Buffer.from(value);
  decodePublicApi(bytes, limits);
  return Object.freeze({ bytes, identity: artifactId(bytes, 'public-api', publicApiContract) });
}
