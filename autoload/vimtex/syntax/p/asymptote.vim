" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'asy\(def\)?',
        \ 'region': 'texAsymptoteZone',
        \ 'nested': 'asy',
        \})
endfunction

" }}}1
