.PHONY: default full help check build build-debian build-ubuntu install clean

BUILD_DIR = ./build

define init
  printf '\033[90m';
endef

define fin
	printf '\033[m';
endef

define console.log
	printf '\033[m%s\033[90m\n' $1;
endef

define console.info
	printf '\033[32minfo: %s\033[90m\n' $1;
endef

define console.warn
	printf '\033[33mwarn: %s\033[90m\n' $1;
endef

define console.error
	printf '\033[31merror: %s\033[90m\n' $1;
endef


default:
	@## An alias for target "build".
	@make build

full:
	@## An alias for target "clean" and "build".
	@make clean
	@make build

help:
	@## Print this message and exit.
	@echo "Usage: make [options] [target] ...\nTargets:"
	@awk 'BEGIN{FS=":"} /^([a-z]|-)+:/{target=$$1; getline; printf "  %-20s%s\n", target, substr($$0, 6)}' $(MAKEFILE_LIST)

check:
	@## Check the build environment.
	@$(call init)
	@if ! command -v git > /dev/null; then \
		$(call console.error, '"git" not found') \
		$(call fin) \
		exit 127; \
	fi
	@if ! command -v awk > /dev/null; then \
		$(call console.error, '"awk" not found') \
		$(call fin) \
	fi
	@$(call fin)

build:
	@## Build packages for all supported distributions.
	@make check
	@make build-debian

build-debian:
	@## Build a package for Debian.
	@$(call init)
	@$(call console.error, "Not implemented yet")
	@$(call fin)

build-ubuntu:
	@## An alias for target "build-debian".
	@make build-debian

install:
	@## Install the package appropriate for the environment in which it is running.
	@$(call init)
	@$(call console.error, "Not implemented yet")
	@$(call fin)

clean:
	@## Remove the build directory.
	@$(call init)
	@$(call console.log, 'Removing the build directory...')
	rm -rf ${BUILD_DIR}
	@$(call console.log, 'done.')
	@$(call fin)
