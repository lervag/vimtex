" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#pos#cursor(...) " {{{1
  call cursor(s:parse_args(a:000))
endfunction

" }}}1
function! vimtex#pos#val(...) " {{{1
  let [l:lnum, l:cnum] = s:parse_args(a:000)

  return 10000*l:lnum + l:cnum
endfunction

" }}}1
function! vimtex#pos#next(...) " {{{1
  let [l:lnum, l:cnum] = s:parse_args(a:000)

  return l:cnum < strlen(getline(l:lnum))
        \ ? [0, l:lnum, l:cnum+1, 0]
        \ : [0, l:lnum+1, 1, 0]
endfunction

" }}}1
function! vimtex#pos#prev(...) " {{{1
  let [l:lnum, l:cnum] = s:parse_args(a:000)

  return l:cnum > 1
        \ ? [0, l:lnum, l:cnum-1, 0]
        \ : [0, max([l:lnum-1, 1]), strlen(getline(l:lnum-1)), 0]
endfunction

" }}}1
function! vimtex#pos#larger(pos1, pos2) " {{{1
  return vimtex#pos#val(a:pos1) > vimtex#pos#val(a:pos2)
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
