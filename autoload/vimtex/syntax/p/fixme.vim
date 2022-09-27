" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#fixme#load(cfg) abort " {{{1
  syntax match texCmdTodo '\\fixme\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdTodo '\\fxnote\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdTodo '\\fxwarning\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdTodo '\\fxerror\>\*\?' nextgroup=texFixmeArg
  syntax match texCmdTodo '\\fxfatal\>\*\?' nextgroup=texFixmeArg

  syntax match texFixmeEnvBgn
        \ "\\begin{anfx\%(note\|warning\|error\|fatal\)\*\?}"
        \ nextgroup=texFixmeArg skipwhite skipnl
  syntax match texFixmeEnvBgn "\\begin{afixme}"
        \ nextgroup=texFixmeArg skipwhite skipnl
  syntax match texFixmeEnvEnd
        \ "\\end{anfx\%(note\|warning\|error\|fatal\)\*\?}"
  syntax match texFixmeEnvEnd "\\end{afixme}"

  call vimtex#syntax#core#new_arg('texFixmeArg', {'contains': 'TOP,@Spell'})

  highlight def link texFixmeEnvBgn texCmdTodo
  highlight def link texFixmeEnvEnd texFixmeEnvBgn
  highlight def link texFixmeArg texArg
endfunction

" }}}1

