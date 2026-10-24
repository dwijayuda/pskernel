# Independent AST boundary: cache normalization and known non-suspending global calls only.
import ast,copy,inspect,json,re,sys,types
class Neutral(ast.NodeTransformer):
 def visit_Call(self,node):
  self.generic_visit(node)
  if isinstance(node.func,ast.Name) and node.func.id=="_psc_utf8":
   assert len(node.args)==1 and not node.keywords
   return ast.Call(func=ast.Attribute(value=node.args[0],attr="encode",ctx=ast.Load()),args=[ast.Constant(value="utf-8")],keywords=[])
  return node
def normalized(path):
 source=open(path,encoding="utf-8").read();tree=ast.parse(source)
 code=compile(source,path,"exec")
 globals={entry.co_name:entry for entry in code.co_consts if isinstance(entry,types.CodeType)}
 tree.body=[node for node in tree.body if not (
  isinstance(node,ast.FunctionDef) and node.name=="_psc_utf8" or
  isinstance(node,ast.Assign) and len(node.targets)==1 and isinstance(node.targets[0],ast.Name) and node.targets[0].id in {"_psc_utf8_cache","_psc_utf8_cache_limit"})]
 return Neutral().visit(tree),globals
actual,functions=normalized(sys.argv[1]);reference,_=normalized(sys.argv[2])
def key(node):
 return node.targets[0].id if isinstance(node,ast.Assign) and len(node.targets)==1 and isinstance(node.targets[0],ast.Name) else None
assignments={key(node):node.value for node in ast.walk(actual) if key(node)}
old={key(node):node.value for node in ast.walk(reference) if key(node) and isinstance(node.value,ast.Yield)}
edges={};converted=0
def visit(node,owner="<module>"):
 global converted
 if isinstance(node,(ast.FunctionDef,ast.AsyncFunctionDef)):owner=node.name
 label=key(node)
 if label in old and isinstance(node.value,ast.Call):
  request=old[label].value
  assert isinstance(request,ast.Tuple) and len(request.elts)==3
  callee,arguments,tail=request.elts
  assert isinstance(callee,ast.Name) and re.fullmatch(r"_psc_l[0-9]+_tmp",callee.id)
  assert isinstance(arguments,ast.Tuple) and isinstance(tail,ast.Constant) and type(tail.value) is bool
  assert not node.value.keywords and ast.dump(node.value.func)==ast.dump(callee)
  assert [ast.dump(arg) for arg in node.value.args]==[ast.dump(arg) for arg in arguments.elts]
  binding=assignments.get(callee.id)
  assert isinstance(binding,ast.Name) and binding.id.startswith("_psc_g_"),"DIRECT_CALLEE_NOT_GLOBAL"
  implementation=functions[binding.id]
  assert not implementation.co_flags & (inspect.CO_GENERATOR|inspect.CO_COROUTINE|inspect.CO_ASYNC_GENERATOR),"DIRECT_CALLEE_SUSPENDS"
  edges.setdefault(owner,set()).add(binding.id)
  node.value=copy.deepcopy(old[label]);converted+=1
 for child in ast.iter_child_nodes(node):visit(child,owner)
visit(actual)
def depth(name,active=()):
 assert name not in active,"DIRECT_SOURCE_CALL_CYCLE"
 return 1+max((depth(next,active+(name,)) for next in edges.get(name,())),default=0)
maximum=max((depth(name) for name in edges),default=0)
assert maximum<=3,"DIRECT_SOURCE_CALL_DEPTH_UNBOUNDED"
assert ast.dump(actual,include_attributes=False)==ast.dump(reference,include_attributes=False),"NON_APPROVED_AST_CHANGED"
print(json.dumps({"passed":True,"directCalls":converted,"maxDirectSourceDepth":maximum,"scope":"all AST outside bounded UTF8 cache and exact callee/arguments of bounded acyclic non-generator global calls matches retained emitter"}))
