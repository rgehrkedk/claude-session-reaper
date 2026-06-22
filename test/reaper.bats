#!/usr/bin/env bats
# Tests for claude-reaper's pure functions. Run: bats test/
# (brew install bats-core  /  apt install bats)

setup() {
    # Source the script without running main().
    SCRIPT="${BATS_TEST_DIRNAME}/../claude-reaper"
    # shellcheck disable=SC1090
    source "$SCRIPT"
}

@test "etime_to_sec: mm:ss" {
    [ "$(etime_to_sec '05:30')" -eq 330 ]
}

@test "etime_to_sec: hh:mm:ss" {
    [ "$(etime_to_sec '01:02:03')" -eq 3723 ]
}

@test "etime_to_sec: dd-hh:mm:ss" {
    [ "$(etime_to_sec '2-01:00:00')" -eq 176400 ]
}

@test "etime_to_sec: leading-zero fields are not octal" {
    [ "$(etime_to_sec '08:09')" -eq 489 ]
}

@test "rss_to_kb: gigabytes" {
    [ "$(rss_to_kb '4G')" -eq 4194304 ]
}

@test "rss_to_kb: megabytes" {
    [ "$(rss_to_kb '512M')" -eq 524288 ]
}

@test "rss_to_kb: lowercase suffix" {
    [ "$(rss_to_kb '2g')" -eq 2097152 ]
}

@test "rss_to_kb: plain number is KB" {
    [ "$(rss_to_kb '1024')" -eq 1024 ]
}

@test "human_idle formats hours and minutes" {
    [ "$(human_idle 8000)" = "2h13m" ]
}

@test "extract_sid: uuid" {
    SESSION_ID_PATTERNS=both
    run extract_sid "claude --session-id 12345678-90ab-cdef-1234-567890abcdef --print"
    [ "$output" = "12345678-90ab-cdef-1234-567890abcdef" ]
}

@test "extract_sid: cse remote-control id" {
    SESSION_ID_PATTERNS=both
    run extract_sid "claude remote-control cse_AbC123xyz"
    [ "$output" = "cse_AbC123xyz" ]
}

@test "extract_sid: uuid pattern ignores cse when uuid-only" {
    SESSION_ID_PATTERNS=uuid
    run extract_sid "claude remote-control cse_AbC123xyz"
    [ -z "$output" ]
}

@test "iso_to_epoch round-trips a known UTC timestamp" {
    # 2026-01-02T03:04:05Z == 1767322Z... compute via the same date binary.
    if date --version >/dev/null 2>&1; then
        expected=$(date -u -d '2026-01-02T03:04:05Z' +%s)
    else
        expected=$(date -j -u -f '%Y-%m-%dT%H:%M:%S' '2026-01-02T03:04:05' +%s)
    fi
    [ "$(iso_to_epoch '2026-01-02T03:04:05')" -eq "$expected" ]
}
