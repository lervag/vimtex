" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#log#init_buffer() " {{{1
  command! -buffer -bang VimtexLog call vimtex#log#open()

  nnoremap <buffer> <plug>(vimtex-log) :VimtexLog<cr>
endfunction

" }}}1

function! vimtex#log#info(...) abort " {{{1
  call s:logger.add(a:000, 'info')
endfunction

" }}}1
function! vimtex#log#warning(...) abort " {{{1
  call s:logger.add(a:000, 'warning')
endfunction

" }}}1
function! vimtex#log#error(...) abort " {{{1
  call s:logger.add(a:000, 'error')
endfunction

" }}}1

function! vimtex#log#open() abort " {{{1
  call vimtex#scratch#new(s:logger)
endfunction

" }}}1
function! vimtex#log#toggle_verbose() abort " {{{1
  if s:logger.verbose
    let s:logger.verbose = 0
    call vimtex#log#info('Logging is now quiet')
  else
    call vimtex#log#info('Logging is now verbose')
    let s:logger.verbose = 1
  endif
endfunction

" }}}1


let s:logger = {
      \ 'name' : 'VimtexMessageLog',
      \ 'entries' : [],
      \ 'type_to_highlight' : {
      \   'info' : 'VimtexInfo',
      \   'warning' : 'VimtexWarning',
      \   'error' : 'VimtexError',
      \ },
      \ 'verbose' : 1,
      \}
function! s:logger.add(msg_arg, type) abort dict " {{{1
  let l:msg_list = []
  for l:msg in a:msg_arg
    if type(l:msg) == type('')
      call add(l:msg_list, l:msg)
    elseif type(l:msg) == type([])
      call extend(l:msg_list, filter(l:msg, "type(v:val) == type('')"))
    endif
  endfor

  let l:entry = {}
  let l:entry.type = a:type
  let l:entry.time = strftime('%T')
  let l:entry.callstack = vimtex#debug#stacktrace()[1:]
  let l:entry.msg = l:msg_list
  call add(self.entries, l:entry)

  if !self.verbose | return | endif

  call vimtex#echo#formatted([
        \ [self.type_to_highlight[a:type], 'vimtex:'],
        \ ' ' . l:msg_list[0]
        \])
  for l:msg in l:msg_list[1:]
    call vimtex#echo#echo('        ' . l:msg)
  endfor
endfunction

" }}}1
function! s:logger.print_content() abort dict " {{{1
  for l:entry in self.entries
    call append('$', printf('%s: %s', l:entry.time, l:entry.type))
    for l:stack in l:entry.callstack
      call append('$', printf('  from: %s', l:stack.function))
    endfor
    for l:msg in l:entry.msg
      call append('$', printf('  %s', l:msg))
    endfor
    call append('$', '')
  endfor
endfunction

" }}}1
function! s:logger.syntax() abort dict " {{{1
  syntax match VimtexInfoOther /.*/
  syntax match VimtexInfoKey /^.*:/ nextgroup=VimtexInfoValue
  syntax match VimtexInfoValue /.*/ contained
endfunction

" }}}1

" vim: fdm=marker sw=2
