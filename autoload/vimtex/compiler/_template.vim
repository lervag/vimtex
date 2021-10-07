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
      \ 'build_dir': '',
      \ 'continuous': 0,
      \ 'hooks': [],
      \ 'output': tempname(),
      \ 'silence_next_callback': 0,
      \ 'state': {},
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

  if self.state.tex !=# b:vimtex.tex
    call add(l:list, ['root', self.state.root])
    call add(l:list, ['target', self.state.tex])
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
  if a:full
    call extend(l:files, ['pdf'])
  endif

  call map(l:files, {_, x -> printf('%s/%s.%s',
        \ self.build_dir, fnamemodify(self.state.tex, ':t:r:S'), x)})

  call vimtex#jobs#run('rm -f ' . join(l:files), {'cwd': self.state.root})
endfunction

" }}}1
function! s:compiler.start(...) abort dict " {{{1
  if self.is_running() | return | endif

  call self.create_build_dir()

  " Initialize output file
  call writefile([], self.output, 'a')

  " Prepare compile command
  let self.cmd = self.__build_cmd()
  let l:cmd = has('win32')
        \ ? 'cmd /s /c "' . self.cmd . '"'
        \ : ['sh', '-c', self.cmd]

  " Execute command and toggle status
  call self.exec(l:cmd)
  let self.status = 1

  if exists('#User#VimtexEventCompileStarted')
    doautocmd <nomodeline> User VimtexEventCompileStarted
  endif
endfunction

" }}}1
function! s:compiler.start_single() abort dict " {{{1
  let l:continuous = self.continuous
  let self.continuous = 0
  call self.start()
  let self.continuous = l:continuous
endfunction

" }}}1
function! s:compiler.stop() abort dict " {{{1
  if !self.is_running() | return | endif

  call self.kill()
  let self.status = 0

  if exists('#User#VimtexEventCompileStopped')
    doautocmd <nomodeline> User VimtexEventCompileStopped
  endif
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

function! s:compiler.create_build_dir() abort dict " {{{1
  " Create build dir if it does not exist
  " Note: This may need to create a hierarchical structure!
  if empty(self.build_dir) | return | endif

  if has_key(self.state, 'sources')
    let l:dirs = copy(self.state.sources)
    call filter(map(
          \ l:dirs, "fnamemodify(v:val, ':h')"),
          \ {_, x -> x !=# '.'})
  else
    let l:dirs = glob(self.state.root . '/**/*.tex', v:false, v:true)
    call map(l:dirs, "fnamemodify(v:val, ':h')")
    call map(l:dirs, 'strpart(v:val, strlen(self.state.root) + 1)')
  endif
  call uniq(sort(filter(l:dirs, '!empty(v:val)')))

  call map(l:dirs, {_, x ->
        \ (vimtex#paths#is_abs(self.build_dir) ? '' : self.state.root . '/')
        \ . self.build_dir . '/' . x})
  call filter(l:dirs, '!isdirectory(v:val)')
  if empty(l:dirs) | return | endif

  " Create the non-existing directories
  call vimtex#log#warning(["Creating build_dir directorie(s):"]
        \ + map(copy(l:dirs), {_, x -> '* ' . x}))

  unsilent echo 'DBG' l:dirs "\n"

  for l:dir in l:dirs
    call mkdir(l:dir, 'p')
  endfor
endfunction

" }}}1
function! s:compiler.remove_build_dir() abort dict " {{{1
  " Remove auxilliary output directories (only if they are empty)
  if empty(self.build_dir) | return | endif

  if vimtex#paths#is_abs(self.build_dir)
    let l:build_dir = self.build_dir
  else
    let l:build_dir = self.state.root . '/' . self.build_dir
  endif

  let l:tree = glob(l:build_dir . '/**/*', 0, 1)
  let l:files = filter(copy(l:tree), 'filereadable(v:val)')

  if empty(l:files)
    for l:dir in sort(l:tree) + [l:build_dir]
      call delete(l:dir, 'd')
    endfor
  endif
endfunction

" }}}1


let s:compiler_jobs = {}
function! s:compiler_jobs.exec(cmd) abort dict " {{{1
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
  else
    let s:cb_target = self.state.tex !=# b:vimtex.tex ? self.state.tex : ''
    let l:options.exit_cb = function('s:callback')
  endif

  call vimtex#paths#pushd(self.state.root)
  let self.job = job_start(a:cmd, l:options)
  call vimtex#paths#popd()
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
function! s:compiler_nvim.exec(cmd) abort dict " {{{1
  let l:shell = {
        \ 'on_stdout' : function('s:callback_nvim_output'),
        \ 'on_stderr' : function('s:callback_nvim_output'),
        \ 'cwd' : self.state.root,
        \ 'tex' : self.state.tex,
        \ 'output' : self.output,
        \}

  if !self.continuous
    let l:shell.on_exit = function('s:callback_nvim_exit')
  endif

  let self.job = jobstart(a:cmd, l:shell)
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

  let l:target = self.tex !=# b:vimtex.tex ? self.tex : ''
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
