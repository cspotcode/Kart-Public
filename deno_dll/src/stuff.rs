use deno_core::{FsModuleLoader, error::AnyError};
use deno_runtime::{deno_broadcast_channel::InMemoryBroadcastChannel, deno_web::BlobStore, permissions::Permissions, worker::{MainWorker, WorkerOptions}};
use std::{path::Path, rc::Rc, sync::Arc};

#[no_mangle]
pub extern fn print_hello_from_rust() {
    println!("Hello from Rust");
}

#[no_mangle]
pub extern fn denodll_launch_deno() {
    // See https://tokio.rs/tokio/topics/bridging
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            do_deno().await
        });
}

fn get_error_class_name(e: &AnyError) -> &'static str {
    deno_runtime::errors::get_error_class_name(e).unwrap_or("Error")
}

// copied from https://github.com/denoland/deno/blob/ddbb7b83f2c483e354f425dfb70dbab494b05ea5/runtime/examples/hello_runtime.rs
async fn do_deno() -> Result<(), AnyError> {
    print_hello_from_rust();

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

    // let js_path =
    //     Path::new(env!("CARGO_MANIFEST_DIR")).join("examples/hello_runtime.js");
    let js_path =
        Path::new(env!("CARGO_MANIFEST_DIR")).join("demo.js");
    let main_module = deno_core::resolve_path(&js_path.to_string_lossy())?;
    let permissions = Permissions::allow_all();

    let mut worker =
        MainWorker::from_options(main_module.clone(), permissions, &options);
    worker.bootstrap(&options);
    worker.execute_module(&main_module).await?;
    worker.run_event_loop(false).await?;
    Ok(())
}