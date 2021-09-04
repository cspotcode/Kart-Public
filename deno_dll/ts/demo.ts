export {};

// Give Rust code a way to call us
declare module globalThis {
  export let rust_to_js: () => number;
}
globalThis.rust_to_js = function(...args) {
  console.log('This is JavaScript code invoked by denodll_call_js_*');
  console.log(`Received ${args.length} function arguments.`);
  for(let i = 0; i < args.length; i++) {
    console.log(`Argument #${i}: ${args[i]}`);
  }
  console.log(`Returning the number 2 to test if C can receive it.`);
  return 2;
}
