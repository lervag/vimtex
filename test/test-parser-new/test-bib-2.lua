vim.opt.runtimepath:prepend "../.."
vim.cmd [[filetype plugin on]]
vim.o.more = false

local bib = require "vimtex.parser.newbib"
local pc = require "vimtex.parser.combinators"

local parsed = bib.parse_file "../common/huge.bib"
-- local parsed = bib.parse_file "../common/local1.bib"
-- local parsed = bib.parse_file "../common/local2.bib"
-- local parsed = bib.parse_file "/usr/share/texmf-dist/bibtex/bib/biblatex/biblatex/biblatex-examples.bib"

pc.show_errors()
-- print(vim.inspect(parsed))
-- print(vim.inspect(parsed[9]))
-- print(vim.inspect(parsed[10]))
-- print(vim.inspect(parsed[11]))
-- print(vim.inspect(parsed[12]))

vim.fn["vimtex#test#finished"]()
