source common.vim

silent edit test-loading.tex

call assert_true(index(keys(b:vimtex_syntax), 'glossaries') >= 0)
call assert_true(index(keys(b:vimtex_syntax), 'amsmath') >= 0)

call vimtex#test#finished()
