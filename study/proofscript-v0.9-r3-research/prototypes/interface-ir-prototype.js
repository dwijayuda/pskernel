"use strict";

function mapType(text) {
  const t = text.trim();
  if (t === "string") return { kind: "string" };
  if (t === "boolean") return { kind: "bool" };
  if (t === "bigint") return { kind: "bigint" };
  if (t === "number") return { kind: "number" };
  const p = /^Promise<(.+)>$/.exec(t);
  if (p) return { kind: "promise", value: mapType(p[1]) };
  const a = /^(.+)\[\]$/.exec(t);
  if (a) return { kind: "array", element: mapType(a[1]), mutable: true };
  if (/^[A-Za-z_$][\w$]*$/.test(t)) return { kind: "named", name: t };
  throw new Error("unsupported type: " + t);
}

function importDts(source) {
  if (/\bextends\b/.test(source) && /\btype\b/.test(source)) {
    throw new Error("unsupported conditional/extends type expression");
  }
  const out = { version: 1, interfaces: [], functions: [] };
  const interfaceRe = /export\s+interface\s+(\w+)\s*\{([\s\S]*?)\}/g;
  for (const m of source.matchAll(interfaceRe)) {
    const fields = [];
    for (const raw of m[2].split(";")) {
      const line = raw.trim();
      if (!line) continue;
      const fm = /^(readonly\s+)?(\w+)(\?)?\s*:\s*(.+)$/.exec(line);
      if (!fm) throw new Error("unsupported field: " + line);
      fields.push({
        name: fm[2],
        readonly: !!fm[1],
        presence: fm[3] ? "missing-or-undefined" : "required",
        type: mapType(fm[4])
      });
    }
    out.interfaces.push({ name: m[1], fields });
  }
  const fnRe = /export\s+declare\s+function\s+(\w+)\s*\(([^)]*)\)\s*:\s*([^;]+);/g;
  for (const m of source.matchAll(fnRe)) {
    const params = m[2].trim() ? m[2].split(",").map(raw => {
      const pm = /^\s*(\w+)(\?)?\s*:\s*(.+)\s*$/.exec(raw);
      if (!pm) throw new Error("unsupported parameter: " + raw);
      return { name: pm[1], optional: !!pm[2], type: mapType(pm[3]) };
    }) : [];
    out.functions.push({ name: m[1], parameters: params, result: mapType(m[3]) });
  }
  return out;
}

module.exports = { importDts, mapType };
