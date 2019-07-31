" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#dot2texi#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'dot2texi') | return | endif
  let b:vimtex_syntax.dot2texi = 1

  call vimtex#syntax#misc#include('dot')
  call vimtex#syntax#misc#add_to_section_clusters('texZoneDot')
  syntax region texZoneDot
        \ start="\\begin{dot2tex}"rs=s
        \ end="\\end{dot2tex}"re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,@vimtex_nested_dot
endfunction

" }}}1
