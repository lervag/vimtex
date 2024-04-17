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

  call vimtex#syntax#core#new_arg('texSagetexArg', {
        \ 'contains': '@vimtex_nested_python',
        \ 'opts': 'contained keepend'
        \})
  call vimtex#syntax#core#new_opt('texSagetexOpt', {'next': 'texSagetexArg'})

  for l:env in [
        \ 'sageblock',
        \ 'sagesilent',
        \ 'sageverbatim',
        \ 'sageexample',
        \ 'sagecommandline'
        \]
    call vimtex#syntax#core#new_env({
          \ 'name': l:env,
          \ 'region': 'texSagetexZone',
          \ 'contains': '@vimtex_nested_python'
          \})
  endfor

  highlight def link texCmdSagetex texCmd
endfunction

" }}}1
