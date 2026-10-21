// Thin UTF8 argv transport; every command and JSON operation lives in source.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {createTypedIo} from '../host-tools/typed-io.mjs';
import {withWasmTypedIo} from '../host-tools/typed-io-wasm.mjs';
const [target,modulePath,configPath,...argv]=process.argv.slice(2);
const config=JSON.parse(fs.readFileSync(configPath,'utf8')),argumentsJson=JSON.stringify(argv);
let status;
if(target==='wasm-core'){
 try{
  status=await withWasmTypedIo({...config,abi:'psc1-wasm-core-linux-string-io/1'},
   ()=>new WebAssembly.Module(fs.readFileSync(modulePath)),
   {run:{parameters:['string'],result:'bool'}},
   program=>program.call('run',argumentsJson))?0:2;
 }catch(error){if(String(error).includes('PSC1_IO_REQUIRED_CAPABILITY_DENIED'))status=78;else throw error;}
}else{
 let io;
 try{io=createTypedIo({...config,abi:'psc1-node-linux-string-io/1'});}
 catch(error){if(String(error).includes('PSC1_IO_REQUIRED_CAPABILITY_DENIED'))process.exit(78);throw error;}
 try{
  const program=await import(pathToFileURL(fs.realpathSync(modulePath)).href);
  status=program.run(argumentsJson,request=>io.execute(request))?0:2;
 }finally{io.close();}
}
process.exitCode=status;
