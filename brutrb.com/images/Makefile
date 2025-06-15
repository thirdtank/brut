DOT_FILES = *.dot
PNG_FILES = $(patsubst %.dot,%.png,$(DOT_FILES))

%.png : %.dot
	dot -Gdpi=300 -Tpng $< -o$@

%.svg : %.dot
	dot -Gdpi=300 -Tsvg $< -o$@

all: $(PNG_FILES)
