" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#tectonic#init(options) abort " {{{1
  let l:compiler = deepcopy(s:compiler)

  call l:compiler.init(extend(a:options,
        \ get(g:, 'vimtex_compiler_tectonic', {}), 'keep'))

  return l:compiler
endfunction

" }}}1

let s:compiler = {
      \ 'name' : 'tectonic',
      \ 'backend' : has('nvim') ? 'nvim'
      \                         : v:version >= 800 ? 'jobs' : 'process',
      \ 'root' : '',
      \ 'target' : '',
      \ 'target_path' : '',
      \ 'background' : 1,
      \ 'build_dir' : '',
      \ 'output' : tempname(),
      \ 'options' : [
      \   '--keep-logs',
      \   '--synctex'
      \ ],
      \}

function! s:compiler.init(options) abort dict " {{{1
  call extend(self, a:options)

  if !executable('tectonic')
    call vimtex#log#warning('tectonic is not executable!')
    throw 'vimtex: Requirements not met'
  endif

  call extend(self, deepcopy(s:compiler_{self.backend}))

  " Processes run with the new jobs api will not run in the foreground
  if self.backend !=# 'process'
    let self.background = 1
  endif
endfunction

" }}}1

function! s:compiler.build_cmd() abort dict " {{{1
  let l:cmd = 'tectonic'

  for l:opt in self.options
    if l:opt =~# '^-\%(o\|-outdir\)'
      call vimtex#log#warning("Don't use --outdir or -o in compiler options,"
            \ . ' use build_dir instead, see :help g:vimtex_compiler_tectonic'
            \ . ' for more details')
      continue
    endif

    let l:cmd .= ' ' . l:opt
  endfor

  if empty(self.build_dir)
    let self.build_dir = fnamemodify(self.target_path, ':p:h')
  elseif !isdirectory(self.build_dir)
    call vimtex#log#warning(
          \ "build_dir doesn't exist, it will be created: " . self.build_dir)
    call mkdir(self.build_dir, 'p')
  endif

  return l:cmd
        \ . ' --outdir=' . self.build_dir
        \ . ' ' . vimtex#util#shellescape(self.target)
endfunction

" }}}1
function! s:compiler.cleanup() abort dict " {{{1
  " Pass
endfunction

" }}}1
function! s:compiler.pprint_items() abort dict " {{{1
  let l:configuration = []

  if self.backend ==# 'process'
    call add(l:configuration, ['background', self.background])
  endif

  call add(l:configuration, ['tectonic options', self.options])

  let l:list = []
  call add(l:list, ['backend', self.backend])
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
    call add(l:list, ['cmd', self.cmd])
  endif

  return l:list
endfunction

" }}}1

function! s:compiler.clean(...) abort dict " {{{1
  let l:files = ['synctex.gz', 'toc', 'out', 'aux', 'log']

  " If a full clean is required
  if a:0 > 0 && a:1
    call extend(l:intermediate, ['pdf'])
  endif

  let l:basename = self.build_dir . '/' . fnamemodify(self.target_path, ':t:r')
  call map(l:files, 'l:basename . v:val')

  call vimtex#process#run('rm -f ' . join(l:files))
  call vimtex#log#info('Compiler clean finished')
endfunction

" }}}1
function! s:compiler.start(...) abort dict " {{{1
  call self.exec()

  if self.background
    call vimtex#log#info('Compiler started in background')
  else
    call vimtex#compiler#callback(!vimtex#qf#inquire(self.target))
  endif
endfunction

" }}}1
function! s:compiler.start_single() abort dict " {{{1
  call self.start()
endfunction

" }}}1
function! s:compiler.stop() abort dict " {{{1
  " Pass
endfunction

" }}}1
function! s:compiler.is_running() abort dict " {{{1
  return 0
endfunction

" }}}1
function! s:compiler.kill() abort dict " {{{1
  " Pass
endfunction

" }}}1
function! s:compiler.get_pid() abort dict " {{{1
  return 0
endfunction

" }}}1

let s:compiler_process = {}
function! s:compiler_process.exec() abort dict " {{{1
  let self.process = vimtex#process#new()
  let self.process.name = 'tectonic'
  let self.process.background = self.background
  let self.process.workdir = self.root
  let self.process.output = self.output
  let self.process.cmd = self.build_cmd()
  call self.process.run()
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

  let s:cb_target = self.target_path !=# b:vimtex.tex ? self.target_path : ''
  let l:options.exit_cb = function('s:callback')

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
        \ 'on_exit' : function('s:callback_nvim_exit'),
        \ 'cwd' : self.root,
        \ 'target' : self.target_path,
        \ 'output' : self.output,
        \}

  let self.job = jobstart(l:cmd, l:shell)
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
