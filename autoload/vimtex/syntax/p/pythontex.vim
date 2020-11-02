" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pythontex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pythontex') | return | endif
  let b:vimtex_syntax.pythontex = 1

  call vimtex#syntax#nested#include('python')

  syntax match texCmd /\\py[bsc]\?/ nextgroup=texPythontexArg skipwhite skipnl
  call vimtex#syntax#core#new_cmd_arg('texPythontexArg', '', '@vimtex_nested_python', 'keepend')
  syntax region texPythontexArg matchgroup=texDelim
        \ start='\z([#@]\)' end='\z1'
        \ contained contains=@vimtex_nested_python keepend

  syntax region texRegionPythontex
        \ start='\\begin{pyblock}'
        \ end='\\end{pyblock}'
        \ keepend
        \ transparent
        \ contains=texCmdEnv,@vimtex_nested_python
  syntax region texRegionPythontex
        \ start='\\begin{pycode}'
        \ end='\\end{pycode}'
        \ keepend
        \ transparent
        \ contains=texCmdEnv,@vimtex_nested_python
endfunction

" }}}1
