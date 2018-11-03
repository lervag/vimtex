" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#pos#set_cursor(...) abort " {{{1
  call cursor(s:parse_args(a:000))
endfunction

" }}}1
function! vimtex#pos#get_cursor() abort " {{{1
  return exists('*getcurpos') ? getcurpos() : getpos('.')
endfunction

" }}}1
function! vimtex#pos#get_cursor_line() abort " {{{1
  let l:pos = vimtex#pos#get_cursor()
  return l:pos[1]
endfunction

" }}}1

function! vimtex#pos#val(...) abort " {{{1
  let [l:lnum, l:cnum; l:rest] = s:parse_args(a:000)

  return 100000*l:lnum + min([l:cnum, 90000])
endfunction

" }}}1
function! vimtex#pos#next(...) abort " {{{1
  let [l:lnum, l:cnum; l:rest] = s:parse_args(a:000)

  return l:cnum < strlen(getline(l:lnum))
        \ ? [0, l:lnum, l:cnum+1, 0]
        \ : [0, l:lnum+1, 1, 0]
endfunction

" }}}1
function! vimtex#pos#prev(...) abort " {{{1
  let [l:lnum, l:cnum; l:rest] = s:parse_args(a:000)

  return l:cnum > 1
        \ ? [0, l:lnum, l:cnum-1, 0]
        \ : [0, max([l:lnum-1, 1]), strlen(getline(l:lnum-1)), 0]
endfunction

" }}}1
function! vimtex#pos#larger(pos1, pos2) abort " {{{1
  return vimtex#pos#val(a:pos1) > vimtex#pos#val(a:pos2)
endfunction

" }}}1
function! vimtex#pos#equal(p1, p2) abort " {{{1
  let l:pos1 = s:parse_args(a:p1)
  let l:pos2 = s:parse_args(a:p2)
  return l:pos1[:1] == l:pos2[:1]
endfunction

" }}}1
function! vimtex#pos#smaller(pos1, pos2) abort " {{{1
  return vimtex#pos#val(a:pos1) < vimtex#pos#val(a:pos2)
endfunction

" }}}1

function! s:parse_args(args) abort " {{{1
  "
  " The arguments should be in one of the following forms (when unpacked):
  "
  "   [lnum, cnum]
  "   [bufnum, lnum, cnum, ...]
  "   {'lnum' : lnum, 'cnum' : cnum}
  "

  if len(a:args) > 1
    return s:parse_args([a:args])
  elseif len(a:args) == 1
    if type(a:args[0]) == type({})
      return [get(a:args[0], 'lnum'), get(a:args[0], 'cnum')]
    else
      if len(a:args[0]) == 2
        return a:args[0]
      else
        return a:args[0][1:]
      endif
    endif
  else
    return a:args
  endif
endfunction

" }}}1
