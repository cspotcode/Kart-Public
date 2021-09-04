use deno_core::{FsModuleLoader, error::AnyError, futures::task::{ArcWake, WakerRef, waker_ref}};
use deno_runtime::{deno_broadcast_channel::InMemoryBroadcastChannel, deno_web::BlobStore, permissions::Permissions, worker::{MainWorker, WorkerOptions}};
use std::{borrow::Borrow, env::current_dir, future::Future, path::Path, rc::Rc, sync::Arc, time::Duration};
use std::task::{Context};
use tokio::{runtime::Runtime, time::sleep};
use owning_ref::{ArcRef, BoxRef, OwningHandle, OwningRef, RcRef};
use rusty_v8 as v8;
use std::ffi::CStr;
use std::os::raw::c_char;

use crate::c_api::DenoRuntime;

fn get_error_class_name(e: &AnyError) -> &'static str {
    deno_runtime::errors::get_error_class_name(e).unwrap_or("Error")
}

// copied from https://github.com/denoland/deno/blob/ddbb7b83f2c483e354f425dfb70dbab494b05ea5/runtime/examples/hello_runtime.rs
pub async fn create_deno() -> Result<MainWorker, AnyError> {
    let module_loader = Rc::new(FsModuleLoader);
    let create_web_worker_cb = Arc::new(|_| {
        todo!("Web workers are not supported in the example");
    });

    let options = WorkerOptions {
        apply_source_maps: false,
        args: vec![],
        debug_flag: false,
        unstable: false,
        enable_testing_features: false,
        unsafely_ignore_certificate_errors: None,
        root_cert_store: None,
        user_agent: "hello_runtime".to_string(),
        seed: None,
        js_error_create_fn: None,
        create_web_worker_cb,
        maybe_inspector_server: None,
        should_break_on_first_statement: false,
        module_loader,
        runtime_version: "x".to_string(),
        ts_version: "x".to_string(),
        no_color: false,
        get_error_class_fn: Some(&get_error_class_name),
        location: None,
        origin_storage_dir: None,
        blob_store: BlobStore::default(),
        broadcast_channel: InMemoryBroadcastChannel::default(),
        shared_array_buffer_store: None,
        cpu_count: 1,
    };

    let js_path = current_dir()?.join("demo.js");
    let main_module = deno_core::resolve_path(&js_path.to_string_lossy())?;
    let permissions = Permissions::allow_all();

    let mut worker =
        MainWorker::from_options(main_module.clone(), permissions, &options);
    worker.bootstrap(&options);
    worker.execute_module(&main_module).await?;
    Ok(worker)
}

pub async fn denodll_run_event_loop(worker: &mut MainWorker) -> Result<(), AnyError> {
    worker.run_event_loop(false).await?;
    Ok(())
}

pub fn create_task_waker_context() -> OwningHandle<
    OwningHandle<
        Box<Arc<Task>>,
        Box<WakerRef<'static>>
    >,
    Box<Context<'static>>
> {
    let task_arc = Box::new(Arc::new(Task {}));
    let waker: OwningHandle<Box<Arc<Task>>, Box<WakerRef>> = OwningHandle::new_with_fn(task_arc, {
        |v| Box::new(waker_ref(unsafe {&*v}))
    });
    let cx = OwningHandle::new_with_fn(waker, |v| Box::new(
        Context::from_waker(
            unsafe {(*v).borrow()}
        )
    ));
    cx
}

pub struct Task {}
impl ArcWake for Task {
    fn wake_by_ref(arc_self: &Arc<Self>) {}
}

pub fn call_js<'a>(deno_runtime: &'a mut DenoRuntime, args: &[v8::Local<v8::Value>]) -> (v8::HandleScope<'a>, v8::Local<'a, v8::Value>) {
    let deno_main_worker = &mut deno_runtime.deno_main_worker;
    let global_context = deno_main_worker.js_runtime.global_context(); // is cloneable
    let global_context2 = global_context.clone();
    let v8_isolate = deno_main_worker.js_runtime.v8_isolate();
    let context = global_context2.get(v8_isolate);
    let mut scope = deno_main_worker.js_runtime.handle_scope();
    let scope_ref = &mut scope;
    let global = context.global(scope_ref);

    let rust_to_js_key = v8::String::new(scope_ref, "rust_to_js").unwrap();
    let rust_to_js_value = global.get(scope_ref, rust_to_js_key.into()).unwrap();
    if !rust_to_js_value.is_function() {
        panic!("rust_to_js is not a function.  Maybe JS bootstrapper made a mistake.");
    }
    let rust_to_js_function = unsafe { v8::Local::<v8::Function>::cast(rust_to_js_value) };

    // Try invoking the function to test that it works
    let local_to_global = v8::Local::new(scope_ref, global);
    let response = rust_to_js_function.call(scope_ref, local_to_global.into(), args).unwrap();
    (scope, response)
}
