# An better cd for nu to replace zoxide

export def state-dir [] {
  $nu.data-dir | path join "nuoxide"
}

export def log-path [] {
  state-dir | path join "visits.jsonl"
}

def ensure-state-dir [] {
  let dir = (state-dir)
  if not ($dir | path exists) {
    mkdir $dir
  }
}

def read-log-lines [] {
  let file = (log-path)

  if not ($file | path exists) {
    []
  } else {
    open --raw $file
    | lines
    | where {|line| ($line | str trim) != ""}
  }
}

def read-events [] {
  read-log-lines | each {|line| $line | from json}
}

def last-event-path [] {
  let events = (read-events)

  if ($events | is-empty) {
    null
  } else {
    $events | last | get path
  }
}

export def --env record-visit [] {
  ensure-state-dir

  let current_path = ($env.PWD | path expand)
  if ($current_path | is-empty) {
    return
  }

  {
    path: $current_path
    accessed_at: (date now)
  }
  | to json --raw
  | $"($in)\n"
  | save --append --raw (log-path)
}

export def visits [] {
  read-events
  | each {|event|
    $event | update accessed_at {|row| $row.accessed_at | into datetime }
  }
}

export def stats [] {
  visits
  | group-by path
  | transpose path events
  |each {|row|
    let sorted = ($row.events | sort-by accessed_at)
    {
      path: $row.path
      visits: ($row.events | length)
      first_accessed_at: ($sorted | first | get accessed_at)
      last_accessed_at: ($sorted | last | get accessed_at)
    }
  }
  | sort-by last_accessed_at
  | reverse
}

export def candidates [] {
  stats
  | where {|row| $row.path | path exists }
  | select path last_accessed_at
}

export def matches [...terms: string] {
  let needles = ($terms | each {|term| $term | str downcase })

  if ($needles | is-empty) {
    candidates
  } else {
    candidates
    | where {|row|
      let haystack = ($row.path | str downcase)
      ($needles | where {|needle| $haystack | str contains $needle } | length) == ($needles | length)
    }
    | sort-by path
    | sort-by {|row| $row.path | str length }
  }
}

export def --env j [...terms: string] {
  let match = (matches ...$terms | first)

  if $match == null {
    let query = ($terms | str join " ")
    error make {
      msg: (
        if $query == "" {
          "nuoxide: no visited directories found"
        } else {
          $"nuoxide: no directory matches '($query)'"
        }
      )
    }
  }

  cd ($match | get path)
}

export def --env ji [...terms: string] {
  let rows = (matches ...$terms)

  if ($rows | is-empty) {
    let query = ($terms | str join " ")
    error make {
      msg: (
        if $query == "" {
          "nuoxide: no visited directories found"
        } else {
          $"nuoxide: no directory matches '($query)'"
        }
      )
    }
  }

  let choice = (try { $rows | input list --fuzzy "jump to" })
  if $choice == null {
    return
  }

  cd ($choice | get path)
}

export def recent [] {
  stats
  | select path last_accessed_at visits
}
