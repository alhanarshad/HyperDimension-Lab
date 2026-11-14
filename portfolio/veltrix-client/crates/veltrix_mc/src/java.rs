use anyhow::{Context, Result, ensure};
use std::{
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

#[derive(Debug, Clone)]
pub struct JavaRuntime {
    pub executable: PathBuf,
    pub major: u16,
}

pub fn find_java(custom: &Path, required: Option<u16>) -> Result<JavaRuntime> {
    if !custom.as_os_str().is_empty() {
        ensure!(
            custom.is_absolute() && custom.is_file(),
            "Enter the full path to java.exe"
        );
        return validate(custom, required);
    }

    let mut paths = Vec::new();
    if let Some(home) = std::env::var_os("JAVA_HOME") {
        paths.push(PathBuf::from(home).join("bin").join("java.exe"));
    }
    if let Some(path) = std::env::var_os("PATH") {
        paths.extend(std::env::split_paths(&path).map(|dir| dir.join("java.exe")));
    }
    if let Some(program_files) = std::env::var_os("ProgramFiles") {
        let root = PathBuf::from(program_files);
        for vendor in [
            "Microsoft",
            "Java",
            "Eclipse Adoptium",
            "BellSoft",
            "Amazon Corretto",
        ] {
            if let Ok(entries) = std::fs::read_dir(root.join(vendor)) {
                paths.extend(
                    entries
                        .flatten()
                        .map(|entry| entry.path().join("bin").join("java.exe")),
                );
            }
        }
    }
    paths.retain(|path| path.is_absolute() && path.is_file());
    let mut seen = std::collections::HashSet::new();
    paths.retain(|path| seen.insert(path.clone()));
    paths
        .iter()
        .find_map(|path| validate(path, required).ok())
        .with_context(|| match required {
            Some(major) => {
                format!("Could not find 64-bit Java {major}. Set its java.exe path in Settings.")
            }
            None => "Could not find 64-bit Java. Set its java.exe path in Settings.".into(),
        })
}

fn validate(path: &Path, required: Option<u16>) -> Result<JavaRuntime> {
    let mut command = Command::new(path);
    command
        .args(["-XshowSettings:properties", "-version"])
        .stdin(Stdio::null())
        .env_remove("JAVA_TOOL_OPTIONS")
        .env_remove("JDK_JAVA_OPTIONS")
        .env_remove("_JAVA_OPTIONS");
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(0x08000000);
    }
    let output = command.output().context("Could not run java.exe")?;
    ensure!(output.status.success(), "Java failed its runtime check");
    let text = String::from_utf8_lossy(&output.stderr);
    let major = major(&text).context("Could not read the Java version")?;
    ensure!(
        property(&text, "sun.arch.data.model") == Some("64")
            && matches!(property(&text, "os.arch"), Some("amd64" | "x86_64")),
        "Veltrix requires x64 Java"
    );
    if let Some(required) = required {
        ensure!(
            major == required,
            "This instance requires Java {required}. Java {major} was found."
        );
    }
    Ok(JavaRuntime {
        executable: path.to_owned(),
        major,
    })
}

fn property<'a>(text: &'a str, key: &str) -> Option<&'a str> {
    text.lines()
        .filter_map(|line| line.split_once('='))
        .find_map(|(name, value)| (name.trim() == key).then(|| value.trim()))
}

fn major(text: &str) -> Option<u16> {
    let value = property(text, "java.specification.version")?;
    value.strip_prefix("1.").unwrap_or(value).parse().ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_legacy_and_modern_java_versions() {
        assert_eq!(major("    java.specification.version = 1.8\n"), Some(8));
        assert_eq!(major("    java.specification.version = 25\n"), Some(25));
        assert_eq!(major("java.version = 25"), None);
    }
}
