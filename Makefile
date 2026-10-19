LUA_LANGUAGE_SERVER ?= lua-language-server
STYLUA ?= stylua
VIMRUNTIME ?= $(shell nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' -c q 2>&1)
export VIMRUNTIME

.NOTPARALLEL:
.PHONY: all test check lint format-check format

all: check test

test:
	@echo '==> test'
	@sh tests/run.sh

lint:
	@echo '==> lint'
	@log_path=$$(mktemp -d) && \
		$(LUA_LANGUAGE_SERVER) --check . --checklevel=Information \
			--check_format=pretty --logpath "$$log_path"; \
		status=$$?; rm -rf "$$log_path"; exit $$status

format-check:
	@echo '==> format-check'
	@$(STYLUA) --check lua tests

check: lint format-check

format:
	@$(STYLUA) lua tests
