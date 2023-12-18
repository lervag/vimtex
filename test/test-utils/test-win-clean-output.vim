set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

let s:output = vimtex#util#win_clean_output(["Usuário"])
call assert_equal(["UsuÃ¡rio"], s:output)

call vimtex#test#finished()
