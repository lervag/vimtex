" vimtex - LaTeX plugin for Vim
"
" Maintainer:   Karl Yngve Lervåg
" Email:        karl.yngve@gmail.com
" Initial work: Johannes Wienke
" Email:        languitar@semipol.de
"

function! vimtex#qf#pplatex#new() " {{{1
  return deepcopy(s:qf)
endfunction

" }}}1


let s:qf = {
      \ 'name' : 'LaTeX logfile using pplatex',
      \}

function! s:qf.init() abort dict "{{{1
  " Each new item starts with two asterics followed by the file,
  " potentially a line number and sometimes even the message itself is on the
  " same line. Please note that the trailing whitspaces in the error formats
  " are intentional as pplatex produces these.

  " Start of new items with file and line number, message on next line(s).
  setlocal errorformat=%E**\ Error\ \ \ in\ %f\\,\ Line\ %l:\ 
  setlocal errorformat+=%W**\ Warning\ in\ %f\\,\ Line\ %l:\ 
  setlocal errorformat+=%I**\ BadBox\ \ in\ %f\\,\ Line\ %l:\ 

  " Start of new items with only a file.
  setlocal errorformat+=%E**\ Error\ \ \ in\ %f:\ 
  setlocal errorformat+=%W**\ Warning\ in\ %f:\ 
  setlocal errorformat+=%I**\ BadBox\ \ in\ %f:\ 

  " Start of items with with file and message on the same line. There are
  " no BadBoxes reported this way.
  setlocal errorformat+=**\ Error\ in\ %f:\ %m
  setlocal errorformat+=**\ Warning\ in\ %f:\ %m

  " Anything that starts with three spaces is part of the message from a
  " previously started multiline error item.
  setlocal errorformat+=%C\ \ \ %m

  " Items are terminated with two newlines.
  setlocal errorformat+=%-Z

  " Skip statistical results at the bottom of the output.
  setlocal errorformat+=%-GResult%.%#
  setlocal errorformat+=%-G
endfunction

function! s:qf.setqflist(base, jump) abort dict "{{{1
  if empty(a:base)
    let l:log = b:vimtex.log()
  else
    let l:log = fnamemodify(a:base, ':r') . '.log'
  endif

  if empty(l:log)
    call setqflist([])
    throw 'Vimtex: No log file found'
  endif

  execute "setlocal" "makeprg=pplatex\\ -i\\ " . l:log

  if a:jump
    silent make l:log %:S
  else
    silent make! l:log %:S
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
