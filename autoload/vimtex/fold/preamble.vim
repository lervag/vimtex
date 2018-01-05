" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#preamble#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config)
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'preamble',
      \ 're' : {
      \   'start' : '^\s*\\documentclass',
      \   'fold_re' : '\\documentclass',
      \ },
      \}
function! s:folder.level(line, lnum) abort dict " {{{1
  if a:line =~# self.re.start
    return '>1'
  endif
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  return '      Preamble'
endfunction

" }}}1
