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
reference_functions={node.name:node for node in reference.body if isinstance(node,ast.FunctionDef)}
loops=0;self_steps=0
class LoopNeutral(ast.NodeTransformer):
 def visit_FunctionDef(self,node):
  global loops,self_steps
  if not node.name.startswith(("_psc_g_","_psc_v_")) or len(node.body)!=1 or not isinstance(node.body[0],ast.While):
   return self.generic_visit(node)
  loop=node.body[0];old_function=reference_functions[node.name]
  assert isinstance(loop.test,ast.Constant) and loop.test.value is True and not loop.orelse
  assert node.args.args and not node.args.defaults and not node.args.vararg and not node.args.kwarg
  assert not any(isinstance(child,(ast.FunctionDef,ast.AsyncFunctionDef,ast.Lambda,ast.GeneratorExp))
                 for statement in old_function.body for child in ast.walk(statement)),"LOOP_LEXICAL_CAPTURE"
  parameters=[parameter.arg for parameter in node.args.args]
  old_assignments={child.targets[0].id:child for child in ast.walk(old_function)
    if isinstance(child,ast.Assign) and len(child.targets)==1 and isinstance(child.targets[0],ast.Name)}
  count=0
  class Steps(ast.NodeTransformer):
   def generic_visit(self,child):
    nonlocal count
    for field,value in ast.iter_fields(child):
     if isinstance(value,list):
      output=[];index=0
      while index<len(value):
       first=value[index]
       if index+2<len(value) and isinstance(first,ast.Assign) and len(first.targets)==1 and isinstance(first.targets[0],ast.Name) and isinstance(first.value,ast.Tuple) and isinstance(value[index+2],ast.Continue):
        middle=value[index+1];label=first.targets[0].id
        assert isinstance(middle,ast.Assign) and len(middle.targets)==1 and isinstance(middle.targets[0],ast.Tuple)
        assert [element.id for element in middle.targets[0].elts if isinstance(element,ast.Name)]==parameters and len(middle.targets[0].elts)==len(parameters)
        assert isinstance(middle.value,ast.Name) and middle.value.id==label
        old=old_assignments[label]
        assert isinstance(old.value,ast.Yield) and isinstance(old.value.value,ast.Tuple) and len(old.value.value.elts)==3
        callee,arguments,tail=old.value.value.elts
        assert isinstance(callee,ast.Name) and isinstance(arguments,ast.Tuple) and isinstance(tail,ast.Constant) and tail.value is True
        binding=old_assignments[callee.id].value
        assert isinstance(binding,ast.Name) and binding.id==node.name,"LOOP_CALLEE_NOT_EXACT_SELF"
        assert ast.dump(first.value)==ast.dump(arguments),"LOOP_ARGUMENT_SNAPSHOT_CHANGED"
        output.append(copy.deepcopy(old));count+=1;index+=3
       else:
        output.append(self.visit(first) if isinstance(first,ast.AST) else first);index+=1
      setattr(child,field,output)
     elif isinstance(value,ast.AST):setattr(child,field,self.visit(value))
    return child
  holder=ast.Module(body=loop.body,type_ignores=[]);holder=Steps().visit(holder)
  assert count>0 and not any(isinstance(child,(ast.Continue,ast.Break)) for child in ast.walk(holder)),"LOOP_UNAPPROVED_CONTROL"
  node.body=holder.body;loops+=1;self_steps+=count
  return node
actual=LoopNeutral().visit(actual)

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
print(json.dumps({"passed":True,"directCalls":converted,"maxDirectSourceDepth":maximum,"selfTailLoops":loops,"selfTailSteps":self_steps,"scope":"all AST outside bounded UTF8 cache and exact callee/arguments of bounded acyclic globals and lambda-free exact self-tail loops matches retained emitter"}))
