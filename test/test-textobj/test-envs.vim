set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

setfiletype tex

call vimtex#test#keys('die',
      \ [
      \  '\begin{complexenvironment}[option1,',
      \  '  option2]{first extra argument}',
      \  '  {second extra',
      \  '  argument}',
      \  '  Hello world!',
      \  '\end{complexenvironment}',
      \ ], [
      \  '\begin{complexenvironment}[option1,',
      \  '  option2]{first extra argument}',
      \  '  {second extra',
      \  '  argument}',
      \  '\end{complexenvironment}',
      \ ])

call vimtex#test#keys('die',
      \ [
      \  '\begin{complexenvironment}[option1,',
      \  '  option2]{first extra argument}',
      \  '',
      \  '  {second extra',
      \  '  argument}',
      \  '  Hello world!',
      \  '\end{complexenvironment}',
      \ ], [
      \  '\begin{complexenvironment}[option1,',
      \  '  option2]{first extra argument}',
      \  '\end{complexenvironment}',
      \ ])

call vimtex#test#keys('dae',
      \ [
      \  '\begin{complexenvironment}[option1,',
      \  '  option2]{first extra argument}',
      \  '  {second extra',
      \  '  argument}',
      \  '  Hello world!',
      \  '\end{complexenvironment}',
      \ ], [''])

call vimtex#test#keys('4j$d2ae',
      \ [
      \   '\begin{document}',
      \   '  \begin{center}',
      \   '      \begin{align}',
      \   '        a = b',
      \   '      \end{align}',
      \   '  \end{center}',
      \   '\end{document}',
      \ ],
      \ [
      \   '\begin{document}',
      \   '  ',
      \   '\end{document}',
      \ ])

" call vimtex#test#keys('3jdie',
"       \ [
"       \   '\begin{minted}',
"       \   '  {',
"       \   '    "contacts": [',
"       \   '      {',
"       \   '        "source_id": "mandatory"',
"       \   '      }',
"       \   '    ]',
"       \   '  }',
"       \   '\end{minted}',
"       \ ],
"       \ [
"       \   '\begin{minted}',
"       \   '  {',
"       \   '    "contacts": [',
"       \   '      {',
"       \   '        "source_id": "mandatory"',
"       \   '      }',
"       \   '    ]',
"       \   '  }',
"       \   '\end{minted}',
"       \ ])

call vimtex#test#finished()
