" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#_template#new(opts) abort " {{{1
  return extend(deepcopy(s:compiler), a:opts)
endfunction

" }}}1


let s:compiler = {
      \ 'name': '__template__',
      \ 'root': '',
      \ 'target': '',
      \ 'target_path': '',
      \ 'build_dir': '',
      \ 'continuous': 0,
      \ 'hooks': [],
      \ 'output': tempname(),
      \ 'status': -1,
      \}

function! s:compiler.new(options) abort dict " {{{1
  let l:compiler = extend(deepcopy(self), a:options)
  let l:backend = has('nvim') ? 'nvim' : 'jobs'
  call extend(l:compiler, deepcopy(s:compiler_{l:backend}))

  call l:compiler.__check_requirements()

  call s:build_dir_materialize(l:compiler)
  call l:compiler.__init()
  call s:build_dir_respect_envvar(l:compiler)

  " Remove init methods
  unlet l:compiler.new
  unlet l:compiler.__check_requirements
  unlet l:compiler.__init

  return l:compiler
endfunction

" }}}1

function! s:compiler.__check_requirements() abort dict " {{{1
endfunction

" }}}1
function! s:compiler.__init() abort dict " {{{1
endfunction

" }}}1
function! s:compiler.__build_cmd() abort dict " {{{1
  throw 'VimTeX: __build_cmd method must be defined!'
endfunction

" }}}1
function! s:compiler.__pprint() abort dict " {{{1
  let l:list = []

  if self.target_path !=# b:vimtex.tex
    call add(l:list, ['root', self.root])
    call add(l:list, ['target', self.target_path])
  endif

  if has_key(self, 'get_engine')
    call add(l:list, ['engine', self.get_engine()])
  endif

  if has_key(self, 'options')
    call add(l:list, ['options', self.options])
  endif

  if !empty(self.build_dir)
    call add(l:list, ['build_dir', self.build_dir])
  endif

  if has_key(self, '__pprint_append')
    call extend(l:list, self.__pprint_append())
  endif

  if has_key(self, 'job')
    let l:job = []
    call add(l:job, ['jobid', self.job])
    call add(l:job, ['output', self.output])
    call add(l:job, ['cmd', self.cmd])
    if self.continuous
      call add(l:job, ['pid', self.get_pid()])
    endif
    call add(l:list, ['process', l:job])
  endif

  return l:list
endfunction

" }}}1

function! s:compiler.clean(full) abort dict " {{{1
  let l:files = ['synctex.gz', 'toc', 'out', 'aux', 'log']

  " If a full clean is required
  if a:full
    call extend(l:files, ['pdf'])
  endif

  call map(l:files, {_, x -> printf('%s/%s.%s',
        \ self.build_dir, fnamemodify(self.target_path, ':t:r:S'), x)})
  call vimtex#process#run('rm -f ' . join(l:files))
  call vimtex#log#info('Compiler clean finished')
endfunction

" }}}1
function! s:compiler.start(...) abort dict " {{{1
  if self.is_running()
    call vimtex#log#warning(
          \ 'Compiler is already running for `' . self.target . "'")
    return
  endif

  " Create build dir if it does not exist
  " Note: This may need to create a hierarchical structure!
  if !empty(self.build_dir)
    let l:dirs = split(glob(self.root . '/**/*.tex'), '\n')
    call map(l:dirs, "fnamemodify(v:val, ':h')")
    call map(l:dirs, 'strpart(v:val, strlen(self.root) + 1)')
    call uniq(sort(filter(l:dirs, '!empty(v:val)')))
    call map(l:dirs, {_, x ->
          \ (vimtex#paths#is_abs(self.build_dir) ? '' : self.root . '/')
          \ . self.build_dir . '/' . x})
    call filter(l:dirs, '!isdirectory(v:val)')

    " Create the non-existing directories
    for l:dir in l:dirs
      call vimtex#log#warning(
            \ "build dir doesn't exist, it will be created: " . l:dir)
      call mkdir(l:dir, 'p')
    endfor
  endif

  call self.exec()
  let self.status = 1

  if self.continuous
    call vimtex#log#info('Compiler started in continuous mode'
          \ . (a:0 > 0 ? ' (single shot)' : ''))
  else
    call vimtex#log#info('Compiler started in background!')
  endif

  if exists('#User#VimtexEventCompileStarted')
    doautocmd <nomodeline> User VimtexEventCompileStarted
  endif
endfunction

" }}}1
function! s:compiler.stop() abort dict " {{{1
  if self.is_running()
    call self.kill()
    call vimtex#log#info('Compiler stopped (' . self.target . ')')
    if exists('#User#VimtexEventCompileStopped')
      doautocmd <nomodeline> User VimtexEventCompileStopped
    endif
  else
    call vimtex#log#warning(
          \ 'There is no process to stop (' . self.target . ')')
  endif

  let self.status = 0
endfunction

" }}}1
function! s:compiler.wait() abort dict " {{{1
  for l:dummy in range(50)
    sleep 100m
    if !self.is_running()
      return
    endif
  endfor

  call self.stop()
endfunction

" }}}1


let s:compiler_jobs = {}
function! s:compiler_jobs.exec() abort dict " {{{1
  let self.cmd = self.__build_cmd()
  let l:cmd = has('win32')
        \ ? 'cmd /s /c "' . self.cmd . '"'
        \ : ['sh', '-c', self.cmd]

  let l:options = {
        \ 'out_io' : 'file',
        \ 'err_io' : 'file',
        \ 'out_name' : self.output,
        \ 'err_name' : self.output,
        \}
  if self.continuous
    let l:options.out_io = 'pipe'
    let l:options.err_io = 'pipe'
    let l:options.out_cb = function('s:callback_continuous_output')
    let l:options.err_cb = function('s:callback_continuous_output')
    call writefile([], self.output, 'a')
  else
    let s:cb_target = self.target_path !=# b:vimtex.tex
          \ ? self.target_path : ''
    let l:options.exit_cb = function('s:callback')
  endif

  call vimtex#paths#pushd(self.root)
  let self.job = job_start(l:cmd, l:options)
  call vimtex#paths#popd()
endfunction

" }}}1
function! s:compiler_jobs.start_single() abort dict " {{{1
  let l:continuous = self.continuous
  let self.continuous = 0
  call self.start()
  let self.continuous = l:continuous
endfunction

" }}}1
function! s:compiler_jobs.kill() abort dict " {{{1
  call job_stop(self.job)
endfunction

" }}}1
function! s:compiler_jobs.is_running() abort dict " {{{1
  return has_key(self, 'job') && job_status(self.job) ==# 'run'
endfunction

" }}}1
function! s:compiler_jobs.get_pid() abort dict " {{{1
  return has_key(self, 'job')
        \ ? get(job_info(self.job), 'process') : 0
endfunction

" }}}1
function! s:callback(ch, msg) abort " {{{1
  call vimtex#compiler#callback(2 + vimtex#qf#inquire(s:cb_target))
endfunction

" }}}1
function! s:callback_continuous_output(channel, msg) abort " {{{1
  if exists('b:vimtex.compiler.output')
        \ && filewritable(b:vimtex.compiler.output)
    call writefile([a:msg], b:vimtex.compiler.output, 'aS')
  endif

  call s:check_callback(a:msg)

  try
    for l:Hook in get(get(get(b:, 'vimtex', {}), 'compiler', {}), 'hooks', [])
      call l:Hook(a:msg)
    endfor
  catch /E716/
  endtry
endfunction

" }}}1


let s:compiler_nvim = {}
function! s:compiler_nvim.exec() abort dict " {{{1
  let self.cmd = self.__build_cmd()
  let l:cmd = has('win32')
        \ ? 'cmd /s /c "' . self.cmd . '"'
        \ : ['sh', '-c', self.cmd]

  let l:shell = {
        \ 'on_stdout' : function('s:callback_nvim_output'),
        \ 'on_stderr' : function('s:callback_nvim_output'),
        \ 'cwd' : self.root,
        \ 'target' : self.target_path,
        \ 'output' : self.output,
        \}

  if !self.continuous
    let l:shell.on_exit = function('s:callback_nvim_exit')
  endif

  " Initialize output file
  try
    call writefile([], self.output)
  endtry

  let self.job = jobstart(l:cmd, l:shell)
endfunction

" }}}1
function! s:compiler_nvim.start_single() abort dict " {{{1
  let l:continuous = self.continuous
  let self.continuous = 0
  call self.start()
  let self.continuous = l:continuous
endfunction

" }}}1
function! s:compiler_nvim.kill() abort dict " {{{1
  call jobstop(self.job)
endfunction

" }}}1
function! s:compiler_nvim.is_running() abort dict " {{{1
  try
    let pid = jobpid(self.job)
    return 1
  catch
    return 0
  endtry
endfunction

" }}}1
function! s:compiler_nvim.get_pid() abort dict " {{{1
  try
    return jobpid(self.job)
  catch
    return 0
  endtry
endfunction

" }}}1
function! s:callback_nvim_output(id, data, event) abort dict " {{{1
  " Filter out unwanted newlines
  let l:data = split(substitute(join(a:data, 'QQ'), '^QQ\|QQ$', '', ''), 'QQ')

  if !empty(l:data) && filewritable(self.output)
    call writefile(l:data, self.output, 'a')
  endif

  call s:check_callback(
        \ get(filter(copy(a:data),
        \   {_, x -> x =~# '^vimtex_compiler_callback'}), -1, ''))

  try
    for l:Hook in get(get(get(b:, 'vimtex', {}), 'compiler', {}), 'hooks', [])
      call l:Hook(join(a:data, "\n"))
    endfor
  catch /E716/
  endtry
endfunction

" }}}1
function! s:callback_nvim_exit(id, data, event) abort dict " {{{1
  if !exists('b:vimtex.tex') | return | endif

  let l:target = self.target !=# b:vimtex.tex ? self.target : ''
  call vimtex#compiler#callback(2 + vimtex#qf#inquire(l:target))
endfunction

" }}}1


function! s:build_dir_materialize(compiler) abort " {{{1
  if type(a:compiler.build_dir) != v:t_func | return | endif

  try
    let a:compiler.build_dir = a:compiler.build_dir()
  catch
    call vimtex#log#error(
          \ 'Could not expand build_dir function!',
          \ v:exception)
    let a:compiler.build_dir = ''
  endtry
endfunction

" }}}1
function! s:build_dir_respect_envvar(compiler) abort " {{{1
  " Specifying the build_dir by environment variable should override the
  " current value.
  if empty($VIMTEX_OUTPUT_DIRECTORY) | return | endif

  if !empty(a:compiler.build_dir)
        \ && (a:compiler.build_dir !=# $VIMTEX_OUTPUT_DIRECTORY)
    call vimtex#log#warning(
          \ 'Setting VIMTEX_OUTPUT_DIRECTORY overrides build_dir!',
          \ 'Changed build_dir from: ' . a:compiler.build_dir,
          \ 'Changed build_dir to: ' . $VIMTEX_OUTPUT_DIRECTORY)
  endif

  let a:compiler.build_dir = $VIMTEX_OUTPUT_DIRECTORY
endfunction

" }}}1

function! s:check_callback(line) abort " {{{1
  if a:line ==# 'vimtex_compiler_callback_compiling'
    call vimtex#compiler#callback(1)
  elseif a:line ==# 'vimtex_compiler_callback_success'
    call vimtex#compiler#callback(2)
  elseif a:line ==# 'vimtex_compiler_callback_failure'
    call vimtex#compiler#callback(3)
  endif
endfunction

" }}}1
