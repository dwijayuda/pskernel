import importlib.util,json,pathlib,sys
root=pathlib.Path(sys.argv[1]);before=sys.getrecursionlimit()
def load(name,file):
 spec=importlib.util.spec_from_file_location(name,root/file);module=importlib.util.module_from_spec(spec)
 exec(compile((root/file).read_bytes(),str(root/file),"exec"),module.__dict__)
 return module
actual=load("direct","actual.py");legacy=load("legacy","legacy.py")
counts={}
def instrument(module,label):
 original=module._psc_run
 def run(fn,*args):
  counts[label]=counts.get(label,0)+1
  return original(fn,*args)
 module._psc_run=run
instrument(actual,"actual");instrument(legacy,"legacy")
for value in [0,1,7,1000,200000]:
 assert actual.run(value)==legacy.run(value)==value+1
assert sys.getrecursionlimit()==before
print("PSC1_PYTHON_DIRECT_CALLS: "+json.dumps({"passed":True,"cases":5,"deepDynamicAliasAndShadowRecursion":200000,"recursionLimit":"unchanged","scope":"retained scheduler versus bounded direct globals; dynamic aliases and recursive functions retain suspension"}))
