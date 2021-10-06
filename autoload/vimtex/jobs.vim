" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#jobs#start(cmd) abort " {{{1
  return deepcopy(s:job).start(a:cmd)
endfunction

" }}}1
function! vimtex#jobs#run(cmd) abort " {{{1
  let l:job = vimtex#jobs#start(a:cmd)
  call l:job.wait()
endfunction

" }}}1
function! vimtex#jobs#capture(cmd) abort " {{{1
  let l:job = vimtex#jobs#start(a:cmd)
  return l:job.output()
endfunction

" }}}1


let s:job = {}

function! s:job.start(cmd) abort dict " {{{1
  if self.is_running() | return | endif

  let self.cmd_string = a:cmd
  let l:cmd = has('win32')
        \ ? 'cmd /s /c "' . self.cmd_string . '"'
        \ : ['sh', '-c', self.cmd_string]

  call self.exec(l:cmd)
  unlet self.start
  return self
endfunction

" }}}1
function! s:job.stop() abort dict " {{{1
  if self.is_running()
    call self.kill()
  endif
endfunction

" }}}1
function! s:job.is_running() abort dict " {{{1
  return self.get_pid() > 0
endfunction

" }}}1
function! s:job.wait() abort dict " {{{1
  for l:dummy in range(50)
    sleep 100m
    if !self.is_running()
      return
    endif
  endfor

  call self.stop()
endfunction

" }}}1

function! s:job.__pprint() abort dict " {{{1
  let l:pid = self.get_pid()

  return [
        \ ['pid', l:pid ? l:pid : '-'],
        \ ['cmd', self.cmd_string],
        \]
endfunction

" }}}1

if has('nvim')
  function! s:job.exec(cmd) abort dict " {{{1
    let selt._output = []

    let l:shell = {
          \ 'on_stdout': function('s:__callback'),
          \ 'on_stderr': function('s:__callback'),
          \ 'stdout_buffered': v:true,
          \ 'stderr_buffered': v:true,
          \ 'cwd': self.state.root,
          \ 'output': self._output,
          \}

    let self.job = jobstart(a:cmd, l:shell)
  endfunction

  function! s:__callback(id, data, event) abort dict
    call extend(self.output, a:data)
  endfunction

  " }}}1
  function! s:job.kill() abort dict " {{{1
    call jobstop(self.job)
  endfunction

  " }}}1
  function! s:job.get_pid() abort dict " {{{1
    try
      return jobpid(self.job)
    catch
      return 0
    endtry
  endfunction

  " }}}1
  function! s:job.output() abort dict " {{{1
    call self.wait()
    return self._output
  endfunction

  " }}}1
else
  function! s:job.exec(cmd) abort dict " {{{1
    let self.output = tempname()

    let l:options = {
          \ 'out_io': 'file',
          \ 'err_io': 'file',
          \ 'out_name': self.output,
          \ 'err_name': self.output,
          \ 'exit_cb': function('s:callback'),
          \ 'cwd': self.state.root,
          \}

    let self.job = job_start(a:cmd, l:options)
  endfunction

  " }}}1
  function! s:job.kill() abort dict " {{{1
    call job_stop(self.job)
  endfunction

  " }}}1
  function! s:job.get_pid() abort dict " {{{1
    try
      return get(job_info(self.job), 'process')
    catch
      return 0
    endtry
  endfunction

  " }}}1
  function! s:job.output() abort dict " {{{1
    call self.wait()
    return readfile(self.output)
  endfunction

  " }}}1
endif
