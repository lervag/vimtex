" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#tectonic#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_template#new({
      \ 'name' : 'tectonic',
      \ 'options' : [
      \   '--keep-logs',
      \   '--synctex'
      \ ],
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  if !executable('tectonic')
    call vimtex#log#warning('tectonic is not executable!')
    throw 'VimTeX: Requirements not met'
  endif

  for l:opt in self.options
    if l:opt =~# '^-\%(o\|-outdir\)'
      call vimtex#log#warning("Don't use --outdir or -o in compiler options,"
            \ . ' use build_dir instead, see :help g:vimtex_compiler_tectonic'
            \ . ' for more details')
      break
    endif
  endfor
endfunction

" }}}1
function! s:compiler.__build_cmd() abort dict " {{{1
  let l:outdir = !empty(self.build_dir)
        \ ? self.build_dir
        \ : fnamemodify(self.state.tex, ':p:h')

  return 'tectonic ' . join(self.options)
        \ . ' --outdir=' . l:outdir
        \ . ' ' . vimtex#util#shellescape(self.state.base)
endfunction

" }}}1
