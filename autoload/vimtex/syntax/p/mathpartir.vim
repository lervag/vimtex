" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#mathpartir#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env(#{
        \ name: 'mathpar',
        \ math: v:true
        \})
  call vimtex#syntax#core#new_env(#{
        \ name: 'mathparpagebreakable',
        \ math: v:true
        \})
endfunction

" }}}1
