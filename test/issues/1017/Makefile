.PHONY: all times

times:=300m 400m 450m 470m 500m 550m 600m 800m

all: $(times)

$(times): linked
	@cd linked; \
	  SLEEPTIME="$@" nvim -u minivimrc

linked:
	ln -snf main linked
