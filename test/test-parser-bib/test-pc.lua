vim.opt.runtimepath:prepend "../.."
vim.cmd [[filetype plugin on]]

local bib = require "vimtex.parser.bib"

vim.fn.assert_equal(
  {
    type = "misc",
    key = "key2",
    source_lnum = 0,
    source_file = "__string__",
    title = "A new title",
    year = "1960",
    author = "##name1## and Mr. Bar",
  },
  bib.pc_parse_string([[
  @misc{key2,
    title = {A new title},
    author = name1 # " and Mr. Bar",
    year = "1960",
  }
]])[1]
)

vim.fn.assert_equal(
  {
    type = "misc",
    key = "key2",
    source_lnum = 1,
    source_file = "__string__",
    title = "A new title",
    year = "1960",
    author = "Mr. Foo and Mr. Bar",
  },
  bib.pc_parse_string([[
  @string{name1 = "Mr. Foo"}
  @misc{key2,
    title = {A new title},
    author = name1 # " and Mr. Bar",
    year = "1960",
  }
]])[1]
)

local test_file_expected = {
  {
    type = "SomeType",
    key = "key1",
    source_lnum = 12,
    source_file = "test.bib",
    title = "Some title, with a comma in it",
    year = "2017",
    author = "Author1 and Author2",
    other = "Something else",
  },
  {
    type = "misc",
    key = "key2",
    source_lnum = 19,
    source_file = "test.bib",
    title = "A new title",
    author = "Mr. Foo and Mr. Bar",
    year = "1960",
  },
  {
    type = "misc",
    key = "key3",
    source_lnum = 25,
    source_file = "test.bib",
    tag1 = "{Bib}\\TeX",
    tag2 = "{Bib}\\TeX",
    tag3 = "{Bib}\\TeX",
    publisher = "nobody",
    year = "2005",
  },
  {
    type = "misc",
    key = "key4",
    source_lnum = 33,
    source_file = "test.bib",
  },
  {
    type = "misc",
    key = "key5",
    source_lnum = 37,
    source_file = "test.bib",
    author = "text here something",
    title = "title: Angew.~Chem. Int.~Ed.",
  },
  {
    type = "errorintags",
    key = "key6",
    source_lnum = 42,
    source_file = "test.bib",
    title = "some title",
    unparsed_content = 'author = "should not work",',
  },
  {
    type = "article",
    key = "knuth",
    source_lnum = 47,
    source_file = "test.bib",
    title = "Other title",
    year = "1938",
    author = "Donald Knuth",
  },
  {
    type = "article",
    key = "knuth-single-line",
    source_lnum = 54,
    source_file = "test.bib",
    title = "Other title",
    year = "1938",
    author = "Donald Knuth",
  },
}
local test_file_parsed = bib.pc_parse_file "test.bib"
for i = 1, #test_file_parsed do
  vim.fn.assert_equal(test_file_expected[i], test_file_parsed[i])
end

-- For performance testing
-- local parsed = bib.parse "../common/huge.bib"
-- local parsed = bib.pc_parse_file "../common/huge.bib"

vim.fn["vimtex#test#finished"]()
