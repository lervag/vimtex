" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#latexmk#init(options) abort " {{{1
  let l:compiler = deepcopy(s:compiler)

  call l:compiler.init(extend(a:options,
        \ get(g:, 'vimtex_compiler_latexmk', {}), 'keep'))

  return l:compiler
endfunction

" }}}1
function! vimtex#compiler#latexmk#wrap_option(name, value) abort " {{{1
  if has('win32')
    return ' -e "$' . a:name . ' = ''' . a:value . '''"'
  else
    return ' -e ''$' . a:name . ' = "' . a:value . '"'''
  endif
endfunction

"}}}1

let s:compiler = {
      \ 'name' : 'latexmk',
      \ 'executable' : 'latexmk',
      \ 'backend' : has('nvim') ? 'nvim'
      \                         : v:version >= 800 ? 'jobs' : 'process',
      \ 'root' : '',
      \ 'target' : '',
      \ 'target_path' : '',
      \ 'background' : 1,
      \ 'build_dir' : '',
      \ 'callback' : 1,
      \ 'continuous' : 1,
      \ 'output' : tempname(),
      \ 'options' : [
      \   '-verbose',
      \   '-pdf',
      \   '-file-line-error',
      \   '-synctex=1',
      \   '-interaction=nonstopmode',
      \ ],
      \ 'shell' : fnamemodify(&shell, ':t'),
      \}

function! s:compiler.init(options) abort dict " {{{1
  call extend(self, a:options)

  call self.init_check_requirements()
  call self.init_build_dir_option()

  call extend(self, deepcopy(s:compiler_{self.backend}))

  " Continuous processes can't run in foreground, neither can processes run
  " with the new jobs api
  if self.continuous || self.backend !=# 'process'
    let self.background = 1
  endif

  if self.backend !=# 'process'
    let self.shell = 'sh'
  endif
endfunction

" }}}1
function! s:compiler.init_build_dir_option() abort dict " {{{1
  "
  " Check if .latexmkrc sets the build_dir - if so this should be respected
  "

  let l:pattern = '^\s*\$out_dir\s*=\s*[''"]\(.\+\)[''"]\s*;\?\s*$'
  let l:files = [
        \ self.root . '/latexmkrc',
        \ self.root . '/.latexmkrc',
        \ fnamemodify('~/.latexmkrc', ':p'),
        \ expand('$XDG_CONFIG_HOME/latexmk/latexmkrc'),
        \]

  for l:file in l:files
    if filereadable(l:file)
      let l:out_dir = matchlist(readfile(l:file), l:pattern)
      if len(l:out_dir) > 1
        if !empty(self.build_dir)
          call vimtex#log#warning(
                \ 'Setting out_dir from latexmkrc overrides build_dir!',
                \ 'Changed build_dir from: ' . self.build_dir,
                \ 'Changed build_dir to: ' . l:out_dir[1])
        endif
        let self.build_dir = l:out_dir[1]
        return
      endif
    endif
  endfor
endfunction

" }}}1
function! s:compiler.init_check_requirements() abort dict " {{{1
  " Check option validity
  if self.callback
    if !(has('clientserver') || has('nvim'))
      let self.callback = 0
      call vimtex#log#warning(
            \ 'Can''t use callbacks without +clientserver',
            \ 'Callback option has been disabled.')
    endif
  endif

  " Check for required executables
  let l:required = [self.executable]
  if self.continuous && !has('win32')
    let l:required += ['pgrep']
  endif
  let l:missing = filter(l:required, '!executable(v:val)')

  " Disable latexmk if required programs are missing
  if len(l:missing) > 0
    for l:cmd in l:missing
      call vimtex#log#warning(l:cmd . ' is not executable')
    endfor
    throw 'vimtex: Requirements not met'
  endif
endfunction

" }}}1

function! s:compiler.build_cmd() abort dict " {{{1
  if has('win32')
    let l:cmd = 'set max_print_line=2000 & ' . self.executable
  else
    if self.shell ==# 'fish'
      let l:cmd = 'set max_print_line 2000; and ' . self.executable
    else
      let l:cmd = 'max_print_line=2000 ' . self.executable
    endif
  endif

  for l:opt in self.options
    let l:cmd .= ' ' . l:opt
  endfor

  if !empty(self.engine)
    let l:cmd .= ' ' . self.engine
  endif

  if !empty(self.build_dir)
    let l:cmd .= ' -outdir=' . self.build_dir
  endif

  if self.continuous
    let l:cmd .= ' -pvc'

    " Set viewer options
    if !get(g:, 'vimtex_view_automatic', 1)
          \ || get(get(b:vimtex, 'viewer', {}), 'xwin_id') > 0
          \ || get(s:, 'silence_next_callback', 0)
      let l:cmd .= ' -view=none'
    elseif g:vimtex_view_enabled
          \ && has_key(b:vimtex.viewer, 'latexmk_append_argument')
      let l:cmd .= b:vimtex.viewer.latexmk_append_argument()
    endif

    if self.callback
      if empty(v:servername)
        call vimtex#log#warning('Can''t use callbacks with empty v:servername')
      else
        " Some notes:
        " - We excape the v:servername because this seems necessary on Windows
        "   for neovim, see e.g. Github Issue #877
        for [l:opt, l:val] in items({'success_cmd' : 1, 'failure_cmd' : 0})
          let l:callback = has('win32')
                \   ? '"vimtex#compiler#callback(' . l:val . ')"'
                \   : '\"vimtex\#compiler\#callback(' . l:val . ')\"'
          let l:func = vimtex#util#shellescape('""')
                \ . g:vimtex_compiler_progname
                \ . vimtex#util#shellescape('""')
                \ . ' --servername ' . vimtex#util#shellescape(v:servername)
                \ . ' --remote-expr ' . l:callback
          let l:cmd .= vimtex#compiler#latexmk#wrap_option(l:opt, l:func)
        endfor
      endif
    endif
  endif

  return l:cmd . ' ' . vimtex#util#shellescape(self.target)
endfunction

" }}}1
function! s:compiler.cleanup() abort dict " {{{1
  if self.is_running()
    call self.kill()
  endif
endfunction

" }}}1
function! s:compiler.pprint_items() abort dict " {{{1
  let l:configuration = [
        \ ['continuous', self.continuous],
        \ ['callback', self.callback],
        \]

  if self.backend ==# 'process' && !self.continuous
    call add(l:configuration, ['background', self.background])
  endif

  if !empty(self.build_dir)
    call add(l:configuration, ['build_dir', self.build_dir])
  endif
  call add(l:configuration, ['latexmk options', self.options])

  let l:list = []
  call add(l:list, ['backend', self.backend])
  if self.executable !=# s:compiler.executable
    call add(l:list, ['latexmk executable', self.executable])
  endif
  if self.background
    call add(l:list, ['output', self.output])
  endif

  if self.target_path !=# b:vimtex.tex
    call add(l:list, ['root', self.root])
    call add(l:list, ['target', self.target_path])
  endif

  call add(l:list, ['configuration', l:configuration])

  if has_key(self, 'process')
    call add(l:list, ['process', self.process])
  endif

  if has_key(self, 'job')
    if self.continuous
      if self.backend ==# 'jobs'
        call add(l:list, ['job', self.job])
      else
        call add(l:list, ['pid', self.get_pid()])
      endif
    endif
    call add(l:list, ['cmd', self.cmd])
  endif

  return l:list
endfunction

" }}}1

function! s:compiler.clean(full) abort dict " {{{1
  let l:restart = self.is_running()
  if l:restart
    call self.stop()
  endif

  " Define and run the latexmk clean cmd
  let l:cmd = (has('win32')
        \   ? 'cd /D "' . self.root . '" & '
        \   : 'cd ' . vimtex#util#shellescape(self.root) . '; ')
        \ . self.executable . ' ' . (a:full ? '-C ' : '-c ')
  if !empty(self.build_dir)
    let l:cmd .= printf(' -outdir=%s ', self.build_dir)
  endif
  let l:cmd .= vimtex#util#shellescape(self.target)
  call vimtex#process#run(l:cmd)

  call vimtex#log#info('Compiler clean finished' . (a:full ? ' (full)' : ''))

  if l:restart
    let self.silent_next_callback = 1
    silent call self.start()
  endif
endfunction

" }}}1
function! s:compiler.start(...) abort dict " {{{1
  if self.is_running()
    call vimtex#log#warning(
          \ 'Compiler is already running for `' . self.target . "'")
    return
  endif

  "
  " Create build dir if it does not exist
  "
  if !empty(self.build_dir)
    let l:dirs = split(glob(self.root . '/**/*.tex'), '\n')
    call map(l:dirs, 'fnamemodify(v:val, '':h'')')
    call map(l:dirs, 'strpart(v:val, strlen(self.root) + 1)')
    call vimtex#util#uniq(sort(filter(l:dirs, "v:val !=# ''")))
    call map(l:dirs, "self.root . '/' . self.build_dir . '/' . v:val")
    call filter(l:dirs, '!isdirectory(v:val)')

    " Create the non-existing directories
    for l:dir in l:dirs
      call mkdir(l:dir, 'p')
    endfor
  endif

  call self.exec()

  if self.continuous
    call vimtex#log#info('Compiler started in continuous mode'
          \ . (a:0 > 0 ? ' (single shot)' : ''))
    if exists('#User#VimtexEventCompileStarted')
      doautocmd User VimtexEventCompileStarted
    endif
  else
    if self.background
      call vimtex#log#info('Compiler started in background!')
    else
      call vimtex#compiler#callback(!vimtex#qf#inquire(self.target))
    endif
  endif
endfunction

" }}}1
function! s:compiler.stop() abort dict " {{{1
  if self.is_running()
    call self.kill()
    call vimtex#log#info('Compiler stopped (' . self.target . ')')
    if exists('#User#VimtexEventCompileStopped')
      doautocmd User VimtexEventCompileStopped
    endif
  else
    call vimtex#log#warning(
          \ 'There is not process to stop (' . self.target . ')')
  endif
endfunction

" }}}1

let s:compiler_process = {}
function! s:compiler_process.exec() abort dict " {{{1
  let l:process = vimtex#process#new()
  let l:process.name = 'latexmk'
  let l:process.continuous = self.continuous
  let l:process.background = self.background
  let l:process.workdir = self.root
  let l:process.output = self.output
  let l:process.cmd = self.build_cmd()

  if l:process.continuous
    if has('win32')
      " Not implemented
    else
      for l:pid in split(system(
            \ 'pgrep -f "^[^ ]*perl.*latexmk.*' . self.target . '"'), "\n")
        let l:path = resolve('/proc/' . l:pid . '/cwd') . '/' . self.target
        if l:path ==# self.target_path
          let l:process.pid = str2nr(l:pid)
          break
        endif
      endfor
    endif
  endif

  function! l:process.set_pid() abort dict " {{{2
    if has('win32')
      let pidcmd = 'tasklist /fi "imagename eq latexmk.exe"'
      let pidinfo = split(system(pidcmd), '\n')[-1]
      let self.pid = str2nr(split(pidinfo,'\s\+')[1])
    else
      let self.pid = str2nr(system('pgrep -nf "^[^ ]*perl.*latexmk"')[:-2])
    endif

    return self.pid
  endfunction

  " }}}2

  let self.process = l:process
  call self.process.run()
endfunction

" }}}1
function! s:compiler_process.start_single() abort dict " {{{1
  let l:continuous = self.continuous
  let self.continuous = self.background && self.callback && !empty(v:servername)

  if self.continuous
    let g:vimtex_compiler_callback_hooks += ['VimtexSSCallback']
    function! VimtexSSCallback(status)
      silent call vimtex#compiler#stop()
      call remove(g:vimtex_compiler_callback_hooks, 'VimtexSSCallback')
    endfunction
  endif

  call self.start(1)
  let self.continuous = l:continuous
endfunction

" }}}1
function! s:compiler_process.is_running() abort dict " {{{1
  return exists('self.process.pid') && self.process.pid > 0
endfunction

" }}}1
function! s:compiler_process.kill() abort dict " {{{1
  call self.process.stop()
endfunction

" }}}1
function! s:compiler_process.get_pid() abort dict " {{{1
  return has_key(self, 'process') ? self.process.pid : 0
endfunction

" }}}1

let s:compiler_jobs = {}
function! s:compiler_jobs.exec() abort dict " {{{1
  let self.cmd = self.build_cmd()
  let l:cmd = has('win32')
        \ ? 'cmd /s /c "' . self.cmd . '"'
        \ : ['sh', '-c', self.cmd]
  let l:options = {
        \ 'out_io' : 'file',
        \ 'err_io' : 'file',
        \ 'out_name' : self.output,
        \ 'err_name' : self.output,
        \}

  if !self.continuous
    let s:cb_target = self.target_path !=# b:vimtex.tex
          \ ? self.target_path : ''
    let l:options.exit_cb = function('s:callback')
  endif

  if !empty(self.root)
    let l:save_pwd = getcwd()
    execute 'lcd' fnameescape(self.root)
  endif
  let self.job = job_start(l:cmd, l:options)
  if !empty(self.root)
    execute 'lcd' fnameescape(l:save_pwd)
  endif
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
  call vimtex#compiler#callback(!vimtex#qf#inquire(s:cb_target))
endfunction

" }}}1

let s:compiler_nvim = {}
function! s:compiler_nvim.exec() abort dict " {{{1
  let self.cmd = self.build_cmd()
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
  if !empty(a:data)
    call writefile(filter(a:data, '!empty(v:val)'), self.output, 'a')
  endif
endfunction

" }}}1
function! s:callback_nvim_exit(id, data, event) abort dict " {{{1
  let l:target = self.target !=# b:vimtex.tex ? self.target : ''
  call vimtex#compiler#callback(!vimtex#qf#inquire(l:target))
endfunction

" }}}1

" vim: fdm=marker sw=2
