" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#arara#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_t#new({
      \ 'name': 'arara',
      \ 'options': ['--log'],
      \})

function! s:compiler.init() abort dict " {{{1
  if !executable('arara')
    call vimtex#log#warning('arara is not executable!')
    throw 'VimTeX: Requirements not met'
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
