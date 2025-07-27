mod build;
mod docgen;
mod path;

use std::{env, error::Error};

type DynError = Box<dyn Error>;

pub mod tasks {
    use crate::{
        build::{build_all, build_cross_platform, build_linux_only},
        docgen::{userguide, write, USER_GUIDE},
        DynError,
    };

    pub fn docgen() -> Result<(), DynError> {
        write(USER_GUIDE, &userguide()?);
        Ok(())
    }

    pub fn build() -> Result<(), DynError> {
        build_all()?;
        Ok(())
    }

    pub fn build_cross() -> Result<(), DynError> {
        build_cross_platform()?;
        Ok(())
    }

    pub fn build_linux() -> Result<(), DynError> {
        build_linux_only()?;
        Ok(())
    }

    pub fn print_help() {
        println!(
            "
Usage: `cargo xtask <task>`

    Tasks:
        docgen:      Generate Markdown files.
        build:       Build for all platforms (Linux, macOS, Windows).
        build-cross: Build for Linux and Windows using cross-compilation.
        build-linux: Build for Linux architectures only (x86_64, aarch64, armv7).
"
        );
    }
}

fn main() -> Result<(), DynError> {
    let task = env::args().nth(1);
    match task {
        None => tasks::print_help(),
        Some(t) => match t.as_str() {
            "docgen" => tasks::docgen()?,
            "build" => tasks::build()?,
            "build-cross" => tasks::build_cross()?,
            "build-linux" => tasks::build_linux()?,
            invalid => return Err(format!("Invalid task: {}", invalid).into()),
        },
    };
    Ok(())
}
