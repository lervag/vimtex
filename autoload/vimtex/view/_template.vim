" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#_template#apply(viewer) abort " {{{1
  return extend(a:viewer, deepcopy(s:template))
endfunction

" }}}1


let s:template = {}

function! s:template.out() dict abort " {{{1
  return g:vimtex_view_use_temp_files
        \ ? b:vimtex.root . '/' . b:vimtex.name . '_vimtex.pdf'
        \ : b:vimtex.out(1)
endfunction

" }}}1
function! s:template.synctex() dict abort " {{{1
  return fnamemodify(self.out(), ':r') . '.synctex.gz'
endfunction

" }}}1
function! s:template.copy_files() dict abort " {{{1
  if !g:vimtex_view_use_temp_files | return | endif

  "
  " Copy pdf file
  "
  let l:out = self.out()
  if getftime(b:vimtex.out()) > getftime(l:out)
    call writefile(readfile(b:vimtex.out(), 'b'), l:out, 'b')
  endif

  "
  " Copy synctex file
  "
  let l:old = b:vimtex.ext('synctex.gz')
  let l:new = self.synctex()
  if getftime(l:old) > getftime(l:new)
    call rename(l:old, l:new)
  endif
endfunction

" }}}1
function! s:template.pprint_items() abort dict " {{{1
  let l:list = []

  if has_key(self, 'xwin_id')
    call add(l:list, ['xwin id', self.xwin_id])
  endif

  if has_key(self, 'process')
    call add(l:list, ['process', self.process])
  endif

  for l:key in filter(keys(self), 'v:val =~# ''^cmd_''')
    call add(l:list, [l:key, self[l:key]])
  endfor

  return l:list
endfunction

" }}}1
