import {executeService} from '../host-tools/generated-target-tools.mjs';
const [artifact,hash,request,output]=process.argv.slice(2);
console.log(JSON.stringify(await executeService(artifact,hash,request,output)));
