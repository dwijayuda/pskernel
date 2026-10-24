# Host transport only: import the generated API, forward unchanged UTF8 text.
import importlib.util,json,pathlib,sys
module_path,mode,names=sys.argv[1:4]
spec=importlib.util.spec_from_file_location("psc1_generated_service",module_path)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
expected=json.loads(names)
if sorted(module.__all__)!=sorted(expected): raise RuntimeError("PSC1_TARGET_API_MISMATCH")
if mode=="probe": sys.exit(0)
if mode!="execute" or len(expected)!=1 or len(sys.argv)!=6: raise RuntimeError("PSC1_TARGET_TRANSPORT_ARGUMENTS")
request,output=sys.argv[4:6]
wire=pathlib.Path(request).read_bytes()
if len(wire)>134217728: raise RuntimeError("PSC1_TARGET_REQUEST_LIMIT")
response=getattr(module,expected[0])(wire.decode("utf-8",errors="strict"))
if type(response) is not str: raise TypeError("PSC1_TARGET_RESPONSE_TYPE")
encoded=response.encode("utf-8",errors="strict")
if len(encoded)>134217728: raise RuntimeError("PSC1_TARGET_RESPONSE_LIMIT")
with open(output,"xb") as result: result.write(encoded)
