set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

silent edit ../example-quickfix/main.tex

try
  call vimtex#qf#setqflist()
catch /VimTeX: No log file found/
  echo 'VimTeX: No log file found'
  cquit
endtry

let s:expected_list = [
      \ {'lnum': 0,   'type': 'E', 'text': "Runaway argument?\n{\\sqrt {{1}} \\end {equation} \\par \\end {document} \nFile ended while scanning use of \\frac ."},
      \ {'lnum': 0,   'type': 'E', 'text': "Emergency stop (fatal error)!"},
      \ {'lnum': 0,   'type': 'E', 'text': 'Runaway argument?'},
      \ {'lnum': 16,  'type': 'E', 'text': 'Paragraph ended before \date  was complete.'},
      \ {'lnum': 11,  'type': 'E', 'text': "Undefined control sequence.\n\\cdashline"},
      \ {'lnum': 0,   'type': 'E', 'text': "pdflatex (file ./a.pdf): PDF inclusion: required page does not exist <1>"},
      \ {'lnum': 5,   'type': 'E', 'text': "Fatal error occurred, no output PDF file produced!"},
      \ {'lnum': 99,  'type': 'W', 'text': 'Package natbib Warning: Citation `Einstein:1905'' on page 1 undefined'},
      \ {'lnum': 12,  'type': 'W', 'text': 'Package refcheck Warning: Unused label `eq:my_equation_label'''},
      \ {'lnum': 9,   'type': 'W', 'text': "Package hyperref Warning: Token not allowed in a PDF string (PDFDocEncoding):\n                removing `\\gamma'"},
      \ {'lnum': 5,   'type': 'W', 'text': "Package hyperref Warning: Composite letter `\\textdotbelow+u'\n                not defined in PD1 encoding,\n                removing `\\textdotbelow'"},
      \ {'lnum': 477, 'type': 'W', 'text': 'LaTeX Warning: Reference `fig:my_picture'' on page 37 undefined'},
      \ {'lnum': 9,   'type': 'W', 'text': 'Overfull \hbox (22.0021pt too wide) in paragraph at lines 9--9'},
      \ {'lnum': 0,   'type': 'W', 'text': 'Package biblatex warning: No "backend" specified, using Biber backend. To use BibTex, load biblatex with the "backend=bibtex" option.'},
      \ {'lnum': 0,   'type': 'W', 'text': "Package biblatex Warning: Data encoding is 'utf8'.\n                Use backend=biber."},
      \ {'lnum': 0,   'type': 'W', 'text': "Package babel Warning: No hyphenation patterns were loaded for\n                the language `Latin'\n                I will use the patterns loaded for \\language=0 instead."},
      \ {'lnum': 18,  'type': 'W', 'text': "Package onlyamsmath Warning: Environment eqnarray or eqnarray* used, please use\nonly the environments provided by the amsmath\npackage"},
      \ {'lnum': 21,  'type': 'W', 'text': "Package typearea Warning: \\typearea used at group level 2.\n               Using \\typearea inside any group, e.g.\n               environments, math mode, boxes, etc. may result in\n               many type setting problems.\n               You should move the command \\typearea\n               outside all groups"},
      \ {'lnum': 0,   'type': 'W', 'text': "Package caption Warning: Unsupported document class (or package) detected,\nusage of the caption package is not recommended."},
      \ {'lnum': 0,   'type': 'W', 'text': "Overfull \\vbox (303.66812pt too high) has occurred while \\output is active []"},
      \ {'lnum': 0,   'type': 'W', 'text': 'Missing character: There is no ^^A (U+0001) in font [lmroman10-regular]:+tlig;!'},
      \ {'lnum': 4,   'type': 'W', 'text': 'Class memoir Warning: As of 2018, \fixpdflayout\ is no longer used'},
      \ {'lnum': 5,   'type': 'W', 'text': "LaTeX Font Warning: Font shape `OT1/cmr/bx/n' in size <8.43146> not available\nsize <8> substituted"},
      \ {'lnum': 6,   'type': 'W', 'text': "LaTeX Warning: No positions in optional float specifier.\nDefault added (so using `tbp')"},
      \ {'lnum': 0,   'type': 'W', 'text': "Package silence Warning: There were 6 warning(s) and 0 error(s).\n                I've killed 5 warning(s) and 0 error(s)."},
      \]
let s:qf = getqflist()
call assert_equal(
      \ len(s:expected_list),
      \ len(s:qf),
      \ "Caught the wrong number of errors!")

for s:n in range(min([len(s:qf), len(s:expected_list)]))
  let s:observed = s:qf[s:n]
  let s:expected = s:expected_list[s:n]
  call assert_equal(s:expected.lnum, s:observed.lnum, 'Failed at index ' . s:n)
  call assert_equal(s:expected.type, s:observed.type, 'Failed at index ' . s:n)
  call assert_equal(s:expected.text, s:observed.text, 'Failed at index ' . s:n)
endfor

call vimtex#test#finished()
