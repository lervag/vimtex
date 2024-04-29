" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#cite#get_key(...) abort " {{{1
  let l:cmd = a:0 > 0 ? a:1 : vimtex#cmd#get_current()
  if empty(l:cmd)
        \ || l:cmd.name[1:] !~# g:vimtex#re#cite_cmd
        \ || len(l:cmd.args) < 1
        \ || len(l:cmd.args) > 2
    return ''
  endif

  let l:current_word = a:0 > 1 ? a:2 : expand('<cword>')
  let l:cites = l:cmd.args->map({_, x -> x.text})->join(',')->split(',\s*')

  return index(l:cites, l:current_word) >= 0
        \ ? l:current_word
        \ : l:cites[0]
endfunction

" }}}1
function! vimtex#cite#get_key_at(line, col) abort " {{{1
  let l:pos_saved = vimtex#pos#get_cursor()

  call vimtex#pos#set_cursor(a:line, a:col)
  let l:key = vimtex#cite#get_key()
  call vimtex#pos#set_cursor(l:pos_saved)

  return l:key
endfunction

" }}}1
