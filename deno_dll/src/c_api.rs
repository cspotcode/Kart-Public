use deno_core::{FsModuleLoader, error::AnyError, futures::task::{ArcWake, WakerRef, waker_ref}};
use deno_runtime::{deno_broadcast_channel::InMemoryBroadcastChannel, deno_web::BlobStore, permissions::Permissions, worker::{MainWorker, WorkerOptions}};
use std::{borrow::Borrow, env::current_dir, future::Future, path::Path, rc::Rc, sync::Arc, time::Duration};
use std::task::{Context};
use tokio::{runtime::Runtime, time::sleep};
use owning_ref::{ArcRef, BoxRef, OwningHandle, OwningRef, RcRef};
use std::ffi::CStr;
use std::os::raw::c_char;
use crate::{core::{Task, call_js, create_deno}, create_task_waker_context};
use rusty_v8 as v8;

/// Our wrapper containing everything needed to run JavaScript in Deno.
/// C code should keep a pointer to this and pass it into most functions in
/// the API.
#[repr(C)]
pub struct DenoRuntime {
    pub deno_main_worker: MainWorker,
    pub tokio_runtime: Runtime,
    cx: OwningHandle<
        OwningHandle<
            Box<Arc<Task>>,
            Box<WakerRef<'static>>
        >,
        Box<Context<'static>>
    >,
    // rust_to_js_function: v8::Local<'a, v8::Function>
}

#[no_mangle]
pub extern fn example_accepting_c_string(ptr: *const c_char) {
    let cstr = unsafe { CStr::from_ptr(ptr) };
    let string = cstr.to_str().unwrap();
}

#[no_mangle]
pub extern fn print_hello_from_rust() {
    println!("Hello from Rust");
}

/// Create an initialized deno runtime stored on the heap.
/// Ownership is transferred to the caller.
#[no_mangle]
pub extern fn denodll_create_deno() -> Box<DenoRuntime> {
    // Create a tokio runtime, used to block the thread and run async operations.
    // See https://tokio.rs/tokio/topics/bridging
    let tokio_runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap();
    
    // Create and initialize a deno_runtime main_worker
    let mut deno_main_worker = tokio_runtime
        .block_on(async {
            let deno = create_deno().await.unwrap();
            deno
        });

    // Save a reference to a function we expect to be set by JS that we will call from Rust.
    {
        let global_context = deno_main_worker.js_runtime.global_context(); // is cloneable
        let global_context2 = global_context.clone();
        let v8_isolate = deno_main_worker.js_runtime.v8_isolate();
        let context = global_context2.get(v8_isolate);
        let scope = &mut deno_main_worker.js_runtime.handle_scope();
        let global = context.global(scope);

        let rust_to_js_key = v8::String::new(scope, "rust_to_js").unwrap();
        let rust_to_js_value = global.get(scope, rust_to_js_key.into()).unwrap();
        if !rust_to_js_value.is_function() {
            panic!("rust_to_js is not a function.  Maybe JS bootstrapper made a mistake.");
        }
        let rust_to_js_function = unsafe { v8::Local::<v8::Function>::cast(rust_to_js_value) };

        // Try invoking the function to test that it works
        let local_to_global = v8::Local::new(scope, global);
        let response = rust_to_js_function.call(scope, local_to_global.into(), &[]).unwrap();
        let response_as_number = response.to_number(scope).unwrap().int32_value(scope).unwrap();
        println!("return value: {}", response_as_number);
    }

    let cx = create_task_waker_context();

    Box::new(DenoRuntime { tokio_runtime, deno_main_worker, cx })
}

#[no_mangle]
pub extern fn denodll_poll_event_loop(deno_runtime: &mut DenoRuntime) {
    deno_runtime.deno_main_worker.poll_event_loop(&mut deno_runtime.cx, false);
}

#[no_mangle]
pub extern fn denodll_start_event_loop(deno_runtime: &mut DenoRuntime) {
    panic!("Not implemented yet");
}

#[no_mangle]
pub extern fn denodll_stop_event_loop(deno_runtime: &mut DenoRuntime) {
    panic!("Not implemented yet");
}

// Naming convention for these:
// denodll_call_js_<return type>_<first argument type>_<second_argument type>_...
// If you want to make this JS invocation:
//     const expecting_a_number = globalThis.rust_to_js('foo', 123);
// Then you make this call from C:
//     f64 float = denodll_call_js_number_string_number(deno_runtime_ptr, "foo", 123);
    

#[no_mangle]
pub extern fn denodll_call_js_string(deno_runtime: &mut DenoRuntime) -> String {
    let (mut scope, result) = call_js(deno_runtime, &[]);
    let result_string = result.to_string(&mut scope).unwrap();
    let rust_string = result_string.to_rust_string_lossy(&mut scope);
    rust_string
}

#[no_mangle]
pub extern fn denodll_call_js_number(deno_runtime: &mut DenoRuntime) -> f64 {
    let (mut scope, result) = call_js(deno_runtime, &[]);
    let result_number = result.to_number(&mut scope).unwrap();
    let rust_f64= result_number.value();
    rust_f64
}
