# Issue descriptions

Please see the [issue template](ISSUE_TEMPLATE.md) for how to write a good
issue description. In short, it should contain the following:

1. Describe the issue in detail, include steps to reproduce the issue
2. Include a minimal working example
3. Include a minimal vimrc file
4. If you have a `.latexmkrc` file, please mention it and provide the relevant
   content

# Guide for code contributions

## Branch model

vimtex is developed mainly through the master branch, and pull requests should
be [fork based](https://help.github.com/articles/using-pull-requests/).

## Code style used with vimtex

When submitting code for vimtex, please adhere to the following standards:

- Use `shiftwidth=2` - no tabs!
- Write readable code
  - Break lines for readability
    - Line should not be longer than 80 columns
  - Use comments:
    - For complex code that is difficult to understand
    - Simple code does not need comments
  - Use (single) empty lines to separate logical blocks of code
  - Use good variable names
    - The name should indicate what the variable is/does
    - Variable names should be lower case
    - Local function variables should be preceded with `l:`
  - Prefer single quoted strings
  - See also the [Google vimscript style
    guide](https://google.github.io/styleguide/vimscriptguide.xml)
- Use markers for folding
  - I generally only fold functions, and I tend to group similar functions so
    that when folded, I get a nice structural overview of a file
  - See some of the files for examples of how I do this

