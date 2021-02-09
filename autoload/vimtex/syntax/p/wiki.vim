" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#wiki#load(cfg) abort " {{{1
  call vimtex#syntax#nested#include('markdown')

  syntax region texWikiZone
        \ start='\\wikimarkup\>'
        \ end='\\nowikimarkup\>'
        \ keepend
        \ transparent
        \ contains=texCmd,@vimtex_nested_markdown
endfunction

" }}}1
