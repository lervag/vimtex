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
  return !exists('b:vimtex.root') || vimtex#paths#is_abs(l:filename)
        \ ? l:filename
        \ : simplify(b:vimtex.root . '/' . l:filename)
endfunction

" }}}1
function! vimtex#kpsewhich#run(args) abort " {{{1
  " kpsewhich should be run at the project root directory
  if exists('b:vimtex.root')
    call vimtex#paths#pushd(b:vimtex.root)
  endif
  let l:output = vimtex#process#capture('kpsewhich ' . a:args)
  if exists('b:vimtex.root')
    call vimtex#paths#popd()
  endif

  " Remove warning lines from output
  call filter(l:output, 'stridx(v:val, "kpsewhich: warning: ") == -1')

  return l:output
endfunction

" }}}1
