package main

import (
	"crypto/rand"
	"encoding/base64"
	"flag"
	"fmt"
	"os"
	"strings"
)

func main() {
	flag.Parse()

	// Default length
	length := 32

	// If an argument is provided, try to use it as the length
	args := flag.Args()
	if len(args) > 0 {
		parsedLength, err := parseLength(args[0])
		if err == nil && parsedLength > 0 {
			length = parsedLength
		}
		// If parsing fails or length is 0, just use default (no error)
	}

	result, err := generateAlphanumeric(length)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating random string: %v\n", err)
		os.Exit(1)
	}

	fmt.Println(result)
}

// parseLength converts a string to an integer length
func parseLength(s string) (int, error) {
	if s == "" {
		return 0, fmt.Errorf("invalid length: empty string")
	}

	length := 0
	for _, ch := range s {
		if ch < '0' || ch > '9' {
			return 0, fmt.Errorf("invalid length: %q (must be a positive integer)", s)
		}
		length = length*10 + int(ch-'0')
	}
	return length, nil
}

// generateAlphanumeric creates a random alphanumeric string of the specified length
func generateAlphanumeric(length int) (string, error) {
	// Handle edge case
	if length == 0 {
		return "", nil
	}

	// Base64 encoding produces 4 chars for every 3 bytes
	// We lose ~3/64 chars when filtering out +/=
	// Oversampling by 1.5x should give us enough in most cases
	// Ensure minimum buffer size to avoid infinite loops
	bufferSize := (length * 3 / 4) + (length / 2)
	if bufferSize < 8 {
		bufferSize = 8
	}

	var result strings.Builder
	result.Grow(length)

	for result.Len() < length {
		// Generate random bytes
		randomBytes := make([]byte, bufferSize)
		_, err := rand.Read(randomBytes)
		if err != nil {
			return "", fmt.Errorf("failed to read random data: %w", err)
		}

		// Base64 encode
		encoded := base64.StdEncoding.EncodeToString(randomBytes)

		// Filter out non-alphanumeric characters
		for _, ch := range encoded {
			if result.Len() >= length {
				break
			}
			// Keep only a-z, A-Z, 0-9
			if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') {
				result.WriteRune(ch)
			}
		}
	}

	return result.String()[:length], nil
}
