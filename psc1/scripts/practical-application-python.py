"""Thin argv transport for checked Python and Wasm-component applications."""
import importlib.util
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "host-tools"))
from typed_io import TypedIo

target, module_path, config_path, *arguments = sys.argv[1:]
config = json.loads(Path(config_path).read_text())
encoded = json.dumps(arguments, ensure_ascii=False, separators=(",", ":"))
if target == "wasm-component":
    from typed_io_component import with_component_io
    try:
        success = with_component_io({**config, "abi": "psc1-wasm-component-linux-string-io/1"},
                                    module_path, lambda call: call("run", encoded))
    except RuntimeError as error:
        if "PSC1_IO_REQUIRED_CAPABILITY_DENIED" in str(error):
            sys.exit(78)
        raise
else:
    try:
        host = TypedIo({**config, "abi": "psc1-python-linux-string-io/1"})
    except RuntimeError as error:
        if "PSC1_IO_REQUIRED_CAPABILITY_DENIED" in str(error):
            sys.exit(78)
        raise
    with host:
        spec = importlib.util.spec_from_file_location("checked_application", module_path)
        program = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(program)
        success = program.run(encoded, host.execute)
sys.exit(0 if success else 2)
