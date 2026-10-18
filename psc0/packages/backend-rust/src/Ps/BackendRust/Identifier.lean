-- Ps.Codegen.Names owns collision-free target spelling before lowering.
-- Keep raw Rust keywords and reserved runtime names out of that target view.
def psRustReservedNames : List String :=
  ["__PS_VALUE", "as", "break", "const", "continue", "crate", "else", "enum", "extern", "false",
   "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut",
   "pub", "ref", "return", "self", "Self", "static", "struct", "super", "trait",
   "true", "type", "unsafe", "use", "where", "while", "async", "await", "dyn",
   "abstract", "become", "box", "do", "final", "gen", "macro", "override",
   "priv", "typeof", "unsized", "virtual", "yield", "try", "union",
   "PsNat", "PsInt", "PsArray", "String"]

def psRustIdentifier (name : String) : String := name
