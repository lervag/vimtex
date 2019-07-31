" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#dot2texi#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'dot2texi') | return | endif
  let b:vimtex_syntax.dot2texi = 1

  unlet b:current_syntax
  syntax include @DOT syntax/dot.vim
  let b:current_syntax = 'tex'

  call vimtex#syntax#add_to_clusters('texZoneDot')
  syntax region texZoneDot
        \ start="\\begin{dot2tex}"rs=s
        \ end="\\end{dot2tex}"re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,@DOT
endfunction

" }}}1
