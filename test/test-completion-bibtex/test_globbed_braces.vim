set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0


" Uses s:files_manual() since there is no bcf file
silent edit test_globbed_braces.tex
let s:candidates = vimtex#test#completion('\cite{', '')
call assert_equal(2, len(s:candidates))
bwipeout!


" Uses bcf parser
call writefile(
      \ ['<bcf:datasource type="file" datatype="bibtex">test_globbed_{1,2}.bib</bcf:datasource>'],
      \ 'test_globbed_braces.bcf')
silent edit test_globbed_braces.tex
let s:candidates = vimtex#test#completion('\cite{', '')
call assert_equal(2, len(s:candidates))
call delete('test_globbed_braces.bcf')


call vimtex#test#finished()
