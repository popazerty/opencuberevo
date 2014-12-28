#!/usr/bin/make -f
#
#  Makefile-opencuberevo v0.1.0 (2011-04-07)
#

# Note: You can override all variables by storing them
# in an external file called "build.conf".
-include build.conf

# target platform: cuberevo, cuberevo-mini, cuberevo-mini2, cuberevo-mini-fta, cuberevo-250hd, cuberevo-2000hd, cuberevo-9500hd, cuberevo-100hd
MACHINE ?= cuberevo

# for a list of some other repositories have
# a look at http://git.opendreambox.org/
GIT_URL ?= git://opencuberevo.git.sourceforge.net/gitroot/opencuberevo/openembedded

# in case you want to send pull requests or generate patches
#GIT_AUTHOR_NAME ?= Your Name
#GIT_AUTHOR_EMAIL ?= you@example.com

# set this to the number of CPU cores to use for parallel build
NUM_THREADS ?= 2

# you should not need to change anything below
BB_URL ?= git://git.opendreambox.org/git/bitbake
BB_BRANCH ?= 1.8-dream

GIT = git
GIT_BRANCH = master

PWD := $(shell pwd)

#OE_BASE = $(PWD)/cuberevo
OE_BASE = $(PWD)/$(MACHINE)

GIT_DIR = $(OE_BASE)/openembedded

ARCH = sh4

all: initialize
	@echo
	@echo "Openembedded for the Cuberevo environment has been initialized"
	@echo "properly. Now you can either:"
	@echo
	@echo "  - make the 'image'-target to build an image, or"
	@echo "  - go into build/, source env.source and start on your own!"
	@echo

bb: bb/.git

bb/.git:
	@if [ -e bb/.svn ]; then \
		echo "BitBake needs to be updated. Please remove the \"bb\" directory manually!"; \
		exit 1; \
	fi
	$(GIT) clone -n $(BB_URL) bb
	cd bb && ( \
		if [ -n "$(GIT_AUTHOR_EMAIL)" ]; then git config user.email "$(GIT_AUTHOR_EMAIL)"; fi; \
		if [ -n "$(GIT_AUTHOR_NAME)" ]; then git config user.name "$(GIT_AUTHOR_NAME)"; fi; \
		$(GIT) branch --track $(BB_BRANCH) origin/$(BB_BRANCH) || true; \
		$(GIT) checkout -f $(BB_BRANCH) \
	)

bb-update: bb/.git
	cd bb && $(GIT) pull origin $(BB_BRANCH)

.PHONY: bb-update image initialize openembedded-update openembedded-update-all

image: bb-update initialize openembedded-update
	cd $(OE_BASE)/build; . ./env.source; bitbake -k cuberevo-image

remove-init:
	rm -rf $(OE_BASE)/build/conf/local.conf; rm -rf $(OE_BASE)/build/env.source

initialize: remove-init $(OE_BASE)/cache sources $(OE_BASE)/build $(OE_BASE)/build/conf \
	$(OE_BASE)/build/tmp $(GIT_DIR) $(OE_BASE)/build/conf/local.conf \
	$(OE_BASE)/build/env.source bb

openembedded-update: $(GIT_DIR)
	cd $(GIT_DIR) && $(GIT) pull origin $(GIT_BRANCH)

openembedded-update-all:
	@for dir in dm*/openembedded; do \
		echo "running $(GIT) pull origin $(GIT_BRANCH) in $$dir"; \
		cd $$dir && $(GIT) pull origin $(GIT_BRANCH) && cd -; \
	done


$(OE_BASE)/build $(OE_BASE)/build/conf $(OE_BASE)/build/tmp $(OE_BASE)/cache sources:
	mkdir -p $@

$(OE_BASE)/build/conf/local.conf:
	echo 'DL_DIR = "$(PWD)/sources"' > $@
	echo 'OE_BASE = "$(OE_BASE)"' >> $@
	echo 'BBFILES = "$(GIT_DIR)/recipes/*/*.bb"' >> $@
	echo 'PREFERRED_PROVIDERS += " virtual/$${TARGET_PREFIX}gcc-initial:gcc-cross-initial"' >> $@
	echo 'PREFERRED_PROVIDERS += " virtual/$${TARGET_PREFIX}gcc:gcc-cross"' >> $@
	echo 'PREFERRED_PROVIDERS += " virtual/$${TARGET_PREFIX}g++:gcc-cross"' >> $@
	echo 'MACHINE = "$(MACHINE)"' >> $@
	echo 'TARGET_OS = "linux"' >> $@
	echo 'DISTRO = "opencuberevo"' >> $@
	echo 'CACHE = "$(OE_BASE)/cache/oe-cache.$${USER}"' >> $@
	echo 'BB_NUMBER_THREADS = "$(NUM_THREADS)"' >> $@
	echo 'CVS_TARBALL_STASH = "http://dreamboxupdate.com/sources-mirror/"' >> $@
	echo 'TOPDIR = "$${OE_BASE}/build"' >> $@
	echo 'IMAGE_KEEPROOTFS = "0"' >> $@

$(OE_BASE)/build/env.source:
	echo 'OE_BASE=$(OE_BASE)' > $@
	echo 'export BBPATH="$(GIT_DIR)/:$(PWD)/bb/:$${OE_BASE}/build/"' >> $@
	echo 'PATH=$(PWD)/bb/bin:$${OE_BASE}/build/tmp/cross/$(ARCH)/bin:$${PATH}' >> $@
	echo 'export PATH' >> $@
	echo 'export LD_LIBRARY_PATH=' >> $@
	echo 'export LANG=C' >> $@
	cat $@

$(GIT_DIR): $(GIT_DIR)/.git

$(GIT_DIR)/.git:
	@if [ -d $(GIT_DIR)/_MTN ]; then echo "Please remove your old monotone repository from $(GIT_DIR)!"; exit 1; fi
	$(GIT) clone -n $(GIT_URL) $(GIT_DIR)
	cd $(GIT_DIR) && ( \
		if [ -n "$(GIT_AUTHOR_EMAIL)" ]; then git config user.email "$(GIT_AUTHOR_EMAIL)"; fi; \
		if [ -n "$(GIT_AUTHOR_NAME)" ]; then git config user.name "$(GIT_AUTHOR_NAME)"; fi; \
		$(GIT) branch --track $(GIT_BRANCH) origin/$(GIT_BRANCH) || true; \
		$(GIT) checkout -f $(GIT_BRANCH) \
	)
