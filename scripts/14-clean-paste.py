#!/usr/bin/env python3
"""
Clean Paste - Remove AI Invisible Characters

This script removes invisible Unicode characters that AI tools sometimes
embed in their output (watermarks, tracking, etc.)

NOTE: This script is NOT used in the LinkedIn scheduler workflow.
Instead, we use the Clean Paste website (https://cleanpaste.site) because:
1. The website provides visual feedback showing hidden characters found
2. Browser-based cleaning is more reliable for complex Unicode

Usage (standalone):
    echo "text with invisible chars" | python3 clean-paste.py
    python3 clean-paste.py < input.txt
    python3 clean-paste.py --clipboard  # Read from and write to clipboard (macOS)
"""

import sys
import unicodedata
import argparse
import subprocess

# Invisible characters commonly added by AI tools
INVISIBLE_CHARS = [
    '\u200b',  # Zero-width space
    '\u200c',  # Zero-width non-joiner
    '\u200d',  # Zero-width joiner
    '\u2060',  # Word joiner
    '\ufeff',  # BOM (Byte Order Mark)
    '\u00ad',  # Soft hyphen
    '\u200e',  # Left-to-right mark
    '\u200f',  # Right-to-left mark
    '\u202a',  # Left-to-right embedding
    '\u202b',  # Right-to-left embedding
    '\u202c',  # Pop directional formatting
    '\u202d',  # Left-to-right override
    '\u202e',  # Right-to-left override
    '\u2061',  # Function application
    '\u2062',  # Invisible times
    '\u2063',  # Invisible separator
    '\u2064',  # Invisible plus
    '\u180e',  # Mongolian vowel separator
    '\u2800',  # Braille pattern blank
]


def clean_text(text):
    """Remove invisible characters and normalize Unicode."""
    cleaned = text

    # Remove invisible characters
    for char in INVISIBLE_CHARS:
        cleaned = cleaned.replace(char, '')

    # Normalize Unicode (NFC normalization)
    cleaned = unicodedata.normalize('NFC', cleaned)

    return cleaned


def get_clipboard():
    """Get text from macOS clipboard."""
    result = subprocess.run(['pbpaste'], capture_output=True, text=True)
    return result.stdout


def set_clipboard(text):
    """Set text to macOS clipboard."""
    subprocess.run(['pbcopy'], input=text, text=True)


def main():
    parser = argparse.ArgumentParser(description='Remove AI invisible characters from text')
    parser.add_argument('--clipboard', '-c', action='store_true',
                        help='Read from and write to clipboard (macOS)')
    parser.add_argument('--count', action='store_true',
                        help='Show character count')
    args = parser.parse_args()

    # Get input
    if args.clipboard:
        text = get_clipboard()
    else:
        text = sys.stdin.read()

    # Clean the text
    cleaned = clean_text(text)

    # Output
    if args.clipboard:
        set_clipboard(cleaned)
        print(f"Cleaned text copied to clipboard ({len(cleaned)} characters)")
    else:
        print(cleaned)

    if args.count:
        print(f"\n---\nCharacter count: {len(cleaned)}", file=sys.stderr)
        if len(cleaned) > 3000:
            print(f"WARNING: Exceeds LinkedIn's 3000 character limit by {len(cleaned) - 3000}", file=sys.stderr)


if __name__ == '__main__':
    main()
