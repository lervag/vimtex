" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#kpsewhich#find(file) abort " {{{1
  let l:output = vimtex#kpsewhich#run(fnameescape(a:file))

  if empty(l:output) | return '' | endif
  let l:filename = l:output[0]

  " If path is already absolute, return it
  return l:filename[0] ==# '/'
        \ ? l:filename
        \ : simplify(b:vimtex.root . '/' . l:filename)
endfunction

" }}}1
function! vimtex#kpsewhich#run(args) abort " {{{1
  " kpsewhich should be run at the project root directory
  call vimtex#paths#pushd(b:vimtex.root)
  let l:output = split(system('kpsewhich ' . a:args), '\n')
  call vimtex#paths#popd()

  return l:output
endfunction

" }}}1
