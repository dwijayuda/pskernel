#![forbid(unsafe_code)]
use std::io::{self,BufRead,Write};
use std::fs::{File,OpenOptions};
use serde_json::{json,Value};
use psc1_typed_io::{Config,TypedIo};
fn reply(value:Value){println!("{value}");io::stdout().flush().unwrap();}
fn main(){
 let value:Value=serde_json::from_str(&std::env::args().nth(1).expect("config")).unwrap();
 let config=match Config::parse(&value){Ok(v)=>v,Err(e)=>{reply(json!({"trap":e}));return}};
 // Test transport: inherited regular console descriptors start at offset zero.
 // The production adapter accepts owned Read/Write streams directly.
 let input=File::open(format!("/proc/self/fd/{}",value["inputFd"])).unwrap();
 let output=OpenOptions::new().write(true).open(format!("/proc/self/fd/{}",value["outputFd"])).unwrap();
 let host=TypedIo::new(config,Box::new(input),Box::new(output)).unwrap();
 reply(json!({"ready":true}));
 for line in io::stdin().lock().lines(){
  let command:Value=serde_json::from_str(&line.unwrap()).unwrap();
  if command["action"]=="close"{host.close();reply(json!({"closed":true}));break}
  let result=std::panic::catch_unwind(std::panic::AssertUnwindSafe(||{
   if command["action"]=="probeClosed"{host.close();}
   host.execute(command["source"].as_str().unwrap_or("{\"op\":\"readLine\"}").to_owned())
  }));
  match result{Ok(v)=>reply(json!({"ok":v})),Err(payload)=>{
   let message=payload.downcast_ref::<&str>().copied()
    .or_else(||payload.downcast_ref::<String>().map(String::as_str)).unwrap_or("PSC1_HOST_TRAP");
   reply(json!({"trap":message}));
  }}
 }
}
