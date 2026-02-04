package main

import (
	"regexp"
	"testing"
)

func TestGenerateAlphanumeric(t *testing.T) {
	tests := []struct {
		name   string
		length int
	}{
		{"tiny", 1},
		{"small", 8},
		{"default", 32},
		{"medium", 64},
		{"large", 256},
		{"very large", 1024},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := generateAlphanumeric(tt.length)
			if err != nil {
				t.Fatalf("generateAlphanumeric(%d) returned error: %v", tt.length, err)
			}

			// Check length
			if len(result) != tt.length {
				t.Errorf("generateAlphanumeric(%d) = %d chars, want %d chars",
					tt.length, len(result), tt.length)
			}

			// Check that it's only alphanumeric
			alphanumericRegex := regexp.MustCompile("^[a-zA-Z0-9]+$")
			if !alphanumericRegex.MatchString(result) {
				t.Errorf("generateAlphanumeric(%d) contains non-alphanumeric characters: %q",
					tt.length, result)
			}

			// Verify no forbidden characters
			forbiddenChars := []rune{'+', '/', '='}
			for _, ch := range forbiddenChars {
				for _, resultChar := range result {
					if resultChar == ch {
						t.Errorf("generateAlphanumeric(%d) contains forbidden character %q: %q",
							tt.length, ch, result)
					}
				}
			}
		})
	}
}

func TestParseLength(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    int
		wantErr bool
	}{
		{"single digit", "8", 8, false},
		{"double digit", "32", 32, false},
		{"large number", "1024", 1024, false},
		{"zero", "0", 0, false},
		{"very large", "999999", 999999, false},
		{"invalid - letters", "abc", 0, true},
		{"invalid - mixed", "12a", 0, true},
		{"invalid - negative", "-5", 0, true},
		{"invalid - special chars", "12!", 0, true},
		{"invalid - float", "12.5", 0, true},
		{"invalid - empty", "", 0, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := parseLength(tt.input)

			if tt.wantErr {
				if err == nil {
					t.Errorf("parseLength(%q) expected error, got nil", tt.input)
				}
				return
			}

			if err != nil {
				t.Errorf("parseLength(%q) unexpected error: %v", tt.input, err)
				return
			}

			if got != tt.want {
				t.Errorf("parseLength(%q) = %d, want %d", tt.input, got, tt.want)
			}
		})
	}
}

func TestGenerateAlphanumericZeroLength(t *testing.T) {
	result, err := generateAlphanumeric(0)
	if err != nil {
		t.Fatalf("generateAlphanumeric(0) returned error: %v", err)
	}
	if len(result) != 0 {
		t.Errorf("generateAlphanumeric(0) = %q, want empty string", result)
	}
}

func TestGenerateAlphanumericRandomness(t *testing.T) {
	// Generate multiple strings and verify they're different
	// This isn't a perfect test for randomness but catches obvious issues
	const iterations = 100
	const length = 32

	seen := make(map[string]bool)

	for i := 0; i < iterations; i++ {
		result, err := generateAlphanumeric(length)
		if err != nil {
			t.Fatalf("generateAlphanumeric(%d) iteration %d returned error: %v",
				length, i, err)
		}

		if seen[result] {
			t.Errorf("generateAlphanumeric(%d) produced duplicate string: %q",
				length, result)
		}
		seen[result] = true
	}

	if len(seen) != iterations {
		t.Errorf("generateAlphanumeric(%d) produced %d unique strings out of %d iterations",
			length, len(seen), iterations)
	}
}

func TestGenerateAlphanumericCharacterDistribution(t *testing.T) {
	// Generate a large string and verify we see all character types
	const length = 1000

	result, err := generateAlphanumeric(length)
	if err != nil {
		t.Fatalf("generateAlphanumeric(%d) returned error: %v", length, err)
	}

	hasLower := false
	hasUpper := false
	hasDigit := false

	for _, ch := range result {
		if ch >= 'a' && ch <= 'z' {
			hasLower = true
		}
		if ch >= 'A' && ch <= 'Z' {
			hasUpper = true
		}
		if ch >= '0' && ch <= '9' {
			hasDigit = true
		}
	}

	if !hasLower {
		t.Errorf("generateAlphanumeric(%d) doesn't contain lowercase letters", length)
	}
	if !hasUpper {
		t.Errorf("generateAlphanumeric(%d) doesn't contain uppercase letters", length)
	}
	if !hasDigit {
		t.Errorf("generateAlphanumeric(%d) doesn't contain digits", length)
	}
}

// Benchmark to see performance characteristics
func BenchmarkGenerateAlphanumeric(b *testing.B) {
	benchmarks := []struct {
		name   string
		length int
	}{
		{"8chars", 8},
		{"32chars", 32},
		{"64chars", 64},
		{"256chars", 256},
		{"1024chars", 1024},
	}

	for _, bm := range benchmarks {
		b.Run(bm.name, func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				_, err := generateAlphanumeric(bm.length)
				if err != nil {
					b.Fatalf("generateAlphanumeric(%d) returned error: %v", bm.length, err)
				}
			}
		})
	}
}

// TestArgumentHandling tests how the program would handle various command-line arguments
// This documents the expected behavior even though we can't easily test main() directly
func TestArgumentHandling(t *testing.T) {
	tests := []struct {
		name           string
		arg            string
		expectedLength int
		description    string
	}{
		{"valid number", "64", 64, "should parse valid number"},
		{"invalid letters", "blah", 32, "should default on invalid input"},
		{"invalid mixed", "12abc", 32, "should default on invalid input"},
		{"invalid negative", "-5", 32, "should default on invalid input"},
		{"zero", "0", 32, "should default on zero"},
		{"empty string", "", 32, "should default on empty string"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Simulate what main() does
			length := 32 // default

			if tt.arg != "" {
				parsedLength, err := parseLength(tt.arg)
				if err == nil && parsedLength > 0 {
					length = parsedLength
				}
			}

			if length != tt.expectedLength {
				t.Errorf("argument %q: got length %d, want %d (%s)",
					tt.arg, length, tt.expectedLength, tt.description)
			}
		})
	}
}
