# Independent AST boundary: only the cache helper/globals and equivalent encode calls differ.
import ast,json,sys
class Neutral(ast.NodeTransformer):
 def visit_Call(self,node):
  self.generic_visit(node)
  if isinstance(node.func,ast.Name) and node.func.id=="_psc_utf8":
   assert len(node.args)==1 and not node.keywords
   return ast.Call(func=ast.Attribute(value=node.args[0],attr="encode",ctx=ast.Load()),args=[ast.Constant(value="utf-8")],keywords=[])
  return node
def normalized(path):
 tree=ast.parse(open(path,encoding="utf-8").read())
 tree.body=[node for node in tree.body if not (
  isinstance(node,ast.FunctionDef) and node.name=="_psc_utf8" or
  isinstance(node,ast.Assign) and len(node.targets)==1 and isinstance(node.targets[0],ast.Name) and node.targets[0].id in {"_psc_utf8_cache","_psc_utf8_cache_limit"})]
 return ast.dump(Neutral().visit(tree),include_attributes=False)
assert normalized(sys.argv[1])==normalized(sys.argv[2]),"NON_UTF8_CACHE_AST_CHANGED"
print(json.dumps({"passed":True,"scope":"all AST outside bounded cache declarations and encode-call normalization matches retained emitter"}))
