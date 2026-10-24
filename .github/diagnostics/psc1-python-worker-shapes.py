import ast,hashlib,json,pathlib
reports=list(pathlib.Path("baseline").rglob("qualification.json"));assert len(reports)==1
report=json.loads(reports[0].read_text());assert report["testedCommit"]=="a8def92c857b71344717d92e2260aef25675fabb"
module=reports[0].parent/"G1-service/module.py";source=module.read_bytes()
assert hashlib.sha256(source).hexdigest()==report["generations"][0]["sourceSha256"]
tree=ast.parse(source);lines=source.decode().splitlines()
hot=["psStringEqFromWithFuel_u36_worker","psJsonParseStringChars_u36_worker","psJsonStringCharsAccWithFuel_u36_worker","psJsonStringOfCharsAcc_u36_worker","psListReverseAcc","psLocalFindUserInList"]
rows=[]
for node in tree.body:
 if not isinstance(node,ast.FunctionDef) or not any(label in node.name for label in hot):continue
 nested=[child.name for child in ast.walk(node) if isinstance(child,(ast.FunctionDef,ast.AsyncFunctionDef)) and child is not node]
 assignments={child.targets[0].id:child.value for child in ast.walk(node) if isinstance(child,ast.Assign) and len(child.targets)==1 and isinstance(child.targets[0],ast.Name)}
 tails=[]
 for child in ast.walk(node):
  if isinstance(child,ast.Yield) and isinstance(child.value,ast.Tuple) and len(child.value.elts)==3:
   callee,arguments,tail=child.value.elts
   if isinstance(tail,ast.Constant) and tail.value is True:
    value=assignments.get(callee.id) if isinstance(callee,ast.Name) else None
    tails.append({"line":child.lineno,"savedCallee":ast.dump(callee),"boundValue":ast.dump(value) if value else None,"arity":len(arguments.elts) if isinstance(arguments,ast.Tuple) else None})
 rows.append({"name":node.name,"line":node.lineno,"parameters":[p.arg for p in node.args.args],"nestedDefinitions":nested,"tailRequests":tails,"source":'\n'.join(lines[node.lineno-1:min(node.end_lineno,node.lineno+139)])})
assert rows
result={"schema":"psc1-python-preserved-hot-worker-shapes/1","qualified":False,"sourceSha256":hashlib.sha256(source).hexdigest(),"scope":"read-only AST/source audit of preserved generated compiler; no compiler execution or new performance claim","workers":rows}
out=pathlib.Path("diagnostics/python-worker-shapes");out.mkdir(parents=True,exist_ok=True);(out/"receipt.json").write_text(json.dumps(result,indent=2)+"\n")
print("PSC1_PYTHON_WORKER_SHAPES: "+json.dumps(result))
