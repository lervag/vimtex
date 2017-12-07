VIMEXE:=vim -es --servername VIM

.PHONY: all

all: 300m 400m 450m 470m 500m 550m 600m 800m

%: linked
	@SLEEPTIME="$@" $(VIMEXE) -u minivimrc

linked:
	ln -snf main linked
