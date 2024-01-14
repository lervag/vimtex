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
    let self.enabled = v:false
  endif
endfunction

" }}}1
function! s:compiler.__build_cmd(passed_options) abort dict " {{{1
  return 'latexrun ' . join(self.options)
        \ . ' --latex-cmd ' . self.get_engine()
        \ . ' -O '
        \ . (empty(self.out_dir) ? '.' : fnameescape(self.out_dir))
        \ . a:passed_options
        \ . ' ' . vimtex#util#shellescape(self.file_info.target_basename)
endfunction

" }}}1

function! s:compiler.clean(...) abort dict " {{{1
  let l:cmd = printf('latexrun --clean-all -O %s',
        \ empty(self.out_dir) ? '.' : fnameescape(self.out_dir))
  call vimtex#jobs#run(l:cmd, {'cwd': self.file_info.root})
endfunction

" }}}1
function! s:compiler.get_engine() abort dict " {{{1
  return get(g:vimtex_compiler_latexrun_engines,
        \ b:vimtex.get_tex_program(),
        \ g:vimtex_compiler_latexrun_engines._)
endfunction

" }}}1
