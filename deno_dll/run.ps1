param(
    [switch]$bundle,
    [switch]$generateHeader,
    [switch]$runExample
)

$oldLocation = Get-Location
try {

    Set-Location $PSScriptRoot

    if($bundle) {
        deno bundle --unstable ./ts/demo.ts ./demo.js
    }

    if($generateHeader) {
        cbindgen --config cbindgen.toml --crate deno_dll --output deno_dll.h
    }

    if($runExample) {
        cargo run --example main
    }

} finally {
    Set-Location $oldLocation
}
