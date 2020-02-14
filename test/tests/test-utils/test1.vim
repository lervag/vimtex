set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

let s:tree = vimtex#util#tex2tree(
      \ '\newlabel{test}{{\textsc {D\''ej\`a vu}\relax }{caption.1}{}}')
call vimtex#test#assert_equal(len(s:tree), 3)
call vimtex#test#assert_equal(s:tree[2][0][0], '\textsc')

quit!
