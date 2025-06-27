set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test_manual_labels.tex

if empty($INMAKE) | finish | endif

" Test that manual parsing finds all labels
let s:manual_labels = vimtex#parser#auxiliary#labels_manual()
call assert_equal(4, len(s:manual_labels))

" Test that specific labels are found
let s:label_names = map(copy(s:manual_labels), 'v:val.word')
call assert_true(index(s:label_names, 'sec:intro') >= 0)
call assert_true(index(s:label_names, 'eq:simple') >= 0)
call assert_true(index(s:label_names, 'eq:complex') >= 0)
call assert_true(index(s:label_names, 'eq:orphan') >= 0)

" Test that manual labels have correct menu format
for s:label in s:manual_labels
  call assert_equal('[manual]', s:label.menu)
endfor

" Test completion includes manual labels
let s:candidates = vimtex#test#completion('\ref{', 'eq:')
" Should find all equation labels from manual parsing
call assert_true(len(s:candidates) >= 3)

call vimtex#test#finished()