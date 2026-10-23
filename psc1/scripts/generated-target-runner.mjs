import {executeService} from '../host-tools/generated-target-tools.mjs';
import {PERFORMANCE_PROFILE} from './selfhost-qualification-profiles.mjs';
const [artifact,hash,request,output,profile=PERFORMANCE_PROFILE]=process.argv.slice(2);
console.log(JSON.stringify(await executeService(artifact,hash,request,output,profile)));
