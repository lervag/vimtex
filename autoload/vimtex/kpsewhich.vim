" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#kpsewhich#find(file) " {{{1
  execute 'lcd' fnameescape(b:vimtex.root)
  let l:output = split(system('kpsewhich "' . a:file . '"'), '\n')
  lcd -

  if empty(l:output) | return '' | endif
  let l:filename = l:output[0]

  " If path is already absolute, return it
  return l:filename[0] ==# '/'
        \ ? l:filename
        \ : simplify(b:vimtex.root . '/' . l:filename)
endfunction

" }}}1
function! vimtex#kpsewhich#run(args) " {{{1
  execute 'lcd' fnameescape(b:vimtex.root)
  let l:output = split(system('kpsewhich ' . a:args), '\n')
  lcd -

  return l:output
endfunction

" }}}1
