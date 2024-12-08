" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#luacas#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'CAS',
        \ 'region': 'texLuacasZone',
        \})

  highlight def link texLuacasZone texVerbZone
endfunction

" }}}1
