set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

let s:output = vimtex#util#win_clean_output(["Usuário\r"])
call assert_equal(["Usuário"], s:output)

call vimtex#test#finished()
