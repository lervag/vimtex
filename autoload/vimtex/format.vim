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
  let s:border_beginning = '\v^\s*%(' . join([
        \ '\\item',
        \ '\\begin',
        \ '\\end',
        \ '%(\\\[|\$\$)\s*$',
        \], '|') . ')'

  let s:border_end = '\v[^\\]\%'
        \ . '|\\%(' . join([
        \   '\\\*?',
        \   'clear%(double)?page',
        \   'linebreak',
        \   'new%(line|page)',
        \   'pagebreak',
        \   '%(begin|end)\{[^}]*\}',
        \  ], '|') . ')\s*$'
        \ . '|^\s*%(\\\]|\$\$)\s*$'
endfunction

" }}}1
function! vimtex#format#init_buffer() " {{{1
  if !g:vimtex_format_enabled | return | endif

  setlocal formatexpr=vimtex#format#formatexpr()
endfunction

" }}}1

function! vimtex#format#formatexpr() " {{{1
  let l:foldenable = &l:foldenable
  setlocal nofoldenable

  let l:top = v:lnum
  let l:bottom = v:lnum + v:count - 1
  let l:mark = l:bottom

  " This is a hack to make undo restore the correct position
  if mode() !=# 'i'
    normal! ix
    normal! x
  endif

  for l:current in range(l:bottom, l:top, -1)
    let l:line = getline(l:current)

    if vimtex#util#in_mathzone(l:current, 1)
          \ && vimtex#util#in_mathzone(l:current, col([l:current, '$']))
      let l:mark = l:current - 1
      continue
    endif

    if l:line =~# s:border_end
      if l:current < l:mark
        execute 'normal!' (l:current+1) . 'Ggw' . l:mark . 'G'
      endif
      let l:mark = l:current
    endif

    if l:line =~# s:border_beginning
      if l:current < l:mark
        execute 'normal!' l:current . 'Ggw' . l:mark . 'G'
      endif
      let l:mark = l:current-1
    endif
  endwhile

  if l:top < l:mark
    execute 'normal!' l:top . 'Ggw' . l:mark . 'G'
  endif

  let &l:foldenable = l:foldenable
endfunction

" }}}1

" vim: fdm=marker sw=2
