# dotfiles/Makefile

# Makefile
# Adapted from jessfraz/dotfiles/Makefile
# https://github.com/jessfraz/dotfiles/blob/master/Makefile
#	install: 
#		Execute /bin/bittersweet.sh to install all the things
#	dotfiles:
#		Creates soft symlinks for dotfiles in $HOME
# 	test:
#		Execute /bin/test.sh to lint shell sctipts with shellcheck


.PHONY: all install dotfiles test

all: install dotfiles

install: 
	
	./bin/bittersweet.sh hailmary

dotfiles:

	for file in $(shell find $(CURDIR) -name ".*" \
				-not -name ".gitignore" \
				-not -name ".travis.yml" \
				-not -name ".git" \
				-not -name ".ssh" \
				-not -name ".gnupg
				-not -name ".DS_Store"); do \
		f=$$(basename $$file); \
		ln -sfn $$file $(HOME)/$$f; \
	done; \

	mkdir -p "$(HOME)/.gnupg";
	ln -sfn "$(CURDIR)/.gnupg/gpg.conf" "$(HOME)/.gnupg/gpg.conf";
	ln -sfn "$(CURDIR)/.gnupg/gpg-agent.conf" "$(HOME)/.gnupg/gpg-agent.conf";

	mkdir -p "$(HOME)/.ssh";
	ln -sfn "$(CURDIR)/.ssh/config" "$(HOME)/.ssh/config";

test: 

	./bin/test.sh
