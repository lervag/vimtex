.PHONY: test

test: cmds.out envs.out
	diff envs.{in,out}
	diff cmds.{in,out}

clean:
	rm *.out

%.out:
	@nvim --headless -u minimal.vim
