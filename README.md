# OSutil

A powerful cross-platform system utility tool with a modern TUI interface that simplifies system administration across macOS and Linux.

## 🚀 How to Run

### **macOS & Linux**

```bash
sh <(curl -fsSL jaredcervantes.com/os)
```

## 📖 Usage

- **Arrow keys** — Navigate
- **Enter** — Select / run
- **Esc** — Back
- **Space** — Multi-select (where supported)

## Supported platforms

- **macOS** — Homebrew
- **Linux** — Auto-detects package manager; supports:

| Distro | Package manager |
|--------|------------------|
| **Arch Linux** | pacman |
| **Debian** / **Ubuntu** | apt/nala |
| **Fedora** | dnf |
| **Fedora Atomic** (Bazzite, Silverblue, Kinoite) | rpm-ostree |
| **aerynOS** | moss |
| **openSUSE** | zypper |
| **Alpine** | apk |
| **Void** | xbps |
| **Solus** | eopkg |
| **MacOS** | brew |

## Screenshots

- **macOS**: Homebrew-based development tools and system utilities
- **Linux**: Multi-distribution support with intelligent package manager detection

## Configuration

Optional `~/config.toml`:

```toml
auto_execute = ["System Update", "Fastfetch Setup"]
skip_confirmation = true
size_bypass = true
```

## Development

Rust 1.85+. Build: `cargo build --release` · Run: `cargo run`

**Contributing:** Add scripts under the right platform dir, register them in `tab_data.toml`, and follow existing script patterns for cross-distro support.

## Acknowledgments

Based on [Chris Titus Tech's linutil](https://github.com/ChrisTitusTech/linutil). Extended for macOS and additional Linux distros (including Fedora Atomic and AerynOS).

## License

MIT — see [LICENSE](LICENSE).
