" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#markers#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config).init()
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'markers',
      \ 'open' : '{{{',
      \ 'close' : '}}}',
      \ 're' : {},
      \ 'opened' : 0,
      \}
function! s:folder.init() abort dict " {{{1
  let self.re.start = '%.*' . self.open
  let self.re.end = '%.*' . self.close
  let self.re.text = [
        \ [self.re.start . '\d\?\s*\zs.*', '% ' . self.open . ' '],
        \ ['%\s*\zs.*\ze' . self.open, '% ' . self.open . ' '],
        \ ['^.*\ze\s*%', ''],
        \]

  let self.re.fold_re = escape(self.open . '|' . self.close, '{}%+*.')

  return self
endfunction

" }}}1
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
  for [l:re, l:pre] in self.re.text
    let l:text = matchstr(a:line, l:re)
    if !empty(l:text) | return l:pre . l:text | endif
  endfor

  return '% ' . self.open . ' ' . getline(v:foldstart + 1)
endfunction

" }}}1
