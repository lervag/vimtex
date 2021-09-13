" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#arara#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_template#new({
      \ 'name': 'arara',
      \ 'options': ['--log'],
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  if !executable('arara')
    call vimtex#log#warning('arara is not executable!')
    throw 'VimTeX: Requirements not met'
  endif
endfunction

" }}}1
function! s:compiler.__build_cmd() abort dict " {{{1
  return 'arara ' . join(self.options)
        \ . ' ' . vimtex#util#shellescape(self.state.base)
endfunction

" }}}1
