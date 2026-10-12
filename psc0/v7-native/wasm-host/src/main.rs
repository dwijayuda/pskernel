use wasmtime::{Config, Engine, Result, Store};
use wasmtime::component::{Component, Instance, Linker, Val};
use std::path::Path;

fn lookup(store: &mut Store<()>, instance: Instance, name: &str) -> wasmtime::component::Func {
    let interface = instance.get_export_index(&mut *store, None, "api");
    let index = instance.get_export_index(&mut *store, interface.as_ref(), name).expect(name);
    instance.get_func(&mut *store, &index).expect(name)
}
fn invoke(store: &mut Store<()>, instance: Instance, name: &str, input: &[Val], expected: Val) -> Result<()> {
    let function = lookup(&mut *store, instance, name);
    let mut output = [Val::Bool(false)];
    function.call(&mut *store, input, &mut output)?;
    assert_eq!(output[0], expected, "{name}");
    function.post_return(&mut *store)?;
    Ok(())
}
fn natural(limbs: &[u32]) -> Val {
    Val::Record(vec![("limbs".into(), Val::List(limbs.iter().map(|x| Val::U32(*x)).collect()))])
}
fn integer(negative: bool, limbs: &[u32]) -> Val {
    Val::Record(vec![("negative".into(), Val::Bool(negative)), ("magnitude".into(), natural(limbs))])
}
fn main() -> Result<()> {
    let directory = std::env::args().nth(1).expect("artifact directory");
    let directory = Path::new(&directory);
    let mut config = Config::new();
    config.wasm_gc(true).wasm_function_references(true).wasm_tail_call(true).wasm_component_model(true);
    let engine = Engine::new(&config)?;
    for suffix in [".wasm", ".roundtrip.wasm"] {
        let count: usize = std::fs::read_to_string(directory.join("observation-count.txt")).unwrap().trim().parse().unwrap();
        let module = wasmtime::Module::from_file(&engine, directory.join(format!("observations.core{suffix}")))?;
        let mut core_store = Store::new(&engine, ());
        let core = wasmtime::Instance::new(&mut core_store, &module, &[])?;
        for i in 0..count {
            let function = core.get_typed_func::<(), i32>(&mut core_store, &format!("wasmCheck{i}"))?;
            assert_eq!(function.call(&mut core_store, ())?, 1, "core observation {i}");
        }
        let component = Component::from_file(&engine, directory.join(format!("observations{suffix}")))?;
        let mut store = Store::new(&engine, ());
        let instance = Linker::new(&engine).instantiate(&mut store, &component)?;
        // Both core and component calls reuse one instance per artifact.
        for i in 0..count {
            invoke(&mut store, instance, &format!("wasm-check{i}"), &[], Val::Bool(true))?;
        }
        let component = Component::from_file(&engine, directory.join(format!("aggregate{suffix}")))?;
        let mut store = Store::new(&engine, ());
        let instance = Linker::new(&engine).instantiate(&mut store, &component)?;
        invoke(&mut store, instance, "echo-natural", &[natural(&[0, 0])], natural(&[]))?;
        invoke(&mut store, instance, "add-natural", &[natural(&[u32::MAX, u32::MAX]), natural(&[1])], natural(&[0, 0, 1]))?;
        invoke(&mut store, instance, "echo-integer", &[integer(true, &[0, 0])], integer(false, &[]))?;
        invoke(&mut store, instance, "show-integer", &[integer(true, &[1, 0, 1])], Val::String("-18446744073709551617".into()))?;
        let array = Val::List(vec![natural(&[]), natural(&[1, 0, 1])]);
        invoke(&mut store, instance, "echo-array", &[array.clone()], array)?;
        let packet = Val::Record(vec![
            ("count".into(), natural(&[42])),
            ("text".into(), Val::String("é🙂".into())),
            ("enabled".into(), Val::Bool(true))]);
        invoke(&mut store, instance, "echo-packet", &[packet.clone()], packet)?;
        let vacant = Val::Variant("vacant".into(), None);
        invoke(&mut store, instance, "echo-choice", &[vacant.clone()], vacant)?;
        let present = Val::Variant("present".into(), Some(Box::new(Val::Record(vec![("value".into(), natural(&[17]))]))));
        invoke(&mut store, instance, "echo-choice", &[present.clone()], present)?;
        invoke(&mut store, instance, "many", &vec![Val::Bool(true); 17], Val::Bool(true))?;
        let boxed = Val::Record(vec![("value".into(), Val::Bool(true))]);
        invoke(&mut store, instance, "echo-box", &[boxed.clone()], boxed)?;
        invoke(&mut store, instance, "echo-char", &[Val::Char('🙂')], Val::Char('🙂'))?;
        let consume = lookup(&mut store, instance, "consume");
        consume.call(&mut store, &[Val::String("discarded".into())], &mut [])?;
        consume.post_return(&mut store)?;
        let text = Val::String("é🙂".repeat(16384));
        for _ in 0..64 {
            invoke(&mut store, instance, "echo-text", &[text.clone()], text.clone())?;
        }
    }
    println!("PSCV0_WASM_COMPONENT_HOST: PASS shared observations, aggregates, normalization, indirect parameters, repeated calls and post-return");
    Ok(())
}
