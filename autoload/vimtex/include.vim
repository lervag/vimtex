" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#include#expr() abort " {{{1
  call s:visited.timeout()
  let l:fname = substitute(v:fname, '^\s*\|\s*$', '', 'g')

  "
  " Check if v:fname matches exactly
  "
  if filereadable(l:fname)
    return s:visited.check(l:fname)
  endif

  "
  " Parse \include or \input style lines
  "
  let l:file = s:input(l:fname, 'tex')
  for l:candidate in [l:file, l:file . '.tex']
    if filereadable(l:candidate)
      return s:visited.check(l:candidate)
    endif
  endfor

  "
  " Parse \bibliography or \addbibresource
  "
  let l:candidate = s:input(l:fname, 'bib')
  if filereadable(l:candidate)
    return s:visited.check(l:candidate)
  endif

  "
  " Check if v:fname matches in $TEXINPUTS
  "
  let l:candidate = s:search_candidates_texinputs(l:fname)
  if !empty(l:candidate)
    return s:visited.check(l:candidate)
  endif

  "
  " Search for file with kpsewhich
  "
  if g:vimtex_include_search_enabled
    let l:candidate = s:search_candidates_kpsewhich(l:fname)
    if !empty(l:candidate)
      return s:visited.check(l:candidate)
    endif
  endif

  return s:visited.check(l:fname)
endfunction

" }}}1

function! s:input(fname, type) abort " {{{1
  let [l:lnum, l:cnum] = searchpos(g:vimtex#re#{a:type}_input, 'bcn', line('.'))
  if l:lnum == 0 | return a:fname | endif

  let l:cmd = vimtex#cmd#get_at(l:lnum, l:cnum)
  if empty(l:cmd) | return a:fname | endif

  let l:file = join(map(
        \   get(l:cmd, 'args', [{}]),
        \   "get(v:val, 'text', '')"),
        \ '')
  let l:file = substitute(l:file, '^\s*"\|"\s*$', '', 'g')
  let l:file = substitute(l:file, '\\space', '', 'g')

  if l:file[-3:] !=# a:type
    let l:file .= '.' . a:type
  endif

  return l:file
endfunction

" }}}1
function! s:search_candidates_texinputs(fname) abort " {{{1
  for l:suffix in [''] + split(&l:suffixesadd, ',')
    let l:candidates = glob(b:vimtex.root . '/**/' . a:fname . l:suffix, 0, 1)
    if !empty(l:candidates)
      return l:candidates[0]
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:search_candidates_kpsewhich(fname) abort " {{{1
  " Split input list on commas, and if applicable, ensure that the entry that
  " the cursor is on is placed first in the queue
  let l:files = split(a:fname, '\s*,\s*')
  let l:current = expand('<cword>')
  let l:index = index(l:files, l:current)
  if l:index >= 0
    call remove(l:files, l:index)
    let l:files = [l:current] + l:files
  endif

  " Add file extensions to create the final list of candidate files
  let l:candidates = []
  for l:file in l:files
    if !empty(fnamemodify(l:file, ':e'))
      call add(l:candidates, l:file)
    else
      call extend(l:candidates, map(split(&l:suffixesadd, ','), 'l:file . v:val'))
    endif
  endfor

  for l:file in l:candidates
    let l:candidate = vimtex#kpsewhich#find(l:file)
    if !empty(l:candidate) && filereadable(l:candidate) | return l:candidate | endif
  endfor

  return ''
endfunction

" }}}1

let s:visited = {
      \ 'time' : 0,
      \ 'list' : [],
      \}
function! s:visited.timeout() abort dict " {{{1
  if localtime() - self.time > 1
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
