" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#include#expr() " {{{1
  "
  " First check if v:fname matches exactly
  "
  if filereadable(v:fname)
    return v:fname
  endif

  "
  " Next parse \include or \input style lines
  "
  let l:file = s:include()
  for l:suffix in [''] + split(&l:suffixesadd, ',')
    let l:candidate = l:file . l:suffix
    if filereadable(l:candidate)
      return l:candidate
    endif
  endfor

  "
  " Next search for file with kpsewhich
  "
  for l:file in s:vfname_split()
    for l:suffix in  reverse(split(&l:suffixesadd, ',')) + ['']
      let l:candidate = vimtex#kpsewhich#find(l:file . l:suffix)
      if filereadable(l:candidate)
        return l:candidate
      endif
    endfor
  endfor

  return v:fname
endfunction

" }}}1

function! s:include() " {{{1
  let [l:lnum, l:cnum] = searchpos(g:vimtex#re#tex_input, 'bcn', line('.'))
  if l:lnum == 0 | return '' | endif

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
function! s:vfname_split() " {{{1
  let l:files = []

  let l:current = expand('<cword>')
  if index(split(v:fname, ','), l:current) >= 0
    call add(l:files, l:current)
  endif

  return l:files + [v:fname]
endfunction

" }}}1
