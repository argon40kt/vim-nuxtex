DIR = ./
TEX = test.tex
DVI = test.dvi
PDF = test.pdf
VPATH = subdir

$(PDF):    $(DVI)
	dvipdfmx -o $@ $<

$(DVI):    $(TEX)
	uplatex -synctex=1 -output-directory=$(DIR) $<

clean:     $(TEX)
	latexmk -C $<
