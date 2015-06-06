" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#echo#init_options() " {{{1
endfunction

" }}}1
function! vimtex#echo#init_script() " {{{1
  highlight link VimtexMsg ModeMsg
  highlight link VimtexSuccess Statement
  highlight link VimtexWarning WarningMsg
endfunction

" }}}1
function! vimtex#echo#init_buffer() " {{{1
endfunction

" }}}1

function! vimtex#echo#echo(message, ...) " {{{1
  let hl = len(a:000) > 0 ? a:0 : 'VimtexMsg'
  execute 'echohl' hl
  echo a:message
  echohl None
endfunction

function! vimtex#echo#warning(message, ...) " {{{1
  let hl = len(a:000) > 0 ? a:0 : 'VimtexWarning'
  execute 'echohl' hl
  echomsg a:message
  echohl None
endfunction

function! vimtex#echo#formatted(parts) " {{{1
  try
    for part in a:parts
      if type(part) == type('')
        echohl VimtexMsg
        echon part
      else
        execute 'echohl' part[0]
        echon part[1]
      endif
      unlet part
    endfor
  finally
    echohl None
  endtry
endfunction

function! vimtex#echo#status(parts) " {{{1
  echon "\r"
  call vimtex#echo#formatted(a:parts)
endfunction

" }}}1

" vim: fdm=marker sw=2
