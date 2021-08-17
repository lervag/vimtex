set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit file\ with\ errors.tex

if empty($INMAKE) | finish | endif

try
  call vimtex#qf#setqflist()
catch /VimTeX: No log file found/
  echo 'VimTeX: No log file found'
  cquit
endtry

let s:qf = getqflist()
let s:qf_number = len(s:qf)
call assert_equal(22, s:qf_number)

for s:expect in [
      \ {'lnum': 16, 'type': 'E', 'text': "Paragraph ended before \\date  was complete."},
      \ {'lnum': 17, 'type': 'W', 'text': "LaTeX Warning: Reference `blabla' on page 1 undefined on input line 17."},
      \ {'lnum': 19, 'type': 'E', 'text': "Undefined control sequence.\n\\test"},
      \ {'lnum': 21, 'type': 'E', 'text': "Too many }'s.\n{Hello world!}}"},
      \ {'lnum': 23, 'type': 'E', 'text': "Missing $ inserted."},
      \ {'lnum': 24, 'type': 'E', 'text': "Missing $ inserted."},
      \ {'lnum': 25, 'type': 'W', 'text': "Underfull \\hbox (badness 10000) in paragraph at lines 25--27"},
      \ {'lnum': 28, 'type': 'W', 'text': "Overfull \\hbox (160.81767pt too wide) in paragraph at lines 28--29"},
      \ {'lnum': 1,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 1,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `\\alpha'"},
      \ {'lnum': 1,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 3,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 3,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `\\epsilon'"},
      \ {'lnum': 3,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 1,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 1,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `\\alpha'"},
      \ {'lnum': 1,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 3,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 3,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `\\epsilon'"},
      \ {'lnum': 3,  'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (Unicode):\n                removing `math shift'"},
      \ {'lnum': 0,  'type': 'W', 'text': "LaTeX Warning: There were undefined references."},
      \ {'lnum': 0,  'type': 'W', 'text': "Package rerunfilecheck Warning: File `\"file with errors\".out' has changed.\n               Rerun to get outlines right\n               or use package `bookmark'."}
      \]
  let s:observe = remove(s:qf, 0)
  call assert_equal(s:expect.text, s:observe.text,
        \ 'Failed at ' . substitute(string(s:expect), "\n", '', 'g'))
  call assert_equal(s:expect.lnum, s:observe.lnum)
  call assert_equal(s:expect.type, s:observe.type)
endfor


" Apply ignore filters
let g:vimtex_quickfix_ignore_filters = ['\\test']
call vimtex#qf#setqflist()
let s:qf = getqflist()
call assert_equal(s:qf_number - 1, len(s:qf))


" Repeated invocations of setqflist should not create extra quickfix lists
try
  let s:qf_nr = getqflist({'nr': '$'}).nr
  call assert_equal(1, s:qf_nr)
catch
endtry

call vimtex#test#finished()
