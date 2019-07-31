" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#load() abort " {{{1
  " Initialize b:vimtex_syntax if necessary
  let b:vimtex_syntax = get(b:, 'vimtex_syntax', {})

  " Load syntax for documentclass
  try
    call vimtex#syntax#p#{b:vimtex.documentclass}#load()
  catch /E117: Unknown function/
  endtry

  " Load syntax for packages
  for l:package in keys(b:vimtex.packages)
    try
      call vimtex#syntax#p#{l:package}#load()
    catch /E117: Unknown function/
    endtry
  endfor
endfunction

" }}}1
function! vimtex#syntax#add_to_clusters(group) abort " {{{1
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
