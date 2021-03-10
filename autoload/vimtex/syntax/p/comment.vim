" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#comment#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_env('texComment', 'comment')
endfunction

" }}}1
