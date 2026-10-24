# Read-only replay profiler for an exact archived generated Python compiler.
import ast,gc,cProfile,hashlib,importlib.util,json,pathlib,pstats,signal,sys,time
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
api=importlib.util.module_from_spec(spec)
original_source=module.read_text()
old_cache="# Immutable snapshots keep identity hits independent of String equality.\n_psc_utf8_cache = ((), 0)\n_psc_utf8_cache_limit = 33554432\n\ndef _psc_utf8(text):\n    global _psc_utf8_cache\n    entries, retained = _psc_utf8_cache\n    for index, entry in _psc_b.enumerate(entries):\n        if entry[0] is text:\n            if index:\n                _psc_utf8_cache = ((entry,) + entries[:index] + entries[index + 1:], retained)\n            return entry[1]\n    data = text.encode(\"utf-8\")\n    size = _psc_b.len(data)\n    if size <= _psc_utf8_cache_limit:\n        entries = ((text, data),) + entries\n        retained += size\n        while _psc_b.len(entries) > 8 or retained > _psc_utf8_cache_limit:\n            retained -= _psc_b.len(entries[-1][1])\n            entries = entries[:-1]\n        _psc_utf8_cache = (entries, retained)\n    return data\n\n"
new_cache="# Immutable snapshots keep identity hits independent of String equality.\n_psc_utf8_cache = ((), 0)\n_psc_utf8_cache_limit = 33554432\n\ndef _psc_utf8(text):\n    global _psc_utf8_cache\n    entries, retained = _psc_utf8_cache\n    if entries:\n        if entries[0][0] is text:\n            return entries[0][1]\n        if _psc_b.len(entries) > 1 and entries[1][0] is text:\n            return entries[1][1]\n    for index in _psc_b.range(2, _psc_b.len(entries)):\n        entry = entries[index]\n        if entry[0] is text:\n            _psc_utf8_cache = ((entry,) + entries[:index] + entries[index + 1:], retained)\n            return entry[1]\n    data = text.encode(\"utf-8\")\n    size = _psc_b.len(data)\n    if size <= _psc_utf8_cache_limit:\n        entries = ((text, data),) + entries\n        retained += size\n        while _psc_b.len(entries) > 8 or retained > _psc_utf8_cache_limit:\n            retained -= _psc_b.len(entries[-1][1])\n            entries = entries[:-1]\n        _psc_utf8_cache = (entries, retained)\n    return data\n\n"
mode=sys.argv[4];assert mode in ("hot-pair","owned-sync")
assert original_source.count(old_cache)==1
modified=original_source.replace(old_cache,new_cache)
dispatch_sites=0
if mode=="owned-sync":
 tree=ast.parse(modified)
 class Dispatch(ast.NodeTransformer):
  def visit_Yield(self,node):
   global dispatch_sites
   if isinstance(node.value,ast.Tuple) and len(node.value.elts)==3:
    callee,arguments,tail=node.value.elts
    assert isinstance(callee,ast.Name) and isinstance(arguments,ast.Tuple)
    dispatch_sites+=1
    return ast.IfExp(test=ast.Call(func=ast.Name(id="_psc_can_run_direct",ctx=ast.Load()),args=[callee],keywords=[]),
      body=ast.Call(func=callee,args=arguments.elts,keywords=[]),orelse=node)
   return node
 for index,node in enumerate(tree.body):
  if isinstance(node,ast.FunctionDef) and node.name.startswith(("_psc_g_","_psc_v_")):
   tree.body[index]=Dispatch().visit(node)
 owned=[index for index,node in enumerate(tree.body) if isinstance(node,ast.FunctionDef) and node.name.startswith(("_psc_g_","_psc_v_"))]
 tree.body[owned[-1]+1:owned[-1]+1]=ast.parse("_psc_init_direct(_psc_b.globals())").body
 tree.body[owned[0]:owned[0]]=ast.parse("\n# Only generated source code is eligible; code identity and globals are authority.\nfrom types import FunctionType as _psc_Function, CodeType as _psc_Code\n_psc_direct_globals = None\n_psc_direct_code_ids = _psc_b.frozenset()\n_psc_direct_code_refs = ()\n\ndef _psc_init_direct(namespace):\n    global _psc_direct_globals, _psc_direct_code_ids, _psc_direct_code_refs\n    pending = [value.__code__ for name, value in namespace.items()\n               if _psc_b.type(value) is _psc_Function and\n               (name.startswith(\"_psc_g_\") or name.startswith(\"_psc_v_\"))]\n    seen = _psc_b.set()\n    refs = []\n    while pending:\n        code = pending.pop()\n        identity = _psc_b.id(code)\n        if identity in seen:\n            continue\n        seen.add(identity)\n        pending.extend(value for value in code.co_consts if _psc_b.type(value) is _psc_Code)\n        name = code.co_name\n        owned = name.startswith(\"_psc_g_\") or name.startswith(\"_psc_v_\") or (\n            name.startswith(\"_psc_l\") and name.endswith(\"_closure\"))\n        if owned and not code.co_flags & (0x20 | 0x80 | 0x200):\n            refs.append(code)\n    _psc_direct_globals = namespace\n    _psc_direct_code_refs = _psc_b.tuple(refs)\n    _psc_direct_code_ids = _psc_b.frozenset(_psc_b.id(code) for code in refs)\n\ndef _psc_can_run_direct(fn):\n    return (_psc_b.type(fn) is _psc_Function and\n            fn.__globals__ is _psc_direct_globals and\n            _psc_b.id(fn.__code__) in _psc_direct_code_ids)\n\n").body
 modified=ast.unparse(ast.fix_missing_locations(tree))+"\n"
exec(compile(modified,str(module)+"["+mode+"]","exec"),api.__dict__)
smoke=[]
for label in ["G1-lean-modules","G1-ps-integer-unicode","G1-ps-list-literal","G1-lean-handler-pattern","G1-lean-ordinary-loop"]:
 request_file=reports[0].parent/(label+".request.json")
 candidate_file=reports[0].parent/(label+".candidate.json")
 assert request_file.is_file() and candidate_file.is_file()
 response=api.psCompilerPythonServiceCandidate(request_file.read_text())
 assert response.strip()==candidate_file.read_text().strip(),label
 smoke.append(label)
gc.collect()

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
 receipt={"schema":"psc1-archived-python-G2-profile/1","qualified":False,"status":status,"elapsedSeconds":elapsed,"requestSha256":digest(request),"sourceSha256":digest(module),"sourceClosureDigest":report["sourceClosureDigest"],"scope":"controlled runtime-only substitution on exact archived G1/G2 input; five full frozen candidate responses match; no native compiler/admission/fixed-point qualification","mode":mode,"modifiedSourceSha256":hashlib.sha256(modified.encode()).hexdigest(),"matchedFrozenCandidates":smoke,"ownedSyncCallSites":dispatch_sites,"globalRecursionAndDigitLimits":"unchanged","lastActiveFrames":last.get("frames"),"cacheEntryBytes":[len(entry[1]) for entry in api._psc_utf8_cache[0]],"cacheRetainedBytes":api._psc_utf8_cache[1]}
 (out/"receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
 print(json.dumps(receipt),flush=True)
 print((out/"actual-G2-cumulative.txt").read_text(),flush=True)
 print((out/"actual-G2-self.txt").read_text(),flush=True)
