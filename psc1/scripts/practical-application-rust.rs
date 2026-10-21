// UTF8 argv transport only. Host and guest dependencies remain locked.
use std::rc::Rc;
use psc1_typed_io::{Config,TypedIo};
fn quote(value:&str)->String {
 let mut result=String::from("\"");
 for c in value.chars() {
  match c {
   '"' => result.push_str("\\\""), '\\' => result.push_str("\\\\"),
   c if c<' ' => result.push_str(&format!("\\u{:04x}",u32::from(c))),
   c => result.push(c)
  }
 }
 result.push('"');result
}
fn main(){
 let mut args=std::env::args().skip(1);
 let config=match Config::from_json(&std::fs::read_to_string(args.next().unwrap()).unwrap()){
  Ok(value)=>value,
  Err(error)=>{if error.contains("REQUIRED_CAPABILITY_DENIED"){std::process::exit(78)}panic!("{}",error)}
 };
 let host=match TypedIo::new(config,Box::new(std::io::stdin()),Box::new(std::io::stdout())){
  Ok(value)=>value,
  Err(error)=>{let message=format!("{:?}",error);if message.contains("REQUIRED_CAPABILITY_DENIED"){std::process::exit(78)}panic!("{}",message)}
 };
 let host=Rc::new(host);let dispatch=host.clone();
 let arguments=format!("[{}]",args.map(|a|quote(&a)).collect::<Vec<_>>().join(","));
 let success=psc1_generated::run(arguments,Rc::new(move|request:String|dispatch.execute(request)));
 host.close();std::process::exit(if success{0}else{2});
}
