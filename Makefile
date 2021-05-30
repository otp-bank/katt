.NOTPARALLEL:

CHMOD := $(shell command -v chmod 2>/dev/null)
CURL := $(shell command -v curl 2>/dev/null)
DIFF := $(shell command -v diff 2>/dev/null)
LN := $(shell command -v ln 2>/dev/null)

OTP_RELEASE = $(shell erl -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().'  -noshell)

ifdef CI
REBAR = ./rebar3.OTP$(OTP_RELEASE)
else
REBAR ?= $(shell command -v rebar3 2>/dev/null || echo "./rebar3.OTP$(OTP_RELEASE)")
endif

ifdef CI
export KATT_DEV_MODE=true
endif

ifneq (,$(wildcard .rebar/DEV_MODE))
export KATT_DEV_MODE=true
endif

ifneq (,$(wildcard .rebar/BARE_MODE))
export KATT_BARE_MODE=true
endif

SRCS := $(wildcard src/* include/* rebar.config)
SRCS := $(filter-out src/katt_blueprint.erl,$(SRCS))

SRC_BEAMS := $(patsubst src/%.erl, ebin/%.beam, $(wildcard src/*.erl))

.PHONY: all
ifdef KATT_BARE_MODE
all: ebin/katt.app
else
all: ebin/katt.app escript
endif

# Clean

.PHONY: conf_clean
conf_clean:
	:

.PHONY: clean
clean:
	$(REBAR) clean

.PHONY: distclean
distclean:
	$(MAKE) clean
	$(RM) -r _build
	$(RM) doc/*.html
	$(RM) doc/edoc-info
	$(RM) doc/erlang.png
	$(RM) doc/stylesheet.css
	$(RM) -r logs
	$(RM) src/katt_blueprint.erl

.PHONY: clean-tests
clean-tests:
	@ rm -rf _build/test/lib

# Docs

.PHONY: docs
docs:
	$(REBAR) edoc

# Compile

ebin/katt.app: compile

.PHONY: escript
escript: ebin/katt.app
	$(REBAR) escriptize
	./_build/default/bin/katt --help

.PHONY: compile
compile: $(SRCS)
	$(REBAR) compile

# Tests

.rebar/DEV_MODE:
	mkdir -p .rebar
	touch .rebar/DEV_MODE

.rebar/BARE_MODE:
	mkdir -p .rebar
	touch .rebar/BARE_MODE

.PHONY: test
# Would be nice to include elvis to test, but it fails on OTP-18
# test: elvis
test: test_cli
test: eunit ct xref dialyzer cover

.PHONY: elvis
elvis:
	$(REBAR) lint

ifdef KATT_BARE_MODE
.PHONY: test_cli
test_cli:
	: Skipping $@ in BARE_MODE
else
test_cli: .rebar/DEV_MODE
	./_build/default/bin/katt hostname=httpbin.org my_name=Joe your_name=Mike protocol=https: -- \
		./doc/example-httpbin.apib >test/cli || { cat test/cli && exit 1; }
	./_build/default/bin/katt from-har --apib -- ./doc/example-teapot.har > test/example-teapot.apib && \
		$(DIFF) -U0 doc/example-teapot.apib test/example-teapot.apib
endif

.PHONY: eunit
eunit:
	@ $(MAKE) clean-tests
	$(REBAR) eunit

# @ rm -rf _build

.PHONY: ct
ct:
	@ $(MAKE) clean-tests
	$(REBAR) ct

.PHONY: xref
xref:
	$(REBAR) xref

$(DEPS_PLT):
	$(DIALYZER) --build_plt --apps $(ERLANG_DIALYZER_APPS) -r deps --output_plt $(DEPS_PLT)

.PHONY: dialyzer
dialyzer: $(DEPS_PLT)
	$(REBAR) dialyzer

.PHONY: cover
cover:
	@ $(MAKE) clean-tests
	$(REBAR) cover -v

.PHONY: publish
publish: docs
	$(REBAR) hex publish -r hexpm --yes

.PHONY: rebar3.OTP18
rebar3.OTP18:
	$(CURL) -fqsS -L -o $@ https://github.com/erlang/rebar3/releases/download/3.13.3/rebar3
	$(CHMOD) +x $@

.PHONY: rebar3.OTP19
rebar3.OTP19:
	$(CURL) -fqsS -L -o $@ https://github.com/erlang/rebar3/releases/download/3.15.2/rebar3
	$(CHMOD) +x $@

.PHONY: rebar3.OTP20
rebar3.OTP20:
	$(LN) -sf rebar3.OTP19 $@

.PHONY: rebar3.OTP21
rebar3.OTP21:
	$(LN) -sf rebar3.OTP19 $@

.PHONY: rebar3.OTP22
rebar3.OTP22:
	$(CURL) -fqsS -L -o $@ https://github.com/erlang/rebar3/releases/download/3.16.1/rebar3
	$(CHMOD) +x $@

.PHONY: rebar3.OTP23
rebar3.OTP23:
	$(LN) -sf rebar3.OTP22 $@

.PHONY: rebar3.OTP24
rebar3.OTP24:
	$(LN) -sf rebar3.OTP22 $@
