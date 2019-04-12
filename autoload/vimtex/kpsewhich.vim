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
  " Ensure that we run kpsewhich at the project root directory
  let l:cwd = getcwd()
  let l:change_dir = l:cwd !=# b:vimtex.root
  if l:change_dir
    execute 'lcd' fnameescape(b:vimtex.root)
  endif

  let l:output = split(system('kpsewhich ' . a:args), '\n')

  " Restore local CWD
  if l:change_dir
    execute 'lcd' l:cwd
  endif

  return l:output
endfunction

" }}}1
