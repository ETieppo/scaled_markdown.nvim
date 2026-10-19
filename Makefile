CYAN ?= cyan
export CYAN

SRC_FILES := $(shell find src -name '*.tl')
TEST_FILES := $(shell cd tests && find . -name '*.tl' -not -path './build/*')

.NOTPARALLEL:
.PHONY: all test check build

all: build

test:
	@echo '==> test'
	@sh tests/run.sh

check:
	@echo '==> check'
	@$(CYAN) check -q $(SRC_FILES)
	@cd tests && $(CYAN) check -q $(TEST_FILES)

build: test check
	@echo '==> build'
	@$(CYAN) build -q
