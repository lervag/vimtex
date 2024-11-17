vim.opt.runtimepath:prepend "../.."
vim.cmd [[filetype plugin on]]

local pc = require "vimtex.parser.combinators"
local g = require "vimtex.parser.general"

local char_succeed = (g.char "x"):run "x"
local char_fail = (g.char "x"):run "y"
vim.fn.assert_equal("x", char_succeed.result)
vim.fn.assert_equal("char: unable to match 'x'", char_fail.error)

local letter1 = g.letter:run "x"
local letter2 = g.letter:run "1"
local letters = g.letters:run "foo123"
vim.fn.assert_equal("x", letter1.result)
vim.fn.assert_equal("letter: did not match", letter2.error)
vim.fn.assert_equal("foo", letters.result)

local str = pc.left { g.letters, g.whitespaces } + g.float
local parsed = str:run "foobar   142.32"
vim.fn.assert_equal({ "foobar", 142.32 }, parsed.result)

vim.fn["vimtex#test#finished"]()
