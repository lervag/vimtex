" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#profile#open() " {{{1
  source ~/.vim/vimrc
  silent edit prof.log
endfunction

" }}}1
function! vimtex#profile#print() " {{{1
  for l:line in readfile('prof.log')
    echo l:line
  endfor
  echo ''
  quit!
endfunction

" }}}1

function! vimtex#profile#file(filename) " {{{1
  profile start prof.log
  profile func *

  execute 'silent edit' a:filename

  profile stop
  call s:fix_sids()
endfunction

" }}}1
function! vimtex#profile#command(cmd) " {{{1
  profile start prof.log
  profile func *

  execute a:cmd

  profile stop
  call s:fix_sids()
endfunction

" }}}1

function! vimtex#profile#filter(sections) " {{{1
  let l:lines = readfile('prof.log')
  call filter(l:lines, 'v:val !~# ''FTtex''')
  call filter(l:lines, 'v:val !~# ''LoadFTPlugin''')

  let l:new = []
  for l:sec in a:sections
    call extend(l:new, s:get_section(l:sec, l:lines))
  endfor

  call writefile(l:new, 'prof.log')
endfunction

" }}}1

function! s:fix_sids() " {{{1
  let l:lines = readfile('prof.log')
  let l:new = []
  for l:line in l:lines
    let l:sid = matchstr(l:line, '\v\<SNR\>\zs\d+\ze_')
    if !empty(l:sid)
      let l:filename = map(
            \ vimtex#util#command('scriptnames'),
            \ 'split(v:val, "\\v:=\\s+")[1]')[l:sid-1]
      if l:filename =~# 'vimtex'
        let l:filename = substitute(l:filename, '^.*autoload\/', '', '')
        let l:filename = substitute(l:filename, '\.vim$', '#s:', '')
        let l:filename = substitute(l:filename, '\/', '#', 'g')
      else
        let l:filename .= ':'
      endif
      call add(l:new, substitute(l:line, '\v\<SNR\>\d+_', l:filename, 'g'))
    else
      call add(l:new, l:line)
    endif
  endfor
  call writefile(l:new, 'prof.log')
endfunction

" }}}1
function! s:get_section(name, lines) " {{{1
  let l:active = 0
  let l:section = []
  for l:line in a:lines
    if l:active
      if l:line =~# '^FUNCTION'
        call add(l:section, '')
        break
      else
        call add(l:section, l:line)
      endif
    endif

    if l:line =~# a:name
      call add(l:section, l:line)
      let l:active = 1
    endif
  endfor

  if l:active
    call add(l:section, ' ')
  endif

  return l:section
endfunction

" }}}1
