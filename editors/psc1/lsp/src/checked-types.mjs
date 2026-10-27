// Presentation of compiler-produced Core data only. No elaboration, reduction,
// inference or proof checking happens here. The worker binds these bytes to the
// independently checked receipt before exposing them as checked declarations.
export function coreName(value, depth = 0) {
  if (depth > 128 || !value || typeof value !== 'object') return null;
  if (value.k === 'a') return '';
  if (!['s', 'n'].includes(value.k) || typeof value.v !== 'string') return null;
  const parent = coreName(value.p, depth + 1);
  return parent === null ? null : (parent ? parent + '.' : '') + value.v;
}

export function formatCoreType(expression) {
  let budget = 4096;
  const limited = () => { if (--budget < 0) throw Error('type presentation limit'); };
  const level = (value, depth = 0) => {
    limited();
    if (depth > 64 || !value) throw Error('unavailable universe');
    if (value.k === 'z') return '0';
    if (value.k === 'p') {
      const name = coreName(value.n);
      if (name === null) throw Error('unavailable universe name');
      return name;
    }
    if (value.k === 's') {
      const inner = level(value.o, depth + 1);
      return /^\d+$/.test(inner) && Number(inner) < 10000 ? String(Number(inner) + 1) : '(' + inner + ' + 1)';
    }
    if (['max', 'imax'].includes(value.k))
      return value.k + '(' + level(value.l, depth + 1) + ', ' + level(value.r, depth + 1) + ')';
    throw Error('unavailable universe tag');
  };
  const render = (value, context = [], depth = 0) => {
    limited();
    if (depth > 96 || !value || typeof value !== 'object') throw Error('unavailable expression');
    switch (value.k) {
      case 'b': {
        if (!Number.isSafeInteger(value.i) || value.i < 0 || value.i >= context.length)
          throw Error('unavailable bound variable');
        return context[context.length - 1 - value.i];
      }
      case 'const': {
        const name = coreName(value.n);
        if (!name || !Array.isArray(value.ls)) throw Error('unavailable constant');
        const levels = value.ls.map(item => level(item));
        return name + (levels.length ? '.{' + levels.join(', ') + '}' : '');
      }
      case 'sort': {
        const universe = level(value.l);
        return universe === '0' ? 'Prop' : 'Sort(' + universe + ')';
      }
      case 'app': return '(' + render(value.f, context, depth + 1) + ' ' + render(value.a, context, depth + 1) + ')';
      case 'forall':
      case 'lam':
      case 'let': {
        const rawName = coreName(value.n);
        if (rawName === null) throw Error('unavailable binder name');
        let name = rawName || 'x';
        while (context.includes(name)) name += '_';
        const type = render(value.t, context, depth + 1);
        const body = render(value.b, [...context, name], depth + 1);
        if (value.k === 'let')
          return '(let ' + name + ' : ' + type + ' := ' + render(value.v, context, depth + 1) + '; ' + body + ')';
        const delimiters = {default: ['(', ')'], implicit: ['{', '}'], strictImplicit: ['{{', '}}'], instImplicit: ['[', ']']}[value.bi];
        if (!delimiters) throw Error('unavailable binder kind');
        const binder = delimiters[0] + name + ' : ' + type + delimiters[1];
        return value.k === 'forall' ? '(' + binder + ' → ' + body + ')' : '(fun ' + binder + ' => ' + body + ')';
      }
      case 'nat':
        if (typeof value.v !== 'string' || !/^\d+$/.test(value.v)) throw Error('unavailable natural');
        return value.v;
      case 'str':
        if (typeof value.v !== 'string') throw Error('unavailable string');
        return JSON.stringify(value.v);
      case 'proj': {
        const name = coreName(value.n);
        if (!name || !Number.isSafeInteger(value.i) || value.i < 0) throw Error('unavailable projection');
        return '(projection ' + name + ' #' + value.i + ' ' + render(value.e, context, depth + 1) + ')';
      }
      default: throw Error('unavailable expression tag');
    }
  };
  try {
    const text = render(expression);
    return text.length > 8192 ? undefined : text;
  } catch {
    return undefined;
  }
}

export function admissionDeclarations(admissionsText) {
  const parsed = JSON.parse(admissionsText);
  if (parsed?.format !== 'proofscript-checked-admissions' || parsed.version !== 2 || !Array.isArray(parsed.admissions))
    throw Error('PSC1_LSP_ADMISSION_FORMAT');
  const result = new Map();
  const add = (declaration, kind) => {
    const name = coreName(declaration?.n);
    if (name) result.set(name, {kind, type: formatCoreType(declaration.t)});
  };
  for (const admission of parsed.admissions) {
    const declaration = admission.declaration;
    if (admission.kind === 'constant') add(declaration, declaration?.k);
    else if (admission.kind === 'inductive' && Array.isArray(declaration?.ts)) {
      for (const type of declaration.ts) {
        add(type, 'inductive');
        if (Array.isArray(type.cs)) for (const constructor of type.cs) add(constructor, 'constructor');
      }
    }
  }
  return result;
}
