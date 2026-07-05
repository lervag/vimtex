set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

if empty($INMAKE) | finish | endif

" A minimal stand-in for a VimTeX state and compiler. We only need the parts
" that the clash detection inspects: the target .tex file and a compiler that
" can report its aux output path and whether it is running. This lets us test
" the detection logic without a real backend (no latexmk, no filesystem).
function! s:fake_state(tex, aux_signature, running) abort
  return {
        \ 'tex': a:tex,
        \ 'compiler': {
        \   'get_output_signature': {ext -> ext ==# 'aux' ? a:aux_signature : ''},
        \   'is_running': {-> a:running},
        \ },
        \}
endfunction

function! s:names(states) abort
  return sort(map(copy(a:states), 'v:val.tex'))
endfunction

let s:a = s:fake_state('/a/note.tex', '/out/note.aux', v:true)
let s:b = s:fake_state('/b/note.tex', '/out/note.aux', v:true)
let s:c = s:fake_state('/c/note.tex', '/out/note.aux', v:false)
let s:d = s:fake_state('/d/other.tex', '/out/other.aux', v:true)
let s:states = [s:a, s:b, s:c, s:d]

" Starting `d` with no other compilers does not clash
call assert_equal(
      \ [],
      \ s:names(vimtex#compiler#get_output_clashes(s:d.compiler, [s:d])))

" Starting `a` clashes with `b`
call assert_equal(
      \ ['/b/note.tex'],
      \ s:names(vimtex#compiler#get_output_clashes(s:a.compiler, s:states)))

" No clash if no running compiler shares the signature
call assert_equal(
      \ [],
      \ s:names(vimtex#compiler#get_output_clashes(s:c.compiler, [s:c, s:d])))

" A compiler with no resolvable output (empty signature) never clashes
let s:empty = s:fake_state('/e/note.tex', '', v:true)
call assert_equal(
      \ [],
      \ s:names(vimtex#compiler#get_output_clashes(s:empty.compiler, s:states)))

" A state whose compiler cannot report its running status is ignored
let s:no_status = {
      \ 'tex': '/f/note.tex',
      \ 'compiler': {'get_output_signature': {ext -> '/out/note.aux'}},
      \}
call assert_equal(
      \ ['/b/note.tex'],
      \ s:names(vimtex#compiler#get_output_clashes(s:a.compiler, s:states + [s:no_status])))

call vimtex#test#finished()
