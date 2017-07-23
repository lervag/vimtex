" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#paths#shorten_relative(path) " {{{1
  " Input: An absolute path
  " Output: Relative path with respect to the vimtex root, path relative to
  "         vimtex root (unless absolute path is shorter)

  let l:relative = vimtex#paths#relative(a:path, b:vimtex.root)
  return strlen(l:relative) < strlen(a:path)
        \ ? l:relative : a:path
endfunction

" }}}1
function! vimtex#paths#relative(path, current) " {{{1
  " Note: This algorithm is based on the one presented by @Offirmo at SO,
  "       http://stackoverflow.com/a/12498485/51634
  let l:target = substitute(a:path, '\\', '/', 'g')
  let l:common = substitute(a:current, '\\', '/', 'g')

  let l:result = ''
  while substitute(l:target, '^' . l:common, '', '') ==# l:target
    let l:common = fnamemodify(l:common, ':h')
    let l:result = empty(l:result) ? '..' : '../' . l:result
  endwhile

  if l:common ==# '/'
    let l:result .= '/'
  endif

  let l:forward = substitute(l:target, '^' . l:common, '', '')
  if !empty(l:forward)
    let l:result = empty(l:result)
          \ ? l:forward[1:]
          \ : l:result . l:forward
  endif

  return l:result
endfunction

" }}}1

" vim: fdm=marker sw=2
