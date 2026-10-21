# Explicit Wasm String ABI v1

Status: scoped-qualified at 74179eb664e132502a24ce60b52a3dbd52b1d0cc in Linux
run 39627387430. Default ABIs remain unchanged.

--abi wasm-string permits public Bool/String arguments/results after source
admission and strict original/transformed IR validation. --abi io-dispatcher
additionally accepts the checked String-to-String dispatcher input and binds it
to the explicit psc1:io dispatch import. A source dispatcher is a logical function
argument; no effectful logical axiom or unchecked kernel reduction is introduced.

Strings inside compiled code remain owned GC structures with UTF-8 byte arrays
and scalar counts. Wrappers copy and validate host bytes, rejecting overlong,
surrogate, truncated, stray continuation and out-of-range UTF-8. Integer range
checks precede copying. Host mutation cannot alias a source String.

The core ABI flattens String arguments to i32 pointer/byte-length pairs and Bool
to canonical i32 zero/one. String results return a pointer to a two-i32 record.
memory is a fixed256-page16MiB arena; cabi_realloc allocates bounded byte buffers.
cabi_post_return resets the arena after the consumer copies the result. The ABI
supports synchronous calls, alignment1 byte allocations, at most16 flat public
arguments and at mostone dispatcher per declaration. Other shapes refuse.
Wasm IO configuration supports payload bounds up to 2 MiB; larger requested bounds
refuse before guest loading. This reserves room for worst-case JSON escaping and
response allocation. Oversized encoded source requests return the same typed
tooLarge response as the portable adapter before copying to the arena.
Pure public String ABI memory exhaustion, malformed boundary values and reentry trap; they are not
source IoError. A trapped guest instance is discarded.

The component emitter uses canonical UTF-8, memory, realloc and post-return
options. Its public schema is rederived from validated source IR, since different
logical result types can flatten to the same core signature. IO components
instantiate the typed allocator module first, lower the explicit host dispatcher,
then instantiate the GC compiler module with that allocator's memory/globals.
The companion .core.wasm is independently executable with local arena memory;
the component embeds the same checked function graph with imported arena memory.

typed-io-wasm.mjs embeds a separately checked core module after Node capability
preflight. typed_io_component.py embeds a separately checked component after
standalone Python capability preflight. Neither provides source admission or a
sandbox for arbitrary host packages. Host exceptions escape source handlers.
The component consumer is independently pinned to wasmtime Python49.0.0; existing
CLI qualification remains pinned to Wasmtime49.0.4 and wasm-tools1.254.0.

Ten native ABI checks, both authored grammar/core/component execution matrices,
malformed UTF8/pointer/allocation refusals and an oversized-GC request compared
with the portable adapter pass. Exact receipt:
PSC1_TYPED_IO_EXECUTION_QUALIFICATION_2026-10-21.json. Pure protocol and prior GC helper tests do
not substitute for String boundary or actual file/console execution evidence.
