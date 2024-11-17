vim.opt.runtimepath:prepend "../.."
vim.cmd [[filetype plugin on]]

local bib = require "vimtex.parser.newbib"

local parsed1 = bib.parse_file "../common/huge.bib"
-- local parsed2 = bib.parse_file "../common/local1.bib"
-- local parsed3 = bib.parse_file "../common/local2.bib"
-- local parsed4 = bib.parse_file "/usr/share/texmf-dist/bibtex/bib/biblatex/biblatex/biblatex-examples.bib"

print(vim.inspect(parsed1[1]))

vim.fn["vimtex#test#finished"]()
