#!/usr/bin/env python3
"""
Normalize Unicode Title

Converts fancy Unicode text (mathematical bold, italic, etc.) to plain ASCII.
Useful for converting AI-generated stylized titles to normal text for spreadsheets.

Examples:
    𝘽𝙤𝙤𝙠𝙞𝙣𝙜.𝙘𝙤𝙢 → Booking.com
    𝙎𝙚𝙘𝙪𝙧𝙞𝙣𝙜 𝘼𝙜𝙚𝙣𝙩𝙞𝙘 → Securing Agentic

Usage:
    echo "𝘽𝙤𝙤𝙠𝙞𝙣𝙜" | python3 normalize-unicode-title.py
    python3 normalize-unicode-title.py --clipboard
"""

import sys
import unicodedata
import argparse
import subprocess

# Unicode mathematical alphanumeric symbols ranges
# Maps fancy Unicode to ASCII equivalents
UNICODE_MAPPINGS = {
    # Mathematical Bold
    range(0x1D400, 0x1D41A): lambda c: chr(ord('A') + (c - 0x1D400)),  # A-Z
    range(0x1D41A, 0x1D434): lambda c: chr(ord('a') + (c - 0x1D41A)),  # a-z

    # Mathematical Italic
    range(0x1D434, 0x1D44E): lambda c: chr(ord('A') + (c - 0x1D434)),  # A-Z
    range(0x1D44E, 0x1D468): lambda c: chr(ord('a') + (c - 0x1D44E)),  # a-z

    # Mathematical Bold Italic
    range(0x1D468, 0x1D482): lambda c: chr(ord('A') + (c - 0x1D468)),  # A-Z
    range(0x1D482, 0x1D49C): lambda c: chr(ord('a') + (c - 0x1D482)),  # a-z

    # Mathematical Sans-Serif Bold Italic (commonly used by ChatGPT)
    range(0x1D63C, 0x1D656): lambda c: chr(ord('A') + (c - 0x1D63C)),  # A-Z
    range(0x1D656, 0x1D670): lambda c: chr(ord('a') + (c - 0x1D656)),  # a-z

    # Mathematical Sans-Serif Bold
    range(0x1D5D4, 0x1D5EE): lambda c: chr(ord('A') + (c - 0x1D5D4)),  # A-Z
    range(0x1D5EE, 0x1D608): lambda c: chr(ord('a') + (c - 0x1D5EE)),  # a-z

    # Mathematical Sans-Serif Italic
    range(0x1D608, 0x1D622): lambda c: chr(ord('A') + (c - 0x1D608)),  # A-Z
    range(0x1D622, 0x1D63C): lambda c: chr(ord('a') + (c - 0x1D622)),  # a-z

    # Mathematical Monospace
    range(0x1D670, 0x1D68A): lambda c: chr(ord('A') + (c - 0x1D670)),  # A-Z
    range(0x1D68A, 0x1D6A4): lambda c: chr(ord('a') + (c - 0x1D68A)),  # a-z

    # Mathematical Bold Digits
    range(0x1D7CE, 0x1D7D8): lambda c: chr(ord('0') + (c - 0x1D7CE)),  # 0-9

    # Mathematical Double-Struck Digits
    range(0x1D7D8, 0x1D7E2): lambda c: chr(ord('0') + (c - 0x1D7D8)),  # 0-9

    # Mathematical Sans-Serif Bold Digits
    range(0x1D7EC, 0x1D7F6): lambda c: chr(ord('0') + (c - 0x1D7EC)),  # 0-9

    # Mathematical Monospace Digits
    range(0x1D7F6, 0x1D800): lambda c: chr(ord('0') + (c - 0x1D7F6)),  # 0-9
}


def normalize_char(char):
    """Convert a single fancy Unicode character to ASCII if possible."""
    code = ord(char)

    for char_range, converter in UNICODE_MAPPINGS.items():
        if code in char_range:
            return converter(code)

    # Try NFKD normalization for other fancy characters
    normalized = unicodedata.normalize('NFKD', char)
    ascii_char = normalized.encode('ascii', 'ignore').decode('ascii')
    if ascii_char:
        return ascii_char

    return char


def normalize_title(text):
    """Normalize fancy Unicode text to plain ASCII."""
    result = []
    for char in text:
        result.append(normalize_char(char))
    return ''.join(result)


def extract_title(text):
    """Extract title from post content (usually first non-empty line after emojis)."""
    lines = text.strip().split('\n')
    for line in lines:
        line = line.strip()
        # Skip empty lines and lines that are just hashtags
        if line and not line.startswith('#') and len(line) > 10:
            # Remove leading/trailing emojis
            # Keep the core title text
            return line
    return text[:100] if text else ''


def get_clipboard():
    """Get text from macOS clipboard."""
    result = subprocess.run(['pbpaste'], capture_output=True, text=True)
    return result.stdout


def set_clipboard(text):
    """Set text to macOS clipboard."""
    subprocess.run(['pbcopy'], input=text, text=True)


def main():
    parser = argparse.ArgumentParser(description='Normalize fancy Unicode to plain text')
    parser.add_argument('--clipboard', '-c', action='store_true',
                        help='Read from and write to clipboard (macOS)')
    parser.add_argument('--extract-title', '-t', action='store_true',
                        help='Extract and normalize just the title from a post')
    args = parser.parse_args()

    # Get input
    if args.clipboard:
        text = get_clipboard()
    else:
        text = sys.stdin.read()

    # Process
    if args.extract_title:
        title = extract_title(text)
        normalized = normalize_title(title)
    else:
        normalized = normalize_title(text)

    # Output
    if args.clipboard:
        set_clipboard(normalized)
        print(f"Normalized text copied to clipboard")
        print(f"Result: {normalized}")
    else:
        print(normalized)


if __name__ == '__main__':
    main()
