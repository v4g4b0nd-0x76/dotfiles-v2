# Srcery — Spaceship prompt palette
#
# Dark 16-color palette. This is loaded by Spaceship through
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
SPACESHIP_TIME_COLOR='#917E6B'

SPACESHIP_USER_SHOW='always'
SPACESHIP_USER_PREFIX='<'
SPACESHIP_USER_SUFFIX='> '
SPACESHIP_USER_COLOR='#C5B088'
SPACESHIP_USER_COLOR_ROOT='#F75341'

# The working path is the main reading surface.
SPACESHIP_DIR_PREFIX=':: '
SPACESHIP_DIR_SUFFIX=' '
SPACESHIP_DIR_TRUNC=3
SPACESHIP_DIR_COLOR='#FCE8C3'
SPACESHIP_DIR_LOCK_SYMBOL=' !'
SPACESHIP_DIR_LOCK_COLOR='#F75341'

# Git is faded brass; only changes pull signal red.
SPACESHIP_GIT_PREFIX='{ '
SPACESHIP_GIT_SUFFIX=' } '
SPACESHIP_GIT_SYMBOL='git:'
SPACESHIP_GIT_BRANCH_PREFIX="$SPACESHIP_GIT_SYMBOL"
SPACESHIP_GIT_BRANCH_SUFFIX=''
SPACESHIP_GIT_BRANCH_COLOR='#FBB829'
SPACESHIP_GIT_STATUS_PREFIX=' ['
SPACESHIP_GIT_STATUS_SUFFIX=']'
SPACESHIP_GIT_STATUS_COLOR='#F75341'
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
SPACESHIP_EXEC_TIME_COLOR='#519F50'
SPACESHIP_EXEC_TIME_ELAPSED=3
SPACESHIP_EXEC_TIME_PRECISION=1

# Red is reserved for failure.
SPACESHIP_EXIT_CODE_SHOW=true
SPACESHIP_EXIT_CODE_PREFIX='[err:'
SPACESHIP_EXIT_CODE_SYMBOL=''
SPACESHIP_EXIT_CODE_SUFFIX='] '
SPACESHIP_EXIT_CODE_COLOR='#F75341'

# Keep the legacy `kuro` command as a compatibility alias for this status card.
SPACESHIP_CHAR_PREFIX='|-- '
SPACESHIP_CHAR_SYMBOL_SUCCESS='> '
SPACESHIP_CHAR_SYMBOL_FAILURE='! '
SPACESHIP_CHAR_SYMBOL_ROOT='# '
SPACESHIP_CHAR_SYMBOL_SECONDARY=': '
SPACESHIP_CHAR_COLOR_SUCCESS='#519F50'
SPACESHIP_CHAR_COLOR_FAILURE='#F75341'
SPACESHIP_CHAR_COLOR_SECONDARY='#C5B088'

alias ls='lsd'
# Suggestions should recede like pencil notes; commands keep warm-paper clarity.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#917E6B'

# Syntax highlighting follows the same quiet hierarchy. The named tools receive
# a brass command face; unknown commands and errors stay signal red.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#FCE8C3,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#FCE8C3'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#FBB829,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#FBB829'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#C5B088'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#C5B088'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#FBB829'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#FBB829'
ZSH_HIGHLIGHT_STYLES[path]='fg=#0AAEB3,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#0AAEB3'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#FBB829'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#C5B088'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#917E6B'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#F75341,bold'

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
typeset -gA ZSH_HIGHLIGHT_PATTERNS
ZSH_HIGHLIGHT_PATTERNS+=(
  '(#s)(git|docker|gcc|go|rustc|cargo|curl|wget)([[:space:]]|$)' 'fg=#FBB829,bold'
)

# A manual little status card for a fresh terminal or a quick mood reset.
kuro() {
  print -P '%F{#3B3935}.------------------------------------------.%f'
  print -P '%F{#3B3935}|%f %F{#F75341}SRCERY%f %F{#917E6B}//%f %F{#FCE8C3}dark terminal%f             %F{#3B3935}|%f'
  print -P '%F{#3B3935}|%f %F{#C5B088}occult / warm / sixteen colors%f          %F{#3B3935}|%f'
  print -P '%F{#3B3935}\x27------------------------------------------\x27%f'
}
