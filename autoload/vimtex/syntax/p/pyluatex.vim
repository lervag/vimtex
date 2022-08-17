" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pyluatex#load(cfg) abort " {{{1
  call vimtex#syntax#nested#include('python')

  for l:env in ['python', 'pythonq', 'pythonrepl']
    call vimtex#syntax#core#new_region_env(
          \ 'texPyluatexZone', l:env, {'contains': '@vimtex_nested_python'})
  endfor

  highlight def link texCmdPyluatex texCmd
endfunction

" }}}1
