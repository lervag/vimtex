" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#sagetex#load(cfg) abort " {{{1
  call vimtex#syntax#nested#include('python')

  syntax match texCmdSagetex /\\sageplot\>/
        \ nextgroup=texSagetexOpt,texSagetexArg skipwhite skipnl

  call vimtex#syntax#core#new_arg('texSagetexArg', {
        \ 'contains': '@vimtex_nested_python',
        \ 'opts': 'contained keepend'
        \})
  call vimtex#syntax#core#new_opt('texSagetexOpt', {'next': 'texSagetexArg'})

  for l:env_name in [
        \ 'sageblock',
        \ 'sagesilent',
        \ 'sageverbatim',
        \ 'sageexample',
        \ 'sagecommandline'
        \]
    call vimtex#syntax#core#new_env({
          \ 'name': l:env_name,
          \ 'region': 'texSagetexZone',
          \ 'contains': '@vimtex_nested_python'
          \})
  endfor

  " Note: The following commands are supported both inside and outside math zones
  for l:cmd_name in [
        \ 'sage',
        \ 'sagestr'
        \]
    for l:in_mathmode in [v:true, v:false]
      call vimtex#syntax#core#new_cmd({
            \ 'name': l:cmd_name,
            \ 'mathmode': l:in_mathmode,
            \ 'nextgroup': 'texSagetexArg'
            \})
    endfor
  endfor

  highlight def link texCmdSagetex texCmd
endfunction

" }}}1
function! vimtex#syntax#p#sagetex#in_sage(...) abort " {{{1
  return call('vimtex#syntax#in', ['texSagetex\(Arg\|Zone\)'] + a:000)
endfunction

" }}}1
