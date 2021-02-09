" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#titlepage#new() abort " {{{1
  return {
      \ 'title' : 'Titlepage',
      \ 'prefilter_cmds' : ['begin'],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\begin\{titlepage\}',
      \}
endfunction

" }}}1
