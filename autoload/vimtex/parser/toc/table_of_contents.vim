" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#table_of_contents#new() abort " {{{1
  return {
      \ 'title' : 'Table of contents',
      \ 'prefilter_cmds' : ['tableofcontents'],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\tableofcontents',
      \}
endfunction

" }}}1
