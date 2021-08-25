" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#generic#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1


let s:compiler = vimtex#compiler#_template#new({
      \ 'name' : 'generic',
      \ 'cmd' : '',
      \})

function! s:compiler.__build_cmd() abort dict " {{{1
  let l:cmd = self.cmd

  " TODO: self.cmd is not good name (set by exec!)!
  " TODO: %O -> vimtex#util#shellescape(self.target)

  return l:cmd
endfunction

" }}}1
