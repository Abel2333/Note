# Makefile for Note project
# Compiles Typst notes into PDFs

.PHONY: all clean mathematics ml deep-learning deepseek guides watch help

# Default target: build all notes
all: mathematics ml deepseek guides

# Build all Mathematics notes
mathematics:
	@echo "Building Mathematics notes..."
	@mkdir -p build/Mathematics/Statistics build/Mathematics/Analysis
	@for file in notes/Mathematics/Statistics/*.typ; do \
		[ -f "$$file" ] && typst compile --root . "$$file" "build/Mathematics/Statistics/$$(basename $$file .typ).pdf" || true; \
	done
	@for file in notes/Mathematics/Analysis/*.typ; do \
		[ -f "$$file" ] && typst compile --root . "$$file" "build/Mathematics/Analysis/$$(basename $$file .typ).pdf" || true; \
	done
	@echo "Mathematics notes built successfully!"

# Build all Machine Learning notes
ml: deep-learning
	@echo "Building Machine Learning notes..."
	@mkdir -p build/Machine_Learning/Supervised
	@for file in notes/Machine_Learning/Supervised/*.typ; do \
		[ -f "$$file" ] && typst compile --root . "$$file" "build/Machine_Learning/Supervised/$$(basename $$file .typ).pdf" || true; \
	done
	@echo "Machine Learning notes built successfully!"

# Build the general Deep Learning notes
# This target is strict so a broken foundation note fails the build.
deep-learning:
	@set -e; \
	mkdir -p build/Machine_Learning/Deep_Learning; \
	for file in notes/Machine_Learning/Deep_Learning/*.typ; do \
		if [ -f "$$file" ]; then \
			typst compile --root . "$$file" "build/Machine_Learning/Deep_Learning/$$(basename "$$file" .typ).pdf"; \
		fi; \
	done
	@echo "Deep Learning notes built successfully!"

# Build the DeepSeek collection
# This target is strict so a broken collection document fails the build.
deepseek:
	@set -e; \
	mkdir -p build/Machine_Learning/DeepSeek; \
	for file in notes/Machine_Learning/DeepSeek/*.typ; do \
		if [ -f "$$file" ]; then \
			typst compile --root . "$$file" "build/Machine_Learning/DeepSeek/$$(basename "$$file" .typ).pdf"; \
		fi; \
	done
	@echo "DeepSeek collection built successfully!"

# Build guides
guides:
	@echo "Building guides..."
	@mkdir -p build/guides
	@for file in guides/*.typ; do \
		[ -f "$$file" ] && typst compile --root . "$$file" "build/guides/$$(basename $$file .typ).pdf" || true; \
	done
	@echo "Guides built successfully!"

# Watch for changes and rebuild (requires typst watch)
watch:
	@echo "Watching for changes... (Press Ctrl+C to stop)"
	@echo "Note: This watches only the first Mathematics note. Use 'typst watch <file>' for specific files."
	@typst watch --root . notes/Mathematics/Statistics/Likelihood.typ build/Mathematics/Statistics/Likelihood.pdf

# Clean all build artifacts
clean:
	@echo "Cleaning build directory..."
	@rm -rf build/
	@echo "Build directory cleaned!"

# Show help
help:
	@echo "Available targets:"
	@echo "  all         - Build all notes (default)"
	@echo "  mathematics - Build only Mathematics notes"
	@echo "  ml          - Build Machine Learning notes, including Deep Learning foundations"
	@echo "  deep-learning - Build only general Deep Learning notes"
	@echo "  deepseek    - Build the DeepSeek note collection"
	@echo "  guides      - Build only guides"
	@echo "  watch       - Watch for changes and rebuild"
	@echo "  clean       - Remove all build artifacts"
	@echo "  help        - Show this help message"
