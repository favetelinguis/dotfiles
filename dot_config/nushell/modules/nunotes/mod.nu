export def repo-dir [] {
  $nu.data-dir | path join "nunotes"
}

def ensure-repo [] {
  let repo = (repo-dir)

  if not ($repo | path exists) {
    mkdir $repo
  }

  if not ($repo | path type | str ends-with "dir") {
    error make {
      msg: $"Notes repo path is not a directory: ($repo)"
    }
  }

  let git_dir = ($repo | path join ".git")
  if not ($git_dir | path exists) {
    let init = (^git -C $repo init | complete)
    if $init.exit_code != 0 {
      error make {
        msg: $"git init failed for ($repo)"
        help: ($init.stderr | str trim)
      }
    }

    let todo = ($repo | path join "TODO.md")
    if not ($todo | path exists) {
      "" | save --raw $todo
    }

    let add = (^git -C $repo add -- TODO.md | complete)
    if $add.exit_code != 0 {
      error make {
        msg: $"git add failed for initial TODO.md in ($repo)"
        help: ($add.stderr | str trim)
      }
    }

    let commit = (^git -C $repo commit -m "Add TODO.md" -- TODO.md | complete)
    if $commit.exit_code != 0 {
      error make {
        msg: $"git commit failed for initial TODO.md in ($repo)"
        help: ($commit.stderr | str trim)
      }
    }
  }

  $repo
}

def repo-changes [repo: path] {
  let status = (^git -C $repo status --porcelain | complete)

  if $status.exit_code != 0 {
    error make {
      msg: $"git status failed for ($repo)"
      help: ($status.stderr | str trim)
    }
  }

  $status.stdout | str trim
}

export def notes-edit [
  ...hx_args: string
] {
  let repo = (ensure-repo)

  do {
    cd $repo

    if ($hx_args | is-empty) {
      ^helix TODO.md
    } else {
      ^helix ...$hx_args
    }
  }

  let changed = (repo-changes $repo)
  if $changed == "" {
    return
  }

  let add = (^git -C $repo add -A | complete)
  if $add.exit_code != 0 {
    error make {
      msg: $"git add failed for ($repo)"
      help: ($add.stderr | str trim)
    }
  }

  let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
  let commit = (^git -C $repo commit -m $"notes: update ($timestamp)" | complete)

  if $commit.exit_code != 0 {
    error make {
      msg: $"git commit failed for ($repo)"
      help: ($commit.stderr | str trim)
    }
  }
}
