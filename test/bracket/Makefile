DIR = ./
DVI = $(DIR)t)\ (est.dvi
PDF = $(DIR)t)\ (est.pdf

$(PDF):    $(DVI)
	dvipdfmx -o "t) (est.pdf" "t) (est.dvi"

$(DVI):    t)\ (est.tex
	uplatex -synctex=1 -output-directory=$(DIR) "t) (est.tex"

clean:; latexmk -C --outdir=$(DIR) 
