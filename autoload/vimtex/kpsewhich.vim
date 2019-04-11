" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#kpsewhich#find(file) abort " {{{1
  execute 'lcd' fnameescape(b:vimtex.root)
  let l:output = split(system('kpsewhich "' . a:file . '"'), '\n')
  lcd -

  " Remove warning lines from output
  call filter(l:output, 'stridx(v:val, "kpsewhich: warning: ") == -1')
  if empty(l:output) | return '' | endif
  let l:filename = l:output[0]

  " If path is already absolute, return it
  return vimtex#paths#is_abs(l:filename)
        \ ? l:filename
        \ : simplify(b:vimtex.root . '/' . l:filename)
endfunction

" }}}1
function! vimtex#kpsewhich#run(args) abort " {{{1
  execute 'lcd' fnameescape(b:vimtex.root)
  let l:output = split(system('kpsewhich ' . a:args), '\n')
  lcd -

  return l:output
endfunction

" }}}1
