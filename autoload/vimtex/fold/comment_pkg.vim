" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#comment_pkg#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config)
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'comment_pkg',
      \ 're' : {
      \   'start' : '^\s*\\begin\s*{comment}',
      \   'end' : '^\s*\\end\s*{comment}',
      \ },
      \ 'opened' : v:false,
      \}
function! s:folder.level(line, lnum) abort dict " {{{1
  if a:line =~# self.re.start
    let self.opened = v:true
    return 'a1'
  elseif a:line =~# self.re.end
    let self.opened = v:false
    return 's1'
  elseif self.opened
    return '='
  endif
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  return a:line
endfunction

" }}}1
