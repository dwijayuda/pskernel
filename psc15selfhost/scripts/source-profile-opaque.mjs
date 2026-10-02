// Input has comments and strings masked by the source-profile scanner.
// A constructor named `opaque` is ordinary portable data. The command remains
// forbidden, including after modifiers/attributes or on a continuation line.
export function hasOpaqueSourceCommand(code) {
  const withoutConstructors = code
    .replace(/\b[A-Za-z_][A-Za-z_0-9.]*\.opaque\b/gu, '')
    .replace(/^[\t ]*\|[\t ]*opaque[\t ]*$/gmu, '');
  return /\bopaque\b/u.test(withoutConstructors);
}
