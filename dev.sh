#!/bin/bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./dev.sh [run|ui|test|acceptance|fmt|fetch] [-- zig args]

Commands:
  run    Compile and run `zig build run`
  ui     Run the libvaxis event loop harness
  test   Execute all Zig tests
  acceptance Run TUI acceptance tests
  fmt    Format Zig sources via `zig fmt`
  fetch  Download Zig dependencies (libvaxis)

Any arguments after `--` are forwarded to `zig build run`.
EOF
}

zig_bin="${ZIG:-zig}"
zig_version="$("$zig_bin" version)"
case "$zig_version" in
    0.16.*) ;;
    *)
        echo "error: lazycurl requires Zig 0.16.x; found $zig_version via $zig_bin" >&2
        exit 1
        ;;
esac

cmd="${1:-run}"
if [ $# -gt 0 ]; then
    shift
fi
case "$cmd" in
    run)
        if [[ "${1:-}" == "--" ]]; then
            shift
        fi
        "$zig_bin" build run -- "$@"
        ;;
    ui)
        "$zig_bin" build run
        ;;
    test)
        "$zig_bin" build test
        ;;
    acceptance)
        "$zig_bin" build acceptance
        ;;
    fmt)
        "$zig_bin" build fmt
        ;;
    fetch)
        "$zig_bin" build --fetch
        ;;
    *)
        usage
        exit 1
        ;;
esac
