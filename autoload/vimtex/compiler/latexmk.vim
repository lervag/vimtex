" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#latexmk#init(options) abort " {{{1
  let l:options = extend(a:options,
        \ get(g:, 'vimtex_compiler_latexmk', {}), 'keep')

  " Create copy of the compiler object and extend with user settings
  let l:compiler = extend(deepcopy(s:compiler), l:options)
  call l:compiler.init_check_requirements()
  call l:compiler.init_build_dir_option()
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
      \ 'root' : '',
      \ 'target' : '',
      \ 'target_path' : '',
      \ 'background' : 0,
      \ 'build_dir' : '',
      \ 'callback' : 1,
      \ 'continuous' : 1,
      \ 'engine' : b:vimtex.engine,
      \ 'output' : tempname(),
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
    if !(has('clientserver') || has('nvim'))
      let self.callback = 0
      call vimtex#echo#warning('Can''t use callbacks without +clientserver')
      call vimtex#echo#wait()
    endif
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
function! s:compiler.cleanup() abort dict " {{{1
  if self.is_running()
    call self.stop()
  endif
endfunction

" }}}1
function! s:compiler.start() abort dict " {{{1
  if self.is_running()
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'already running for `' . self.target . "'"]])
    return
  endif

  let self.process = s:init_process(self.get_default_opts())
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
            \ vimtex#qf#inquire(self.target)
            \   ? ['VimtexWarning', 'fail']
            \   : ['VimtexSuccess', 'success']])
    endif
  endif
endfunction

" }}}1
function! s:compiler.start_single() abort dict " {{{1
  if self.is_running()
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'already running for `' . self.target . "'"]])
    return
  endif

  let l:opts = self.get_default_opts()
  let l:opts.continuous = l:opts.callback && !empty(v:servername)

  if l:opts.continuous
    let g:vimtex_compiler_callback_hooks += ['VimtexSSCallback']
    function! VimtexSSCallback(status)
      silent call vimtex#compiler#stop()
      call remove(g:vimtex_compiler_callback_hooks, 'VimtexSSCallback')
    endfunction
  endif

  let self.process = s:init_process(l:opts)
  call self.process.run()

  if self.background
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'started in background!']])
  else
    call vimtex#echo#status(['latexmk compile: ',
          \ vimtex#qf#inquire(self.target)
          \   ? ['VimtexWarning', 'fail']
          \   : ['VimtexSuccess', 'success']])
  endif
endfunction

" }}}1
function! s:compiler.stop() abort dict " {{{1
  if self.is_running()
    call self.process.stop()
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
  return exists('self.process.pid') && self.process.pid > 0
endfunction

" }}}1
function! s:compiler.get_default_opts() abort dict " {{{1
  return {
        \ 'root' : self.root,
        \ 'target' : self.target,
        \ 'target_path' : self.target_path,
        \ 'background' : self.background,
        \ 'build_dir' : self.build_dir,
        \ 'callback' : self.callback,
        \ 'continuous' : self.continuous,
        \ 'engine' : self.engine,
        \ 'output' : self.output,
        \ 'options' : self.options,
        \}
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

  if self.target_path !=# b:vimtex.tex
    call add(l:list, ['root', self.root])
    call add(l:list, ['target', self.target_path])
  endif

  if has_key(self, 'process')
    call add(l:list, ['process', self.process])
  endif

  return l:list
endfunction

" }}}1

function! s:init_process(opts) abort " {{{1
  "
  " a:opts is a Dict with the following entries:
  "
  "       'root'
  "       'target'
  "       'target_path'
  "       'background'
  "       'build_dir'
  "       'callback'
  "       'continuous'
  "       'engine'
  "       'output'
  "       'options'
  "

  " Ensure args are consistent
  if a:opts.continuous
    let a:opts.background = 1
  endif

  let l:process = vimtex#process#new()
  let l:process.name = 'latexmk'
  let l:process.continuous = a:opts.continuous
  let l:process.background = a:opts.background
  let l:process.workdir = a:opts.root
  let l:process.output = a:opts.output
  let l:process.cmd = s:build_cmd(a:opts)

  if l:process.continuous
    if has('win32')
      " Not implemented
    else
      for l:pid in split(system(
            \ 'pgrep -f "^[^ ]*perl.*latexmk.*' . a:opts.target . '"'), "\n")
        let l:path = resolve('/proc/' . l:pid . '/cwd') . '/' . a:opts.target
        if l:path ==# a:opts.target_path
          let l:process.pid = str2nr(l:pid)
          let l:process.is_running = 1
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

  call s:create_build_dir(a:opts)

  return l:process
endfunction

" }}}1
function! s:build_cmd(opts) abort " {{{1
  if has('win32')
    let l:cmd = 'set max_print_line=2000 & latexmk'
  else
    if fnamemodify(&shell, ':t') ==# 'fish'
      let l:cmd = 'set max_print_line 2000; and latexmk'
    else
      let l:cmd = 'max_print_line=2000 latexmk'
    endif
  endif

  for l:opt in a:opts.options
    let l:cmd .= ' ' . l:opt
  endfor

  if !empty(a:opts.engine)
    let l:cmd .= ' ' . a:opts.engine
  endif

  if !empty(a:opts.build_dir)
    let l:cmd .= ' -outdir=' . a:opts.build_dir
  endif

  if a:opts.continuous
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

  if a:opts.callback
    if empty(v:servername)
      call vimtex#echo#warning('Can''t use callbacks with empty v:servername')
      call vimtex#echo#wait()
    else
      let l:cb = vimtex#util#shellescape(
            \ '""' . g:vimtex_compiler_progname . '""')
            \ . ' --servername ' . v:servername
      let l:cmd .= vimtex#compiler#latexmk#wrap_option('success_cmd',
            \ l:cb . ' --remote-expr \"vimtex\#compiler\#callback(1)\"')
      let l:cmd .= vimtex#compiler#latexmk#wrap_option('failure_cmd',
            \ l:cb . ' --remote-expr \"vimtex\#compiler\#callback(0)\"')
    endif
  endif

  return l:cmd . ' ' . vimtex#util#shellescape(a:opts.target)
endfunction

" }}}1
function! s:create_build_dir(opts) abort " {{{1
  if empty(a:opts.build_dir) | return | endif

  " First create list of necessary directories
  let l:dirs = split(glob(a:opts.root . '/**/*.tex'), '\n')
  call map(l:dirs, 'fnamemodify(v:val, '':h'')')
  call map(l:dirs, 'strpart(v:val, strlen(a:opts.root) + 1)')
  call vimtex#util#uniq(sort(filter(l:dirs, "v:val !=# ''")))
  call map(l:dirs,
        \ "a:opts.root . '/' . a:opts.build_dir . '/' . v:val")
  call filter(l:dirs, '!isdirectory(v:val)')

  " Create the non-existing directories
  for l:dir in l:dirs
    call mkdir(l:dir, 'p')
  endfor
endfunction

" }}}1

" vim: fdm=marker sw=2
