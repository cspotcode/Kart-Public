use deno_core::futures::FutureExt;
use deno_dll::{create_task_waker_context, denodll_call_js_number, denodll_create_deno, denodll_poll_event_loop, denodll_run_event_loop};
use futures_task::waker_ref;
use std::{fmt::Debug, future::Future, sync::Arc, task::Context, time::Duration};
use rusty_v8 as v8;

fn main() {
    let mut deno_runtime = denodll_create_deno();

    let response = denodll_call_js_number(&mut deno_runtime);
    println!("Value returned by JavaScript: {}", response);

    // println!("from rust before poll 1");
    // denodll_poll_event_loop(&mut deno_runtime);
    // println!("from rust before poll 2");
    // denodll_poll_event_loop(&mut deno_runtime);
    // println!("sleeping 4 seconds");
    // std::thread::sleep(Duration::new(4, 0));
    // println!("from rust before poll 4");
    // Need to re-enter tokio and hold onto the `guard` while we run code.
    // For some reason this is necessary after `sleep()`
    // let guard = deno_runtime.tokio_runtime.enter();
    // denodll_poll_event_loop(&mut deno_runtime);
    // println!("from rust end");
}
