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
  let l:aux = fnamemodify(a:vimtex.base, ':r') . '.aux'
  let l:pdf = fnamemodify(a:vimtex.base, ':r') . '.pdf'
  let l:i1 = index(l:files, 'OUTPUT ' . l:aux)
  let l:i2 = index(l:files, 'OUTPUT ' . l:pdf)
  let l:files = vimtex#util#uniq_unsorted(l:files[l:i1+1 : l:i2-1])

  " Only include the INPUT lines with .tex extension
  call filter(l:files, 'stridx(v:val, ''INPUT'') == 0')
  call filter(l:files, 'v:val =~# ''\.tex$''')
  call map(l:files, 'strpart(v:val, 6)')

  " Add the main file to the list before returning
  return [a:vimtex.base] + l:files
endfunction

" }}}1
