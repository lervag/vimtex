" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#url#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'url') | return | endif
  let b:vimtex_syntax.url = 1

  call vimtex#syntax#p#hyperref#load()
endfunction

" }}}1
