set nocompatible
let &rtp = '~/.vim/bundle/vimtex,' . &rtp
let &rtp .= ',~/.vim/bundle/vimtex/after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:vimtex_fold_enabled = 1

function! s:do_profile(filename) " {{{1
  profile start test.log
  profile func *
  " profile file *

  execute 'silent edit' a:filename

  profile stop
endfunction

" }}}1
function! s:change_sid_numbers() " {{{1
  let l:lines = readfile('test.log')
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
  call writefile(l:new, 'test.log')
endfunction

" }}}1
function! s:filter(sections) " {{{1
  let l:lines = readfile('test.log')
  call filter(l:lines, 'v:val !~# ''FTtex''')
  call filter(l:lines, 'v:val !~# ''LoadFTPlugin''')

  let l:new = []
  for l:sec in a:sections
    call extend(l:new, s:get_section(l:sec, l:lines))
  endfor

  call writefile(l:new, 'test.log')
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
function! s:open() " {{{1
  source ~/.vim/vimrc
  silent edit test.log
endfunction

" }}}1
function! s:print() " {{{1
  for l:line in readfile('test.log')
    echo l:line
  endfor
  echo ''
  quit!
endfunction

" }}}1

call s:do_profile('~/sintef/papers/2017-08-23_rpt_spreading/paper-spreading.tex')
call s:change_sid_numbers()
call s:filter([
      \ 'FUNCTIONS SORTED ON SELF',
      \ 'FUNCTIONS SORTED ON TOTAL',
      \ '105()',
      \])
call s:print()
" call s:open()
