#!/usr/bin/env bash
# Example: Text Processing Automation
# Demonstrates using the applescript-full-automation.sh framework

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUTOMATION_SCRIPT="$ROOT_DIR/scripts/applescript-full-automation.sh"

# Example 1: Process single text
process_text() {
    local text="$1"
    echo "Processing: $text"
    
    "$AUTOMATION_SCRIPT" "https://cleanpaste.site" "$text" 2>&1 | \
        grep -A 1000 "RESULT:" | \
        tail -n +2 | \
        head -n -1
}

# Example 2: Batch process from file
batch_process() {
    local input_file="$1"
    local output_file="${2:-output.txt}"
    
    echo "Batch processing from $input_file..."
    
    > "$output_file"  # Clear output file
    
    while IFS= read -r line; do
        if [ -n "${line//[[:space:]]/}" ]; then
            echo "Processing: ${line:0:50}..."
            result=$(process_text "$line")
            echo "$result" >> "$output_file"
            echo "---" >> "$output_file"
            sleep 1  # Be nice to the server
        fi
    done < "$input_file"
    
    echo "Done! Results saved to $output_file"
}

# Example 3: Interactive mode
interactive_mode() {
    echo "=== Interactive Text Processor ==="
    echo "Enter text to process (Ctrl+D to finish):"
    echo ""
    
    text=$(cat)
    
    if [ -n "${text//[[:space:]]/}" ]; then
        echo ""
        echo "Processing..."
        process_text "$text"
    else
        echo "No text provided."
    fi
}

# Main
main() {
    if [ ! -x "$AUTOMATION_SCRIPT" ]; then
        echo "Error: Automation script not found or not executable: $AUTOMATION_SCRIPT"
        exit 1
    fi
    
    case "${1:-interactive}" in
        single)
            if [ -z "${2:-}" ]; then
                echo "Usage: $0 single 'text to process'"
                exit 1
            fi
            process_text "$2"
            ;;
        batch)
            if [ -z "${2:-}" ]; then
                echo "Usage: $0 batch input.txt [output.txt]"
                exit 1
            fi
            batch_process "$2" "${3:-output.txt}"
            ;;
        interactive)
            interactive_mode
            ;;
        *)
            cat <<'HELP'
Text Processing Automation Examples

USAGE:
  ./text-processor-example.sh [MODE] [ARGS]

MODES:
  interactive          Read text from stdin (default)
  single 'TEXT'        Process single text string
  batch INPUT [OUTPUT] Process file line by line

EXAMPLES:
  # Interactive mode
  ./text-processor-example.sh interactive
  
  # Single text
  ./text-processor-example.sh single "Text with   extra spaces"
  
  # Batch process
  ./text-processor-example.sh batch input.txt output.txt
  
  # Pipeline
  echo "Text to clean" | ./text-processor-example.sh interactive

HELP
            ;;
    esac
}

main "$@"
