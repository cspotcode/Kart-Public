mod c_api;
mod core;

// This file exposes our library API.
// The `c_api` bits are compatible with C
// The `core` bits are only compatible with rust, but we use them from our `./examples`

pub use c_api::{
    denodll_create_deno,
    denodll_poll_event_loop,
    example_accepting_c_string,
    print_hello_from_rust,
    denodll_start_event_loop,
    denodll_stop_event_loop,
    denodll_call_js_number,
    denodll_call_js_string,
};

pub use self::core::{
    denodll_run_event_loop,
    create_task_waker_context
};