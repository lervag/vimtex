" vimtex - LaTeX plugin for Vim
"
" CreatedBy:    Johannes Wienke (languitar@semipol.de)
" Maintainer:   Karl Yngve Lervåg
" Email:        karl.yngve@gmail.com
"

function! vimtex#qf#pplatex#new() " {{{1
  return deepcopy(s:qf)
endfunction

" }}}1


let s:qf = {
      \ 'name' : 'LaTeX logfile using pplatex',
      \}

function! s:qf.init(state) abort dict "{{{1
  if !executable('pplatex')
    call vimtex#log#error('pplatex is not executable!')
    throw 'vimtex: Requirements not met'
  endif

  " Automatically remove the -file-line-error option if we use the latexmk
  " backend (for convenience)
  if a:state.compiler.name ==# 'latexmk'
    let l:index = index(a:state.compiler.options, '-file-line-error')
    if l:index >= 0
      call remove(a:state.compiler.options, l:index)
    endif
  endif

  " Each new item starts with two asterics followed by the file, potentially
  " a line number and sometimes even the message itself is on the same line.
  " Please note that the trailing whitspaces in the error formats are
  " intentional as pplatex produces these.

  " Start of new items with file and line number, message on next line(s).
  setlocal errorformat=%E**\ Error\ \ \ in\ %f\\,\ Line\ %l:\ 
  setlocal errorformat+=%W**\ Warning\ in\ %f\\,\ Line\ %l:\ 
  setlocal errorformat+=%I**\ BadBox\ \ in\ %f\\,\ Line\ %l:\ 

  " Start of items with with file, line and message on the same line. There are
  " no BadBoxes reported this way.
  setlocal errorformat+=%E**\ Error\ \ \ in\ %f\\,\ Line\ %l:\ %m
  setlocal errorformat+=%W**\ Warning\ in\ %f\\,\ Line\ %l:\ %m

  " Start of new items with only a file.
  setlocal errorformat+=%E**\ Error\ \ \ in\ %f:\ 
  setlocal errorformat+=%W**\ Warning\ in\ %f:\ 
  setlocal errorformat+=%I**\ BadBox\ \ in\ %f:\ 

  " Start of items with with file and message on the same line. There are
  " no BadBoxes reported this way.
  setlocal errorformat+=%E**\ Error\ in\ %f:\ %m
  setlocal errorformat+=%W**\ Warning\ in\ %f:\ %m

  " Some errors are difficult even for pplatex
  setlocal errorformat+=%E**\ Error\ \ :\ 

  " Anything that starts with three spaces is part of the message from a
  " previously started multiline error item.
  setlocal errorformat+=%C\ \ \ %m\ on\ input\ line\ %l.
  setlocal errorformat+=%C\ \ \ %m

  " Items are terminated with two newlines.
  setlocal errorformat+=%-Z

  " Skip statistical results at the bottom of the output.
  setlocal errorformat+=%-GResult%.%#
  setlocal errorformat+=%-G
endfunction

function! s:qf.setqflist(tex, log, jump) abort dict " {{{1
  if empty(a:log) || !filereadable(a:log)
    call setqflist([])
    throw 'Vimtex: No log file found'
  endif

  let l:tmp = fnameescape(fnamemodify(a:log, ':r') . '.pplatex')
  let l:log = fnameescape(a:log)

  silent call system(printf('pplatex -i %s >%s', l:log, l:tmp))
  execute (a:jump ? 'cfile' : 'cgetfile') l:tmp
  silent call system('rm ' . l:tmp)

  try
    call setqflist(getqflist(), 'r', {'title': 'Vimtex errors (' . self.name . ')'})
  catch
  endtry
endfunction

" }}}1
