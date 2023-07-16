" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pyluatex#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'python\(q\|repl\)\?',
        \ 'region': 'texPyluatexZone',
        \ 'nested': 'python',
        \})

  highlight def link texCmdPyluatex texCmd
endfunction

" }}}1
