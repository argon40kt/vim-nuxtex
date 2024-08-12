DIR = ./
DVI = $(DIR)test.dvi
PDF = $(DIR)test.pdf

$(PDF):    $(DVI)
	dvipdfmx -o $(PDF) $<

$(DVI):    test.tex
	platex -kanji=sjis -synctex=1 -output-directory=$(DIR) $<

clean:; latexmk -C --outdir=$(DIR) 
