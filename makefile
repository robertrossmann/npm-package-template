# Defining shell is necessary in order to modify PATH
SHELL := sh
export PATH := node_modules/.bin/:$(PATH)
export NODE_OPTIONS := --trace-deprecation

# On CI servers, use the `npm ci` installer to avoid introducing changes to the package-lock.json
# On developer machines, prefer the generally more flexible `npm install`. 💪
NPM_I := $(if $(CI), ci, install)

# Modify these variables in local.mk to add flags to the commands, ie.
# MOCHA_FLAGS += --reporter nyan
# Now mocha will be invoked with the extra flag and will show a nice nyan cat as progress bar 🎉
MOCHA_FLAGS :=
BABEL_FLAGS :=
ESLINT_FLAGS :=
NPM_FLAGS :=
NYC_FLAGS :=

SRCFILES = $(shell find src test -name "*.mjs")
DSTFILES = $(patsubst %.mjs, %.js, $(SRCFILES))
GITFILES = $(patsubst utils/githooks/%, .git/hooks/%, $(wildcard utils/githooks/*))
SRCGLOB = "**/*.mjs"
TSTGLOB = "test/**/*.test.js"

# Do this when make is invoked without targets
all: recompile $(GITFILES)


# GENERIC TARGETS

node_modules: package.json
	npm $(NPM_I) $(NPM_FLAGS) && touch node_modules

# Default compilation target for all source files
%.js: %.mjs node_modules babel.config.js
	babel $< --out-file $@ $(BABEL_FLAGS)

# Default target for all possible git hooks
.git/hooks/%: utils/githooks/%
	cp $< $@

coverage/lcov.info: $(DSTFILES) nyc.config.js
	nyc $(NYC_FLAGS) mocha $(MOCHA_FLAGS) $(TSTGLOB)


# TASK DEFINITIONS

compile: $(DSTFILES)

coverage: coverage/lcov.info

recompile: install
	babel . --extensions .mjs --out-dir . $(BABEL_FLAGS)

install: node_modules $(GITFILES)

lint: force install
	eslint --cache --report-unused-disable-directives $(ESLINT_FLAGS) $(SRCGLOB)
	remark --quiet .
	fixpack

test: force compile
	mocha $(MOCHA_FLAGS) $(TSTGLOB)

inspect: force compile
	mocha --inspect --inspect-brk $(MOCHA_FLAGS) $(TSTGLOB)

watch: force compile
	mocha $(MOCHA_FLAGS) --watch $(TSTGLOB)

unlock: pristine
	rm -f package-lock.json
	touch package.json

clean:
	rm -rf .nyc_output coverage docs .eslintcache
	find . -not -path '*/node_modules/*' -name '*.log' -print -delete

distclean: clean
	rm -f $(shell find src test -name "*.js")

pristine: distclean
	rm -rf node_modules

.PHONY: force

-include local.mk
