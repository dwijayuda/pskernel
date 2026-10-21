// Explicit Linux host capability adapter for the checked String request protocol.
// Source semantics remain pure; this module neither admits code nor grants authority
// from manifests. The embedding host must load a separately checked artifact.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const C=fs.constants;
const operations=['readLine','writeLine','readUtf8','writeUtf8'];
const reply=(kind,fields={})=>JSON.stringify({kind,...fields});
const error=code=>reply('error',{error:code});
class PolicyError extends Error { constructor(code){super(code);this.code=code;} }
const deny=code=>{throw new PolicyError(code);};
function syscallError(e){
 if(e instanceof PolicyError)return e.code;
 if(e?.code==='ENOENT')return 'notFound';
 if(['ELOOP','ENOTDIR'].includes(e?.code))return 'pathDenied';
 if(['EISDIR','ENXIO','ENODEV'].includes(e?.code))return 'wrongType';
 if(['EACCES','EPERM','ENOSPC','EDQUOT','EROFS','EIO','EMFILE','ENFILE','EFBIG'].includes(e?.code))return 'ioFailure';
 // Programming errors, traps, malformed integration and unknown failures escape.
 throw e;
}
function finiteLimit(value,name){
 if(!Number.isSafeInteger(value)||value<1||value>16*1024*1024)
  throw Error('PSC1_IO_CONFIGURATION: '+name+' must be 1..16777216 bytes');
 return value;
}
function scalarBytes(text,limit){
 if(typeof text!=='string')deny('protocolError');
 if(!text.isWellFormed())deny('invalidUtf8');
 if(Buffer.byteLength(text,'utf8')>limit)deny('tooLarge');
 return Buffer.from(text,'utf8');
}
function decode(bytes){
 try{return new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);}
 catch(e){if(e instanceof TypeError)deny('invalidUtf8');throw e;}
}
function writeAll(fd,bytes){
 let offset=0;
 while(offset<bytes.length){
  const size=fs.writeSync(fd,bytes,offset,bytes.length-offset);
  if(size===0)throw Error('PSC1_IO_HOST_WRITE_STALLED');
  offset+=size;
 }
}
function segments(relative){
 if(typeof relative!=='string'||relative.length===0||relative.includes('\\')||
    relative.includes('\0')||path.posix.isAbsolute(relative))deny('pathDenied');
 const parts=relative.split('/');
 if(Buffer.byteLength(relative,'utf8')>4096||!relative.isWellFormed()||parts.some(p=>p===''||p==='.'||p==='..'))deny('pathDenied');
 return parts;
}
function exactKeys(object,keys){
 return object!==null&&typeof object==='object'&&!Array.isArray(object)&&
  Object.keys(object).sort().join(',')===[...keys].sort().join(',');
}
export function createTypedIo(config){
 if(process.platform!=='linux'||config?.abi!=='psc1-node-linux-string-io/1')
  throw Error('PSC1_IO_UNSUPPORTED_ABI');
 if(!exactKeys(config,['abi','capabilities','required','root','maxFileBytes','maxLineBytes','inputFd','outputFd']))
  throw Error('PSC1_IO_CONFIGURATION: exact configuration required');
 if(!Array.isArray(config.capabilities)||!Array.isArray(config.required)||
    [...config.capabilities,...config.required].some(x=>!operations.includes(x))||
    new Set(config.capabilities).size!==config.capabilities.length||
    new Set(config.required).size!==config.required.length)
  throw Error('PSC1_IO_CONFIGURATION: capabilities');
 if(config.required.some(x=>!config.capabilities.includes(x)))
  throw Error('PSC1_IO_REQUIRED_CAPABILITY_DENIED');
 const allowed=new Set(config.capabilities);
 const fileLimit=finiteLimit(config.maxFileBytes,'maxFileBytes');
 const lineLimit=finiteLimit(config.maxLineBytes,'maxLineBytes');
 for(const fd of [config.inputFd,config.outputFd])if(!Number.isSafeInteger(fd)||fd<0)
  throw Error('PSC1_IO_CONFIGURATION: console descriptor');
 if(typeof config.root!=='string'||!path.isAbsolute(config.root))
  throw Error('PSC1_IO_CONFIGURATION: absolute root');
 const root=fs.openSync(config.root,C.O_RDONLY|C.O_DIRECTORY|C.O_NOFOLLOW);
 let closed=false;
 function parent(relative,action){
  const parts=segments(relative),fds=[];
  let fd=root;
  try{
   for(const part of parts.slice(0,-1)){
    fd=fs.openSync('/proc/self/fd/'+fd+'/'+part,C.O_RDONLY|C.O_DIRECTORY|C.O_NOFOLLOW);
    fds.push(fd);
   }
   return action('/proc/self/fd/'+fd,parts.at(-1));
  }finally{for(const held of fds.reverse())fs.closeSync(held);}
 }
 function readText(relative){
  return parent(relative,(directory,name)=>{
   const fd=fs.openSync(directory+'/'+name,C.O_RDONLY|C.O_NOFOLLOW|C.O_NONBLOCK);
   try{
    const stat=fs.fstatSync(fd);
    if(!stat.isFile())deny('wrongType');
    if(stat.size>fileLimit)deny('tooLarge');
    // A growing file is still bounded. One extra byte detects overflow.
    const buffer=Buffer.alloc(fileLimit+1);
    let size=0;
    while(size<buffer.length){
     const count=fs.readSync(fd,buffer,size,buffer.length-size,null);
     if(count===0)break;
     size+=count;
    }
    if(size>fileLimit)deny('tooLarge');
    return decode(buffer.subarray(0,size));
   }finally{fs.closeSync(fd);}
  });
 }
 function writeText(relative,text){
  const bytes=scalarBytes(text,fileLimit);
  return parent(relative,(directory,name)=>{
   try{
    const stat=fs.lstatSync(directory+'/'+name);
    if(stat.isSymbolicLink())deny('pathDenied');
    if(!stat.isFile())deny('wrongType');
   }catch(e){if(e?.code!=='ENOENT')throw e;}
   const temporary=directory+'/.psc1-io-'+crypto.randomUUID();
   let fd,renamed=false;
   try{
    fd=fs.openSync(temporary,C.O_WRONLY|C.O_CREAT|C.O_EXCL|C.O_NOFOLLOW,0o600);
    writeAll(fd,bytes);
    fs.fsyncSync(fd);
    fs.closeSync(fd);fd=undefined;
    fs.renameSync(temporary,directory+'/'+name);renamed=true;
   }finally{
    if(fd!==undefined)fs.closeSync(fd);
    if(!renamed)try{fs.unlinkSync(temporary);}catch(e){if(e?.code!=='ENOENT')throw e;}
   }
  });
 }
 let input=Buffer.alloc(0),inputOffset=0,inputEnded=false,lineOverflow=false;
 function readLine(){
  if(lineOverflow)deny('tooLarge');
  const bytes=Buffer.alloc(lineLimit+1);let size=0;
  for(;;){
   if(inputOffset===input.length&&!inputEnded){
    const chunk=Buffer.alloc(4096),count=fs.readSync(config.inputFd,chunk,0,chunk.length,null);
    input=chunk.subarray(0,count);inputOffset=0;inputEnded=count===0;
   }
   if(inputEnded){
    if(size>lineLimit){lineOverflow=true;deny('tooLarge');}
    return size===0?null:decode(bytes.subarray(0,size));
   }
   const byte=input[inputOffset++];
   if(byte===10){
    if(size&&bytes[size-1]===13)size--;
    return decode(bytes.subarray(0,size));
   }
   if(size===bytes.length){lineOverflow=true;deny('tooLarge');}
   bytes[size++]=byte;
   if(size>lineLimit&&byte!==13){lineOverflow=true;deny('tooLarge');}
  }
 }
 return Object.freeze({
  execute(source){
   if(closed)throw Error('PSC1_IO_CLOSED');
   if(typeof source!=='string'||Buffer.byteLength(source,'utf8')>6*Math.max(fileLimit,lineLimit)+4096)
    return error('tooLarge');
   let request;
   try{request=JSON.parse(source);}catch(e){if(e instanceof SyntaxError)return error('protocolError');throw e;}
   const keys={readLine:['op'],writeLine:['op','text'],readUtf8:['op','path'],writeUtf8:['op','path','text']};
   if(!request||!Object.hasOwn(keys,request.op)||!exactKeys(request,keys[request.op]))return error('protocolError');
   if(!allowed.has(request.op))return error('capabilityDenied');
   try{
    if(request.op==='readLine')return reply('line',{text:readLine()});
    if(request.op==='writeLine'){
     if(typeof request.text!=='string'||/[\r\n]/.test(request.text))deny('protocolError');
     const bytes=scalarBytes(request.text,lineLimit);
     writeAll(config.outputFd,Buffer.concat([bytes,Buffer.from('\n')]));
     return reply('unit');
    }
    if(request.op==='readUtf8')return reply('text',{text:readText(request.path)});
    writeText(request.path,request.text);return reply('unit');
   }catch(e){return error(syscallError(e));}
  },
  close(){if(!closed){closed=true;fs.closeSync(root);}}
 });
}

// Preflight precedes loading. Application traps and checker failures escape.
export async function withTypedIo(config,loadProgram,useProgram){
 const io=createTypedIo(config);
 try{return await useProgram(await loadProgram(),io);}
 finally{io.close();}
}
