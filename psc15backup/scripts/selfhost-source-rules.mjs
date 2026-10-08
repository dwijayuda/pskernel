import { maskLeanSource } from './lean-source-mask.mjs';

// Shared structural source rules for portable self-host implementation profiles.
// The checks are source-structural rather than file-specific repair guards.

export const portableSelfhostStructuralRuleIds = Object.freeze([
  'recursive-equation-definition',
  'structural-recursion-call-shape',
  'term-arithmetic-operator',
  'scalar-member-capability',
  'opaque-primitive-match',
  'explicit-option-constructors',
  'term-list-append',
  'term-list-cons',
  'numeric-tuple-projection',
  'tuple-construction',
  'grouped-dot-application',
  'string-literal-pattern',
  'boolean-convenience',
  'to-string-convenience',
  'value-length-dot-notation',
  'value-conversion-dot-notation',
  'leading-dot-term-constructor',
  'untyped-lambda-binder',
  'untyped-lambda-let',
  'untyped-match-let',
  'untyped-numeric-choice-let',
  'layout-let-sequencing',
  'record-update',
]);

function lineNumberAt(source, offset) {
  let line = 1;
  for (let index = 0; index < offset; index++) {
    if (source[index] === '\n') line++;
  }
  return line;
}

function indentation(line) {
  return (line.match(/^(\s*)/u)?.[1] ?? '').replace(/\t/gu, '  ').length;
}

function delimiterDelta(code) {
  let depth = 0;
  for (const ch of code) {
    if ('([{'.includes(ch)) depth++;
    else if (')]}'.includes(ch)) depth--;
  }
  return depth;
}

function escapeRegex(text) {
  const special = '\\^$.*+?()[]{}|';
  let out = '';
  for (const ch of text) out += special.includes(ch) ? '\\' + ch : ch;
  return out;
}

function recursiveEquationViolations(code) {
  const lines = code.split('\n');
  const starts = [];
  for (let index = 0; index < lines.length; index++) {
    if (/^\s*(?:partial\s+)?def\s+/u.test(lines[index])) starts.push(index);
  }
  starts.push(lines.length);
  const hits = [];

  for (let index = 0; index + 1 < starts.length; index++) {
    const start = starts[index];
    const end = starts[index + 1];
    const nameMatch =
      lines[start].match(/^\s*(?:partial\s+)?def\s+([A-Za-z0-9_?']+)/u);
    if (!nameMatch) continue;
    const name = nameMatch[1];
    const block = lines.slice(start, end).join('\n');
    const firstClause = block.search(/(^|\n)\s*\|/u);
    const firstAssignment = block.indexOf(':=');
    if (firstClause < 0 || (firstAssignment >= 0 && firstAssignment < firstClause)) continue;

    const occurrences =
      block.match(new RegExp('\\b' + escapeRegex(name) + '\\b', 'gu')) ?? [];
    if (occurrences.length > 1) {
      hits.push({
        id: 'recursive-equation-definition',
        line: start + 1,
        text: lines[start].trim(),
      });
    }
  }
  return hits;
}

function topLevelDeclarationColon(header) {
  let depth = 0;
  for (let index = 0; index < header.length; index++) {
    const ch = header[index];
    if ('([{'.includes(ch)) depth++;
    else if (')]}'.includes(ch)) depth--;
    else if (ch === ':' && depth === 0) return index;
  }
  return -1;
}

function explicitBinderNames(header) {
  const separator = topLevelDeclarationColon(header);
  if (separator < 0) return [];
  const prefix = header.slice(0, separator);
  const names = [];
  let index = 0;

  while (index < prefix.length) {
    if (prefix[index] !== '(') {
      index++;
      continue;
    }

    let depth = 1;
    let cursor = index + 1;
    while (cursor < prefix.length && depth > 0) {
      if (prefix[cursor] === '(') depth++;
      else if (prefix[cursor] === ')') depth--;
      cursor++;
    }
    if (depth !== 0) break;

    const group = prefix.slice(index + 1, cursor - 1);
    let groupDepth = 0;
    let colon = -1;
    for (let position = 0; position < group.length; position++) {
      const ch = group[position];
      if ('([{'.includes(ch)) groupDepth++;
      else if (')]}'.includes(ch)) groupDepth--;
      else if (ch === ':' && groupDepth === 0) {
        colon = position;
        break;
      }
    }

    if (colon >= 0) {
      const binders = group.slice(0, colon).trim().split(/\s+/u);
      for (const binder of binders) {
        if (/^[A-Za-z_][A-Za-z0-9_']*$/u.test(binder) && binder !== '_') {
          names.push(binder);
        }
      }
    }
    index = cursor;
  }

  return names;
}

function parseApplicationAtom(source, start) {
  let index = start;
  while (index < source.length && /\s/u.test(source[index])) index++;
  if (index >= source.length) return undefined;
  const atomStart = index;
  const ch = source[index];

  if ('([{'.includes(ch)) {
    const close = ch === '(' ? ')' : (ch === '[' ? ']' : '}');
    let depth = 0;
    while (index < source.length) {
      if (source[index] === ch) depth++;
      else if (source[index] === close) {
        depth--;
        if (depth === 0) {
          index++;
          break;
        }
      }
      index++;
    }
    return {
      text: source.slice(atomStart, index).replace(/\s+/gu, ' ').trim(),
      end: index,
      bareIdentifier: false,
    };
  }

  const identifier =
    source.slice(index).match(/^([A-Za-z_][A-Za-z0-9_?']*)/u);
  if (identifier) {
    index += identifier[1].length;
    let bareIdentifier = true;
    while (
      source[index] === '.' &&
      /[A-Za-z0-9_]/u.test(source[index + 1] ?? '')
    ) {
      bareIdentifier = false;
      index++;
      const field = source.slice(index).match(/^([A-Za-z0-9_]+)/u);
      if (!field) break;
      index += field[1].length;
    }
    return {
      text: source.slice(atomStart, index).trim(),
      end: index,
      bareIdentifier,
    };
  }

  const number = source.slice(index).match(/^([0-9]+)/u);
  if (number) {
    return {
      text: number[1],
      end: index + number[1].length,
      bareIdentifier: false,
    };
  }

  return {
    text: source[index],
    end: index + 1,
    bareIdentifier: false,
  };
}

function structuralRecursionCallViolations(code) {
  const lines = code.split('\n');
  const lineOffsets = [];
  let offset = 0;
  for (const line of lines) {
    lineOffsets.push(offset);
    offset += line.length + 1;
  }

  const starts = [];
  for (let index = 0; index < lines.length; index++) {
    if (/^\s*(?:partial\s+)?def\s+/u.test(lines[index])) starts.push(index);
  }
  starts.push(lines.length);
  const hits = [];

  for (let blockIndex = 0; blockIndex + 1 < starts.length; blockIndex++) {
    const start = starts[blockIndex];
    const end = starts[blockIndex + 1];
    const nameMatch =
      lines[start].match(/^\s*(?:partial\s+)?def\s+([A-Za-z0-9_?']+)/u);
    if (!nameMatch) continue;
    const name = nameMatch[1];
    const block = lines.slice(start, end).join('\n');
    const assignment = block.indexOf(':=');
    if (assignment < 0) continue;

    const binders = explicitBinderNames(block.slice(0, assignment));
    if (binders.length === 0) continue;

    const body = block.slice(assignment + 2);
    const calls = new RegExp('\\b' + escapeRegex(name) + '\\b', 'gu');
    let call;
    while ((call = calls.exec(body)) !== null) {
      let cursor = call.index + name.length;
      const arguments_ = [];
      let complete = true;
      for (let index = 0; index < binders.length; index++) {
        const atom = parseApplicationAtom(body, cursor);
        if (!atom) {
          complete = false;
          break;
        }
        arguments_.push(atom);
        cursor = atom.end;
      }
      if (!complete) continue;

      const changed = [];
      for (let index = 0; index < binders.length; index++) {
        const argument = arguments_[index];
        if (!(argument.bareIdentifier && argument.text === binders[index])) {
          changed.push({ binder: binders[index], argument });
        }
      }

      const valid =
        changed.length === 1 &&
        changed[0].argument.bareIdentifier;
      if (!valid) {
        const bodyOffset = lineOffsets[start] + assignment + 2 + call.index;
        hits.push({
          id: 'structural-recursion-call-shape',
          line: lineNumberAt(code, bodyOffset),
          text:
            name +
            ' ' +
            arguments_.map(argument => argument.text).join(' '),
        });
      }
    }
  }

  return hits;
}

function tupleConstructionViolations(code) {
  const hits = [];
  const stack = [];
  for (let index = 0; index < code.length; index++) {
    const ch = code[index];
    if ('([{'.includes(ch)) {
      stack.push({ ch, offset: index, comma: false });
    } else if (
      ch === ',' &&
      stack.length > 0 &&
      stack[stack.length - 1].ch === '('
    ) {
      stack[stack.length - 1].comma = true;
    } else if (')]}'.includes(ch) && stack.length > 0) {
      const open = stack.pop();
      if (open.ch === '(' && ch === ')' && open.comma) {
        hits.push({
          id: 'tuple-construction',
          line: lineNumberAt(code, open.offset),
          text: code.slice(open.offset, index + 1).replace(/\s+/gu, ' ').trim(),
        });
      }
    }
  }
  return hits;
}

function layoutLetViolations(source) {
  const lines = source.split('\n');
  const hits = [];

  for (let index = 0; index < lines.length; index++) {
    if (!/^\s*let\b/u.test(lines[index])) continue;

    const baseIndent = indentation(lines[index]);
    let depth = delimiterDelta(lines[index]);
    let seenAssignment = lines[index].includes(':=');
    let end = index;

    for (let cursor = index + 1; cursor < lines.length; cursor++) {
      const trimmed = lines[cursor].trim();
      if (trimmed === '' || trimmed.startsWith('--')) {
        end = cursor;
        continue;
      }
      const currentIndent = indentation(lines[cursor]);
      if (seenAssignment && depth <= 0 && currentIndent <= baseIndent) break;

      end = cursor;
      if (!seenAssignment && lines[cursor].includes(':=')) seenAssignment = true;
      depth += delimiterDelta(lines[cursor]);
    }

    while (
      end >= index &&
      (lines[end].trim() === '' || lines[end].trim().startsWith('--'))
    ) {
      end--;
    }

    if (
      seenAssignment &&
      !lines[end].trim().endsWith(';')
    ) {
      hits.push({
        id: 'layout-let-sequencing',
        line: index + 1,
        text: lines[index].trim(),
      });
    }
  }

  return hits;
}

const portableScalarMemberCapabilities = new Set([
  'Nat.zero',
  'Nat.succ',
  'Nat.add',
  'Nat.sub',
  'Nat.mul',
  'Nat.div',
  'Nat.mod',
  'Nat.beq',
  'Nat.ble',
  'Nat.blt',
  'Int.ofNat',
  'Int.negSucc',
  'Int.neg',
  'Int.add',
  'Int.sub',
  'Int.mul',
  'Int.repr',
  'Char.ofNat',
  'Char.toNat',
  'UInt8.ofNat',
]);

function scalarMemberViolations(lines) {
  const hits = [];
  const scalarMember =
    /\b(Nat|Int|Char|UInt8|UInt16|UInt32|UInt64|USize|Int8|Int16|Int32|Int64|ISize|Float|Float32)\.([A-Za-z_][A-Za-z0-9_']*)\b/gu;

  for (let index = 0; index < lines.length; index++) {
    const line = lines[index];
    for (const match of line.matchAll(scalarMember)) {
      const capability = match[1] + '.' + match[2];
      if (!portableScalarMemberCapabilities.has(capability)) {
        hits.push({
          id: 'scalar-member-capability',
          line: index + 1,
          text: capability,
        });
      }
    }
  }

  return hits;
}


function recordUpdateViolations(code) {
  const frames = [];
  const hits = [];
  let grouping = 0;
  for (const token of code.matchAll(/\{|\}|\(|\)|\[|\]|:=|\bwith\b/gu)) {
    const text = token[0];
    if (text === '(' || text === '[') { grouping++; continue; }
    if (text === ')' || text === ']') { grouping--; continue; }
    if (text === '{') {
      frames.push({ offset: token.index, grouping, assigned: false });
      continue;
    }
    if (text === '}') { frames.pop(); continue; }
    const frame = frames.at(-1);
    if (!frame || frame.grouping !== grouping) continue;
    if (text === ':=') frame.assigned = true;
    if (text === 'with' && !frame.assigned) {
      hits.push({ id: 'record-update', line: lineNumberAt(code, frame.offset),
        text: code.slice(frame.offset, token.index + 4).trim() });
      frame.assigned = true;
    }
  }
  return hits;
}

export function findSelfhostStructuralViolations(
  source,
  enabledRuleIds = portableSelfhostStructuralRuleIds,
) {
  const enabled = new Set(enabledRuleIds);
  const code = maskLeanSource(source);
  const commentsMasked = maskLeanSource(source, { preserveStrings: true });
  const lines = code.split('\n');
  const stringLines = commentsMasked.split('\n');
  const hits = [];

  const add = (id, line, text) => {
    if (enabled.has(id)) {
      hits.push({ id, line, text: text.trim().slice(0, 200) });
    }
  };

  if (enabled.has('recursive-equation-definition')) {
    hits.push(...recursiveEquationViolations(code));
  }
  if (enabled.has('structural-recursion-call-shape')) {
    hits.push(...structuralRecursionCallViolations(code));
  }

  if (enabled.has('scalar-member-capability')) {
    hits.push(...scalarMemberViolations(lines));
  }

  for (let index = 0; index < lines.length; index++) {
    const line = lines[index];
    const trimmed = line.trim();

    if (/(^|[^A-Za-z0-9_.])(?:none|some)(?=$|[^A-Za-z0-9_'])/u.test(line)) {
      add('explicit-option-constructors', index + 1, line);
    }

    if (
      /^\|\s*(Int|UInt8|UInt16|UInt32|UInt64|USize|Int8|Int16|Int32|Int64|ISize|Float|Float32|String|Char)\./u
        .test(trimmed)
    ) {
      add('opaque-primitive-match', index + 1, line);
    }

    if (line.includes('++')) add('term-list-append', index + 1, line);

    const consIndex = line.indexOf('::');
    if (consIndex >= 0) {
      const arrowIndex = line.indexOf('=>');
      const patternOnly =
        trimmed.startsWith('|') &&
        arrowIndex >= 0 &&
        consIndex < arrowIndex;
      const laterCons =
        line.indexOf('::', Math.max(consIndex + 2, arrowIndex + 2)) >= 0;
      if (!patternOnly || laterCons) add('term-list-cons', index + 1, line);
    }

    if (/(^|[^0-9])\.[12]\b/u.test(line)) {
      add('numeric-tuple-projection', index + 1, line);
    }
    if (/\)\s*\.[A-Za-z_]/u.test(line)) {
      add('grouped-dot-application', index + 1, line);
    }

    let termSegment = line;
    if (trimmed.startsWith('|')) {
      termSegment = line.includes('=>')
        ? line.slice(line.indexOf('=>') + 2)
        : '';
    }

    if (/(^|[\s(=,:])\.[A-Za-z_][A-Za-z0-9_]*/u.test(termSegment)) {
      add('leading-dot-term-constructor', index + 1, line);
    }
    if (/&&|\|\||(^|[\s(=,:])!\s*[A-Za-z_(]/u.test(termSegment)) {
      add('boolean-convenience', index + 1, line);
    }

    const arithmeticSegment =
      termSegment
        .replace(/->/gu, '  ')
        .replace(/=>/gu, '  ');
    if (
      /(?:%|\/|\*|\+|<=|>=|==|!=)/u.test(arithmeticSegment) ||
      /(^|\s)-(\s|$)/u.test(arithmeticSegment) ||
      /(^|[^<])<([^=]|$)/u.test(arithmeticSegment) ||
      /(^|[^>])>([^=]|$)/u.test(arithmeticSegment)
    ) {
      add('term-arithmetic-operator', index + 1, line);
    }
    if (/\btoString\b/u.test(termSegment)) {
      add('to-string-convenience', index + 1, line);
    }
    if (/(?:\b[a-z_][A-Za-z0-9_]*|\))\.length\b/u.test(termSegment)) {
      add('value-length-dot-notation', index + 1, line);
    }
    if (/\b[a-z_][A-Za-z0-9_]*\.(?:toNat|toList)\b/u.test(termSegment)) {
      add('value-conversion-dot-notation', index + 1, line);
    }
    if (/\bfun\s+[A-Za-z_][A-Za-z0-9_]*\s*=>/u.test(line)) {
      add('untyped-lambda-binder', index + 1, line);
    }

    if (/^\s*let\s+[A-Za-z_][A-Za-z0-9_']*\s*:=\s*$/u.test(line)) {
      let cursor = index + 1;
      while (cursor < lines.length && lines[cursor].trim() === '') cursor++;
      if (
        cursor < lines.length &&
        (lines[cursor].trim() === 'fun' ||
          /^fun\s*\(/u.test(lines[cursor].trim()))
      ) {
        add('untyped-lambda-let', index + 1, line);
      }
    }

    const inlineUntypedMatch =
      /^\s*let\s+[A-Za-z_][A-Za-z0-9_']*\s*:=\s*match\b/u.test(line);
    if (inlineUntypedMatch) {
      add('untyped-match-let', index + 1, line);
    } else if (/^\s*let\s+[A-Za-z_][A-Za-z0-9_']*\s*:=\s*$/u.test(line)) {
      let cursor = index + 1;
      while (cursor < lines.length && lines[cursor].trim() === '') cursor++;
      if (
        cursor < lines.length &&
        /^match\b/u.test(lines[cursor].trim())
      ) {
        add('untyped-match-let', index + 1, line);
      }
    }

    const numericChoicePattern =
      /^if\b[\s\S]*\bthen\s+\d+\s+else\s+\d+\s*;?\s*$/u;
    const inlineNumericChoice = line.match(
      /^\s*let\s+[A-Za-z_][A-Za-z0-9_']*\s*:=\s*(if[\s\S]*)$/u,
    );
    if (
      inlineNumericChoice &&
      numericChoicePattern.test(inlineNumericChoice[1].trim())
    ) {
      add('untyped-numeric-choice-let', index + 1, line);
    } else if (
      /^\s*let\s+[A-Za-z_][A-Za-z0-9_']*\s*:=\s*$/u.test(line)
    ) {
      let cursor = index + 1;
      while (cursor < lines.length && lines[cursor].trim() === '') cursor++;
      if (
        cursor < lines.length &&
        numericChoicePattern.test(lines[cursor].trim())
      ) {
        add('untyped-numeric-choice-let', index + 1, line);
      }
    }

    const stringLine = stringLines[index] ?? '';
    const arrow = stringLine.indexOf('=>');
    if (
      stringLine.trim().startsWith('|') &&
      arrow >= 0 &&
      stringLine.slice(0, arrow).includes('"')
    ) {
      add('string-literal-pattern', index + 1, stringLine);
    }
  }

  if (enabled.has('record-update')) {
    hits.push(...recordUpdateViolations(code));
  }
  if (enabled.has('tuple-construction')) {
    hits.push(...tupleConstructionViolations(code));
  }
  if (enabled.has('layout-let-sequencing')) {
    hits.push(...layoutLetViolations(code));
  }

  return hits
    .filter(hit => enabled.has(hit.id))
    .sort((left, right) =>
      left.line - right.line || left.id.localeCompare(right.id));
}
