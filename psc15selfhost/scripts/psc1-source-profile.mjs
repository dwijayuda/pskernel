import { maskLeanSource } from './lean-source-mask.mjs';
import { hasOpaqueSourceCommand } from "./source-profile-opaque.mjs";

export const maskLeanNonCode = maskLeanSource;

export const psc1ForbiddenSourceRules = [
  {
    key: "lean-import",
    label: "Lean implementation import",
    pattern: /(^|\n)\s*import\s+Lean(?:\.|\s|$)/,
  },
  {
    key: "std-import",
    label: "Std implementation import",
    pattern: /(^|\n)\s*import\s+Std(?:\.|\s|$)/,
  },
  { key: "unsafe", label: "unsafe", pattern: /\bunsafe\b/ },
  {
    key: "implemented-by",
    label: "implemented_by",
    pattern: /\bimplemented_by\b/,
  },
  { key: "extern", label: "extern", pattern: /\bextern\b/ },
  {
    key: "macro",
    label: "macro",
    pattern: /\bmacro_rules\b|\bmacro\b/,
  },
  {
    key: "custom-syntax",
    label: "custom syntax",
    pattern: /(^|\s)syntax(?:\s|$)/,
  },
  {
    key: "custom-elaborator",
    label: "custom elaborator",
    pattern: /\belab_rules\b|\belab\b/,
  },
  { key: "run-tac", label: "run_tac", pattern: /\brun_tac\b/ },
  { key: "set-option", label: "set_option", pattern: /\bset_option\b/ },
  {
    key: "open-scoped",
    label: "open scoped",
    pattern: /\bopen\s+scoped\b/,
  },
  {
    key: "namespace",
    label: "namespace convenience",
    pattern: /\bnamespace\b/,
  },
  {
    key: "section",
    label: "section convenience",
    pattern: /\bsection\b/,
  },
  {
    key: "abbrev",
    label: "abbrev convenience",
    pattern: /\babbrev\b/,
  },
  {
    key: "opaque",
    label: "opaque source convenience",
    test: hasOpaqueSourceCommand,
  },
  {
    key: "mutual",
    label: "mutual declaration convenience",
    pattern: /\bmutual\b/,
  },
  {
    key: "termination",
    label: "explicit termination machinery",
    pattern: /\btermination_by\b|\bdecreasing_by\b/,
  },
  {
    key: "io",
    label: "IO in portable semantic module",
    pattern: /\bIO(?:\.|\s|\b)/,
  },
  {
    key: "lean-api",
    label: "Lean implementation API",
    pattern: /\bLean\./,
  },
  {
    key: "std-api",
    label: "Std implementation API",
    pattern: /\bStd\./,
  },
];

export function psc1RuleMatches(rule, auditedSource) {
  if (rule.test) return rule.test(auditedSource);
  return rule.pattern.test(auditedSource);
}

export function auditPsc1Source(source) {
  const auditedSource = maskLeanNonCode(source);
  return psc1ForbiddenSourceRules.filter((rule) =>
    psc1RuleMatches(rule, auditedSource),
  );
}
