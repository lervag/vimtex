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
function! vimtex#parser#fls#parse_files(vimtex) abort " {{{1
  " Argument: vimtex is a vimtex blob because we need several properties

  if !filereadable(a:vimtex.fls())
    return []
  endif

  " This seems like a correct heuristic to limit the scope for parsing the
  " included main source files
  let l:files = readfile(a:vimtex.fls())

  " Only include the INPUT lines with .tex extension
  call filter(l:files, 'stridx(v:val, ''INPUT'') == 0')
  call filter(l:files, 'v:val =~# ''\.tex$''')

  " Ignore package files under texmf trees
  call filter(l:files, 'v:val !~# ''\/texmf[^\/]*\/''')

  " Remove INPUT prefix
  call map(l:files, 'strpart(v:val, 6)')

  " Add the main file to the list before returning
  return vimtex#util#uniq_unsorted(l:files)
endfunction

" }}}1
