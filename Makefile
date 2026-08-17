# Makefile for layrz_logging Flutter package

# Flutter executable
FLUTTER ?= flutter

.PHONY: test
test:
	@echo "Running Flutter tests with coverage..."
	$(FLUTTER) test --coverage
	@echo ""
	@echo "Coverage data written to coverage/lcov.info"
	@awk -F: '/^LH:/ {hit+=$$2} /^LF:/ {total+=$$2} END { if (total>0) printf "Coverage: %.2f%% (%d/%d lines)\n", hit*100/total, hit, total; else print "No coverage data" }' coverage/lcov.info

.PHONY: analyze
analyze:
	@echo "Running Flutter analyzer..."
	$(FLUTTER) analyze

.PHONY: coverage
coverage: test
	@dart run tool/strip_ignored_coverage.dart
	@awk -F: '/^LH:/ {hit+=$$2} /^LF:/ {total+=$$2} END { if (total>0) printf "Coverage: %.2f%% (%d/%d lines)\n", hit*100/total, hit, total; else print "No coverage data" }' coverage/lcov.info

.PHONY: check
check: analyze test

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make test      - Run test suite with coverage measurement"
	@echo "  make analyze   - Run Dart analyzer"
	@echo "  make coverage  - Run tests and generate coverage report"
	@echo "  make check     - Run analyzer and tests (CI-equivalent)"
	@echo "  make help      - Show this help message"
