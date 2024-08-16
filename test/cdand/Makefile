DIR = subdir
TEX = $(DIR)/test.tex
DVI = $(DIR)/test.dvi
PDF = $(DIR)/test.pdf

$(PDF):    $(DVI)
	cd $(DIR) && dvipdfmx -o test.pdf test.dvi

$(DVI):    $(TEX)
	cd $(DIR) && uplatex -synctex=1 test.tex

clean:
	cd $(DIR) && latexmk -C
