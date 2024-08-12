DIR = ./subdir/
TEX = test.tex
DVI = $(DIR)test.dvi
PDF = $(DIR)test.pdf
VPATH = subdir

$(PDF):    $(DVI)
	dvipdfmx -o $@ $<

$(DVI):    $(TEX)
	uplatex -synctex=1 -output-directory=$(DIR) $<

clean:     $(TEX)
	latexmk -C $<
