" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#context#init_buffer() abort " {{{1
  command! -buffer VimtexContextMenu call vimtex#context#menu()

  nnoremap <buffer> <plug>(vimtex-context-menu) :VimtexContextMenu<cr>
endfunction

" }}}1
function! vimtex#context#init_state(state) abort " {{{1
  let a:state.context_menu = []

  for l:handler in copy(s:handlers)
    call add(a:state.context_menu, vimtex#context#{l:handler}#new())
  endfor
endfunction

let s:handlers = map(
      \ glob(fnamemodify(expand('<sfile>'), ':r') . '/*.vim', 0, 1),
      \ "fnamemodify(v:val, ':t:r')")

" }}}1

function! vimtex#context#menu() abort " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return | endif

  let l:word = expand('<cword>')

  for l:handler in b:vimtex.context_menu
    if l:handler.match(l:cmd, l:word)
      return vimtex#ui#menu(l:handler.get_actions())
    endif
  endfor
endfunction

" }}}1
function! vimtex#context#get(...) abort " {{{1
  if a:0 > 0
    let l:pos_saved = vimtex#pos#get_cursor()
    call vimtex#pos#set_cursor(a:000)
  endif

  let l:cmd = vimtex#cmd#get_current()
  let l:word = expand('<cword>')

  if a:0 > 0
    call vimtex#pos#set_cursor(l:pos_saved)
  endif

  if empty(l:cmd) | return | endif

  for l:handler in b:vimtex.context_menu
    if l:handler.match(l:cmd, l:word)
      return {
            \ 'cmd': l:cmd,
            \ 'word': l:word,
            \ 'handler': l:handler,
            \}
    endif
  endfor
endfunction

" }}}1
