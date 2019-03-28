#!/bin/bash

# set up "solarized" color scheme in Linux Mint 18.x

# 1. enable the color scheme in terminal

## From terminal emulator select "Edit" -> "Preferences":
## - select "Profiles" tab and create "New"
## -- select "Colors" tab
## -- -- select "Solarized_dark" from the built-in schemes in the "Text and Background Color" section"
## -- -- select "Solarized" from the built-in schemes in the "Palette" section

# 2. set up color support of ls command (the LS_COLORS environment variable)

DOT_DIRCOLORS=.dircolors

cd
if [ ! -d dircolors-solarized ]; then
	# clone repo
	git clone https://github.com/seebi/dircolors-solarized.git

	# back up existing dotfile
	[ -f ~/$DOT_DIRCOLORS ] && mv -fv ~/$DOT_DIRCOLORS ~/$DOT_DIRCOLORS.bak

	# create new link
	ln -s dircolors-solarized/dircolors.256dark ~/$DOT_DIRCOLORS

	# add settings in .bashrc, if they are missing
	if [ -e ~/.bashrc ]; then
		grep "$DOT_DIRCOLORS" ~/.bashrc
		[ $? != 0 ] && echo "[ -f ~/$DOT_DIRCOLORS ] && eval \"\$(dircolors ~/$DOT_DIRCOLORS)\"" >> ~/.bashrc
	fi
fi
