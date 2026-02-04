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
	length := flag.Int("l", 32, "length of the output string")
	flag.Parse()

	if *length <= 0 {
		fmt.Fprintf(os.Stderr, "Error: length must be positive\n")
		os.Exit(1)
	}

	result, err := generateAlphanumeric(*length)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating random string: %v\n", err)
		os.Exit(1)
	}

	fmt.Println(result)
}

// generateAlphanumeric creates a random alphanumeric string of the specified length
func generateAlphanumeric(length int) (string, error) {
	// Handle edge case for zero length
	if length == 0 {
		return "", nil
	}

	// Base64 encoding produces 4 chars for every 3 bytes
	// We lose ~3/64 chars when filtering out +/=
	// Oversampling by 1.5x should give us enough in most cases
	bufferSize := (length * 3 / 4) + (length / 2)

	// Ensure minimum buffer size to guarantee progress
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

	return result.String(), nil
}
