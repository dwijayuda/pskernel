//! Trusted, explicit Linux host adapter. Generated code retains its safe owned ABI.
//! Console streams are supplied as owned Rust Read/Write objects, never raw pointers.
#![forbid(unsafe_code)]
use serde_json::{json, value::RawValue, Value};
use std::collections::{BTreeMap, BTreeSet};
use std::fs::{self, File, OpenOptions};
use std::io::{self, Read, Write};
use std::os::fd::AsRawFd;
use std::os::unix::fs::OpenOptionsExt;
use std::path::{Path, PathBuf};
use std::sync::{atomic::{AtomicU64, Ordering}, Mutex};
const OPS: [&str;4]=["readLine","writeLine","readUtf8","writeUtf8"];
// Linux asm-generic/fcntl.h. This ABI explicitly refuses non-Linux hosts.
const DIRECTORY:i32=0o200000;
const NOFOLLOW:i32=0o400000;
const NONBLOCK:i32=0o4000;
static TEMP:AtomicU64=AtomicU64::new(0);

#[derive(Debug)]
enum Failure { Policy(&'static str), Host(io::Error) }
impl From<io::Error> for Failure { fn from(e:io::Error)->Self {Self::Host(e)} }
type Result<T> = std::result::Result<T,Failure>;
fn deny<T>(code:&'static str)->Result<T>{Err(Failure::Policy(code))}
fn error_code(error:Failure)->&'static str {
 match error {
  Failure::Policy(code)=>code,
  Failure::Host(e)=>match e.raw_os_error(){
   Some(2)=>"notFound",
   Some(20|40|36)=>"pathDenied",
   Some(21|6|19)=>"wrongType",
   Some(13|1|28|122|30|5|24|23|27|32|11)=>"ioFailure",
   _=>panic!("PSC1_IO_HOST_ERROR: {e}")
  }
 }
}
pub struct Config {
 root:PathBuf, allowed:BTreeSet<String>, file_limit:usize, line_limit:usize,
}
impl Config {
 pub fn from_json(source:&str)->std::result::Result<Self,String>{
  let value:Value=serde_json::from_str(source).map_err(|_|"PSC1_IO_CONFIGURATION".to_owned())?;
  Self::parse(&value)
 }
 pub fn parse(value:&Value)->std::result::Result<Self,String>{
  if !cfg!(target_os="linux") || value["abi"]!="psc1-rust-linux-string-io/1"{
   return Err("PSC1_IO_UNSUPPORTED_ABI".into())
  }
  let invalid=||"PSC1_IO_CONFIGURATION".to_owned();
  let map=value.as_object().ok_or_else(invalid)?;
  let expected=["abi","capabilities","required","root","maxFileBytes","maxLineBytes","inputFd","outputFd"];
  if map.len()!=expected.len()||expected.iter().any(|k|!map.contains_key(*k)){return Err(invalid())}
  let caps=|key:&str|->std::result::Result<BTreeSet<String>,String>{
   let values=value[key].as_array().ok_or_else(invalid)?;
   let mut out=BTreeSet::new();
   for v in values{
    let s=v.as_str().ok_or_else(invalid)?;
    if !OPS.contains(&s)||!out.insert(s.to_owned()){return Err(invalid())}
   }Ok(out)
  };
  let allowed=caps("capabilities")?;
  if !caps("required")?.is_subset(&allowed){return Err("PSC1_IO_REQUIRED_CAPABILITY_DENIED".into())}
  let limit=|key:&str|->std::result::Result<usize,String>{
   let n=value[key].as_u64().ok_or_else(invalid)?;
   if !(1..=16777216).contains(&n){return Err(invalid())}Ok(n as usize)
  };
  for key in ["inputFd","outputFd"]{
   if value[key].as_u64().filter(|n|*n<=i32::MAX as u64).is_none(){return Err(invalid())}
  }
  let root=PathBuf::from(value["root"].as_str().ok_or_else(invalid)?);
  if !root.is_absolute(){return Err(invalid())}
  Ok(Self{root,allowed,file_limit:limit("maxFileBytes")?,line_limit:limit("maxLineBytes")?})
 }
}
struct Console {
 input:Box<dyn Read+Send>, output:Box<dyn Write+Send>,
 pending:Vec<u8>, offset:usize, ended:bool, overflow:bool,
}
pub struct TypedIo { config:Config, root:Mutex<Option<File>>, console:Mutex<Console> }
impl TypedIo {
 pub fn new(config:Config,input:Box<dyn Read+Send>,output:Box<dyn Write+Send>)->io::Result<Self>{
  let root=OpenOptions::new().read(true).custom_flags(DIRECTORY|NOFOLLOW).open(&config.root)?;
  Ok(Self{config,root:Mutex::new(Some(root)),console:Mutex::new(Console{
   input,output,pending:vec![],offset:0,ended:false,overflow:false})})
 }
 pub fn close(&self){self.root.lock().expect("PSC1_IO_HOST_POISONED").take();}
 fn parent<T>(&self,relative:&str,action:impl FnOnce(&Path,&str)->Result<T>)->Result<T>{
  if relative.is_empty()||relative.len()>4096||relative.contains(['\\','\0'])||Path::new(relative).is_absolute(){
   return deny("pathDenied")
  }
  let parts:Vec<_>=relative.split('/').collect();
  if parts.iter().any(|x|["",".",".."].contains(x)){return deny("pathDenied")}
  let root=self.root.lock().expect("PSC1_IO_HOST_POISONED");
  let root=root.as_ref().expect("PSC1_IO_CLOSED");
  let mut directory=PathBuf::from(format!("/proc/self/fd/{}",root.as_raw_fd()));
  let mut held=Vec::new();
  for part in &parts[..parts.len()-1]{
   let file=OpenOptions::new().read(true).custom_flags(DIRECTORY|NOFOLLOW).open(directory.join(part))?;
   directory=PathBuf::from(format!("/proc/self/fd/{}",file.as_raw_fd()));
   held.push(file);
  }
  action(&directory,parts[parts.len()-1])
 }
 fn read_text(&self,relative:&str)->Result<String>{
  self.parent(relative,|directory,name|{
   let file=OpenOptions::new().read(true).custom_flags(NOFOLLOW|NONBLOCK).open(directory.join(name))?;
   let info=file.metadata()?;
   if !info.is_file(){return deny("wrongType")}
   if info.len()>self.config.file_limit as u64{return deny("tooLarge")}
   let mut bytes=Vec::new();
   file.take(self.config.file_limit as u64+1).read_to_end(&mut bytes)?;
   if bytes.len()>self.config.file_limit{return deny("tooLarge")}
   String::from_utf8(bytes).map_err(|_|Failure::Policy("invalidUtf8"))
  })
 }
 fn write_text(&self,relative:&str,text:&str)->Result<()>{
  if text.len()>self.config.file_limit{return deny("tooLarge")}
  self.parent(relative,|directory,name|{
   match fs::symlink_metadata(directory.join(name)){
    Ok(info)=>{
     if info.file_type().is_symlink(){return deny("pathDenied")}
     if !info.is_file(){return deny("wrongType")}
    }
    Err(e) if e.kind()==io::ErrorKind::NotFound=>{},
    Err(e)=>return Err(e.into())
   }
   let temporary=directory.join(format!(".psc1-io-{}-{}",std::process::id(),TEMP.fetch_add(1,Ordering::Relaxed)));
   let mut file=OpenOptions::new().write(true).create_new(true).mode(0o600)
     .custom_flags(NOFOLLOW).open(&temporary)?;
   let result=(||->Result<()>{
    file.write_all(text.as_bytes())?;file.sync_all()?;drop(file);
    fs::rename(&temporary,directory.join(name))?;Ok(())
   })();
   if result.is_err(){
    match fs::remove_file(&temporary){Ok(())=>{},Err(e) if e.kind()==io::ErrorKind::NotFound=>{},Err(e)=>return Err(e.into())}
   }
   result
  })
 }
 fn read_line(&self)->Result<Option<String>>{
  let mut c=self.console.lock().expect("PSC1_IO_HOST_POISONED");
  if c.overflow{return deny("tooLarge")}
  let mut value=Vec::new();
  loop{
   if c.offset==c.pending.len()&&!c.ended{
    let mut buffer=[0;4096];
    let count=c.input.read(&mut buffer)?;
    c.pending=buffer[..count].to_vec();c.offset=0;c.ended=count==0;
   }
   if c.ended{
    if value.len()>self.config.line_limit{c.overflow=true;return deny("tooLarge")}
    return if value.is_empty(){Ok(None)}else{
     String::from_utf8(value).map(Some).map_err(|_|Failure::Policy("invalidUtf8"))
    }
   }
   let byte=c.pending[c.offset];c.offset+=1;
   if byte==10{
    if value.last()==Some(&13){value.pop();}
    return String::from_utf8(value).map(Some).map_err(|_|Failure::Policy("invalidUtf8"))
   }
   if value.len()==self.config.line_limit+1{c.overflow=true;return deny("tooLarge")}
   value.push(byte);
   if value.len()>self.config.line_limit&&byte!=13{c.overflow=true;return deny("tooLarge")}
  }
 }
 fn perform(&self,op:&str,fields:&BTreeMap<String,Box<RawValue>>)->Result<Value>{
  let text=|key:&str,invalid_unicode:&'static str|->Result<String>{
   let raw=fields.get(key).ok_or(Failure::Policy("protocolError"))?.get();
   if !raw.starts_with('"'){return deny("protocolError")}
   serde_json::from_str::<String>(raw).map_err(|_|Failure::Policy(invalid_unicode))
  };
  match op{
   "readLine"=>Ok(json!({"kind":"line","text":self.read_line()?})),
   "writeLine"=>{
    let value=text("text","invalidUtf8")?;
    if value.contains(['\r','\n']){return deny("protocolError")}
    if value.len()>self.config.line_limit{return deny("tooLarge")}
    let mut c=self.console.lock().expect("PSC1_IO_HOST_POISONED");
    c.output.write_all(value.as_bytes())?;c.output.write_all(b"\n")?;c.output.flush()?;
    Ok(json!({"kind":"unit"}))
   }
   "readUtf8"=>Ok(json!({"kind":"text","text":self.read_text(&text("path","pathDenied")?)?})),
   "writeUtf8"=>{
    let value=text("text","invalidUtf8")?;
    self.write_text(&text("path","pathDenied")?,&value)?;Ok(json!({"kind":"unit"}))
   }
   _=>deny("protocolError")
  }
 }
 pub fn execute(&self,source:String)->String{
  let open=self.root.lock().expect("PSC1_IO_HOST_POISONED").is_some();
  assert!(open,"PSC1_IO_CLOSED");
  let error=|code:&str|json!({"kind":"error","error":code}).to_string();
  if source.len()>6*self.config.file_limit.max(self.config.line_limit)+4096{return error("tooLarge")}
  // Raw fields preserve unpaired escaped UTF-16 long enough for the field's
  // explicit invalidUtf8/pathDenied policy. Syntax is still parsed by serde_json.
  let fields:BTreeMap<String,Box<RawValue>>=match serde_json::from_str(&source){
   Ok(v)=>v,Err(_)=>return error("protocolError")
  };
  let op=match fields.get("op").and_then(|v|serde_json::from_str::<String>(v.get()).ok()){
   Some(v)=>v,None=>return error("protocolError")
  };
  let keys:&[&str]=match op.as_str(){
   "readLine"=>&["op"],"writeLine"=>&["op","text"],
   "readUtf8"=>&["op","path"],"writeUtf8"=>&["op","path","text"],
   _=>return error("protocolError")
  };
  if fields.len()!=keys.len()||keys.iter().any(|k|!fields.contains_key(*k)){return error("protocolError")}
  if !self.config.allowed.contains(&op){return error("capabilityDenied")}
  match self.perform(&op,&fields){Ok(v)=>v.to_string(),Err(e)=>error(error_code(e))}
 }
}
