# Pinned optional target consumer. Source never selects tools or public names.
import ast, json, runpy, sys
if sys.version_info[:3] != (3,14,8):
    raise RuntimeError("PSC1_PYTHON_RUNTIME_PIN")
source, names = sys.argv[1:]
expected=json.load(open(names,encoding="utf-8"))
with open(source,encoding="utf-8") as stream:
    tree=ast.parse(stream.read(),filename=source)
compile(tree,source,"exec")
module=runpy.run_path(source)
if module.get("__all__") != expected or any(name not in module for name in expected):
    raise RuntimeError("PSC1_PROVIDER_PUBLIC_API")
print(json.dumps({"accepted": True, "publicNames": expected, "runtime": "Python 3.14.8"}))
