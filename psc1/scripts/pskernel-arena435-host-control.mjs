// Host-policy fixtures only. This file does not import or exercise a kernel.
import { readFileSync, writeSync } from "node:fs";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const mode=process.argv[2];
const modes=new Set(["normal","exit","hang","descendant","descendant-child","oom"]);
if(!modes.has(mode))throw Error("unknown host-control mode");
const cgroup=readFileSync("/proc/self/cgroup","utf8").split("\n").find(line=>line.startsWith("0::"))?.slice(3);
if(!cgroup||!/^\/psc1-generated-[0-9a-f]{32}$/.test(cgroup))throw Error("private cgroup missing");
const root="/sys/fs/cgroup"+cgroup;
const memoryMax=readFileSync(root+"/memory.max","utf8").trim();
const swapMax=readFileSync(root+"/memory.swap.max","utf8").trim();
const oomGroup=readFileSync(root+"/memory.oom.group","utf8").trim();
if(memoryMax!=="134217728"||swapMax!=="0"||oomGroup!=="1")throw Error("control-only cgroup policy differs");
const groupLine=readFileSync("/proc/self/status","utf8").match(/^Groups:[ \t]*(.*)$/m);
if(!groupLine)throw Error("supplementary group evidence missing");
const supplementary=groupLine[1].trim().split(/\s+/).filter(Boolean).map(Number);
if(process.getuid()===0||process.getgid()===0||supplementary.length!==0||process.env.PATH!=="")
  throw Error("unprivileged empty-PATH control required");
const evidence={mode,pid:process.pid,uid:process.getuid(),gid:process.getgid(),groups:supplementary,nodeGroups:process.getgroups(),
  path:process.env.PATH,cgroup,memoryMax,swapMax,oomGroup,node:process.version};
if(mode==="descendant-child"){
  setInterval(()=>{},1000);
}else{
  if(mode==="descendant"){
    const child=spawn(process.execPath,[fileURLToPath(import.meta.url),"descendant-child"],{
      detached:true,stdio:"ignore",env:{PATH:"",LANG:"C.UTF-8",LC_ALL:"C",TZ:"UTC"}
    });
    await new Promise((resolve,reject)=>{child.once("spawn",resolve);child.once("error",reject);});
    evidence.childPid=child.pid;
    evidence.childCgroup=readFileSync("/proc/"+child.pid+"/cgroup","utf8").split("\n")
      .find(line=>line.startsWith("0::"))?.slice(3);
    child.unref();
  }
  writeSync(1,"PSC1_HOST_CONTROL "+JSON.stringify(evidence)+"\n");
  if(mode==="exit")process.exitCode=17;
  else if(mode==="hang"||mode==="descendant")setInterval(()=>{},1000);
  else if(mode==="oom"){
    // External buffers are touched and retained, forcing the 128 MiB cgroup
    // before the unchanged 2048 MiB V8 old-space limit.
    const retained=[];
    for(;;)retained.push(Buffer.alloc(8*1024*1024,0x5a));
  }
}
