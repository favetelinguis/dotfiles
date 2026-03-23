
# task.kak
#
# Discover and run executable task scripts from ~/.local/bin.
#
# Naming:
# - Tasks: ~/.local/bin/kak-task--<task-name>
#
# Discovery:
# - The picker rescans ~/.local/bin every time it opens.
#
# Metadata:
# - The plugin reads the first 40 lines of each script.
# - Metadata lives in shell comments so the script still runs normally.
# - Supported headers:
#   # kak-task-title: Human readable title
#   # kak-task-desc: One-line description shown in menus
#   # kak-task-group: Logical group label
#   # kak-task-sudo: no|yes
#   # kak-task-cwd: repo|cwd|subdir:<path>|<absolute-path>
#   # kak-task-mode: fifo|terminal
#   # kak-task-error-pattern: <regex>
#
# Metadata defaults:
# - title: task name from the filename, with '-' and '_' turned into spaces
# - group: misc
# - sudo: no
# - cwd: cwd
# - mode: fifo, unless kak-task-sudo is yes, which forces terminal mode
# - error-pattern: Kakoune's current make_error_pattern
#
# Execution behavior:
# - fifo mode runs the task in a Kakoune fifo buffer and sets filetype=make so
#   enter, next-error, and previous-error work on compiler-style output.
# - terminal mode opens a tmux split and runs the task interactively.
# - kak-task-sudo: yes does not rewrite your script. It warms sudo credentials
#   with sudo -v in the terminal pane before running the script normally, so
#   scripts that call sudo internally work without repeated prompts.
#
# Working directory:
# - repo: run from the git root of the current buffer's context; fails if no
#   repo is active
# - cwd: run from the current client working directory
# - subdir:<path>: relative to the git root if inside a repo, otherwise
#   relative to the client cwd
# - <absolute-path>: always run from the given fixed directory (e.g. /srv/app)
#
# Environment exported to the task script:
# - KAK_TASK_NAME
# - KAK_TASK_REPO_ROOT
# - KAK_TASK_REPO_SLUG
# - KAK_TASK_FILE
#
# Usage:
# - <space> t enters task user mode
# - In task mode:
#   - t opens the task picker
#   - r reruns the last task
#   - o opens the last fifo output buffer
#   - n jumps to the next error in the last fifo output buffer
#   - p jumps to the previous error in the last fifo output buffer
#   - x cancels the running fifo task
#   - f lists all running fifo tasks and switches to the selected output buffer
#
# Examples:
# - Task running from current directory:
#   #!/bin/sh
#   # kak-task-title: Sync dotfiles
#   # kak-task-desc: Run chezmoi apply from the current shell context
#   exec chezmoi apply
#
#   Save as ~/.local/bin/kak-task--sync-dotfiles
#
# - Task running from git root:
#   #!/bin/sh
#   # kak-task-title: Test
#   # kak-task-group: ci
#   # kak-task-cwd: repo
#   exec cargo test
#
#   Save as ~/.local/bin/kak-task--test
#
# - Task running from a fixed directory:
#   #!/bin/sh
#   # kak-task-title: Deploy
#   # kak-task-cwd: /srv/myapp
#   exec ./deploy.sh
#
#   Save as ~/.local/bin/kak-task--deploy
#
# - Sudo task:
#   #!/bin/sh
#   # kak-task-title: Install
#   # kak-task-sudo: yes
#   # kak-task-mode: terminal
#   exec ./scripts/install.sh
#
# Public commands:
# - :task-menu
# - :task-run <script-basename> [<context-path>]
# - :task-rerun
# - :task-open-last-output
# - :task-next-error
# - :task-previous-error
# - :task-cancel
# - :task-find
#
# Helper resolution:
# - This plugin runs ~/.local/bin/kak-task-list and ~/.local/bin/kak-task-run
#   by absolute path. They do not need to be present in PATH.

hook -once global KakBegin .* %{
    require-module fifo
    require-module jump
    require-module make
    require-module menu
}

try %{ declare-option -hidden str task_last_script '' }
try %{ declare-option -hidden str task_last_context '' }
try %{ declare-option -hidden str task_last_output_buffer '' }
try %{ declare-option -hidden str task_last_title '' }
try %{ declare-option -hidden str task_last_pid_file '' }

define-command -hidden task-set-last -params 3 %{
    set-option global task_last_script %arg{1}
    set-option global task_last_context %arg{2}
    set-option global task_last_title %arg{3}
}

define-command \
    -docstring 'open the shell task picker from ~/.local/bin' \
    task-menu %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        task_list=${HOME%/}/.local/bin/kak-task-list

        context=$kak_buffile
        [ -n "$context" ] || context=${kak_client_env_PWD:-$PWD}

        [ -x "$task_list" ] || {
            printf "fail %s\n" "$(kakquote "task helper not found: $task_list")"
            exit
        }

        catalog=$("$task_list" "$context")
        [ -n "$catalog" ] || {
            printf "fail %s\n" "$(kakquote "no tasks found in ~/.local/bin for the current context")"
            exit
        }

        if [ -n "$TMUX" ] && command -v fzf >/dev/null 2>&1; then
            session=$kak_session
            client=$kak_client
            kak_bin=$(command -v kak 2>/dev/null) || {
                printf "fail %s\n" "$(kakquote "kak executable not found in PATH")"
                exit
            }
            tmp=$(mktemp "${TMPDIR:-/tmp}/kak-task-menu.XXXXXX") || {
                printf "fail %s\n" "$(kakquote "unable to create a temporary picker script")"
                exit
            }

            session_q=$(printf '%s' "$session" | sed "s/'/'\\\\''/g")
            client_q=$(printf '%s' "$client" | sed "s/'/'\\\\''/g")
            kak_bin_q=$(printf '%s' "$kak_bin" | sed "s/'/'\\\\''/g")
            context_q=$(printf '%s' "$context" | sed "s/'/'\\\\''/g")

            cat >"$tmp" << SHELL
#!/bin/sh
SESSION='$session_q'
CLIENT='$client_q'
KAK_BIN='$kak_bin_q'
CONTEXT='$context_q'
SELF='$tmp'
TASK_LIST='${HOME%/}/.local/bin/kak-task-list'
TAB=\$(printf '\t')

list=\$("\$TASK_LIST" "\$CONTEXT")
[ -n "\$list" ] || {
    rm -f "\$SELF"
    exit 0
}

choice=\$(printf '%s\n' "\$list" | awk -F '\t' '
{
    desc = \$5
    if (desc == "") {
        desc = "-"
    }
    printf "%s\t[%s] %s\t%s\n", \$1, \$4, \$3, desc
}' | fzf --delimiter="\$TAB" --with-nth=2.. --reverse --border --prompt='task> ' --exit-0)
[ -n "\$choice" ] || {
    rm -f "\$SELF"
    exit 0
}

script=\$(printf '%s' "\$choice" | cut -f1)
script_q=\$(printf '%s' "\$script" | sed "s/'/''/g")
context_cmd=\$(printf '%s' "\$CONTEXT" | sed "s/'/''/g")
printf "evaluate-commands -client '%s' 'task-run ''%s'' ''%s'''\n" \
    "\$CLIENT" "\$script_q" "\$context_cmd" | "\$KAK_BIN" -p "\$SESSION"
rm -f "\$SELF"
SHELL

            chmod +x "$tmp"
            printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
            exit
        fi

        menu_cmd="menu"
        tab=$(printf '\t')
        while IFS="$tab" read -r base task_name title group desc mode sudo cwd error_pattern; do
            display="[$group] $title"
            if [ -n "$desc" ]; then
                display="$display - $desc"
            fi
            menu_cmd="$menu_cmd $(kakquote "$display") $(kakquote "task-run '$base' '$context'")"
        done << EOF
$catalog
EOF
        printf '%s\n' "$menu_cmd"
    }
}

define-command \
    -params 1..2 \
    -docstring 'run a discovered shell task from ~/.local/bin' \
    task-run %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        shellquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
        task_list=${HOME%/}/.local/bin/kak-task-list
        task_run=${HOME%/}/.local/bin/kak-task-run

        script=$1
        context=$2

        [ -n "$script" ] || {
            printf "fail %s\n" "$(kakquote "task-run requires a task basename")"
            exit
        }
        [ -n "$context" ] || context=$kak_buffile
        [ -n "$context" ] || context=${kak_client_env_PWD:-$PWD}

        [ -x "$task_list" ] || {
            printf "fail %s\n" "$(kakquote "task helper not found: $task_list")"
            exit
        }
        [ -x "$task_run" ] || {
            printf "fail %s\n" "$(kakquote "task helper not found: $task_run")"
            exit
        }

        row=$("$task_list" "$context" | awk -F '\t' -v script="$script" '$1 == script { print; exit }')
        [ -n "$row" ] || {
            printf "fail %s\n" "$(kakquote "task $script is not available for the current context")"
            exit
        }

        tab=$(printf '\t')
        IFS="$tab" read -r base task_name title group desc mode sudo cwd error_pattern << EOF
$row
EOF

        context_dir=$context
        [ -d "$context_dir" ] || context_dir=$(dirname "$context")
        repo_root=$(git -C "$context_dir" rev-parse --show-toplevel 2>/dev/null || true)
        if [ -n "$repo_root" ]; then
            context_name=$(basename "$repo_root")
        else
            context_name=$(basename "$context_dir")
        fi

        buffer_name="*task:$base:$context_name*"
        printf "task-set-last %s %s %s\n" \
            "$(kakquote "$base")" "$(kakquote "$context")" "$(kakquote "$title")"

        if [ "$mode" = terminal ] || [ "$sudo" = yes ]; then
            [ -n "$TMUX" ] || {
                printf "fail %s\n" "$(kakquote "terminal tasks require Kakoune to run inside tmux")"
                exit
            }

            tmp=$(mktemp "${TMPDIR:-/tmp}/kak-task-terminal.XXXXXX") || {
                printf "fail %s\n" "$(kakquote "unable to create a temporary terminal script")"
                exit
            }
            title_q=$(printf '%s' "$title" | sed "s/'/'\\\\''/g")
            base_q=$(printf '%s' "$base" | sed "s/'/'\\\\''/g")
            context_q=$(printf '%s' "$context" | sed "s/'/'\\\\''/g")
            sudo_q=$(printf '%s' "$sudo" | sed "s/'/'\\\\''/g")

            cat >"$tmp" << SHELL
#!/bin/sh
TITLE='$title_q'
SCRIPT='$base_q'
CONTEXT='$context_q'
NEED_SUDO='$sudo_q'
SELF='$tmp'
TASK_RUN='${HOME%/}/.local/bin/kak-task-run'

printf '==> %s\n\n' "\$TITLE"
if [ "\$NEED_SUDO" = yes ]; then
    if ! sudo -n true >/dev/null 2>&1; then
        printf 'Acquiring sudo credentials for %s...\n' "\$TITLE"
        sudo -v || exit \$?
        printf '\n'
    fi
fi

"\$TASK_RUN" "\$SCRIPT" "\$CONTEXT"
status=\$?
printf '\n[%s] exit %s\n' "\$TITLE" "\$status"
printf 'Press enter to close...'
IFS= read -r _
rm -f "\$SELF"
exit "\$status"
SHELL

            chmod +x "$tmp"
            printf "set-option global task_last_output_buffer %s\n" "$(kakquote "")"
            printf "set-option global task_last_pid_file %s\n" "$(kakquote "")"
            printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
            exit
        fi

        piddir="${TMPDIR:-/tmp}/kak-task-pids"
        mkdir -p "$piddir"
        file_key="${base}@${context_name}"
        pidfile="$piddir/$file_key"
        logfile="$piddir/$file_key.log"

        existing_pid=$(cat "$pidfile" 2>/dev/null)
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            printf "fail %s\n" "$(kakquote "task '$title' is already running in $context_name")"
            exit
        fi

        touch "$logfile"
        ( exec "$task_run" "$base" "$context" > "$logfile" 2>&1 < /dev/null ) &
        printf '%s\n' "$!" > "$pidfile"
        printf '%s\t%s\t%s\t%s\n' "$title" "$buffer_name" "$logfile" "$context_name" > "$piddir/$file_key.meta"

        printf "set-option global task_last_output_buffer %s\n" "$(kakquote "$buffer_name")"
        printf "set-option global task_last_pid_file %s\n" "$(kakquote "$pidfile")"
        printf "fifo -scroll -name %s -- tail -n +1 -f %s\n" "$(kakquote "$buffer_name")" "$(kakquote "$logfile")"
        printf "hook -always -once buffer BufCloseFifo .* %%{ nop %%sh{ pid=\$(cat %s 2>/dev/null); [ -n \"\$pid\" ] && kill -0 \"\$pid\" 2>/dev/null || rm -f %s %s %s }; set-option global task_last_pid_file '' }\n" "$(shellquote "$pidfile")" "$(shellquote "$pidfile")" "$(shellquote "$piddir/$file_key.meta")" "$(shellquote "$logfile")"
        printf "set-option buffer filetype make\n"
        printf "set-option buffer jump_current_line 0\n"
        if [ -n "$error_pattern" ]; then
            printf "set-option buffer make_error_pattern %s\n" "$(kakquote "$error_pattern")"
        fi
    }
}

define-command \
    -docstring 'rerun the last shell task' \
    task-rerun %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        script=$kak_opt_task_last_script
        context=$kak_opt_task_last_context

        [ -n "$script" ] || {
            printf "fail %s\n" "$(kakquote "no previous task has been run")"
            exit
        }

        printf "task-run %s %s\n" "$(kakquote "$script")" "$(kakquote "$context")"
    }
}

define-command \
    -docstring 'open the last fifo task output buffer' \
    task-open-last-output %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffer_name=$kak_opt_task_last_output_buffer
        [ -n "$buffer_name" ] || {
            printf "fail %s\n" "$(kakquote "the last task did not create an output buffer")"
            exit
        }
        printf "try %%{ buffer %s }\n" "$(kakquote "$buffer_name")"
    }
}

define-command \
    -docstring 'jump to the next error in the last fifo task output buffer' \
    task-next-error %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffer_name=$kak_opt_task_last_output_buffer
        [ -n "$buffer_name" ] || {
            printf "fail %s\n" "$(kakquote "the last task did not create an output buffer")"
            exit
        }

        printf "evaluate-commands -try-client %%opt{jumpclient} -save-regs / %%{\n"
        printf "buffer %s\n" "$(kakquote "$buffer_name")"
        printf "make-select-next\n"
        printf "make-jump\n"
        printf "}\n"
        printf "try %%{\n"
        printf "evaluate-commands -client %%opt{toolsclient} %%{\n"
        printf "buffer %s\n" "$(kakquote "$buffer_name")"
        printf "execute-keys gg %%opt{jump_current_line}g\n"
        printf "}\n"
        printf "}\n"
    }
}

define-command \
    -docstring 'jump to the previous error in the last fifo task output buffer' \
    task-previous-error %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffer_name=$kak_opt_task_last_output_buffer
        [ -n "$buffer_name" ] || {
            printf "fail %s\n" "$(kakquote "the last task did not create an output buffer")"
            exit
        }

        printf "evaluate-commands -try-client %%opt{jumpclient} -save-regs / %%{\n"
        printf "buffer %s\n" "$(kakquote "$buffer_name")"
        printf "make-select-previous\n"
        printf "make-jump\n"
        printf "}\n"
        printf "try %%{\n"
        printf "evaluate-commands -client %%opt{toolsclient} %%{\n"
        printf "buffer %s\n" "$(kakquote "$buffer_name")"
        printf "execute-keys gg %%opt{jump_current_line}g\n"
        printf "}\n"
        printf "}\n"
    }
}

define-command \
    -docstring 'cancel the running fifo task' \
    task-cancel %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        pidfile=$kak_opt_task_last_pid_file
        [ -n "$pidfile" ] && [ -f "$pidfile" ] || {
            printf "fail %s\n" "$(kakquote "no running task to cancel")"
            exit
        }

        pid=$(cat "$pidfile" 2>/dev/null)
        [ -n "$pid" ] || {
            printf "fail %s\n" "$(kakquote "pid file is empty")"
            exit
        }

        if kill -0 "$pid" 2>/dev/null; then
            pkill -TERM -P "$pid" 2>/dev/null
            kill -TERM "$pid" 2>/dev/null
            printf "echo -markup '{Information}{\\}task cancelled'\n"
        else
            printf "echo -markup '{Information}{\\}task is not running'\n"
        fi

        rm -f "$pidfile" "${pidfile}.meta" "${pidfile}.log"
        printf "set-option global task_last_pid_file ''\n"
    }
}

define-command \
    -docstring 'list running fifo tasks and switch to the selected output buffer' \
    task-find %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        piddir="${TMPDIR:-/tmp}/kak-task-pids"
        [ -d "$piddir" ] || {
            printf "fail %s\n" "$(kakquote "no task processes found")"
            exit
        }

        [ -n "$TMUX" ] && command -v fzf >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "task-find requires tmux and fzf")"
            exit
        }

        tab=$(printf '\t')
        list=""
        for metafile in "$piddir"/*.meta; do
            [ -f "$metafile" ] || continue
            pidfile="${metafile%.meta}"
            [ -f "$pidfile" ] || continue
            pid=$(cat "$pidfile" 2>/dev/null)
            if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
                rm -f "$pidfile" "$metafile"
                continue
            fi
            IFS="$tab" read -r title buffer_name logfile context_name < "$metafile"
            list="${list}${buffer_name}${tab}[${context_name}] ${title} (pid ${pid})${tab}${logfile}${tab}${pidfile}
"
        done

        [ -n "$list" ] || {
            printf "fail %s\n" "$(kakquote "no running tasks")"
            exit
        }

        session=$kak_session
        client=$kak_client
        kak_bin=$(command -v kak 2>/dev/null) || {
            printf "fail %s\n" "$(kakquote "kak executable not found in PATH")"
            exit
        }
        tmp=$(mktemp "${TMPDIR:-/tmp}/kak-task-find.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary picker script")"
            exit
        }

        session_q=$(printf '%s' "$session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$client" | sed "s/'/'\\\\''/g")
        kak_bin_q=$(printf '%s' "$kak_bin" | sed "s/'/'\\\\''/g")
        list_q=$(printf '%s' "$list" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
SESSION='$session_q'
CLIENT='$client_q'
KAK_BIN='$kak_bin_q'
SELF='$tmp'
TAB=\$(printf '\t')

choice=\$(printf '%s' '$list_q' | fzf --delimiter="\$TAB" --with-nth=2 --reverse --border --prompt='running tasks> ' --exit-0)
[ -n "\$choice" ] || { rm -f "\$SELF"; exit 0; }

buffer=\$(printf '%s' "\$choice" | cut -f1)
logfile=\$(printf '%s' "\$choice" | cut -f3)
pidfile=\$(printf '%s' "\$choice" | cut -f4)
buffer_q=\$(printf '%s' "\$buffer" | sed "s/'/''/g")
logfile_q=\$(printf '%s' "\$logfile" | sed "s/'/''/g")
pidfile_q=\$(printf '%s' "\$pidfile" | sed "s/'/''/g")
printf "evaluate-commands -client '%s' 'try %%{ buffer ''%s'' } catch %%{ fifo -scroll -name ''%s'' -- tail -n +1 -f ''%s''; set-option buffer filetype make; set-option buffer jump_current_line 0 }; set-option global task_last_pid_file ''%s''; set-option global task_last_output_buffer ''%s'''\n" \
    "\$CLIENT" "\$buffer_q" "\$buffer_q" "\$logfile_q" "\$pidfile_q" "\$buffer_q" | "\$KAK_BIN" -p "\$SESSION"
rm -f "\$SELF"
SHELL

        chmod +x "$tmp"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}
