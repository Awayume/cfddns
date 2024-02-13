.PHONY: default full help check check-debian check-ubuntu build build-debian build-ubuntu install clean

SHELL := $(SHELL) -e
VERSION := $(shell git describe --tags --dirty | sed 's/^v//')
BUILD_DIR := ./build
DEBIAN_BUILD_DIR := ${BUILD_DIR}/tmp/debian/cfddns-${VERSION}
BUILD_OUTPUT := ${BUILD_DIR}/dist
DEBIAN_BUILD_OUTPUT := ${BUILD_OUTPUT}/debian
INSTALL_LOCATION := /usr/local/sbin

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
	@$(call console.info, 'Checking the build environment...')
	@$(call console.log, 'Checking for git...')
	@if ! command -v git > /dev/null; then \
		$(call console.error, '"git" not found') \
		$(call fin) \
		exit 127; \
	fi
	@$(call console.log, 'Checking for awk...')
	@if ! command -v awk > /dev/null; then \
		$(call console.error, '"awk" not found') \
		$(call fin) \
		exit 127; \
	fi
	@$(call console.log, 'Checking for sed...')
	@if ! command -v sed > /dev/null; then \
		$(call console.error  '"sed" not found') \
		$(call fin) \
		exit 127; \
	fi
	@$(call console.log, 'Checking for du...')
	@if ! command -v du > /dev/null; then \
		$(call console.error, '"du" not found') \
		$(call fin) \
		exit 127; \
	fi
	@$(call console.log, 'Checking for fakeroot...')
	@if ! command -v fakeroot > /dev/null; then \
		$(call console.error '"fakeroot" not found') \
		$(call fin) \
		exit 127; \
	fi
	@$(call console.info, 'done.')
	@$(call fin)

check-debian:
	@## Check the build environment for Debian.
	@$(call init)
	@$(call console.info, 'Checking the build environment for Debian...')
	@$(call console.log, 'Checking for dpkg-deb...')
	@if ! command -v dpkg-deb > /dev/null; then \
		$(call console.error, '"dpkg-deb" not found') \
		$(call fin) \
		exit 127; \
	fi
	@$(call console.info, 'done.')
	@$(call fin)

check-ubuntu:
	@## An alias for target "check-debian".
	@$(call console.warn, 'This target is an alias for "check-debian".')
	@$(call fin)
	@make check-debian

build:
	@## Build packages for all supported distributions.
	@make check
	@$(call console.info, 'Building...')
	@$(call fin)
	@make build-debian
	@$(call console.info, 'All builds were successful.')
	@$(call fin)

build-debian:
	@## Build a package for Debian.
	@make check-debian
	@$(call init)
	@$(call console.info, 'Building a package for Debian...')
	mkdir -p ${DEBIAN_BUILD_OUTPUT}
	mkdir -p ${DEBIAN_BUILD_DIR}
	mkdir -p ${DEBIAN_BUILD_DIR}/${INSTALL_LOCATION}
	cp src/cfddns.py ${DEBIAN_BUILD_DIR}/${INSTALL_LOCATION}/cfddns
	chmod 755 ${DEBIAN_BUILD_DIR}/${INSTALL_LOCATION}/cfddns
	cp -r ./debian ${DEBIAN_BUILD_DIR}/DEBIAN
	sed -i 's/\[version]/${VERSION}/' ${DEBIAN_BUILD_DIR}/DEBIAN/control
	sed -i 's/\[installed size]/$(shell du -b ./src/cfddns.py | awk "{print int((\$$1 + 1023) / 1024)}")/' ${DEBIAN_BUILD_DIR}/DEBIAN/control
	fakeroot dpkg-deb --build ${DEBIAN_BUILD_DIR} ${DEBIAN_BUILD_OUTPUT}
	@$(call console.info, 'Success.')
	@$(call fin)

build-ubuntu:
	@## An alias for target "build-debian".
	@$(call console.warn, 'This target is an alias for "build-debian".')
	@$(call fin)
	@make build-debian

install:
	@## Install the package appropriate for the environment in which it is running.
	@$(call init)
	@if [ "$$(grep ID_LIKE /etc/os-release)" = "ID_LIKE=debian" ]; then \
		$(call console.log, 'Installing the package for Debian...') \
		apt install -y ${DEBIAN_BUILD_OUTPUT}/cfddns_$(VERSION)_all.deb; \
		$(call console.log, 'done.') \
	else \
		$(call console.error, 'Unsupported platform') \
		$(call fin) \
		exit 1; \
	fi
	@$(call fin)

clean:
	@## Remove the build directory.
	@$(call init)
	@$(call console.info, 'Removing the build directory...')
	rm -rf ${BUILD_DIR}
	@$(call console.info, 'done.')
	@$(call fin)
