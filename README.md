# claude-tools-library

A collection of utility tools for use with Claude Code.

## Tools

### Go

#### [randstring](tools/golang/randstring/)

Cryptographically secure random alphanumeric string generator.

```bash
cd tools/golang/randstring
go build -o randstring

./randstring      # 32 characters (default)
./randstring 64   # 64 characters
```

### Python

#### [pdftotext](tools/python/pdftotext/)

Extract text from PDF files with page range support.

```bash
cd tools/python/pdftotext
pip install pypdf

python pdftotext.py document.pdf                    # Extract all pages
python pdftotext.py document.pdf -o output.txt      # Custom output file
python pdftotext.py document.pdf -s 1 -e 10         # Pages 1-10 only
python pdftotext.py document.pdf --no-page-numbers  # Skip page markers
```

## Structure

```
tools/
├── golang/
│   └── randstring/    # Random string generator
└── python/
    └── pdftotext/     # PDF text extraction
```

## Contributing

Add new tools under `tools/<language>/<tool-name>/` with their own README.
