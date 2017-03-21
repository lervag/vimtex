" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#pos#cursor(...) " {{{1
  call cursor(s:parse_args(a:000))
endfunction

" }}}1

function! s:parse_args(args) " {{{1
  "
  " The arguments should be in one of the following forms:
  "
  "   lnum, cnum
  "   [lnum, cnum]
  "   [bufnum, lnum, cnum, ...]
  "   {'lnum' : lnum, 'cnum' : cnum}
  "

  if len(a:args) == 1
    if type(a:args[0]) == type({})
      let l:lnum = get(a:args[0], 'lnum')
      let l:cnum = get(a:args[0], 'cnum')
    else
      if len(a:args[0]) == 2
        let l:lnum = a:args[0][0]
        let l:cnum = a:args[0][1]
      else
        let l:lnum = a:args[0][1]
        let l:cnum = a:args[0][2]
      endif
    endif
  else
    let l:lnum = a:args[0]
    let l:cnum = a:args[1]
  endif

  return [l:lnum, l:cnum]
endfunction

" }}}1

" vim: fdm=marker sw=2
