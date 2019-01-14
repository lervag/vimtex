*Please* take the time to report the issue with enough detail to make the request fully understandable/reproducible. If necessary, read [this guide](https://guides.github.com/features/mastering-markdown/) on how to format Github issues.

In most cases, one should include a *minimal example* that consists of a clear and concise description of the issue and **the steps to reproduce** it. This should include something like `vim --servername VIM -u minivimrc minimal.tex`, where `minivimrc` is a minimal vimrc file and `minimal.tex` is a minimal LaTeX sample. An example of the minimal files [may be found here](test/examples/minimal). To use it, copy the files and do `vim --servername VIM -u minivimrc`. Note, one may need to change the `&rtp` (runtime) paths!

Often it is useful to describe both the *expected behaviour* and the *observed behaviour*.

If relevant, please include the content of your `.latexmkrc` file.

Finally, the output of `:VimtexInfo` is often useful. If the problem is related to compilation, one may also inspect the output of `:VimtexCompileOutput`.
