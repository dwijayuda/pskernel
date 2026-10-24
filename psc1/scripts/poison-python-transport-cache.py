# Constructed transport fixture only; no compiler semantics or qualification.
import importlib.util,marshal,pathlib,struct,sys
module=pathlib.Path(sys.argv[1]);stat=module.stat()
payload=compile("raise RuntimeError('PSC1_UNTRUSTED_PYC_EXECUTED')\n",str(module),"exec")
cache=pathlib.Path(importlib.util.cache_from_source(str(module)))
cache.parent.mkdir(parents=True,exist_ok=True)
cache.write_bytes(importlib.util.MAGIC_NUMBER+struct.pack("<III",0,int(stat.st_mtime)&0xffffffff,stat.st_size&0xffffffff)+marshal.dumps(payload))
# Control: prove this cache is accepted by the ordinary source loader.
spec=importlib.util.spec_from_file_location("poison_control",module)
loaded=importlib.util.module_from_spec(spec)
try:spec.loader.exec_module(loaded)
except RuntimeError as error:assert str(error)=="PSC1_UNTRUSTED_PYC_EXECUTED"
else:raise AssertionError("POISON_CACHE_CONTROL_NOT_EXECUTED")
print("PSC1_PYTHON_PYC_POISON_CONTROL: ordinary loader executed unlisted cache; production must ignore it")
