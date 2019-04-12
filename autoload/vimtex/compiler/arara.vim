" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#arara#init(options) abort " {{{1
  let l:compiler = deepcopy(s:compiler)

  call l:compiler.init(extend(a:options,
        \ get(g:, 'vimtex_compiler_arara', {}), 'keep'))

  return l:compiler
endfunction

" }}}1

let s:compiler = {
      \ 'name' : 'arara',
      \ 'backend' : has('nvim') ? 'nvim'
      \                         : v:version >= 800 ? 'jobs' : 'process',
      \ 'root' : '',
      \ 'target' : '',
      \ 'target_path' : '',
      \ 'background' : 1,
      \ 'output' : tempname(),
      \ 'options' : ['--log'],
      \}

function! s:compiler.init(options) abort dict " {{{1
  call extend(self, a:options)

  if !executable('arara')
    call vimtex#log#warning('arara is not executable!')
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
  let l:cmd = 'arara'

  for l:opt in self.options
    let l:cmd .= ' ' . l:opt
  endfor

  return l:cmd . ' ' . vimtex#util#shellescape(self.target)
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

  call add(l:configuration, ['arara options', self.options])

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
  call vimtex#log#warning('Clean not implemented for arara')
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
  let self.process.name = 'arara'
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

  call vimtex#paths#pushd(self.root)
  let self.job = job_start(l:cmd, l:options)
  call vimtex#paths#popd()
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
