function! toc#fold_level(lnum) " {{{1
  let pline = getline(a:lnum - 1)
  let cline = getline(a:lnum)
  let nline = getline(a:lnum + 1)
  let pn = matchstr(pline, '\d$')
  let cn = matchstr(cline, '\d$')
  let nn = matchstr(nline, '\d$')

  " Don't fold options
  if cline =~# '^\s*$'
    return 0
  endif

  if nn > cn
    return '>' . nn
  endif

  if cn < pn && cn >= nn
    return cn
  endif

  return '='
endfunction

function! toc#fold_text() " {{{1
  return getline(v:foldstart)
endfunction

" }}}1

" vim: fdm=marker
