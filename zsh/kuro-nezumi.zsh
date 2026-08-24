# Kuro Nezumi — Spaceship prompt layer
#
# Deep ash, warm paper, and signal red.  This is loaded by Spaceship through
# ~/.config/spaceship/spaceship.zsh (a symlink to this file).

# Keep the shell compact, readable, and quietly retro.
SPACESHIP_PROMPT_ASYNC=true
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=true
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true
SPACESHIP_PROMPT_PREFIXES_SHOW=true
SPACESHIP_PROMPT_SUFFIXES_SHOW=true
SPACESHIP_PROMPT_DEFAULT_SUFFIX=' '

# [ 21:04 ] <vangabond> :: ~/project { git:main [!+] }
# |-- >
SPACESHIP_PROMPT_ORDER=(
  time
  user
  dir
  git
  exec_time
  line_sep
  exit_code
  char
)

# A muted clock and identity: visible but never shouting.
SPACESHIP_TIME_SHOW=true
SPACESHIP_TIME_FORMAT='%D{%H:%M}'
SPACESHIP_TIME_PREFIX='[ '
SPACESHIP_TIME_SUFFIX=' ] '
SPACESHIP_TIME_COLOR='#6F6A63'

SPACESHIP_USER_SHOW='always'
SPACESHIP_USER_PREFIX='<'
SPACESHIP_USER_SUFFIX='> '
SPACESHIP_USER_COLOR='#9A948A'
SPACESHIP_USER_COLOR_ROOT='#D94A4A'

# The working path is the main reading surface.
SPACESHIP_DIR_PREFIX=':: '
SPACESHIP_DIR_SUFFIX=' '
SPACESHIP_DIR_TRUNC=3
SPACESHIP_DIR_COLOR='#D7D2C8'
SPACESHIP_DIR_LOCK_SYMBOL=' !'
SPACESHIP_DIR_LOCK_COLOR='#D94A4A'

# Git is faded brass; only changes pull signal red.
SPACESHIP_GIT_PREFIX='{ '
SPACESHIP_GIT_SUFFIX=' } '
SPACESHIP_GIT_SYMBOL='git:'
SPACESHIP_GIT_BRANCH_PREFIX="$SPACESHIP_GIT_SYMBOL"
SPACESHIP_GIT_BRANCH_SUFFIX=''
SPACESHIP_GIT_BRANCH_COLOR='#B8A781'
SPACESHIP_GIT_STATUS_PREFIX=' ['
SPACESHIP_GIT_STATUS_SUFFIX=']'
SPACESHIP_GIT_STATUS_COLOR='#D94A4A'
SPACESHIP_GIT_STATUS_UNTRACKED='?'
SPACESHIP_GIT_STATUS_ADDED='+'
SPACESHIP_GIT_STATUS_MODIFIED='!'
SPACESHIP_GIT_STATUS_RENAMED='>'
SPACESHIP_GIT_STATUS_DELETED='x'
SPACESHIP_GIT_STATUS_STASHED='$'
SPACESHIP_GIT_STATUS_UNMERGED='='
SPACESHIP_GIT_STATUS_AHEAD='^'
SPACESHIP_GIT_STATUS_BEHIND='v'
SPACESHIP_GIT_STATUS_DIVERGED='x'

# Long commands get a small, moss-green timing note.
SPACESHIP_EXEC_TIME_SHOW=true
SPACESHIP_EXEC_TIME_PREFIX='t+'
SPACESHIP_EXEC_TIME_SUFFIX=' '
SPACESHIP_EXEC_TIME_COLOR='#8A8F73'
SPACESHIP_EXEC_TIME_ELAPSED=3
SPACESHIP_EXEC_TIME_PRECISION=1

# Red is reserved for failure.
SPACESHIP_EXIT_CODE_SHOW=true
SPACESHIP_EXIT_CODE_PREFIX='[err:'
SPACESHIP_EXIT_CODE_SYMBOL=''
SPACESHIP_EXIT_CODE_SUFFIX='] '
SPACESHIP_EXIT_CODE_COLOR='#D94A4A'

# The little ASCII rail is the Kuro Nezumi signature.
SPACESHIP_CHAR_PREFIX='|-- '
SPACESHIP_CHAR_SYMBOL_SUCCESS='> '
SPACESHIP_CHAR_SYMBOL_FAILURE='! '
SPACESHIP_CHAR_SYMBOL_ROOT='# '
SPACESHIP_CHAR_SYMBOL_SECONDARY=': '
SPACESHIP_CHAR_COLOR_SUCCESS='#B73535'
SPACESHIP_CHAR_COLOR_FAILURE='#D94A4A'
SPACESHIP_CHAR_COLOR_SECONDARY='#9A948A'

alias ls='lsd'
# Suggestions should recede like pencil notes; commands keep warm-paper clarity.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6F6A63'

# Syntax highlighting follows the same quiet hierarchy. The named tools receive
# a brass command face; unknown commands and errors stay signal red.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#D7D2C8,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#D7D2C8'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#B8A781,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#B8A781'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#9A948A'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#9A948A'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#B8A781'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#B8A781'
ZSH_HIGHLIGHT_STYLES[path]='fg=#7F9693,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#7F9693'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#B8A781'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#9A948A'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6F6A63'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#D94A4A,bold'

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
typeset -gA ZSH_HIGHLIGHT_PATTERNS
ZSH_HIGHLIGHT_PATTERNS+=(
  '(#s)(git|docker|gcc|go|rustc|cargo|curl|wget)([[:space:]]|$)' 'fg=#B8A781,bold'
)

# A manual little status card for a fresh terminal or a quick mood reset.
kuro() {
  print -P '%F{#343434}.------------------------------------------.%f'
  print -P '%F{#343434}|%f %F{#D94A4A}KURO NEZUMI%f %F{#6F6A63}//%f %F{#D7D2C8}night shift terminal%f       %F{#343434}|%f'
  print -P '%F{#343434}|%f %F{#9A948A}ash / warm paper / signal red%f            %F{#343434}|%f'
  print -P '%F{#343434}\x27------------------------------------------\x27%f'
}
