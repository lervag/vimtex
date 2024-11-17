vim.opt.runtimepath:prepend "../.."
vim.cmd [[filetype plugin on]]

local pc = require "vimtex.parser.combinators"
local g = require "vimtex.parser.general"

-- Test operators
local concatenated = (g.letter .. g.digit):run "a4"
local added = (g.letter + g.digit):run "a4"
vim.fn.assert_equal("a4", concatenated.result)
vim.fn.assert_equal({ "a", "4" }, added.result)

-- Test recursives with lazy
local group_exc
group_exc = pc.sequence_flat {
  g.lb,
  pc.many_flat(pc.choice {
    g.letters,
    pc.lazy(function()
      return group_exc
    end),
  }),
  g.rb,
}
local group_exc_result = group_exc:run "{foo{bar}baz}more"
vim.fn.assert_equal("{foo{bar}baz}", group_exc_result.result)

vim.fn["vimtex#test#finished"]()
