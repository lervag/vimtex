set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set fillchars=fold:\ 
set number
set foldcolumn=4

nnoremap q :qall!<cr>

let g:vimtex_fold_bib_enabled = 1

silent edit test.bib
silent normal zM

if empty($INMAKE) | finish | endif

" Test foldexpr -- 'normal' cases
call assert_equal(-1, foldclosed(1))
call assert_equal(2, foldclosed(2))
call assert_equal(2, foldclosed(5))
call assert_equal(2, foldclosed(9))
call assert_equal(9, foldclosedend(2))
call assert_equal(9, foldclosedend(5))
call assert_equal(9, foldclosedend(9))
call assert_equal(-1, foldclosed(10))
call assert_equal(-1, foldclosed(11))
call assert_equal(-1, foldclosed(12))

" Test foldexpr -- edge cases
call assert_equal(62, foldclosed(62))
call assert_equal(73, foldclosedend(62))
call assert_equal(76, foldclosed(77))
call assert_equal(87, foldclosedend(77))
call assert_equal(90, foldclosed(91))
call assert_equal(103, foldclosedend(91))
call assert_equal(106, foldclosed(106))
call assert_equal(107, foldclosedend(106))
call assert_equal(110, foldclosed(111))
call assert_equal(119, foldclosedend(111))

" Test foldexpr -- whitespace outside entry
call assert_equal(-1, foldclosed(60))
call assert_equal(-1, foldclosed(61))
call assert_equal(-1, foldclosed(74))
call assert_equal(-1, foldclosed(75))
call assert_equal(-1, foldclosed(88))
call assert_equal(-1, foldclosed(89))
call assert_equal(-1, foldclosed(104))
call assert_equal(-1, foldclosed(105))

" Test foldtext
call assert_equal(28, b:vimtex_fold_bib_maxwidth)
call assert_equal('@book{Ernst1987}              Principles of Nuclear Magnetic Resonance in One and Two Dimensions', foldtextresult(2))
call assert_equal('@article{Kupce2021NRMP}       Parallel nuclear magnetic resonance spectroscopy', foldtextresult(13))
call assert_equal('@set{ultrafast}               Frydman2002PNASUSA, Frydman2003JACS', foldtextresult(44))

call assert_equal('@article{Kupce2021NRMP2}      ', foldtextresult(51))
call assert_equal('@article{Kupce2021NRMP3}      Parallel nuclear magnetic resonance spectroscopy', foldtextresult(62))
call assert_equal('@article{Kupce2021NRMP4}      Parallel nuclear magnetic resonance spectroscopy', foldtextresult(76))
call assert_equal('@article{Kupce2021NRMP5}      Parallel nuclear magnetic resonance spectroscopy', foldtextresult(90))
call assert_equal('+--  2 lines: @string{ NMR = ', foldtextresult(106))
call assert_equal('@article{Kupce2021NRMP6}      Parallel nuclear magnetic resonance spectroscopy', foldtextresult(110))

" Test foldtext with manual g:vimtex_fold_bib_max_key_width
let g:vimtex_fold_bib_max_key_width = 20
silent VimtexReload
call assert_equal('@book{Ernst1987}      Principles of Nuclear Magnetic Resonance in One and Two Dimensions', foldtextresult(2))
call assert_equal('@article{Kupce2021NR  Parallel nuclear magnetic resonance spectroscopy', foldtextresult(13))
call assert_equal('@set{ultrafast}       Frydman2002PNASUSA, Frydman2003JACS', foldtextresult(44))
call assert_equal('@article{Kupce2021NR  ', foldtextresult(51))

call vimtex#test#finished()
