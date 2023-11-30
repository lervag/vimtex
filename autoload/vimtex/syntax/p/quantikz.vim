" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#quantikz#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'quantikz',
        \ 'starred': v:false,
        \ 'math': v:true
        \})
endfunction

" }}}1
