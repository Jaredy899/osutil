# MacUtil

A simple utility tool for macOS system management and application setup.

## Installation

### Quick Install (Recommended)

```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/start.sh)
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Jaredy899/jaredmacutil.git
cd jaredmacutil

# Build and run
cargo build --release
./target/release/macutil
```

## Usage

Run the application:

```bash
# If installed via script
macutil

# If built from source
./target/release/macutil
```

For development:

```bash
cargo run
```

## Features

- Application setup and management
- System configuration tools
- Terminal-based user interface

## License

This project is licensed under the MIT License - see the LICENSE file for details.
