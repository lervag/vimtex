set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

let g:vimtex_quickfix_method = 'pplatex'

silent edit test-pplatex.tex

try
  call vimtex#qf#setqflist()
catch /VimTeX: No log file found/
  echo 'VimTeX: No log file found'
  cquit
endtry

let s:qf = getqflist()

let s:n = 0
for s:expect in [
      \ {'lnum': 43,  'type': 'W', 'text': "so3_matrix_norm' on page 1 undefined"},
      \ {'lnum': 177, 'type': 'W', 'text': "Reference `section_model_main' on page 1 undefined"},
      \ {'lnum': 181, 'type': 'W', 'text': "orient_samp' on page 1 undefined"},
      \]
  call assert_equal(s:expect.lnum, s:qf[s:n].lnum, 'Failed at index ' . s:n)
  call assert_equal(s:expect.type, s:qf[s:n].type, 'Failed at index ' . s:n)
  call assert_equal(s:expect.text, s:qf[s:n].text, 'Failed at index ' . s:n)
  let s:n += 1
endfor

call assert_equal(s:n, len(s:qf))

call vimtex#test#finished()
