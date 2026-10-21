"""Explicit Wasmtime component String binding backed by standalone Python IO.

Requires the separately pinned wasmtime Python package. Preflight precedes
component compilation/instantiation; host exceptions retain their host channel.
"""
from pathlib import Path
import sys
from typed_io import TypedIo


def with_component_io(config, component_path, use_program):
    if config.get("abi") != "psc1-wasm-component-linux-string-io/1":
        raise RuntimeError("PSC1_IO_UNSUPPORTED_ABI")
    if config.get("maxFileBytes", 0) > 2097152 or config.get("maxLineBytes", 0) > 2097152:
        raise RuntimeError("PSC1_IO_CONFIGURATION: Wasm IO supports at most 2097152 payload bytes")
    # No Wasmtime import or guest load occurs until capability preflight succeeds.
    with TypedIo({**config, "abi": "psc1-python-linux-string-io/1"}) as host:
        import wasmtime
        from wasmtime.component import Component, Linker
        engine = wasmtime.Engine()
        store = wasmtime.Store(engine)
        component = Component.from_file(engine, component_path)
        linker = Linker(engine)
        with linker.root() as root:
            root.add_func("dispatch", lambda _store, request: host.execute(request))
        instance = linker.instantiate(store, component)

        def call(name, *args):
            function = instance.get_func(store, name)
            if function is None:
                raise RuntimeError("PSC1_COMPONENT_EXPORT_MISSING")
            result = function(store, *args)
            function.post_return(store)
            return result

        return use_program(call)
