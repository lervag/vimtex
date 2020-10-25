" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pythontex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pythontex') | return | endif
  let b:vimtex_syntax.pythontex = 1

  call vimtex#syntax#misc#include('python')

  syntax match texCmd /\\py[bsc]\?/ contained nextgroup=texPythontexArg
  syntax region texPythontexArg matchgroup=Delimiter
        \ start='{' end='}'
        \ contained contains=@vimtex_nested_python
  syntax region texPythontexArg matchgroup=Delimiter
        \ start='\z([#@]\)' end='\z1'
        \ contained contains=@vimtex_nested_python

  syntax region texRegionPythontex
        \ start='\\begin{pyblock}'rs=s
        \ end='\\end{pyblock}'re=e
        \ keepend
        \ transparent
        \ contains=texCmdEnv,@vimtex_nested_python
  syntax region texRegionPythontex
        \ start='\\begin{pycode}'rs=s
        \ end='\\end{pycode}'re=e
        \ keepend
        \ transparent
        \ contains=texCmdEnv,@vimtex_nested_python
endfunction

" }}}1
