// Syntax-only target ABI inventory, parsed by the pinned upstream Rust parser.
use std::{env,fs};
fn main() {
 let args:Vec<String>=env::args().collect();assert_eq!(args.len(),2);
 let source=fs::read_to_string(&args[1]).expect("source");
 let parsed=syn::parse_file(&source).expect("Rust syntax");
 let mut names:Vec<String>=Vec::new();
 for item in parsed.items {
  let named=match item {
   syn::Item::Fn(x)=>Some((x.vis,x.sig.ident)),
   syn::Item::Const(x)=>Some((x.vis,x.ident)),
   syn::Item::Static(x)=>Some((x.vis,x.ident)),
   // Type carriers do not add callable/value exports.
   syn::Item::Struct(_)|syn::Item::Enum(_)|syn::Item::Type(_)|syn::Item::Impl(_)=>None,
   syn::Item::Use(x)=>{assert!(!matches!(x.vis,syn::Visibility::Public(_)),"public re-export");None},
   syn::Item::Mod(x)=>{assert!(!matches!(x.vis,syn::Visibility::Public(_)),"public module");None},
   syn::Item::Macro(x)=>{assert!(x.attrs.iter().all(|a|!a.path().is_ident("macro_export")),"public macro");None},
   syn::Item::ExternCrate(x)=>{assert!(!matches!(x.vis,syn::Visibility::Public(_)),"public extern");None},
   other=>panic!("unsupported target item: {}",match other {syn::Item::Trait(_)=>"trait",_=>"item"})
  };
  if let Some((syn::Visibility::Public(_),ident))=named {names.push(ident.to_string());}
 }
 names.sort();for name in names{println!("{}",name.strip_prefix("r#").unwrap_or(&name));}
}
