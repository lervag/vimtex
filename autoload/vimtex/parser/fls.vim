" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#fls#parse(file) abort " {{{1
  if !filereadable(a:file)
    return []
  endif

  return readfile(a:file)
endfunction

" }}}1
