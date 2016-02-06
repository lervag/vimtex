" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#format#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_format_enabled', 0)
endfunction

" }}}1
function! vimtex#format#init_script() " {{{1
endfunction

" }}}1
function! vimtex#format#init_buffer() " {{{1
  if !g:vimtex_format_enabled | return | endif

  setlocal formatexpr=vimtex#format#formatexpr()
endfunction

" }}}1

function! vimtex#format#formatexpr() " {{{1
  let i0 = v:lnum + v:count - 1
  let i1 = i0

  " This is a hack to make undo restore the correct position
  if mode() !=# 'i'
    normal! ix
    normal! x
  endif

  while i0 >= v:lnum
    if getline(i0) =~# '[^\\]%'
      if i0 < i1
        execute 'normal!' (i0+1) . 'Ggw' . i1 . 'G'
      endif
      let i1 = i0 - 1
    elseif i0 == v:lnum
      if v:count > 1
        execute 'normal!' i0 . 'Ggw' . i1 . 'G'
      else
        return 1
      endif
    endif
    let i0 = i0 - 1
  endwhile

  return 0
endfunction

" }}}1

" vim: fdm=marker sw=2
