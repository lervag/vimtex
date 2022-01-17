" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#sagetex#load(cfg) abort " {{{1
  call vimtex#syntax#nested#include('python')

  syntax match texCmdSagetex /\\sagestr\>/
        \ nextgroup=texSagetexArg skipwhite skipnl
  syntax match texCmdSagetex /\\sageplot\>/
        \ nextgroup=texSagetexOpt,texSagetexArg skipwhite skipnl

  call vimtex#syntax#core#new_arg('texSagetexArg',
        \ {'contains': '@vimtex_nested_python', 'opts': 'contained keepend'})
  call vimtex#syntax#core#new_opt('texSagetexOpt', {'next': 'texSagetexArg'})

  call vimtex#syntax#core#new_region_env('texSagetexZone', 'sagesilent',
        \ {'contains': '@vimtex_nested_python'})

  highlight def link texCmdSagetex texCmd
endfunction

" }}}1
