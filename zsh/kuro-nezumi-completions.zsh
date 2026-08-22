# Kuro Nezumi — completion bridge
# Load after Oh My Zsh. Native Zsh completions cover the common Unix tools;
# the compact rustc completer fills the one gap that macOS does not ship.

_kuro_completion() {
  local command_name="$1" completion_name="$2"
  (( $+commands[$command_name] )) || return 0
  (( $+functions[$completion_name] )) || autoload -Uz "$completion_name"
  (( $+functions[$completion_name] )) && compdef "$completion_name" "$command_name"
}

_kuro_completion git _git
_kuro_completion docker _docker
_kuro_completion gcc _gcc
_kuro_completion go _go
_kuro_completion curl _curl
_kuro_completion wget _wget

_kuro_rustc() {
  local -a targets
  targets=("${(@f)$(rustc --print target-list 2>/dev/null)}")

  _arguments -s -S \
    '(-h --help)'{-h,--help}'[display rustc help]' \
    '(-V --version)'{-V,--version}'[display compiler version]' \
    '--explain=[explain an error code]:error code' \
    '--edition=[Rust edition]:edition:(2015 2018 2021 2024)' \
    '--crate-name=[set the crate name]:crate name' \
    '--crate-type=[set crate type]:crate type:(bin lib rlib dylib cdylib staticlib proc-macro)' \
    '(-O --opt-level)'{-O,--opt-level=}'[set optimization level]:level:(0 1 2 3 s z)' \
    '(-g --debuginfo)'{-g,--debuginfo=}'[set debug information level]:level:(0 1 2 full limited line-directives-only line-tables-only none)' \
    '--emit=[choose compiler output]:kind:(asm llvm-bc llvm-ir obj metadata link dep-info mir)' \
    '(-o --out-dir)'{-o,--out-dir=}'[write output to a file or directory]:path:_files' \
    '--target=[compile for a target triple]:target:(( ${targets[@]} ))' \
    '-L+[add a library search path]:path:_directories' \
    '--extern=[link an external crate]:crate:file:_files' \
    '--cfg=[configure a conditional compilation flag]:flag' \
    '(-A --allow)'{-A,--allow=}'[allow a lint]:lint' \
    '(-W --warn)'{-W,--warn=}'[warn on a lint]:lint' \
    '(-D --deny)'{-D,--deny=}'[deny a lint]:lint' \
    '(-F --forbid)'{-F,--forbid=}'[forbid a lint]:lint' \
    '--cap-lints=[set the most severe lint level]:level:(allow warn deny forbid)' \
    '--error-format=[select diagnostic format]:format:(human json short)' \
    '--color=[control diagnostic color]:mode:(auto always never)' \
    '*:Rust source file:_files -g "*.rs"'
}

if (( $+commands[rustc] )); then
  compdef _kuro_rustc rustc
fi

unset -f _kuro_completion
