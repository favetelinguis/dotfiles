try %{ declare-option -hidden str utility_temp_return_buffer '' }
try %{ declare-option -hidden str utility_temp_return_cursor '' }

define-command -hidden utility-close-temp-buffer %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        return_buffer=$kak_opt_utility_temp_return_buffer
        return_cursor=$kak_opt_utility_temp_return_cursor
        current_buffer=$kak_bufname

        if [ -n "$return_buffer" ]; then
            printf "try %%{ buffer %s }\n" "$(kakquote "$return_buffer")"
            if [ -n "$return_cursor" ]; then
                printf "try %%{ select %s,%s }\n" "$return_cursor" "$return_cursor"
            fi
        fi

        printf "nop %%sh{ rm -f %s }\n" "$(kakquote "$current_buffer")"
        printf "delete-buffer! %s\n" "$(kakquote "$current_buffer")"
    }
}

define-command -hidden utility-jwt-decode %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        origin_buffer=$kak_bufname
        origin_cursor="${kak_cursor_line}.${kak_cursor_column}"
        selection=$kak_selection

        command -v python3 >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "python3 command not found in PATH")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/kak-jwt.XXXXXX.json") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary JWT buffer")"
            exit
        }
        err=$(mktemp "${TMPDIR:-/tmp}/kak-jwt.XXXXXX.err") || {
            rm -f "$tmp"
            printf "fail %s\n" "$(kakquote "unable to create a temporary JWT error file")"
            exit
        }

        if ! JWT_INPUT="$selection" python3 - >"$tmp" 2>"$err" <<'PY'
import base64
import json
import os
import re
import sys


def fail(message: str) -> None:
    raise SystemExit(message)


raw = os.environ.get("JWT_INPUT", "").strip()
if not raw:
    fail("no token text under the cursor")

pattern = re.compile(r"[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)?")
trimmed = raw.strip(" \t\r\n'\"`()[]{}<>,;")

if pattern.fullmatch(trimmed):
    token = trimmed
else:
    matches = pattern.findall(raw)
    if not matches:
        fail("no JWT token found under the cursor")
    if len(matches) > 1:
        fail("multiple JWT-like tokens found under the cursor")
    token = matches[0]

parts = token.split(".")
if len(parts) not in (2, 3):
    fail("JWT token must have 2 or 3 dot-separated segments")


def decode_segment(segment: str, label: str):
    padded = segment + ("=" * (-len(segment) % 4))
    try:
        decoded = base64.urlsafe_b64decode(padded.encode("ascii"))
    except Exception as exc:  # pragma: no cover
        fail(f"unable to decode JWT {label}: {exc}")

    text = decoded.decode("utf-8", errors="replace")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return text


result = {
    "header": decode_segment(parts[0], "header"),
    "payload": decode_segment(parts[1], "payload"),
}

if len(parts) == 3:
    result["signature"] = parts[2]

if token != raw:
    result["token"] = token

json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
sys.stdout.write("\n")
PY
        then
            message=$(tr '\n' ' ' < "$err")
            [ -n "$message" ] || message='unable to decode JWT token'
            rm -f "$tmp" "$err"
            printf "fail %s\n" "$(kakquote "$message")"
            exit
        fi

        rm -f "$err"

        printf "edit -existing %s\n" "$(kakquote "$tmp")"
        printf "set-option buffer filetype json\n"
        printf "set-option buffer readonly true\n"
        printf "set-option buffer utility_temp_return_buffer %s\n" "$(kakquote "$origin_buffer")"
        printf "set-option buffer utility_temp_return_cursor %s\n" "$(kakquote "$origin_cursor")"
        printf "map buffer normal q ':utility-close-temp-buffer<ret>' -docstring %s\n" \
            "$(kakquote "close decoded JWT buffer")"
    }
}

define-command \
    -docstring 'decode the JWT token under the cursor into a formatted JSON buffer' \
    utility-jwt-decode-cursor %{
    execute-keys <a-i>W
    utility-jwt-decode
}
