" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#latexrun#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_t#new({
      \ 'name' : 'latexrun',
      \ 'options' : [
      \   '--verbose-cmds',
      \   '--latex-args="-synctex=1"',
      \ ],
      \})

function! s:compiler.init() abort dict " {{{1
  if !executable('latexrun')
    call vimtex#log#warning('latexrun is not executable!')
    throw 'VimTeX: Requirements not met'
  endif

  call vimtex#compiler#_t#build_dir_materialize(self)
  call vimtex#compiler#_t#build_dir_respect_envvar(self)
endfunction

" }}}1

function! s:compiler.build_cmd() abort dict " {{{1
  let l:cmd = 'latexrun'

  for l:opt in self.options
    let l:cmd .= ' ' . l:opt
  endfor

  let l:cmd .= ' --latex-cmd ' . self.get_engine()

  let l:cmd .= ' -O '
        \ . (empty(self.build_dir) ? '.' : fnameescape(self.build_dir))

  return l:cmd . ' ' . vimtex#util#shellescape(self.target)
endfunction

" }}}1
function! s:compiler.get_engine() abort dict " {{{1
  return get(extend(g:vimtex_compiler_latexrun_engines,
        \ {
        \  '_'                : 'pdflatex',
        \  'pdflatex'         : 'pdflatex',
        \  'lualatex'         : 'lualatex',
        \  'xelatex'          : 'xelatex',
        \ }, 'keep'), self.tex_program, '_')
endfunction

" }}}1
function! s:compiler.pprint_items() abort dict " {{{1
  let l:configuration = []

  if !empty(self.build_dir)
    call add(l:configuration, ['build_dir', self.build_dir])
  endif
  call add(l:configuration, ['latexrun options', self.options])
  call add(l:configuration, ['latexrun engine', self.get_engine()])

  let l:list = []
  call add(l:list, ['output', self.output])

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
  let l:cmd = (has('win32')
        \   ? 'cd /D "' . self.root . '" & '
        \   : 'cd ' . vimtex#util#shellescape(self.root) . '; ')
        \ . 'latexrun --clean-all'
        \ . ' -O '
        \   . (empty(self.build_dir) ? '.' : fnameescape(self.build_dir))
  call vimtex#process#run(l:cmd)

  call vimtex#log#info('Compiler clean finished')
endfunction

" }}}1
