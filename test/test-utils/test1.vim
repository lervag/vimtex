set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

let s:tree = vimtex#util#tex2tree(
      \ '\newlabel{test}{{\textsc {D\''ej\`a vu}\relax }{caption.1}{}}')
call assert_equal(3, len(s:tree))
call assert_equal('\textsc', s:tree[2][0][0])

" Test for #1599: Fail label completion due to tex2unicode
let s:line = vimtex#util#tex2unicode('{\textsc {D\''ej\`a}\relax }')
call assert_equal('{\textsc {Déjà}\relax }', s:line)

let s:str = 'title={Temporary, complete list of references}'
call assert_equal([s:str], vimtex#util#texsplit(s:str))

call vimtex#test#finished()
