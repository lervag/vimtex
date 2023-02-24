" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#empheq#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_math('empheq', {
        \ 'next': 'texEmpheqArg',
        \})
  call vimtex#syntax#core#new_arg('texEmpheqArg')

  highlight def link texEmpheqArg texOpt
endfunction
