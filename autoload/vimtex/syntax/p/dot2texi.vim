" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#dot2texi#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'dot2texi') | return | endif
  let b:vimtex_syntax.dot2texi = 1

  call vimtex#syntax#nested#include('dot')
  syntax region texRegionDot
        \ start="\\begin{dot2tex}"
        \ end="\\end{dot2tex}"
        \ keepend transparent contains=texCmdEnv,@vimtex_nested_dot
endfunction

" }}}1
