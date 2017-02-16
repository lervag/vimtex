" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#echo#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_echo_ignore_wait', 0)
endfunction

" }}}1
function! vimtex#echo#init_buffer() " {{{1
endfunction

" }}}1

function! vimtex#echo#wait() " {{{1
  if get(g:, 'vimtex_echo_ignore_wait') | return | endif

  if filereadable(expand('%'))
    echohl VimtexMsg
    call input('Press ENTER to continue')
    echohl None
  else
    sleep 1
  endif
endfunction

function! vimtex#echo#echo(message) " {{{1
  echohl VimtexMsg
  echo a:message
  echohl None
endfunction

function! vimtex#echo#warning(message) " {{{1
  call vimtex#echo#formatted([
        \ ['VimtexWarning', 'vimtex warning: '],
        \ ['VimtexMsg', a:message]])
endfunction

function! vimtex#echo#info(message) " {{{1
  call vimtex#echo#formatted([
        \ ['VimtexInfo', 'vimtex: '],
        \ ['VimtexMsg', a:message]])
endfunction

function! vimtex#echo#formatted(parts) " {{{1
  echon "\r"
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

" {{{1 Script initialization

call vimtex#util#set_highlight('VimtexMsg', 'ModeMsg')
call vimtex#util#set_highlight('VimtexSuccess', 'Statement')
call vimtex#util#set_highlight('VimtexWarning', 'WarningMsg')
call vimtex#util#set_highlight('VimtexInfo', 'Question')

" }}}1

" vim: fdm=marker sw=2
