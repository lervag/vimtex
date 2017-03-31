" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#lacheck#new() " {{{1
  return deepcopy(s:qf)
endfunction

" }}}1


let s:qf = {
      \ 'name' : 'Lacheck',
      \}

function! s:qf.init() abort dict "{{{1
  let g:current_compiler = 'lacheck'

  CompilerSet makeprg=lacheck\ %
  CompilerSet errorformat="%f",\ line\ %l:\ %m
endfunction

" }}}1
function! s:qf.pprint_items() abort dict " {{{1
  return []
endfunction

" }}}1

" vim: fdm=marker sw=2
