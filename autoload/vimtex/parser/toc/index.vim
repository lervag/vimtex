" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#index#new() abort " {{{1
  return {
      \ 'title' : 'Alphabetical index',
      \ 'prefilter_cmds' : ['printindex'],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\printindex\[?',
      \}
endfunction

" }}}1
