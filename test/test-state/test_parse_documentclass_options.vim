set nocompatible
set runtimepath^=../..
filetype plugin on

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

silent edit test_parse_documentclass_options.tex

if empty($INMAKE) | finish | endif

call assert_equal('scrbook', b:vimtex.documentclass)

let s:options = {
      \  'fontsize': '12pt',
      \  'headings': 'big',
      \  'english': v:true,
      \  'paper': 'a4',
      \  'twoside': v:true,
      \  'open': 'right',
      \  'DIV': '14',
      \  'BCOR': '20mm',
      \  'headinclude': v:false,
      \  'footinclude': v:false,
      \  'mpinclude': v:false,
      \  'titlepage': v:true,
      \  'parskip': 'half',
      \  'headsepline': v:true,
      \  'chapterprefix': v:false,
      \  'appendixprefix': 'Appendix',
      \  'appendixwithprefixline': v:true,
      \  'bibliography': 'totoc',
      \  'toc': 'graduated',
      \  'numbers': 'noenddot',
      \ }
call assert_equal(s:options, b:vimtex.documentclass_options)

call vimtex#test#finished()
