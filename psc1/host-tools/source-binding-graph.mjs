// Pure validation/edit planning for source binding provenance.
// No tools, files, checkers or capability handles live in this module.
export function validateSourceBindingModule(wire, module, row, helpers) {
  const { exactKeys, spanInSource, coreName, hash, refuse, tokensInSpan } = helpers;
  const nat = (value, bound = 262144) => {
    if (!Number.isSafeInteger(value) || value < 0 || value > bound) refuse('BINDING_INTEGER');
  };
  const name = value => Array.isArray(value) && value.length === 0 ? '[]' : coreName(value);
  const words = value => {
    name(value);
    if (!value.length || value.some(part => part[0] !== 's')) refuse('BINDING_SOURCE_NAME');
    return value.map(part => part[1]);
  };
  const sourceNameSpan = (span, tagged) => {
    spanInSource(span, row);
    const tokens = tokensInSpan(span, row);
    if (!tokens.length || tokens.at(-1).span.stop.byteOffset !== span.stop.byteOffset ||
        tokens.some(piece => !['identifier', 'natural'].includes(piece.token.kind) &&
          !(piece.token.kind === 'symbol' && piece.token.text === '.')) ||
        tokens.map(piece => piece.token.text).join('') !== words(tagged).join('.'))
      throw new Error('PSC1_LOSSLESS_BINDING_REFERENCE_SPAN', { cause: {
        module: module.module, name: tagged, span,
        raw: row.bytes.subarray(span.start.byteOffset, span.stop.byteOffset).toString('utf8').slice(0,512),
        tokenSpelling: tokens.map(piece => piece.token.text).join('').slice(0,512),
      } });
  };
  const decodeSpan = value => {
    if (!Array.isArray(value) || value.length !== 6) refuse('BINDING_SPAN_ROW');
    for (const coordinate of value)
      if (!Number.isSafeInteger(coordinate) || coordinate < 0) refuse('BINDING_SPAN_ROW');
    return { start: { byteOffset: value[0], line: value[1], column: value[2] },
      stop: { byteOffset: value[3], line: value[4], column: value[5] } };
  };
  const decodeBinder = row => {
    if (!Array.isArray(row) || row.length !== 5) refuse('BINDING_BINDER_ROW');
    return { index: row[0], localId: row[1], name: row[2], parent: row[3],
      span: row[4] === null ? null : decodeSpan(row[4]) };
  };
  const decodeReference = row => {
    if (!Array.isArray(row) || row.length !== 6 || !Array.isArray(row[4]))
      refuse('BINDING_REFERENCE_ROW');
    const value = row[4];
    let target;
    if (value[0] === 'local' && value.length === 3)
      target = { kind: 'local', localId: value[1], binder: value[2] };
    else if (value[0] === 'global' && value.length === 2)
      target = { kind: 'global', name: value[1] };
    else if (value[0] === 'sort' && value.length === 1) target = { kind: 'sort' };
    else refuse('BINDING_TARGET_ROW');
    return { index: row[0], sourceName: row[1], span: decodeSpan(row[2]),
      baseSegments: row[3], target, sourceSpan: row[5] === null ? null : decodeSpan(row[5]) };
  };
  if (!Array.isArray(wire) || wire.length !== module.origins.length) refuse('BINDING_COVERAGE');
  return wire.map((batch, sourceIndex) => {
    exactKeys(batch, ['sourceIndex', 'traces']);
    const origin = module.origins[sourceIndex];
    if (batch.sourceIndex !== sourceIndex || !Array.isArray(batch.traces) ||
        batch.traces.length > origin.members.length) refuse('BINDING_BATCH');
    const owners = new Set();
    const traces = batch.traces.map(trace => {
      exactKeys(trace, ['name', 'kind', 'phase', 'encoding', 'bodyStart', 'enabled', 'complete',
        'events', 'binders', 'references']);
      const owner = coreName(trace.name);
      if (owners.has(owner) || !origin.members.some(member => coreName(member.name) === owner) ||
          !['definition', 'partialDefinition', 'theorem'].includes(trace.kind) ||
          trace.phase !== 'source-elaboration-before-lifts' ||
          trace.encoding !== 'psc1-source-bindings-compact/2' || trace.enabled !== true ||
          typeof trace.complete !== 'boolean' || !Array.isArray(trace.binders) ||
          !Array.isArray(trace.references)) refuse('BINDING_TRACE');
      owners.add(owner); nat(trace.events); nat(trace.bodyStart, trace.events);
      if (trace.binders.length + trace.references.length !== trace.events) refuse('BINDING_EVENTS');
      const events = new Set(), binders = new Map();
      const identity = index => hash(JSON.stringify(['psc1-source-binder/1', origin.id, trace.name, index]));
      const checkEvent = index => {
        nat(index, trace.events);
        if (index >= trace.events || events.has(index)) refuse('BINDING_EVENT');
        events.add(index);
      };
      const outputBinders = trace.binders.map(encodedBinder => {
        const binder = decodeBinder(encodedBinder);
        exactKeys(binder, ['index', 'localId', 'name', 'parent', 'span']);
        checkEvent(binder.index); nat(binder.localId); name(binder.name);
        if (binder.parent !== null) {
          nat(binder.parent, binder.index);
          if (binder.parent >= binder.index || !binders.has(binder.parent)) refuse('BINDING_PARENT');
        }
        let sourceBacked = false;
        if (binder.span !== null) {
          spanInSource(binder.span, row);
          if (binder.span.start.byteOffset < origin.span.start.byteOffset ||
              binder.span.stop.byteOffset > origin.span.stop.byteOffset) refuse('BINDING_SPAN');
          const piece = row.tokens[row.tokenStarts.get(binder.span.start.byteOffset)];
          sourceBacked = binder.name.length === 1 && binder.name[0][0] === 's' &&
            !!piece && piece.token.kind === 'identifier' &&
            piece.span.stop.byteOffset === binder.span.stop.byteOffset &&
            piece.token.text === binder.name[0][1];
        }
        const result = { ...binder, id: identity(binder.index), sourceBacked,
          region: binder.index < trace.bodyStart ? 'public-header' : 'body' };
        binders.set(binder.index, result);
        return result;
      });
      const references = trace.references.map(encodedReference => {
        const reference = decodeReference(encodedReference);
        exactKeys(reference, ['index', 'sourceName', 'span', 'baseSegments', 'target', 'sourceSpan']);
        checkEvent(reference.index);
        spanInSource(reference.span, row);
        if (reference.sourceSpan !== null) {
          sourceNameSpan(reference.sourceSpan, reference.sourceName);
          if (reference.sourceSpan.start.byteOffset < reference.span.start.byteOffset ||
              reference.sourceSpan.stop.byteOffset > reference.span.stop.byteOffset)
            refuse('BINDING_REFERENCE_SOURCE_SPAN');
        }
        const parts = words(reference.sourceName);
        nat(reference.baseSegments, parts.length);
        if (reference.baseSegments < 1) refuse('BINDING_REFERENCE_BASE');
        if (reference.span.start.byteOffset < origin.span.start.byteOffset ||
            reference.span.stop.byteOffset > origin.span.stop.byteOffset) refuse('BINDING_REFERENCE_SPAN');
        const target = reference.target;
        if (target?.kind === 'local') {
          exactKeys(target, ['kind', 'localId', 'binder']); nat(target.localId);
          if (target.binder !== null) {
            nat(target.binder, reference.index);
            const binder = binders.get(target.binder);
            if (!binder || binder.index >= reference.index || binder.localId !== target.localId)
              refuse('BINDING_TARGET');
          } else if (trace.complete) refuse('BINDING_UNBOUND_LOCAL');
        } else if (target?.kind === 'global') {
          exactKeys(target, ['kind', 'name']); coreName(target.name);
        } else if (target?.kind === 'sort') exactKeys(target, ['kind']);
        else refuse('BINDING_TARGET');
        return { ...reference, sourceBacked: reference.sourceSpan !== null, target: { ...target,
          ...(target.kind === 'local' && target.binder !== null
            ? { binderId: identity(target.binder) } : {}) } };
      });
      if (events.size !== trace.events) refuse('BINDING_EVENTS');
      return { ...trace, binders: outputBinders, references };
    });
    return { sourceIndex, ownerId: origin.id,
      coverage: traces.length ? 'recorded-term-bases' : 'not-recorded', traces };
  });
}

export function planSourceBinderRename(module, batch, trace, binder, newName, helpers) {
  const { refuse } = helpers;
  const origin = module.origins[batch.sourceIndex];
  if (trace.kind !== 'definition' || !trace.complete || trace.phase !== 'source-elaboration-before-lifts' ||
      origin.normalization !== null || origin.members.length !== 1 ||
      origin.members[0].role !== 'sourceDeclaration' || binder.region !== 'body' ||
      !binder.sourceBacked || !binder.span || binder.name.length !== 1 ||
      binder.name[0][0] !== 's' || binder.name[0][1] === '_')
    refuse('BINDING_RENAME_UNSUPPORTED');
  if (typeof newName !== 'string' || !/^[A-Za-z_][A-Za-z0-9_]*$/.test(newName) ||
      newName === '_' || newName === '_root_' || newName === binder.name[0][1] ||
      Buffer.byteLength(newName) > 4096) refuse('BINDING_RENAME_NAME');
  const oldName = binder.name[0][1], edits = new Map();
  const add = (startByte, endByte) => edits.set(startByte + ':' + endByte,
    { startByte, endByte, replacement: Buffer.from(newName) });
  add(binder.span.start.byteOffset, binder.span.stop.byteOffset);
  for (const item of trace.binders) {
    if (item !== binder && item.sourceBacked && item.span &&
        item.span.start.byteOffset === binder.span.start.byteOffset &&
        item.span.stop.byteOffset === binder.span.stop.byteOffset)
      refuse('BINDING_AMBIGUOUS_SOURCE');
  }
  for (const reference of trace.references) {
    if (reference.target.kind !== 'local' || reference.target.binder !== binder.index) continue;
    if (!reference.sourceBacked || reference.sourceSpan === null) refuse('BINDING_GENERATED_USE');
    if (reference.baseSegments !== 1 || reference.sourceName[0]?.[0] !== 's' ||
        reference.sourceName[0]?.[1] !== oldName) refuse('BINDING_REFERENCE_BASE');
    add(reference.sourceSpan.start.byteOffset,
      reference.sourceSpan.start.byteOffset + Buffer.byteLength(oldName));
  }
  const result = [...edits.values()].sort((a, b) => a.startByte - b.startByte);
  for (const reference of trace.references) {
    const start = reference.sourceSpan?.start.byteOffset ?? reference.span.start.byteOffset;
    if (result.some(edit => edit.startByte === start) &&
        !(reference.target.kind === 'local' && reference.target.binder === binder.index))
      refuse('BINDING_AMBIGUOUS_REFERENCE');
  }
  return result;
}

export function requireRenameBindingCorrespondence(before, after, moduleIndex, sourceIndex,
    traceIndex, binderIndex, newName, edits, helpers) {
  const { refuse } = helpers;
  const same = (left, right) => JSON.stringify(left) === JSON.stringify(right);
  const offset = value => {
    let change = 0;
    for (const edit of edits) {
      if (value <= edit.startByte) return value + change;
      if (value < edit.endByte) refuse('BINDING_SPAN_INTERIOR');
      change += edit.replacement.length - (edit.endByte - edit.startByte);
    }
    return value + change;
  };
  const span = (left, right, moved) => {
    if (left === null || right === null) return left === right;
    return right.start.byteOffset === (moved ? offset(left.start.byteOffset) : left.start.byteOffset) &&
      right.stop.byteOffset === (moved ? offset(left.stop.byteOffset) : left.stop.byteOffset);
  };
  if (before.modules.length !== after.modules.length || !same(before.partialNames, after.partialNames) ||
      before.sourceCoreDeclarations !== after.sourceCoreDeclarations ||
      before.logicalCoreDeclarations !== after.logicalCoreDeclarations) refuse('BINDING_GRAPH_SHAPE');
  for (let i = 0; i < before.modules.length; i++) {
    const left = before.modules[i], right = after.modules[i], moved = i === moduleIndex;
    if (left.module !== right.module || !same(left.imports, right.imports) ||
        left.origins.length !== right.origins.length || left.bindings.length !== right.bindings.length)
      refuse('BINDING_MODULE_SHAPE');
    for (let j = 0; j < left.origins.length; j++) {
      const oldOwner = left.origins[j], newOwner = right.origins[j];
      const memberShape = owner => owner.members.map(member => ({
        index: member.index, name: member.name, role: member.role,
      }));
      if (!same(oldOwner.sourceName, newOwner.sourceName) ||
          !same(memberShape(oldOwner), memberShape(newOwner)) ||
          !span(oldOwner.span, newOwner.span, moved) ||
          !span(oldOwner.nameSpan, newOwner.nameSpan, moved) ||
          !same(oldOwner.normalization?.workerName ?? null, newOwner.normalization?.workerName ?? null))
        refuse('BINDING_OWNER_CORRESPONDENCE');
      const oldBatch = left.bindings[j], newBatch = right.bindings[j];
      if (oldBatch.sourceIndex !== newBatch.sourceIndex ||
          oldBatch.traces.length !== newBatch.traces.length) refuse('BINDING_TRACE_SHAPE');
      for (let k = 0; k < oldBatch.traces.length; k++) {
        const a = oldBatch.traces[k], b = newBatch.traces[k];
        if (!same(a.name, b.name) || a.kind !== b.kind || a.phase !== b.phase ||
            a.complete !== b.complete || a.bodyStart !== b.bodyStart || a.events !== b.events ||
            a.binders.length !== b.binders.length || a.references.length !== b.references.length)
          refuse('BINDING_TRACE_SHAPE');
        for (let n = 0; n < a.binders.length; n++) {
          const x = a.binders[n], y = b.binders[n];
          const chosen = i === moduleIndex && j === sourceIndex && k === traceIndex && x.index === binderIndex;
          const expected = chosen ? [['s', newName]] : x.name;
          if (x.index !== y.index || x.localId !== y.localId || x.parent !== y.parent ||
              x.region !== y.region || x.sourceBacked !== y.sourceBacked ||
              !same(expected, y.name) || !span(x.span, y.span, moved))
            refuse('BINDING_BINDER_CORRESPONDENCE');
        }
        for (let n = 0; n < a.references.length; n++) {
          const x = a.references[n], y = b.references[n];
          const chosen = i === moduleIndex && j === sourceIndex && k === traceIndex &&
            x.target.kind === 'local' && x.target.binder === binderIndex;
          const expected = x.sourceName.map((part, p) => chosen && p === 0 ? ['s', newName] : part);
          const targetShape = target => target.kind === 'local'
            ? { kind: target.kind, localId: target.localId, binder: target.binder }
            : target;
          if (x.index !== y.index || x.baseSegments !== y.baseSegments ||
              x.sourceBacked !== y.sourceBacked || !span(x.sourceSpan, y.sourceSpan, moved) ||
              !same(expected, y.sourceName) || !span(x.span, y.span, moved) ||
              !same(targetShape(x.target), targetShape(y.target)))
            refuse('BINDING_REFERENCE_CORRESPONDENCE');
        }
      }
    }
  }
}
