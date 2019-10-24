" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#process#new(...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  return extend(deepcopy(s:process), l:opts)
endfunction

" }}}1
function! vimtex#process#run(cmd, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  let l:opts.cmd = a:cmd
  let l:process = vimtex#process#new(l:opts)

  return l:process.run()
endfunction

" }}}1
function! vimtex#process#capture(cmd) abort " {{{1
  return vimtex#process#run(a:cmd, {'capture': 1})
endfunction

" }}}1
function! vimtex#process#start(cmd, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  let l:opts.continuous = 1
  return vimtex#process#run(a:cmd, l:opts)
endfunction

" }}}1

let s:process = {
      \ 'cmd' : '',
      \ 'pid' : 0,
      \ 'background' : 1,
      \ 'continuous' : 0,
      \ 'output' : '',
      \ 'workdir' : '',
      \ 'silent' : 1,
      \ 'capture' : 0,
      \ 'result' : '',
      \}

function! s:process.run() abort dict " {{{1
  if self._do_not_run() | return | endif

  call self._pre_run()
  call self._prepare()
  call self._execute()
  call self._restore()
  call self._post_run()

  return self.capture ? self.result : self
endfunction

" }}}1
function! s:process.stop() abort dict " {{{1
  if !self.pid | return | endif

  let l:cmd = has('win32')
        \ ? 'taskkill /PID ' . self.pid . ' /T /F'
        \ : 'kill ' . self.pid
  call vimtex#process#run(l:cmd, {'background': 0})

  let self.pid = 0
endfunction

" }}}1
function! s:process.pprint_items() abort dict " {{{1
  let l:list = [
        \ ['pid', self.pid ? self.pid : '-'],
        \ ['cmd', get(self, 'prepared_cmd', self.cmd)],
        \]

  return l:list
endfunction

" }}}1

function! s:process._do_not_run() abort dict " {{{1
  if empty(self.cmd)
    call vimtex#log#warning('Can''t run empty command')
    return 1
  endif
  if self.pid
    call vimtex#log#warning('Process already running!')
    return 1
  endif

  return 0
endfunction

" }}}1
function! s:process._pre_run() abort dict " {{{1
  if self.capture
    let self.silent = 0
    let self.background = 0
  elseif empty(self.output) && self.background
    let self.output = 'null'
  endif

  call vimtex#paths#pushd(self.workdir)
endfunction

" }}}1
function! s:process._execute() abort dict " {{{1
  if self.capture
    let self.result = split(system(self.prepared_cmd), '\n')
  elseif self.silent
    silent call system(self.prepared_cmd)
  elseif self.background
    silent execute '!' . self.prepared_cmd
    if !has('gui_running')
      redraw!
    endif
  else
    execute '!' . self.prepared_cmd
  endif

  " Capture the pid if relevant
  if has_key(self, 'set_pid') && self.continuous
    call self.set_pid()
  endif
endfunction

" }}}1
function! s:process._post_run() abort dict " {{{1
  call vimtex#paths#popd()
endfunction

" }}}1

if has('win32')
  function! s:process._prepare() abort dict " {{{1
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

    let l:cmd = self.cmd

    if self.background
      if !empty(self.output)
        let l:cmd .= self.output ==# 'null'
              \ ? ' >nul'
              \ : ' >'  . self.output
        let l:cmd = 'cmd /s /c "' . l:cmd . '"'
      else
        let l:cmd = 'cmd /c "' . l:cmd . '"'
      endif
      let l:cmd = 'start /b ' . cmd
    endif

    if self.silent && self.output ==# 'null'
      let self.prepared_cmd = '"' . l:cmd . '"'
    else
      let self.prepared_cmd = l:cmd
    endif
  endfunction

  " }}}1
  function! s:process._restore() abort dict " {{{1
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
  function! s:process.get_pid() abort dict " {{{1
    let self.pid = 0
  endfunction

  " }}}1
else
  function! s:process._prepare() abort dict " {{{1
    let l:cmd = self.cmd

    if self.background
      if !empty(self.output)
        let l:cmd .= ' >'
              \ . (self.output ==# 'null'
              \    ? '/dev/null'
              \    : shellescape(self.output))
              \ . ' 2>&1'
      endif
      let l:cmd .= ' &'
    endif

    if !self.silent
      let l:cmd = escape(l:cmd, '%#')
    endif

    let self.prepared_cmd = l:cmd
  endfunction

  " }}}1
  function! s:process._restore() abort dict " {{{1
  endfunction

  " }}}1
  function! s:process.get_pid() abort dict " {{{1
    let self.pid = 0
  endfunction

  " }}}1
endif
