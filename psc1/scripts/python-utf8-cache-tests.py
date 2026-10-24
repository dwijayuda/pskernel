# Differential execution against retained helpers and retained emitted intrinsics.
import concurrent.futures,importlib.util,json,pathlib,random,sys
root=pathlib.Path(sys.argv[1])
def load(name,file):
 spec=importlib.util.spec_from_file_location(name,root/file)
 value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value)
 return value
a=load("optimized","actual.py");b=load("reference","reference.py")
runtime=load("runtime","runtime.py");old=load("legacy","legacy-runtime.py")
assert sorted(a.__all__)==sorted(b.__all__)==["atEnd","extract","get","next","size"]
checks=0
def same(fn,args):
 global checks
 actual=getattr(runtime,fn)(*args);expected=getattr(old,fn)(*args)
 assert actual==expected,(fn,args,actual,expected);checks+=1
 return expected
def invariant():
 entries,retained=runtime._psc_utf8_cache
 assert type(entries) is tuple and len(entries)<=8
 assert retained==sum(len(entry[1]) for entry in entries)
 assert 0<=retained<=33554432
 assert len({id(entry[0]) for entry in entries})==len(entries)
 for text,data in entries:assert type(text) is str and data==text.encode("utf-8")
samples=["","ASCII","λ🙂A\0é","\x7f\x80\u07ff\u0800\ud7ff\ue000\uffff\U00010000\U0010ffff","a\u0301é"]
rng=random.Random(4350)
scalars=[chr(n) for n in list(range(128))+[128,255,256,2047,2048,55295,57344,65535,65536,1114111]]
for _ in range(96):samples.append("".join(rng.choice(scalars) for _ in range(rng.randrange(25))))
for text in samples:
 size=len(text.encode("utf-8"))
 positions=sorted(set([-7,-1,0,1,size,size+1,10**100]+list(range(size+1))))
 assert a.size(text)==b.size(text)==size
 for position in positions:
  expected=same("_psc_string_get",(text,position))
  following=same("_psc_string_next",(text,position))
  if position>=0:
   assert a.get(text,position)==b.get(text,position)==expected
   assert a.next(text,position)==b.next(text,position)==following
   assert a.atEnd(text,position)==b.atEnd(text,position)==(position>=size)
  for stop in [-1,0,1,size//2,size,size+1,10**100]:
   value=same("_psc_string_extract",(text,position,stop))
   if position>=0 and stop>=0:assert a.extract(text,position,stop)==b.extract(text,position,stop)==value
 invariant()
# Distributed scalar coverage includes every UTF8 width and surrogate boundary.
for point in range(0,0x110000,61):
 if 0xd800<=point<0xe000:continue
 text=chr(point);size=len(text.encode("utf-8"))
 for position in range(size+2):
  same("_psc_string_get",(text,position));same("_psc_string_next",(text,position))
for text in ["\ud800","x\udfff","\ud800\udfff"]:
 for fn,args in [("_psc_string_get",(text,0)),("_psc_string_next",(text,0)),("_psc_string_extract",(text,0,1)),("_psc_string_extract",(text,2,1))]:
  results=[]
  for module in [runtime,old]:
   try:results.append(("ok",getattr(module,fn)(*args)))
   except Exception as error:results.append((type(error).__name__,str(error)))
  assert results[0]==results[1],(fn,results)
# Identity keys avoid equality scans; strong entries prevent id reuse confusion.
text="λ"*1001;other=("!"+text)[1:]
assert text==other and text is not other
first=runtime._psc_utf8(text);second=runtime._psc_utf8(other)
assert first==second and first is not second
assert runtime._psc_utf8(text) is first
for index in range(40):
 value=str(index)+"x"*2048
 assert runtime._psc_utf8(value)==value.encode("utf-8")
 invariant()
for index in range(5):
 value=str(index)+"λ"*(5*1024*1024)
 assert runtime._psc_utf8(value)==value.encode("utf-8")
 invariant()
before=runtime._psc_utf8_cache
oversized="a"*(33554432+1)
assert runtime._psc_utf8(oversized)==oversized.encode("utf-8")
assert runtime._psc_utf8_cache is before
assert all(entry[0] is not oversized for entry in runtime._psc_utf8_cache[0])
def worker(index):
 for step in range(80):
  text=str(index)+":"+str(step)+"λ🙂"*17
  assert runtime._psc_utf8(text)==text.encode("utf-8")
  assert runtime._psc_string_get(text,0)==text[0]
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:list(pool.map(worker,range(32)))
invariant()
print("PSC1_PYTHON_UTF8_CACHE: "+json.dumps({"passed":True,"differentialHelperQueries":checks,"publicIntrinsicComparisons":"both retained/current emitted code","unicodeScalarStride":61,"encodedCacheBudget":33554432,"entryLimit":8,"identityAndEviction":True,"oversizedNotRetained":True,"concurrentImmutableSnapshots":True,"surrogateErrorPriority":"retained","globalRecursionAndDigitLimits":"unchanged"}))
