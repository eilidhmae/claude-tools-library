#!/usr/bin/env python3
"""
Advanced PDF text extraction with options
"""
import sys
from pathlib import Path
from pypdf import PdfReader


def extract_text_advanced(
    pdf_path: Path,
    output_path: Path = None,
    page_range: tuple = None,
    include_page_numbers: bool = True
):
    """
    Extract text with more control.
    
    Args:
        pdf_path: Path to PDF file
        output_path: Where to save output (optional)
        page_range: Tuple of (start, end) pages, 1-indexed (optional)
        include_page_numbers: Whether to include page markers
    """
    reader = PdfReader(pdf_path)
    total_pages = len(reader.pages)
    
    # Handle page range
    if page_range:
        start, end = page_range
        start = max(1, start) - 1  # Convert to 0-indexed
        end = min(total_pages, end)
        pages = reader.pages[start:end]
        print(f"Extracting pages {start+1} to {end} of {total_pages}...")
    else:
        pages = reader.pages
        print(f"Extracting all {total_pages} pages...")
    
    text_parts = []
    for i, page in enumerate(pages, 1):
        actual_page = i + (page_range[0] - 1 if page_range else 0)
        
        if i % 10 == 0:
            print(f"  Progress: {i}/{len(pages)} pages...")
        
        text = page.extract_text()
        
        if include_page_numbers:
            text_parts.append(f"\n{'='*60}\nPage {actual_page}\n{'='*60}\n{text}")
        else:
            text_parts.append(text)
    
    full_text = "\n\n".join(text_parts)
    
    if output_path:
        output_path.write_text(full_text, encoding='utf-8')
        print(f"\nSaved {len(full_text):,} characters to {output_path}")
    
    return full_text


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Extract text from PDF')
    parser.add_argument('pdf', type=Path, help='PDF file to process')
    parser.add_argument('-o', '--output', type=Path, help='Output text file')
    parser.add_argument('-s', '--start', type=int, help='Start page (1-indexed)')
    parser.add_argument('-e', '--end', type=int, help='End page (inclusive)')
    parser.add_argument('--no-page-numbers', action='store_true', help='Skip page number markers')
    
    args = parser.parse_args()
    
    if not args.pdf.exists():
        print(f"Error: {args.pdf} not found")
        sys.exit(1)
    
    output = args.output or args.pdf.with_suffix('.txt')
    page_range = (args.start, args.end) if args.start and args.end else None
    
    extract_text_advanced(
        args.pdf,
        output,
        page_range=page_range,
        include_page_numbers=not args.no_page_numbers
    )
