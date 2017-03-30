" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#process#new() abort " {{{1
  return deepcopy(s:process)
endfunction

" }}}1
function! vimtex#process#run(cmd, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  let l:process = extend(deepcopy(s:process), l:opts)
  let l:process.cmd = a:cmd
  call l:process.run()

  return l:process
endfunction

" }}}1
function! vimtex#process#start(cmd, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  let l:process = extend(deepcopy(s:process), l:opts)
  let l:process.cmd = a:cmd
  let l:process.continuous = 1
  call l:process.run()

  return l:process
endfunction

" }}}1

let s:process = {
      \ 'cmd' : '',
      \ 'pid' : 0,
      \ 'background' : 1,
      \ 'continuous' : 0,
      \ 'silent' : 1,
      \ 'null' : 0,
      \ 'workdir' : '',
      \ 'use_system' : 0,
      \}

function! s:process.run() abort dict " {{{1
  if empty(self.cmd)
    echom 'Can''t run empty command'
    return
  endif
  if self.pid
    echom 'Process already running!'
    return
  endif

  " Change directory if wanted
  if !empty(self.workdir)
    let l:save_pwd = getcwd()
    execute 'lcd' fnameescape(self.workdir)
  endif

  " Set up command string based on the given system
  if has('win32')
    let l:cmd = self.build_cmd_win32()
    call self.win32_prepare()
  else
    let l:cmd = self.build_cmd_unix()
  endif

  " Run the command
  if self.use_system
    if self.silent && self.background
      silent call system(l:cmd)
    else
      call system(l:cmd)
    endif
  else
    if self.silent && self.background
      silent execute '!' . l:cmd
    else
      execute '!' . l:cmd
    endif

    if !has('gui_running')
      redraw!
    endif
  endif

  " Capture the pid if relevant
  if has_key(self, 'set_pid') && self.continuous
    call self.set_pid()
  endif

  " Restore Vim settings on windows systems
  if has('win32')
    call self.win32_restore()
  endif

  " Return to original working directory
  if !empty(self.workdir)
    execute 'lcd' fnameescape(l:save_pwd)
  endif
endfunction

" }}}1
function! s:process.kill() abort dict " {{{1
  if !self.pid | return | endif

  let l:cmd = has('win32')
        \ ? 'taskkill /PID ' . self.pid . ' /T /F'
        \ : 'kill ' . self.pid
  silent call system(l:cmd)

  let self.pid = 0
endfunction

" }}}1
function! s:process.get_pid() abort dict " {{{1
  if has('win32')
    " Not implemented
    return
  endif

  let self.pid = 0
endfunction

" }}}1

function! s:process.build_cmd_win32() abort dict " {{{1
  let l:cmd = self.cmd

  if self.null
    let l:cmd .= ' >nul'
  endif

  if self.background
    let l:cmd = 'start /b "' . cmd . '"'
  endif

  return l:cmd
endfunction

" }}}1
function! s:process.build_cmd_unix() abort dict " {{{1
  let l:cmd = self.cmd

  if self.null
    let l:cmd .= fnamemodify(&shell, ':t') ==# 'tcsh'
          \ ? ' >/dev/null |& cat'
          \ : ' >/dev/null 2>&1'
  endif

  if self.background
    let cmd .= ' &'
  endif

  return l:cmd
endfunction

" }}}1

function! s:process.win32_prepare() abort dict " {{{1
  if &shell !~? 'cmd'
    let self.win32_restore_shell = 1
    let self.win32_saved_shell = [
          \ &shell,
          \ &shellcmdflag,
          \ &shellxquote,
          \ &shellxescape,
          \ &shellquote,
          \ &shellpipe,
          \ &shellredir,
          \ &shellslash
          \]
    set shell& shellcmdflag& shellxquote& shellxescape&
    set shellquote& shellpipe& shellredir& shellslash&
  else
    let self.win32_restore_shell = 0
  endif
endfunction

" }}}1
function! s:process.win32_restore() abort dict " {{{1
  if self.win32_restore_shell
    let [   &shell,
          \ &shellcmdflag,
          \ &shellxquote,
          \ &shellxescape,
          \ &shellquote,
          \ &shellpipe,
          \ &shellredir,
          \ &shellslash] = self.win32_saved_shell
  endif
endfunction

" }}}1

function! s:process.pprint_items() abort dict " {{{1
  let l:list = [
        \ ['pid', self.pid ? self.pid : 'Not started'],
        \ ['cmd', self.cmd],
        \]

  call add(l:list, ['configuration', {
        \ 'background': self.background,
        \ 'continuous': self.continuous,
        \ 'silent': self.silent,
        \ 'null': self.null,
        \}])

  return l:list
endfunction

" }}}1

" vim: fdm=marker sw=2
