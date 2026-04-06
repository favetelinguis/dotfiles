# numoi
#
# Manual live-file snapshotting for dotfiles.
# The tracked live files are canonical. `numoi sync` copies them into a
# central store under `~/.local/share/nushell/numoi`.

def numoi-home [] {
  (
    $env
    | get -o NUMOI_HOME
    | default "~/.local/share/nushell/numoi"
    | path expand
  )
}

export def paths [] {
  let base = (numoi-home)

  {
    base: $base
    manifest: ($base | path join manifest.nuon)
    state: ($base | path join state.nuon)
    store: ($base | path join store)
  }
}

def ensure-layout [] {
  let p = (paths)

  if not ($p.base | path exists) {
    mkdir $p.base
  }

  if not ($p.store | path exists) {
    mkdir $p.store
  }

  if not ($p.manifest | path exists) {
    [] | to nuon --indent 2 | save -f $p.manifest
  }

  if not ($p.state | path exists) {
    [] | to nuon --indent 2 | save -f $p.state
  }

  $p
}

def normalize-target [target: path] {
  $target | path expand
}

def store-relative-path [target: path] {
  normalize-target $target | str replace -r '^/' ''
}

def store-path [target: path] {
  let p = (paths)
  $p.store | path join (store-relative-path $target)
}

def load-list [file: path] {
  if ($file | path exists) {
    open $file
  } else {
    []
  }
}

def save-list [file: path, rows: list] {
  $rows | to nuon --indent 2 | save -f $file
}

def require-file-kind [target: path] {
  if not ($target | path exists) {
    return "file"
  }

  let kind = ($target | path type)
  if $kind != "file" {
    error make {
      msg: $"numoi currently supports only files, not ($kind): ($target)"
    }
  }

  $kind
}

def manifest-record [target: path] {
  let normalized = (normalize-target $target)

  {
    target: $normalized
    kind: (require-file-kind $normalized)
  }
}

def get-manifest-record [target: path] {
  let normalized = (normalize-target $target)
  let matches = (manifest | where target == $normalized)

  if ($matches | is-empty) {
    error make {
      msg: $"target is not tracked: ($normalized)"
    }
  }

  $matches | first
}

def record-state [rows: list] {
  let p = (ensure-layout)
  let stamped = (
    $rows
    | each {|row|
      $row | upsert observed_at (date now)
    }
  )

  save-list $p.state $stamped
  $stamped
}

def classify-record [entry: record] {
  let target = $entry.target
  let store = (store-path $target)
  let target_exists = ($target | path exists)
  let store_exists = ($store | path exists)

  let status = if not $target_exists and not $store_exists {
    "missing"
  } else if not $target_exists {
    "target-missing"
  } else if not $store_exists {
    "new"
  } else if (file-differ $store $target) {
    "changed"
  } else {
    "clean"
  }

  {
    target: $target
    store: $store
    kind: $entry.kind
    target_exists: $target_exists
    store_exists: $store_exists
    status: $status
  }
}

def sync-record [row: record] {
  if not $row.target_exists {
    return ($row | upsert action "skipped")
  }

  if $row.status == "clean" {
    return ($row | upsert action "unchanged")
  }

  let parent = ($row.store | path dirname)
  if not ($parent | path exists) {
    mkdir $parent
  }

  cp -f $row.target $row.store

  $row | upsert action (
    if $row.status == "new" {
      "copied"
    } else {
      "updated"
    }
  )
}

export def roadmap [] {
  [
    {
      phase: "1-foundation"
      goal: "Manual live-to-store snapshots"
      commands: ["init" "track" "untrack" "manifest" "status" "sync" "diff" "edit"]
      notes: [
        "Tracked live files are canonical."
        "Store mirrored files under ~/.local/share/nushell/numoi/store."
        "Persist manifest.nuon and state.nuon."
      ]
    }
    {
      phase: "2-git-journal"
      goal: "Optional Git integration around the store"
      commands: ["git-status" "git-add" "git-commit" "sync --commit"]
      notes: [
        "Keep Git as a journal on the storage side."
        "Batch commits explicitly or behind a flag."
      ]
    }
    {
      phase: "3-reconciliation"
      goal: "Smarter drift reporting and restore flows"
      commands: ["restore" "forget-missing" "prune" "doctor"]
      notes: [
        "Support restoring from store back to live targets."
        "Add policy around missing targets and stale store entries."
      ]
    }
  ]
}

export def init [] {
  ensure-layout
}

export def manifest [] {
  let p = (ensure-layout)
  load-list $p.manifest
}

export def state [] {
  let p = (ensure-layout)
  load-list $p.state
}

export def track [target: path] {
  let p = (ensure-layout)
  let entry = (manifest-record $target)

  let updated = (
    manifest
    | where target != $entry.target
    | append $entry
    | sort-by target
  )

  save-list $p.manifest $updated
  $entry
}

export def untrack [target: path] {
  let p = (ensure-layout)
  let normalized = (normalize-target $target)

  let updated_manifest = (
    manifest
    | where target != $normalized
    | sort-by target
  )

  let updated_state = (
    state
    | where target != $normalized
    | sort-by target
  )

  save-list $p.manifest $updated_manifest
  save-list $p.state $updated_state

  {
    target: $normalized
    removed: true
  }
}

export def status [] {
  manifest | each {|entry| classify-record $entry }
}

export def sync [] {
  let current = (status)
  let results = ($current | each {|row| sync-record $row })
  let final = (status)

  record-state $final | ignore
  $results
}

export def file-differ [a: path, b: path] {
  let r = (^cmp -s -- $a $b | complete)

  if $r.exit_code == 0 {
    false
  } else if $r.exit_code == 1 {
    true
  } else {
    error make { msg: $"cmp failed for ($a) and ($b)" }
  }
}

export def show-diff [
  src: path
  dst: path
  --color
] {
  let args = if $color {
    [
      diff
      --no-index
      --color=always
      --src-prefix=store/
      --dst-prefix=target/
      --
      $src
      $dst
    ]
  } else {
    [
      diff
      --no-index
      --src-prefix=store/
      --dst-prefix=target/
      --
      $src
      $dst
    ]
  }

  let r = (^git ...$args | complete)

  if $r.exit_code == 0 {
    return
  }

  if $r.exit_code == 1 {
    if ($r.stdout != "") {
      print -n $r.stdout
    }
    return
  }

  if ($r.stderr != "") {
    print -n $r.stderr
  }

  error make {
    msg: $"git diff failed for ($src) and ($dst)"
  }
}

export def diff [
  target: path
  --color
] {
  let entry = (get-manifest-record $target)
  let live = $entry.target
  let store = (store-path $live)

  if not ($store | path exists) {
    error make {
      msg: $"no stored copy exists for ($live); run `numoi sync` first"
    }
  }

  if not ($live | path exists) {
    error make {
      msg: $"live target is missing: ($live)"
    }
  }

  show-diff $store $live --color=$color
}

export def --env edit [
  --cd
] {
  let entries = (
    status
    | each {|row|
      $row
      | insert dir ($row.target | path dirname)
      | insert name ($row.target | path basename)
    }
  )

  if ($entries | is-empty) {
    error make {
      msg: "no tracked files; add some with `numoi track <path>` first"
    }
  }

  let selected = (
    try {
      $entries | input list --fuzzy "Select a tracked file"
    } catch {
      null
    }
  )

  if $selected == null {
    return
  }

  if $cd {
    cd $selected.dir
  }

  ^helix $selected.target
}
