# Makefile for layrz_logging Flutter package

# Flutter executable
FLUTTER ?= flutter

.PHONY: test
test:
	@echo "Running Flutter tests with coverage..."
	$(FLUTTER) test --coverage
	@echo ""
	@echo "Coverage data written to coverage/lcov.info"
	@if command -v lcov >/dev/null 2>&1; then \
		echo ""; \
		echo "Coverage summary:"; \
		lcov --summary coverage/lcov.info; \
	else \
		echo "(lcov not found; skipping coverage summary)"; \
	fi

.PHONY: analyze
analyze:
	@echo "Running Flutter analyzer..."
	$(FLUTTER) analyze

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make test      - Run test suite with coverage measurement"
	@echo "  make analyze   - Run Dart analyzer"
	@echo "  make help      - Show this help message"
