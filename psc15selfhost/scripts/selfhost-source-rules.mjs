// Shared structural source rules for portable self-host implementation profiles.
// The checks are source-structural rather than file-specific repair guards.

export const portableSelfhostStructuralRuleIds = Object.freeze([
  'recursive-equation-definition',
  'term-list-append',
  'term-list-cons',
  'numeric-tuple-projection',
  'tuple-construction',
  'grouped-dot-application',
  'string-literal-pattern',
  'boolean-convenience',
  'leading-dot-term-constructor',
  'untyped-lambda-binder',
  'layout-let-sequencing',
]);

function maskLean(source, preserveStrings) {
  let out = '';
  let index = 0;
  let blockDepth = 0;
  let lineComment = false;
  let inString = false;
  let escaped = false;

  while (index < source.length) {
    const ch = source[index];
    const next = source[index + 1] ?? '';

    if (lineComment) {
      if (ch === '\n') {
        lineComment = false;
        out += '\n';
      } else {
        out += ' ';
      }
      index++;
      continue;
    }

    if (blockDepth > 0) {
      if (ch === '/' && next === '-') {
        blockDepth++;
        out += '  ';
        index += 2;
      } else if (ch === '-' && next === '/') {
        blockDepth--;
        out += '  ';
        index += 2;
      } else {
        out += ch === '\n' ? '\n' : ' ';
        index++;
      }
      continue;
    }

    if (inString) {
      out += preserveStrings ? ch : (ch === '\n' ? '\n' : ' ');
      if (escaped) {
        escaped = false;
      } else if (ch === '\\') {
        escaped = true;
      } else if (ch === '"') {
        inString = false;
      }
      index++;
      continue;
    }

    if (ch === '-' && next === '-') {
      lineComment = true;
      out += '  ';
      index += 2;
    } else if (ch === '/' && next === '-') {
      blockDepth = 1;
      out += '  ';
      index += 2;
    } else if (ch === '"') {
      inString = true;
      out += preserveStrings ? '"' : ' ';
      index++;
    } else {
      out += ch;
      index++;
    }
  }

  return out;
}

function lineNumberAt(source, offset) {
  let line = 1;
  for (let index = 0; index < offset; index++) {
    if (source[index] === '\n') line++;
  }
  return line;
}

function stripLineComment(line) {
  let inString = false;
  let escaped = false;
  for (let index = 0; index + 1 < line.length; index++) {
    const ch = line[index];
    const next = line[index + 1];
    if (inString) {
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') {
      inString = true;
      continue;
    }
    if (ch === '-' && next === '-') return line.slice(0, index);
  }
  return line;
}

function indentation(line) {
  return (line.match(/^(\s*)/u)?.[1] ?? '').replace(/\t/gu, '  ').length;
}

function delimiterDelta(line) {
  const code = stripLineComment(line);
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (const ch of code) {
    if (inString) {
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') {
      inString = true;
      continue;
    }
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
      !stripLineComment(lines[end]).trim().endsWith(';')
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

export function findSelfhostStructuralViolations(
  source,
  enabledRuleIds = portableSelfhostStructuralRuleIds,
) {
  const enabled = new Set(enabledRuleIds);
  const code = maskLean(source, false);
  const commentsMasked = maskLean(source, true);
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

  for (let index = 0; index < lines.length; index++) {
    const line = lines[index];
    const trimmed = line.trim();

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

    const termSegment =
      trimmed.startsWith('|') && line.includes('=>')
        ? line.slice(line.indexOf('=>') + 2)
        : line;

    if (/(^|[\s(=,:])\.[A-Za-z_][A-Za-z0-9_]*/u.test(termSegment)) {
      add('leading-dot-term-constructor', index + 1, line);
    }
    if (/&&|\|\||(^|[\s(=,:])!\s*[A-Za-z_(]/u.test(termSegment)) {
      add('boolean-convenience', index + 1, line);
    }
    if (/\bfun\s+[A-Za-z_][A-Za-z0-9_]*\s*=>/u.test(line)) {
      add('untyped-lambda-binder', index + 1, line);
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

  if (enabled.has('tuple-construction')) {
    hits.push(...tupleConstructionViolations(code));
  }
  if (enabled.has('layout-let-sequencing')) {
    hits.push(...layoutLetViolations(source));
  }

  return hits
    .filter(hit => enabled.has(hit.id))
    .sort((left, right) =>
      left.line - right.line || left.id.localeCompare(right.id));
}
