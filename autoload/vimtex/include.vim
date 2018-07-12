" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#include#expr() " {{{1
  call s:visited.timeout()
  let l:fname = substitute(v:fname, '^\s*\|\s*$', '', 'g')

  "
  " First check if v:fname matches exactly
  "
  if filereadable(l:fname)
    return s:visited.check(l:fname)
  endif

  "
  " Next parse \include or \input style lines
  "
  let l:file = s:input(l:fname)
  for l:suffix in [''] + split(&l:suffixesadd, ',')
    let l:candidate = l:file . l:suffix
    if filereadable(l:candidate)
      return s:visited.check(l:candidate)
    endif
  endfor

  "
  " Next search for file with kpsewhich
  "
  for l:file in s:split(l:fname)
    for l:suffix in  reverse(split(&l:suffixesadd, ',')) + ['']
      let l:candidate = vimtex#kpsewhich#find(l:file . l:suffix)
      if filereadable(l:candidate)
        return s:visited.check(l:candidate)
      endif
    endfor
  endfor

  return s:visited.check(l:fname)
endfunction

" }}}1

function! s:input(fname) " {{{1
  let [l:lnum, l:cnum] = searchpos(g:vimtex#re#tex_input, 'bcn', line('.'))
  if l:lnum == 0 | return a:fname | endif

  let l:cmd = vimtex#cmd#get_at(l:lnum, l:cnum)
  let l:file = join(map(
        \   get(l:cmd, 'args', [{}]),
        \   "get(v:val, 'text', '')"),
        \ '')
  let l:file = substitute(l:file, '^\s*"\|"\s*$', '', 'g')
  let l:file = substitute(l:file, '\\space', '', 'g')

  return l:file
endfunction

" }}}1
function! s:split(fname) " {{{1
  let l:files = []

  let l:current = expand('<cword>')
  if index(split(a:fname, ','), l:current) >= 0
    call add(l:files, l:current)
  endif

  return l:files + [a:fname]
endfunction

" }}}1

let s:visited = {
      \ 'time' : 0,
      \ 'list' : [],
      \}
function! s:visited.timeout() abort dict " {{{1
  if localtime() - self.time > 1.0
    let self.time = localtime()
    let self.list = [expand('%:p')]
  endif
endfunction

" }}}1
function! s:visited.check(fname) abort dict " {{{1
  if index(self.list, fnamemodify(a:fname, ':p')) < 0
    call add(self.list, fnamemodify(a:fname, ':p'))
    return a:fname
  endif

  return ''
endfunction

" }}}1
