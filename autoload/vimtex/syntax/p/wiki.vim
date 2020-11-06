" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#wiki#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'wiki') | return | endif
  let b:vimtex_syntax.wiki = 1

  call vimtex#syntax#nested#include('markdown')

  syntax region texWikiRegion
        \ start='\\wikimarkup\>'
        \ end='\\nowikimarkup\>'
        \ keepend
        \ transparent
        \ contains=texCmd,@vimtex_nested_markdown
endfunction

" }}}1
