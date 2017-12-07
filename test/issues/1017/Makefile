VIMEXE:=nvim
times:=300m 400m 450m 470m 500m 550m 600m 800m 1000m 2

.PHONY: all times

all: $(times)

$(times): linked
	@cd linked; \
	  SLEEPTIME="$@" $(VIMEXE) -u minivimrc

linked:
	ln -snf main linked
