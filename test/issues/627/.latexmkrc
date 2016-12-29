$pdflatex = "xelatex --shell-escape -src-specials -synctex=1 -interaction=nonstopmode %O %S";
$preview_continuous_mode = 1;
$pdf_previewer = "start SumatraPDF -reuse-instance -inverse-search -a %O %S";
$pdf_mode = 1;
$clean_ext = 'synctex.gz synctex.gz(busy) acn acr alg aux bbl bcf blg brf dvi fdb_latexmk glg \
glo gls idx ilg ind ist lof log lot lox out paux pdfsync run.xml toc';
$recorder = 1;
