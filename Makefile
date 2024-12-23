paper/paper.pdf: paper/paper.tex paper/header.tex
	cd paper && latexmk -bibtex -pdf paper.tex
paper/header.tex: paper/paper.yml paper/prep.rb
	cd paper && ruby prep.rb