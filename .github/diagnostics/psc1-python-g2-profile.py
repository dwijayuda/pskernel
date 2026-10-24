# Read-only replay profiler for an exact archived generated Python compiler.
import cProfile,hashlib,importlib.util,json,pathlib,pstats,signal,sys,time
assert sys.version_info[:3]==(3,14,8)
root=pathlib.Path(sys.argv[1])
reports=list(root.rglob("qualification.json"))
assert len(reports)==1
report=json.loads(reports[0].read_text())
assert report["target"]=="python"
assert report["testedCommit"]==sys.argv[2]
request=reports[0].parent/"G2-self.request.json"
module=reports[0].parent/"G1-service"/"module.py"
assert request.is_file() and module.is_file()
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
g1=next(g for g in report["generations"] if g["generation"]==1)
assert digest(module)==g1["sourceSha256"]
assert digest(request)==next(e["requestSha256"] for e in report["events"] if e.get("id")=="G2-self")
out=pathlib.Path(sys.argv[3]);out.mkdir(parents=True,exist_ok=True)
spec=importlib.util.spec_from_file_location("archived_psc1",module)
api=importlib.util.module_from_spec(spec);exec(compile(module.read_bytes(),str(module),"exec"),api.__dict__)
assert api.__all__==["psCompilerPythonServiceCandidate"]
wire=request.read_bytes().decode("utf-8",errors="strict")
profile=cProfile.Profile()
class DiagnosticBudgetEnded(Exception):pass
last={}
def end_budget(_signal,frame):
 chain=[];walk=frame
 while walk is not None:
  row={"function":walk.f_code.co_name,"line":walk.f_lineno}
  if walk.f_code.co_name=="_psc_run":
   current=walk.f_locals.get("current")
   if current is not None and hasattr(current,"gi_code"):
    row["currentGenerator"]=current.gi_code.co_name
    row["generatorLine"]=current.gi_frame.f_lineno if current.gi_frame is not None else None
   stack=walk.f_locals.get("stack",[])
   row["suspendedCount"]=len(stack)
   row["suspendedFunctions"]=[g.gi_code.co_name for g in stack[-16:]]
  chain.append(row);walk=walk.f_back
 last["frames"]=chain
 raise DiagnosticBudgetEnded()
signal.signal(signal.SIGALRM,end_budget)
started=time.monotonic();status="finished";response=None
profile.enable();signal.setitimer(signal.ITIMER_REAL,120)
try:response=api.psCompilerPythonServiceCandidate(wire)
except DiagnosticBudgetEnded:status="diagnostic-120s-budget-ended"
finally:
 signal.setitimer(signal.ITIMER_REAL,0);profile.disable()
 elapsed=time.monotonic()-started
 profile.dump_stats(str(out/"actual-G2.cprofile"))
 with (out/"actual-G2-cumulative.txt").open("w") as f:pstats.Stats(profile,stream=f).strip_dirs().sort_stats("cumulative").print_stats(65)
 with (out/"actual-G2-self.txt").open("w") as f:pstats.Stats(profile,stream=f).strip_dirs().sort_stats("tottime").print_stats(65)
 receipt={"schema":"psc1-archived-python-G2-profile/1","qualified":False,"status":status,"elapsedSeconds":elapsed,"requestSha256":digest(request),"sourceSha256":digest(module),"sourceClosureDigest":report["sourceClosureDigest"],"scope":"cProfile of exact archived generated G1 and G2 request for 120 seconds; no native compiler, no admission or fixed-point qualification","globalRecursionAndDigitLimits":"unchanged","lastActiveFrames":last.get("frames"),"cacheEntryBytes":[len(entry[1]) for entry in api._psc_utf8_cache[0]],"cacheRetainedBytes":api._psc_utf8_cache[1]}
 (out/"receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
 print(json.dumps(receipt),flush=True)
 print((out/"actual-G2-cumulative.txt").read_text(),flush=True)
 print((out/"actual-G2-self.txt").read_text(),flush=True)

# Exact self-tail-qualified G1 baseline; terminal G2 deadline40079719620.
