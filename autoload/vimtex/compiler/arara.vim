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
    let self.enabled = v:false
  endif
endfunction

" }}}1
function! s:compiler.__build_cmd(passed_options) abort dict " {{{1
  return 'arara ' . join(self.options)
        \ . ' ' . a:passed_options
        \ . ' ' . vimtex#util#shellescape(self.file_info.target_basename)
endfunction

" }}}1
