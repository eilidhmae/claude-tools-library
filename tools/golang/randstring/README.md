# randstring

A simple Go utility for generating cryptographically secure random alphanumeric strings.

## Features

- Cryptographically secure randomness using `crypto/rand`
- Pure alphanumeric output (a-z, A-Z, 0-9 only)
- No special characters (`+`, `/`, `=` filtered out)
- Simple command-line interface
- Fast and memory-efficient

## Installation

```bash
go build -o randstring randstring.go
```

Or install directly:

```bash
go install
```

## Usage

### Generate a string with default length (32 characters)
```bash
randstring
```

### Generate a string of specific length
```bash
randstring 8      # 8 characters
randstring 64     # 64 characters
randstring 256    # 256 characters
```

### Invalid arguments default to 32 characters
```bash
randstring blah   # defaults to 32 characters
randstring 0      # defaults to 32 characters
randstring 12abc  # defaults to 32 characters
```

The program is forgiving - if you provide an invalid argument (non-numeric, zero, or negative), it simply uses the default length of 32 characters without error.

## Examples

```bash
$ randstring
ZtlTNOSEQxBMFJRwLQTyvZya62D7AtyV

$ randstring 16
bjtBykAWtmBry7zF

$ randstring 64
tmBry7zFQdj9QIkx8gQXLvoO0TWPHnYAC9GzvVqZcMRe0xeKGpzTu3wEFnMbsbMo

$ randstring blah
cYv6z8AvsGPokX8LaoondGdeIzASeTt7
# Invalid argument defaults to 32 characters
```

## Development

### Running Tests

```bash
go test -v
```

### Running Benchmarks

```bash
go test -bench=. -benchmem
```

### Test Coverage

```bash
go test -cover
```

## Implementation Details

- Uses Base64 encoding of random bytes as the source material
- Filters out non-alphanumeric characters (`+`, `/`, `=`)
- Oversamples random data to ensure enough characters in typically one pass
- Handles edge cases (zero length, very small lengths)

## Performance

Typical performance on modern hardware:
- 8 chars: ~5.6 µs
- 32 chars: ~6.1 µs
- 64 chars: ~6.7 µs
- 256 chars: ~10 µs
- 1024 chars: ~25 µs

Memory allocations are constant (4 allocations) regardless of output length.
