set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set hidden

nnoremap q :qall!<cr>
call vimtex#log#set_silent()

let s:result = vimtex#view#inverse_search(10, 'main.tex')
call assert_equal(-1, s:result)

silent edit test.tex

let s:result = vimtex#view#inverse_search(10, 'main.tex')
call assert_equal(-2, s:result)

bwipeout!
let g:vimtex_view_reverse_search_edit_cmd = 'splitview'
silent edit main.tex
let s:result = vimtex#view#inverse_search(2, 'included.tex')
let s:log = vimtex#log#get()
call assert_equal(-3, s:result)
call assert_equal('Command error: splitview included.tex', s:log[0].msg[1])

bwipeout!
let g:vimtex_view_reverse_search_edit_cmd = 'edit'
silent edit main.tex
function! b:vimtex.get_sources(...) abort
  return ['main.tex', 'new.tex']
endfunction
let s:result = vimtex#view#inverse_search(2, 'new.tex')
let s:log = vimtex#log#get()
call assert_equal(-4, s:result)
call assert_equal('File not readable: "new.tex"', s:log[1].msg[1])

bwipeout!
silent edit main.tex
call assert_equal('main.tex', expand('%:t'))
call vimtex#view#inverse_search(3, 'included.tex')
call assert_equal('included.tex', expand('%:t'))
call assert_equal(3, line('.'))

" The owning project must react also when the focused buffer is not a VimTeX
" buffer, e.g. a terminal or a file tree.
silent %bwipeout!
silent edit main.tex
enew
call assert_false(exists('b:vimtex'))
call vimtex#view#inverse_search(3, 'included.tex')
call assert_equal('included.tex', expand('%:t'))
call assert_equal(3, line('.'))

" This should also work across windows and tabs
silent %bwipeout!
silent edit main.tex
silent tabedit included.tex
tabprevious
enew
call assert_false(exists('b:vimtex'))
call vimtex#view#inverse_search(4, 'included.tex')
call assert_equal('included.tex', expand('%:t'))
call assert_equal(4, line('.'))
call assert_equal(2, tabpagenr())

call vimtex#test#finished()
