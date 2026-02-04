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
		{"single char", 1},
		{"short string", 8},
		{"medium string", 32},
		{"long string", 64},
		{"very long", 256},
		{"huge string", 1024},
	}

	alphanumericRegex := regexp.MustCompile(`^[a-zA-Z0-9]+$`)

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := generateAlphanumeric(tt.length)
			if err != nil {
				t.Fatalf("generateAlphanumeric(%d) returned error: %v", tt.length, err)
			}

			// Check length
			if len(result) != tt.length {
				t.Errorf("generateAlphanumeric(%d) = %q (len %d), want length %d",
					tt.length, result, len(result), tt.length)
			}

			// Check it's only alphanumeric
			if !alphanumericRegex.MatchString(result) {
				t.Errorf("generateAlphanumeric(%d) = %q, contains non-alphanumeric chars",
					tt.length, result)
			}

			// Double-check no forbidden chars
			for _, ch := range result {
				if ch == '+' || ch == '/' || ch == '=' {
					t.Errorf("generateAlphanumeric(%d) = %q, contains forbidden char: %c",
						tt.length, result, ch)
				}
			}
		})
	}
}

func TestGenerateAlphanumericZeroLength(t *testing.T) {
	result, err := generateAlphanumeric(0)
	if err != nil {
		t.Fatalf("generateAlphanumeric(0) returned error: %v", err)
	}
	if result != "" {
		t.Errorf("generateAlphanumeric(0) = %q, want empty string", result)
	}
}

func TestGenerateAlphanumericRandomness(t *testing.T) {
	// Generate multiple strings and ensure they're different
	// This is a probabilistic test - collisions are theoretically possible but extremely unlikely
	seen := make(map[string]bool)
	length := 32
	iterations := 100

	for i := 0; i < iterations; i++ {
		result, err := generateAlphanumeric(length)
		if err != nil {
			t.Fatalf("generateAlphanumeric(%d) iteration %d returned error: %v", length, i, err)
		}
		if seen[result] {
			t.Errorf("generateAlphanumeric(%d) produced duplicate string: %q", length, result)
		}
		seen[result] = true
	}
}

func TestGenerateAlphanumericCharacterDistribution(t *testing.T) {
	// Generate a large string and verify we see all character types
	// This is a sanity check to ensure we're not accidentally filtering too much
	length := 1000
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
		t.Error("generateAlphanumeric(1000) didn't produce any lowercase letters")
	}
	if !hasUpper {
		t.Error("generateAlphanumeric(1000) didn't produce any uppercase letters")
	}
	if !hasDigit {
		t.Error("generateAlphanumeric(1000) didn't produce any digits")
	}
}

func BenchmarkGenerateAlphanumeric8(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, _ = generateAlphanumeric(8)
	}
}

func BenchmarkGenerateAlphanumeric32(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, _ = generateAlphanumeric(32)
	}
}

func BenchmarkGenerateAlphanumeric256(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, _ = generateAlphanumeric(256)
	}
}

func BenchmarkGenerateAlphanumeric1024(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, _ = generateAlphanumeric(1024)
	}
}
