" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#wiki#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'wiki') | return | endif
  let b:vimtex_syntax.wiki = 1

  call vimtex#syntax#misc#add_to_section_clusters('texZoneWiki')
  call vimtex#syntax#misc#include('markdown')

  syntax region texZoneWiki
        \ start='\\wikimarkup\>'
        \ end='\\nowikimarkup\>'re=e
        \ keepend
        \ transparent
        \ contains=@vimtex_nested_markdown,@texFoldGroup,@texDocGroup
endfunction

" }}}1
