" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#markers#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config)
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'markers',
      \ 're' : {
      \   'start' : '\v\%.*\{\{\{',
      \   'end' : '\v\%\s*\}\}\}',
      \   'parser1' : '\v\%\s*\{\{\{',
      \   'parser2' : '\v\%\s*\zs.*\ze\{\{\{',
      \ },
      \ 'opened' : 0,
      \}
function! s:folder.level(line, lnum) abort dict " {{{1
  if a:line =~# self.re.start
    let s:self.opened = 1
    return 'a1'
  elseif a:line =~# self.re.end
    let s:self.opened = 0
    return 's1'
  endif
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  return a:line =~# self.re.parser1
        \ ? ' ' . matchstr(a:line, self.re.parser1 . '\s*\zs.*')
        \ : ' ' . matchstr(a:line, self.re.parser2)
endfunction

" }}}1
