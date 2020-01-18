" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#pulp#new() abort " {{{1
  return deepcopy(s:qf)
endfunction

" }}}1


let s:qf = {
      \ 'name' : 'LaTeX logfile using pulp',
      \}

function! s:qf.init(state) abort dict "{{{1
  if !executable('pulp')
    call vimtex#log#error('pulp is not executable!')
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
endfunction

function! s:qf.set_errorformat() abort dict "{{{1
  setlocal errorformat=
  setlocal errorformat+=%-G%*[^\ ])\ %.%#
  setlocal errorformat+=%-G%.%#For\ some\ reason%.%#
  setlocal errorformat+=%W%f:%l-%*[0-9?]:\ %*[^\ ]\ warning:\ %m
  setlocal errorformat+=%E%f:%l-%*[0-9?]:\ %*[^\ ]\ error:\ %m
  setlocal errorformat+=%W%f:%l-%*[0-9?]:\ %m
  setlocal errorformat+=%W%l-%*[0-9?]:\ %m
  setlocal errorformat+=%-G%.%#
endfunction

" }}}1
function! s:qf.addqflist(tex, log) abort dict " {{{1
  if empty(a:log) || !filereadable(a:log)
    call setqflist([])
    throw 'Vimtex: No log file found'
  endif

  let l:tmp = fnameescape(fnamemodify(a:log, ':r') . '.pulp')
  let l:log = fnameescape(a:log)

  silent call system(printf('pulp %s >%s', l:log, l:tmp))
  let self.errorformat_saved = &l:errorformat
  call self.set_errorformat()
  execute 'caddfile' l:tmp
  let &l:errorformat = self.errorformat_saved
  silent call system('rm ' . l:tmp)
endfunction

" }}}1
