" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#jobs#start(cmd, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  return s:job.start(a:cmd, l:opts)
endfunction

" }}}1
function! vimtex#jobs#run(cmd, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  let l:job = s:job.start(a:cmd, l:opts)
  call l:job.wait()
endfunction

" }}}1
function! vimtex#jobs#capture(cmd, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  let l:opts.collect_output = v:true
  let l:job = s:job.start(a:cmd, l:opts)
  return l:job.output()
endfunction

" }}}1


let s:job = {}

function! s:job.start(cmd, opts) abort dict " {{{1
  let l:job = deepcopy(self)
  unlet l:job.start

  let l:job.cmd_raw = a:cmd
  let l:job.cwd = get(a:opts, 'cwd',
        \ exists('b:vimtex.root') ? b:vimtex.root : '')
  let l:job.wait_timeout = str2nr(get(a:opts, 'wait_timeout', 5000))
  let l:job.collect_output = get(a:opts, 'collect_output', v:false)

  let l:job.cmd = has('win32')
        \ ? 'cmd /s /c "' . l:job.cmd_raw . '"'
        \ : ['sh', '-c', l:job.cmd_raw]

  call l:job.exec()

  return l:job
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

if has('nvim')
  function! s:job.exec() abort dict " {{{1
    let l:options = {}

    if self.collect_output
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
function! s:job.is_running() abort dict " {{{1
  try
    let l:pid = jobpid(self.job)
    return l:pid > 0
  catch
    return v:false
  endtry
endfunction

" }}}1
  function! s:job.output() abort dict " {{{1
    call self.wait()

    if !self.collect_output | return [] | endif

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
else
  function! s:job.exec() abort dict " {{{1
    let l:options = {}

    if self.collect_output
      let self._output = tempname()
      let l:options.out_io = 'file'
      let l:options.err_io = 'file'
      let l:options.out_name = self._output
      let l:options.err_name = self._output
    else
      let l:options.in_io = 'null'
      let l:options.out_io = 'null'
      let l:options.err_io = 'null'
    endif
    if !empty(self.cwd)
      let l:options.cwd = self.cwd
    endif

    let self.job = job_start(self.cmd, l:options)
  endfunction

  " }}}1
  function! s:job.stop() abort dict " {{{1
    call job_stop(self.job)
    sleep 25m
  endfunction

  " }}}1
function! s:job.wait() abort dict " {{{1
  for l:dummy in range(self.wait_timeout/100)
    if !self.is_running() | return | endif
    sleep 100m
  endfor

  call vimtex#log#warning('Job timed out while waiting!', join(self.cmd))
  call self.stop()
endfunction

" }}}1
  function! s:job.get_pid() abort dict " {{{1
    if !has_key(self, 'pid')
      try
        return get(job_info(self.job), 'process')
      catch
        return 0
      endtry
    endif

    return self.pid
  endfunction

  " }}}1
function! s:job.is_running() abort dict " {{{1
  return job_status(self.job) ==# 'run'
endfunction

" }}}1
  function! s:job.output() abort dict " {{{1
    call self.wait()
    return self.collect_output ? readfile(self._output) : []
  endfunction

  " }}}1
endif
