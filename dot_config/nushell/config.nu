$env.config.show_banner = false
$env.PROMPT_COMMAND = {||
  let dir = match (do -i { $env.PWD | path relative-to $nu.home-dir }) {
    null => $env.PWD
    '' => '~'
    $relative_pwd => ([~ $relative_pwd] | path join)
  }

  let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
  let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
  let path_segment = $"($path_color)($dir)(ansi reset)"
  let rendered_path = (
    $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
  )

  $"($rendered_path)\n> "
}
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_COMMAND_RIGHT = {|| "" }
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

$env.EDITOR = "/usr/bin/nvim"
$env.VISUAL = "/usr/bin/nvim"
alias vi = /usr/bin/nvim


use ~/.config/nushell/modules/nuoxide *
use ~/.config/nushell/modules/nunotes *
use ~/.config/nushell/modules/numoi 

$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD? | default [])

$env.config.hooks.env_change.PWD ++= [
{||
  record-visit
}]

use '/home/favetelinguis/.config/broot/launcher/nushell/br' * 
