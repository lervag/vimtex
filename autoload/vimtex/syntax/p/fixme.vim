" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#fixme#load(cfg) abort " {{{1
  syntax match texCmdTodo '\\fixme\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdTodo '\\fxnote\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdWarning '\\fxwarning\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdError '\\fxerror\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdFatal '\\fxfatal\>\*\?' nextgroup=texFixmeArg

  syntax match texFixmeTodoEnvBgn "\\begin{afixme}"
        \ nextgroup=texFixmeArg skipwhite skipnl
  syntax match texFixmeTodoEnvEnd "\\end{afixme}"
  syntax match texFixmeTodoEnvBgn "\\begin{anfxnote\*\?}"
        \ nextgroup=texFixmeArg skipwhite skipnl
  syntax match texFixmeTodoEnvEnd "\\end{anfxnote\*\?}"
  syntax match texFixmeWarningEnvBgn "\\begin{anfxwarning\*\?}"
        \ nextgroup=texFixmeArg skipwhite skipnl
  syntax match texFixmeWarningEnvEnd "\\end{anfxwarning\*\?}"
  syntax match texFixmeErrorEnvBgn "\\begin{anfxerror\*\?}"
        \ nextgroup=texFixmeArg skipwhite skipnl
  syntax match texFixmeErrorEnvEnd "\\end{anfxerror\*\?}"
  syntax match texFixmeFatalEnvBgn "\\begin{anfxfatal\*\?}"
        \ nextgroup=texFixmeArg skipwhite skipnl
  syntax match texFixmeFatalEnvEnd "\\end{anfxfatal\*\?}"

  call vimtex#syntax#core#new_arg('texFixmeArg', {'contains': 'TOP,@Spell'})

  highlight def link texFixmeTodoEnvBgn texCmdTodo
  highlight def link texFixmeTodoEnvEnd texFixmeTodoEnvBgn
  highlight def link texFixmeWarningEnvBgn texCmdWarning
  highlight def link texFixmeWarningEnvEnd texFixmeWarningEnvBgn
  highlight def link texFixmeErrorEnvBgn texCmdError
  highlight def link texFixmeErrorEnvEnd texFixmeErrorEnvBgn
  highlight def link texFixmeFatalEnvBgn texCmdFatal
  highlight def link texFixmeFatalEnvEnd texFixmeFatalEnvBgn
  highlight def link texFixmeArg texArg
endfunction

" }}}1

