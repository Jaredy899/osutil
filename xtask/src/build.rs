use std::error::Error;
use std::fs;
use std::process::Command;

type DynError = Box<dyn Error>;

pub fn build_all() -> Result<(), DynError> {
    println!("Building for all platforms and architectures...");

    // Detect current platform
    let platform = std::env::consts::OS;
    println!("Current platform: {platform}");

    // Build for Linux architectures
    println!("Building for Linux architectures...");
    build_linux_targets()?;

    // Build for Windows (cross-compiled from any platform)
    println!("Building for Windows...");
    build_target("x86_64-pc-windows-gnu")?;

    // Build for macOS (only if on macOS)
    if platform == "macos" {
        println!("Building for macOS (x86_64)...");
        build_target("x86_64-apple-darwin")?;

        println!("Building for macOS (ARM)...");
        build_target("aarch64-apple-darwin")?;

        // Prepare separate macOS binaries (no lipo)
        println!("Preparing separate macOS binaries (no universal binary)...");
        prepare_separate_macos_binaries()?;
    } else {
        println!("Not on macOS, skipping macOS builds");
        println!("Note: macOS builds require native macOS environment");
    }

    println!("All builds completed successfully!");
    Ok(())
}

fn build_linux_targets() -> Result<(), DynError> {
    // Build x86_64 Linux
    println!("Building for Linux x86_64...");
    build_target("x86_64-unknown-linux-musl")?;

    // Build aarch64 Linux
    println!("Building for Linux aarch64...");
    build_target("aarch64-unknown-linux-musl")?;

    // Build armv7 Linux
    println!("Building for Linux armv7...");
    build_target("armv7-unknown-linux-musleabihf")?;

    Ok(())
}

fn build_target(target: &str) -> Result<(), DynError> {
    let status = Command::new("cargo")
        .args(["build", "--release", "--target", target])
        .status()?;

    if !status.success() {
        return Err(format!("Failed to build for target: {target}").into());
    }

    Ok(())
}

#[allow(dead_code)]
fn create_universal_macos_binary() -> Result<(), DynError> {
    let x86_64_path = "target/x86_64-apple-darwin/release/osutil";
    let aarch64_path = "target/aarch64-apple-darwin/release/osutil";
    let output_path = "target/release/osutil";

    // Check if both binaries exist
    if !std::path::Path::new(x86_64_path).exists() {
        return Err("x86_64 macOS binary not found".into());
    }

    if !std::path::Path::new(aarch64_path).exists() {
        return Err("aarch64 macOS binary not found".into());
    }

    // Create universal binary using lipo
    let status = Command::new("lipo")
        .args(["-create", x86_64_path, aarch64_path, "-output", output_path])
        .status()?;

    if !status.success() {
        return Err("Failed to create universal macOS binary".into());
    }

    Ok(())
}

fn prepare_separate_macos_binaries() -> Result<(), DynError> {
    let x86_64_src = "target/x86_64-apple-darwin/release/osutil";
    let arm64_src = "target/aarch64-apple-darwin/release/osutil";
    let out_dir = "target/release";
    let x86_64_dst = format!("{out_dir}/osutil-macos-x86_64");
    let arm64_dst = format!("{out_dir}/osutil-macos-arm64");

    if !std::path::Path::new(x86_64_src).exists() {
        return Err("x86_64 macOS binary not found".into());
    }
    if !std::path::Path::new(arm64_src).exists() {
        return Err("aarch64 macOS binary not found".into());
    }

    fs::create_dir_all(out_dir)?;
    fs::copy(x86_64_src, &x86_64_dst)?;
    fs::copy(arm64_src, &arm64_dst)?;

    println!("✓ Created {x86_64_dst}");
    println!("✓ Created {arm64_dst}");

    Ok(())
}

// Removed unused build_current_platform()

pub fn build_cross_platform() -> Result<(), DynError> {
    println!("Building for Linux and Windows using cross-compilation...");

    // Build for Linux architectures
    build_linux_targets()?;

    // Build for Windows
    println!("Building for Windows...");
    build_target("x86_64-pc-windows-gnu")?;

    println!("Cross-platform builds completed successfully!");
    Ok(())
}

pub fn build_linux_only() -> Result<(), DynError> {
    println!("Building for Linux architectures only...");
    build_linux_targets()?;
    println!("Linux builds completed successfully!");
    Ok(())
}
