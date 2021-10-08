" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#jobs#neovim#new(cmd) abort " {{{1
  let l:job = deepcopy(s:job)
  let l:job.cmd = has('win32')
        \ ? 'cmd /s /c "' . a:cmd . '"'
        \ : ['sh', '-c', a:cmd]
  return l:job
endfunction

" }}}1
function! vimtex#jobs#neovim#run(cmd) abort " {{{1
  call s:neovim_{s:os}_run(a:cmd)
endfunction

" }}}1
function! vimtex#jobs#neovim#capture(cmd) abort " {{{1
  return s:neovim_{s:os}_capture(a:cmd)
endfunction

" }}}1

let s:os = has('win32') ? 'win' : 'unix'


let s:job = {}

function! s:job.start() abort dict " {{{1
  let l:options = {}

  if self.capture_output
    let self._output = []
    let l:options.on_stdout = function('s:__callback')
    let l:options.on_stderr = function('s:__callback')
    let l:options.stdout_buffered = v:true
    let l:options.stderr_buffered = v:true
    let l:options.output = self._output
  endif
  if !empty(self.cwd)
    let l:options.cwd = self.cwd
  endif

  let self.job = jobstart(self.cmd, l:options)

  return self
endfunction

function! s:__callback(id, data, event) abort dict
  call extend(self.output, a:data)
endfunction

" }}}1
function! s:job.stop() abort dict " {{{1
  call jobstop(self.job)
endfunction

" }}}1
function! s:job.wait() abort dict " {{{1
  let l:retvals = jobwait([self.job], self.wait_timeout)
  if empty(l:retvals) | return | endif
  let l:status = l:retvals[0]
  if l:status >= 0 | return | endif

  if l:status == -1
    call vimtex#log#warning('Job timed out while waiting!', join(self.cmd))
    call self.stop()
  elseif l:status == -2
    call vimtex#log#warning('Job interrupted!', self.cmd)
  endif
endfunction

" }}}1
function! s:job.is_running() abort dict " {{{1
  try
    let l:pid = jobpid(self.job)
    return l:pid > 0
  catch
    return v:false
  endtry
endfunction

" }}}1
function! s:job.get_pid() abort dict " {{{1
  if !has_key(self, 'pid')
    try
      let self.pid = jobpid(self.job)
    catch
      let self.pid = 0
    endtry
  endif

  return self.pid
endfunction

" }}}1
function! s:job.output() abort dict " {{{1
  call self.wait()

  if !self.capture_output | return [] | endif

  " Trim output
  while len(self._output) > 0
    if !empty(self._output[0]) | break | endif
    call remove(self._output, 0)
  endwhile
  while len(self._output) > 0
    if !empty(self._output[-1]) | break | endif
    call remove(self._output, -1)
  endwhile

  return self._output
endfunction

" }}}1

function! s:job.__pprint() abort dict " {{{1
  let l:pid = self.get_pid()

  return [
        \ ['pid', l:pid ? l:pid : '-'],
        \ ['cmd', self.cmd_raw],
        \]
endfunction

" }}}1


function! s:neovim_unix_run(cmd) abort " {{{1
  call system(['sh', '-c', a:cmd])
endfunction

" }}}1
function! s:neovim_unix_capture(cmd) abort " {{{1
  return systemlist(['sh', '-c', a:cmd])
endfunction

" }}}1

function! s:neovim_win_run(cmd) abort " {{{1
  let s:saveshell = [&shell, &shellcmdflag, &shellslash]
  set shell& shellcmdflag& shellslash&

  call system('cmd /s /c "' . a:cmd . '"')

  let [&shell, &shellcmdflag, &shellslash] = s:saveshell
endfunction

" }}}1
function! s:neovim_win_capture(cmd) abort " {{{1
  let s:saveshell = [&shell, &shellcmdflag, &shellslash]
  set shell& shellcmdflag& shellslash&

  let l:output = systemlist('cmd /s /c "' . a:cmd . '"')

  let [&shell, &shellcmdflag, &shellslash] = s:saveshell

  return l:output
endfunction

" }}}1
