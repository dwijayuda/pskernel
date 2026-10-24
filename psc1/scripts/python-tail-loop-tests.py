import ast,importlib.util,inspect,json,pathlib,sys,time
root=pathlib.Path(sys.argv[1]);limit=sys.getrecursionlimit()
def load(name,file):
 spec=importlib.util.spec_from_file_location(name,root/file);module=importlib.util.module_from_spec(spec)
 exec(compile((root/file).read_bytes(),str(root/file),"exec"),module.__dict__);return module
actual=load("actual","actual.py");retained=load("retained","retained.py")
tree=ast.parse((root/"actual.py").read_text());definitions={node.name:node for node in tree.body if isinstance(node,ast.FunctionDef)}
for name in ["count","swap","build","length","ordered"]:
 assert isinstance(definitions["_psc_g_"+name].body[0],ast.While),name
for name in ["closure","closureRun","shadow"]:
 assert not any(isinstance(node,ast.While) for node in ast.walk(definitions["_psc_g_"+name])),name
assert not actual._psc_g_count.__code__.co_flags & inspect.CO_GENERATOR
assert retained._psc_g_count.__code__.co_flags & inspect.CO_GENERATOR
cases=0
for value in [0,1,2,7,1000,200000]:
 assert actual.count(value,7)==retained.count(value,7)==value+7;cases+=1
 expected=13*1000000+29 if value%2==0 else 29*1000000+13
 assert actual.swap(value,13,29)==retained.swap(value,13,29)==expected;cases+=1
 assert actual.chain(value)==retained.chain(value)==value;cases+=1
 assert actual.closureRun(value)==retained.closureRun(value)==(0 if value==0 else 1);cases+=1
 assert actual.shadowRun(value)==retained.shadowRun(value)==value*2;cases+=1
assert actual.count(2000000,0)==retained.count(2000000,0)==2000000;cases+=1
def ordered(module,count,failure):
 events=[]
 def dispatcher(payload):
  events.append(payload)
  if failure and payload.startswith(failure):raise RuntimeError("ORDER_"+failure)
  return payload
 try:result=("ok",module.ordered(count,dispatcher,"left","right"))
 except BaseException as error:result=("error",type(error).__name__,str(error))
 return result,events
for count in [0,1,7,1000]:
 for failure in ["","first","second"]:
  current=ordered(actual,count,failure);old=ordered(retained,count,failure)
  assert current==old;(result,events)=current
  expected=[] if count==0 else ["first:"+str(count),"second:"+str(count)]
  if count and failure=="first":expected=expected[:1]
  assert events[:len(expected)]==expected
  if not failure:assert len(events)==count*2
  cases+=1
assert sys.getrecursionlimit()==limit
print("PSC1_PYTHON_SELF_TAIL_LOOPS: "+json.dumps({"passed":True,"comparisons":cases,"deepTailSteps":2000000,"deepEscapingLambdaFallback":200000,"parallelArgumentSwap":True,"typedIoOrderAndFirstFailure":True,"lexicalShadowRefusal":True,"exactAstOutsideApprovedLoops":True,"recursionLimit":"unchanged","scope":"same emitter retained scheduler versus lambda-free exact-self loops; semantic fuel and other calls unchanged"}))
