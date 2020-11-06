" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pythontex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pythontex') | return | endif
  let b:vimtex_syntax.pythontex = 1

  call vimtex#syntax#nested#include('python')

  syntax match texCmdPythontex /\\py[bsc]\?/ nextgroup=texPythontexArg skipwhite skipnl
  call vimtex#syntax#core#new_cmd_arg('texPythontexArg', '', '@vimtex_nested_python', 'keepend')
  syntax region texPythontexArg matchgroup=texDelim
        \ start='\z([#@]\)' end='\z1'
        \ contained contains=@vimtex_nested_python keepend

  call vimtex#syntax#core#new_region_env('texPythontexRegion', 'pyblock', '@vimtex_nested_python')
  call vimtex#syntax#core#new_region_env('texPythontexRegion', 'pycode', '@vimtex_nested_python')

  highlight def link texCmdPythontex texCmd
endfunction

" }}}1
