# ---------------------------------------------------------
# Makefile for compiling LaTeX student report templates
#
# Usage:
#   make           - Same as "make all"
#   make full      - Compile the full report (multiple passes + biber)
#   make all       - Compile everything and removes auxiliary files
#   make clean     - Remove auxiliary files
# ---------------------------------------------------------

# Main LaTeX filename (without extension)
MAIN = report_template

# List of auxiliary file extensions to clean
EXTENSIONS = aux bbl blg glg glo gls ilg ist lof log lot nlo nls out toc glsdefs acn acr alg bcf dvi fdb_latexmk fls pre nav snm synctex.gz auxlock xml

.PHONY: all clean full

# Default target
all: full clean


# Full build (use this to fully compile the LaTeX document)
# Includes multiple pdflatex passes and bibliography compilation
full:
	@echo "Compiling '$(MAIN).tex'..."
	@pdflatex -interaction=nonstopmode $(MAIN) > /dev/null 2>&1
	@biber $(MAIN) > /dev/null 2>&1
	@pdflatex -interaction=nonstopmode $(MAIN) > /dev/null 2>&1
	@pdflatex -interaction=nonstopmode $(MAIN) > /dev/null 2>&1
	@echo "Compilation complete."


# Clean up auxiliary files
clean:
	@echo "Removing auxiliary files..."
	@for ext in $(EXTENSIONS); do \
		find . -type f -name "*.$$ext" -exec rm -f {} +; \
	done
	@echo "Cleanup done."
