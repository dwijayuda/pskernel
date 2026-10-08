import Ps.Foundation.Source

inductive PsDiagnosticSeverity where
  | error
  | warning
  | info

structure PsDiagnostic where
  severity : PsDiagnosticSeverity
  message : String
  span : PsSourceSpan
