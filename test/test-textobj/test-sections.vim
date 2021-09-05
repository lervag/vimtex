set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

setfiletype tex

call vimtex#test#keys('daP',
      \ [
      \   '\chapter{section 1}',
      \   '  Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \   'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At',
      \   'vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren,',
      \   'no sea takimata sanctus est Lorem ipsum dolor sit amet.',
      \   '',
      \   'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \   'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At',
      \   'vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren,',
      \   'no sea takimata sanctus est Lorem ipsum dolor sit amet.',
      \   '',
      \   '\chapter{section 2}',
      \   '  Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \   'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At',
      \   'vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren,',
      \   'no sea takimata sanctus est Lorem ipsum dolor sit amet.',
      \ ], [
      \   '\chapter{section 2}',
      \   '  Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \   'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At',
      \   'vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren,',
      \   'no sea takimata sanctus est Lorem ipsum dolor sit amet.',
      \])

call vimtex#test#keys('diP',
      \ [
      \   '\chapter{section 2}',
      \   '  Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \   'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At',
      \   'vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren,',
      \   'no sea takimata sanctus est Lorem ipsum dolor sit amet.',
      \   '',
      \   '\chapter{section 3}',
      \   '  Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \   'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.',
      \ ], [
      \   '\chapter{section 2}',
      \   '',
      \   '\chapter{section 3}',
      \   '  Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \   'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.',
      \])

call vimtex#test#keys('5jd2aP',
      \ [
      \   'Hello world.',
      \   '',
      \   '\section{Outer}',
      \   'Some text here',
      \   '',
      \   '\subsection{Inner 1}',
      \   'Some text here',
      \   '',
      \   '\subsection{Inner 2}',
      \   'Some text here',
      \   '',
      \   '\subsection{Inner 3}',
      \   'Some text here',
      \ ], [
      \   'Hello world.',
      \   '',
      \ ])

call vimtex#test#finished()
