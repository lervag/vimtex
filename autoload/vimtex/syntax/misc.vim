" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#misc#add_to_section_clusters(group) abort " {{{1
  for l:cluster in [
        \ 'texPartGroup',
        \ 'texChapterGroup',
        \ 'texSectionGroup',
        \ 'texSubSectionGroup',
        \ 'texSubSubSectionGroup',
        \]
    execute printf('syntax cluster %s add=%s', l:cluster, a:group)
  endfor
endfunction

" }}}1
