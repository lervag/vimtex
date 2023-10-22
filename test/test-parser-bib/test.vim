set nocompatible
let &rtp = '../..,' . &rtp

function! TestBackend(bibfile, backend) abort
  let g:vimtex_parser_bib_backend = a:backend
  return vimtex#parser#bib(a:bibfile)
endfunction

let s:backends = ['bibtex', 'vim']
if has('nvim')
  call add(s:backends, 'lua')
endif

for s:backend in s:backends
  let s:parsed = TestBackend('test.bib', s:backend)
  call assert_equal(8, len(s:parsed),
        \ "Failed for backend: " . s:backend)

  for s:entry in s:parsed
    if s:entry.key == 'key5'
      call assert_match(
            \ 'text.here something',
            \ get(s:entry, 'author', ''),
            \ "Failed for backend: " . s:backend)
      call assert_match(
            \ '^title: Angew',
            \ get(s:entry, 'title', ''),
            \ "Failed for backend: " . s:backend)
    endif
  endfor
endfor

" Check that Vim and Lua parser give the same result
if has('nvim')
  let s:parsed_lua = TestBackend('test.bib', 'lua')
  let s:parsed_vim = TestBackend('test.bib', 'vim')
  call assert_equal(len(s:parsed_lua), len(s:parsed_vim))
  for s:i in range(len(s:parsed_lua))
    call assert_equal(s:parsed_lua[s:i], s:parsed_vim[s:i])
  endfor
endif

let s:bib = vimtex#kpsewhich#find('biblatex-examples.bib')
if !empty(s:bib) && filereadable(s:bib)
  for s:backend in s:backends
    let s:parsed = TestBackend(s:bib, s:backend)
    call assert_equal(92, len(s:parsed),
          \ "Failed for backend: " . s:backend)
  endfor
endif

call vimtex#log#set_silent()
let s:parsed = TestBackend('test.bib', 'badparser')
call assert_equal(0, len(s:parsed))

call vimtex#test#finished()
