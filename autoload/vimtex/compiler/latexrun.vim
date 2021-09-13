" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#latexrun#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_template#new({
      \ 'name' : 'latexrun',
      \ 'options' : [
      \   '--verbose-cmds',
      \   '--latex-args="-synctex=1"',
      \ ],
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  if !executable('latexrun')
    call vimtex#log#warning('latexrun is not executable!')
    throw 'VimTeX: Requirements not met'
  endif
endfunction

" }}}1
function! s:compiler.__build_cmd() abort dict " {{{1
  return 'latexrun ' . join(self.options)
        \ . ' --latex-cmd ' . self.get_engine()
        \ . ' -O '
        \ . (empty(self.build_dir) ? '.' : fnameescape(self.build_dir))
        \ . ' ' . vimtex#util#shellescape(self.state.base)
endfunction

" }}}1

function! s:compiler.clean(...) abort dict " {{{1
  let l:cmd = (has('win32')
        \   ? 'cd /D "' . self.state.root . '" & '
        \   : 'cd ' . vimtex#util#shellescape(self.state.root) . '; ')
        \ . 'latexrun --clean-all'
        \ . ' -O '
        \   . (empty(self.build_dir) ? '.' : fnameescape(self.build_dir))
  call vimtex#process#run(l:cmd)
endfunction

" }}}1
function! s:compiler.get_engine() abort dict " {{{1
  return get(extend(g:vimtex_compiler_latexrun_engines,
        \ {
        \  '_'                : 'pdflatex',
        \  'pdflatex'         : 'pdflatex',
        \  'lualatex'         : 'lualatex',
        \  'xelatex'          : 'xelatex',
        \ }, 'keep'), self.state.get_tex_program(), '_')
endfunction

" }}}1
