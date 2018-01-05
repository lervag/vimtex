" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#comments#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config)
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'comments',
      \ 're' : {'start' : '^\s*%'},
      \ 'opened' : 0,
      \}
function! s:folder.level(line, lnum) abort dict " {{{1
  if exists('b:vimtex.fold_types_dict.markers.opened')
        \ && b:vimtex.fold_types_dict.markers.opened | return | endif

  if a:line =~# self.re.start
    let l:next = getline(a:lnum-1) !~# self.re.start
    let l:prev = getline(a:lnum+1) !~# self.re.start
    if l:next && !l:prev
      let self.opened = 1
      return 'a1'
    elseif l:prev && !l:next
      let self.opened = 0
      return 's1'
    endif
  endif
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  let l:lines = map(getline(v:foldstart, v:foldend), 'matchstr(v:val, ''%\s*\zs.*\ze\s*'')')
  return matchstr(a:line, '^.*\s*%') . join(l:lines, ' ')
endfunction

" }}}1
