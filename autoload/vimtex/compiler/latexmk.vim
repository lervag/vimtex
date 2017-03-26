" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#latexmk#init(...) abort " {{{1
  let l:options = extend(a:0 > 0 ? a:1 : {},
        \ get(g:, 'vimtex_compiler_latexmk', {}), 'keep')

  " Create copy of the compiler object and extend with user settings
  let l:compiler = extend(deepcopy(s:compiler), l:options)
  call l:compiler.init_check_requirements()
  call l:compiler.init_build_dir_option()
  call l:compiler.init_process()
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
      \ 'root' : b:vimtex.root,
      \ 'target' : b:vimtex.base,
      \ 'target_full_path' : b:vimtex.tex,
      \ 'background' : 0,
      \ 'build_dir' : '',
      \ 'callback' : 1,
      \ 'continuous' : 1,
      \ 'options' : [
      \   '-verbose',
      \   '-pdf',
      \   '-file-line-error',
      \   '-synctex=1',
      \   '-interaction=nonstopmode',
      \ ],
      \}

function! s:compiler.init_check_requirements() abort dict " {{{1
  " Check option validity
  if self.callback
        \ && !(has('clientserver') || has('nvim'))
    let self.callback = 0
    call vimtex#echo#warning('Can''t use callbacks without +clientserver')
    call vimtex#echo#wait()
  endif

  " Check for required executables
  let l:required = ['latexmk']
  if self.continuous && !has('win32')
    let l:required += ['pgrep']
  endif
  let l:missing = filter(l:required, '!executable(v:val)')

  " Disable latexmk if required programs are missing
  if len(l:missing) > 0
    for l:cmd in l:missing
      call vimtex#echo#warning(l:cmd . ' is not executable')
    endfor
    throw 'vimtex: Requirements not met'
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
        \]

  for l:file in l:files
    if filereadable(l:file)
      let l:out_dir = matchlist(readfile(l:file), l:pattern)
      if len(l:out_dir) > 1
        if !empty(self.build_dir)
          call vimtex#echo#warning(
                \ 'compiler.build_dir changed to: ' . self.build_dir)
          call vimtex#echo#wait()
        endif
        let self.build_dir = l:out_dir[1]
        return
      endif
    endif
  endfor
endfunction

" }}}1
function! s:compiler.init_process() abort dict " {{{1
  let l:process = vimtex#process#new()
  let l:process.continuous = self.continuous
  let l:process.name = 'latexmk'

  if !self.continuous && !self.background
    let l:process.background = 0
    let l:process.silent = 0
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

  let l:process.cmd = self.build_cmd()

  if self.continuous
    if has('win32')
      " Not implemented
      return
    else
      for l:pid in split(system(
            \ 'pgrep -f "^[^ ]*perl.*latexmk.*' . self.target . '"'), "\n")
        let l:path = resolve('/proc/' . l:pid . '/cwd') . '/' . self.target
        if l:path ==# self.target_full_path
          let l:process.pid = str2nr(l:pid)
          let l:process.is_running = 1
          break
        endif
      endfor
    endif
  endif

  let self.process = l:process
endfunction

" }}}1
function! s:compiler.start() abort dict " {{{1
  if self.is_running()
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'already running for `' . self.target . "'"]])
    return
  endif

  call self.create_build_dir()
  call self.process.run()

  if self.continuous
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'started continuous mode']])
    if exists('#User#VimtexEventCompileStarted')
      doautocmd User VimtexEventCompileStarted
    endif
  else
    if self.background
      call vimtex#echo#status(['latexmk compile: ',
            \ ['VimtexSuccess', 'started in background!']])
    else
      call vimtex#echo#status(['latexmk compile: ',
            \ vimtex#compiler#errors_inquire(self.file)
            \   ? ['VimtexWarning', 'fail']
            \   : ['VimtexSuccess', 'success']])
    endif
  endif
endfunction

" }}}1
function! s:compiler.start_single(verbose) abort dict " {{{1
  if self.is_running() | return | endif

  if exists('v:servername')
    let l:opts = {
          \ 'continuous' : 1,
          \ 'background' : 1,
          \ 'callback' : 1,
          \}
    let g:vimtex_compiler_callback_hooks = ['VimtexSSCallback']
    function! VimtexSingleShotWithCallback(status)
      silent call vimtex#compiler#stop()
      call remove(g:vimtex_compiler_callback_hooks, 'VimtexSSCallback')
    endfunction
  else
    let l:opts = {
          \ 'continuous' : 0,
          \ 'background' : self.background,
          \ 'callback' : 0,
          \}
  endif

  let l:process = extend(vimtex#process#new(), l:opts)
  let l:process.cmd = self.build_cmd(l:opts)
  call l:process.run()
endfunction

" }}}1
function! s:compiler.stop() abort dict " {{{1
  if self.is_running()
    call self.process.kill()
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'stopped (' . self.target . ')']])
    if exists('#User#VimtexEventCompileStopped')
      doautocmd User VimtexEventCompileStopped
    endif
  else
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'no process to stop (' . self.target . ')']])
  endif
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
        \ . 'latexmk ' . (a:full ? '-C ' : '-c ')
  if !empty(self.build_dir)
    let l:cmd .= ' -outdir=' . self.build_dir
  endif
  let l:cmd .= vimtex#util#shellescape(self.target)
  call vimtex#process#run(l:cmd)

  call vimtex#echo#status(['latexmk clean: ',
        \ ['VimtexSuccess', 'finished' . (a:full ? ' (full)' : '')]])

  if l:restart
    let self.silent_next_callback = 1
    silent call self.start()
  endif
endfunction

" }}}1
function! s:compiler.is_running() abort dict " {{{1
  return self.process.pid > 0
endfunction

" }}}1
function! s:compiler.build_cmd(...) abort dict " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}

  if has('win32')
    let l:cmd  = 'cd /D "' . self.root . '"'
    let l:cmd .= ' && set max_print_line=2000 & latexmk'
    let l:shellslash = &shellslash
    set noshellslash
  else
    let l:cmd  = 'cd ' . vimtex#util#shellescape(self.root)
    if fnamemodify(&shell, ':t') ==# 'fish'
      let l:cmd .= '; and set max_print_line 2000; and latexmk'
    elseif fnamemodify(&shell, ':t') ==# 'tcsh'
      let l:cmd .= ' && set max_print_line=2000 && latexmk'
    else
      let l:cmd .= ' && max_print_line=2000 latexmk'
    endif
  endif

  for l:opt in get(l:opts, 'options', self.options)
    let l:cmd .= ' ' . l:opt
  endfor

  if !empty(b:vimtex.engine)
    let l:cmd .= ' ' . b:vimtex.engine
  endif

  let l:build_dir = get(l:opts, 'build_dir', self.build_dir)
  if !empty(l:build_dir)
    let l:cmd .= ' -outdir=' . l:build_dir
  endif

  if get(l:opts, 'continuous', self.continuous)
    let l:cmd .= ' -pvc'

    " Set viewer options
    if !get(g:, 'vimtex_view_automatic', 1)
          \ || get(get(b:vimtex, 'viewer', {}), 'xwin_id', 0) > 0
          \ || get(s:, 'silence_next_callback', 0)
      let l:cmd .= ' -view=none'
    elseif g:vimtex_view_enabled
          \ && has_key(b:vimtex.viewer, 'latexmk_append_argument')
      let l:cmd .= b:vimtex.viewer.latexmk_append_argument()
    endif
  endif

  if get(l:opts, 'callback', self.callback) && exists('v:servername')
    let l:cb = shellescape('""') . g:vimtex_compiler_progname . shellescape('""')
          \ . ' --servername ' . v:servername
    let l:cmd .= vimtex#compiler#latexmk#wrap_option('success_cmd',
          \ l:cb . ' --remote-expr \"vimtex\#compiler\#callback(1)\"')
    let l:cmd .= vimtex#compiler#latexmk#wrap_option('failure_cmd',
          \ l:cb . ' --remote-expr \"vimtex\#compiler\#callback(0)\"')
  endif

  let l:cmd .= ' ' . vimtex#util#shellescape(self.target)

  if get(l:opts, 'continuous', self.continuous)
        \ || get(l:opts, 'background', self.background)
    let l:tmp = tempname()

    if has('win32')
      let l:cmd .= ' >'  . l:tmp
      let l:cmd = 'cmd /s /c "' . l:cmd . '"'
    elseif fnamemodify(&shell, ':t') ==# 'tcsh'
      let l:cmd .= ' >' . l:tmp . ' |& cat'
    else
      let l:cmd .= ' >' . l:tmp . ' 2>&1'
    endif

    let self.output = l:tmp
  elseif has('win32')
    let l:cmd = 'cmd /c "' . l:cmd . '"'
  endif

  if has('win32')
    let &shellslash = l:shellslash
  endif

  return l:cmd
endfunction

" }}}1
function! s:compiler.create_build_dir() abort dict " {{{1
  if empty(self.build_dir) | return | endif

  " First create list of necessary directories
  let l:dirs = split(glob(self.root . '/**/*.tex'), '\n')
  call map(l:dirs, 'fnamemodify(v:val, '':h'')')
  call map(l:dirs, 'strpart(v:val, strlen(self.root) + 1)')
  call vimtex#util#uniq(sort(filter(l:dirs, "v:val !=# ''")))
  call map(l:dirs,
        \ "self.root . '/' . self.build_dir . '/' . v:val")
  call filter(l:dirs, '!isdirectory(v:val)')

  " Create the non-existing directories
  for l:dir in l:dirs
    call mkdir(l:dir, 'p')
  endfor
endfunction

" }}}1
function! s:compiler.pprint_items() abort dict " {{{1
  let l:configuration = [
        \ ['continuous', self.continuous],
        \ ['callback', self.callback],
        \]
  if !self.continuous
    call add(l:configuration, ['background', self.background])
  endif
  if !empty(self.build_dir)
    call add(l:configuration, ['build_dir', self.build_dir])
  endif
  call add(l:configuration, ['latexmk options', self.options])

  let l:list = [['configuration', l:configuration]]

  if self.target_full_path !=# b:vimtex.tex
    call add(l:list, ['root', self.root])
    call add(l:list, ['target', self.target_full_path])
  endif

  if self.is_running()
    call add(l:list, ['process', self.process])
    if has_key(self, 'output')
      call add(l:list, ['output', self.output])
    endif
  endif

  return l:list
endfunction

" }}}1

" vim: fdm=marker sw=2
