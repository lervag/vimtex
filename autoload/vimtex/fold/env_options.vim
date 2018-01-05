" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#env_options#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config)
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'envs with options',
      \ 're' : {
      \   'start' : g:vimtex#re#not_comment . '\\begin\s*\{.{-}\}\[\s*($|\%)',
      \   'end' : '\s*\]\s*$',
      \ },
      \ 'opened' : 0,
      \}
function! s:folder.level(line, lnum) abort dict " {{{1
  return self.opened
        \ ? self.fold_closed(a:line, a:lnum)
        \ : self.fold_opened(a:line, a:lnum)
endfunction

" }}}1
function! s:folder.fold_opened(line, lnum) abort dict " {{{1
  if a:line =~# self.re.start
    let self.opened = 1
    return 'a1'
  endif
endfunction

" }}}1
function! s:folder.fold_closed(line, lnum) abort dict " {{{1
  if a:line =~# self.re.end
    let self.opened = 0
    return 's1'
  endif
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  return a:line . '...] '
endfunction

" }}}1
