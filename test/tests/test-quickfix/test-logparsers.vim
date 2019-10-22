set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

silent edit ../../examples/quickfix/main.tex

try
  call vimtex#qf#setqflist()
catch /Vimtex: No log file found/
  echo 'Vimtex: No log file found'
  cquit
endtry

let s:qf = getqflist()

" NOTE: Update the total number when additional messages are added
"       to '../../examples/quickfix/main.log'
call vimtex#test#assert_equal(len(s:qf), 12)

" NOTE: Order always tests according to the order of messages
"       in '../../examples/quickfix/main.log'

" Verify captured LaTeX logfile warnings: Package natbib
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ 'Package natbib Warning: Citation `Einstein:1905'' on page 1 undefined on input line 99.')
call vimtex#test#assert_equal(s:error.lnum, 99)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package refcheck (general pattern):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ 'Package refcheck Warning: Unused label `eq:my_equation_label'' on input line 12.')
call vimtex#test#assert_equal(s:error.lnum, 12)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package hyperref (two lines):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ "Package hyperref Warning: Token not allowed in a PDF string (PDFDocEncoding):\n                removing `\\gamma'")
call vimtex#test#assert_equal(s:error.lnum, 9)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package hyperref (three lines):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ "Package hyperref Warning: Composite letter `\\textdotbelow+u'\n                not defined in PD1 encoding,\n                removing `\\textdotbelow'")
call vimtex#test#assert_equal(s:error.lnum, 5)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Undefined reference:
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ 'LaTeX Warning: Reference `fig:my_picture'' on page 37 undefined on input line 477.')
call vimtex#test#assert_equal(s:error.lnum, 477)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Overfull \hbox:
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ 'Overfull \hbox (22.0021pt too wide) in paragraph at lines 9--9')
call vimtex#test#assert_equal(s:error.lnum, 9)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package biblatex:
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ 'Package biblatex warning: No "backend" specified, using Biber backend. To use BibTex, load biblatex with the "backend=bibtex" option.')
call vimtex#test#assert_equal(s:error.lnum, 0)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package biblatex (two lines):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ "Package biblatex Warning: Data encoding is 'utf8'.\n                Use backend=biber.")
call vimtex#test#assert_equal(s:error.lnum, 0)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package babel (three lines):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ "Package babel Warning: No hyphenation patterns were loaded for\n                the language `Latin'\n                I will use the patterns loaded for \\language=0 instead.")
call vimtex#test#assert_equal(s:error.lnum, 0)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package onlyamsmath (general pattern for three lines):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ "Package onlyamsmath Warning: Environment eqnarray or eqnarray* used, please use\nonly the environments provided by the amsmath\npackage")
call vimtex#test#assert_equal(s:error.lnum, 18)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package typearea (general pattern for six lines):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ "Package typearea Warning: \\typearea used at group level 2.\n               Using \\typearea inside any group, e.g.\n               environments, math mode, boxes, etc. may result in\n               many type setting problems.\n               You should move the command \\typearea\n               outside all groups")
call vimtex#test#assert_equal(s:error.lnum, 21)
call vimtex#test#assert_equal(s:error.type, 'W')

" Verify captured LaTeX logfile warnings: Package caption (general pattern for two lines without line number):
let s:error = remove(s:qf, 0)
call vimtex#test#assert_equal(s:error.text,
      \ "Package caption Warning: Unsupported document class (or package) detected,\nusage of the caption package is not recommended.")
call vimtex#test#assert_equal(s:error.lnum, 0)
call vimtex#test#assert_equal(s:error.type, 'W')

quit!
