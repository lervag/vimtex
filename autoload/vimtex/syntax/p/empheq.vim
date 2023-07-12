" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#empheq#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'empheq',
        \ 'starred': v:true,
        \ 'math': v:true,
        \ 'mtah_nextgroup': 'texEmpheqArg',
        \})
  call vimtex#syntax#core#new_arg('texEmpheqArg')

  highlight def link texEmpheqArg texOpt
endfunction
