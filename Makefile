GO ?= go
GORELEASER ?= goreleaser

OTELCOL_BUILDER_VERSION ?= 0.68.0
OTELCOL_BUILDER_DIR ?= ${HOME}/bin
OTELCOL_BUILDER ?= ${OTELCOL_BUILDER_DIR}/ocb

DISTRIBUTIONS ?= "nr-otel-collector"

ci: build

build: go ocb
	@./scripts/build.sh -d "${DISTRIBUTIONS}" -b ${OTELCOL_BUILDER} -g ${GO}

generate: generate-sources

generate-sources: go ocb
	@./scripts/build.sh -d "${DISTRIBUTIONS}" -s true -b ${OTELCOL_BUILDER} -g ${GO}

goreleaser-verify: goreleaser
	@${GORELEASER} release --snapshot --rm-dist

.PHONY: ocb
ocb:
ifeq (, $(shell command -v ocb 2>/dev/null))
	@{ \
	[ ! -x '$(OTELCOL_BUILDER)' ] || exit 0; \
	set -e ;\
	os=$$(uname | tr A-Z a-z) ;\
	machine=$$(uname -m) ;\
	[ "$${machine}" != x86 ] || machine=386 ;\
	[ "$${machine}" != x86_64 ] || machine=amd64 ;\
	[ "$${machine}" != aarch64 ] || machine=arm64 ;\
	echo "Installing ocb ($${os}/$${machine}) at $(OTELCOL_BUILDER_DIR)";\
	mkdir -p $(OTELCOL_BUILDER_DIR) ;\
	curl -sLo $(OTELCOL_BUILDER) "https://github.com/open-telemetry/opentelemetry-collector/releases/download/cmd%2Fbuilder%2Fv$(OTELCOL_BUILDER_VERSION)/ocb_$(OTELCOL_BUILDER_VERSION)_$${os}_$${machine}" ;\
	chmod +x $(OTELCOL_BUILDER) ;\
	}
else
OTELCOL_BUILDER=$(shell command -v ocb)
endif

.PHONY: go
go:
	@{ \
		if ! command -v '$(GO)' >/dev/null 2>/dev/null; then \
			echo >&2 '$(GO) command not found. Please install golang. https://go.dev/doc/install'; \
			exit 1; \
		fi \
	}

.PHONY: goreleaser
goreleaser:
	@{ \
		if ! command -v '$(GORELEASER)' >/dev/null 2>/dev/null; then \
			echo >&2 '$(GORELEASER) command not found. Please install goreleaser. https://goreleaser.com/install/'; \
			exit 1; \
		fi \
	}

REMOTE?=git@github.com:newrelic/opentelemetry-collector-releases.git
.PHONY: push-tags
push-tags:
	@[ "${TAG}" ] || ( echo ">> env var TAG is not set"; exit 1 )
	@echo "Adding tag ${TAG}"
	@git tag -a ${TAG} -s -m "Version ${TAG}"
	@echo "Pushing tag ${TAG}"
	@git push ${REMOTE} ${TAG}
