use anyhow::{Context, Result, ensure};
use reqwest::blocking::Client;
use sha1::{Digest, Sha1};
use std::{
    fs::{self, File},
    io::{self, Read, Write},
    path::{Path, PathBuf},
    sync::atomic::{AtomicBool, Ordering},
    time::Duration,
};
use url::Url;

pub fn public_url(raw: &str, allowed: &[&str]) -> Result<Url> {
    let url = Url::parse(raw).context("Invalid download URL")?;
    ensure!(
        url.scheme() == "https"
            && url.username().is_empty()
            && url.password().is_none()
            && url.port().is_none()
            && url.host_str().is_some_and(|host| allowed.contains(&host)),
        "Unexpected download origin"
    );
    Ok(url)
}

pub fn safe_segment(segment: &str) -> Result<&str> {
    let base = segment.split('.').next().unwrap_or("").to_ascii_uppercase();
    let device = matches!(base.as_str(), "CON" | "PRN" | "AUX" | "NUL")
        || (base.len() == 4
            && (base.starts_with("COM") || base.starts_with("LPT"))
            && base.as_bytes()[3].is_ascii_digit());
    ensure!(
        !segment.is_empty()
            && segment.len() <= 180
            && !segment.starts_with('.')
            && !segment.ends_with('.')
            && !device
            && segment
                .bytes()
                .all(|c| c.is_ascii_alphanumeric() || matches!(c, b'.' | b'_' | b'-' | b'+')),
        "Invalid path component"
    );
    Ok(segment)
}

pub fn child_path(root: &Path, relative: &str) -> Result<PathBuf> {
    let mut target = root.to_owned();
    for part in relative.split('/') {
        target.push(safe_segment(part)?);
    }
    Ok(target)
}

pub fn check_cancel(cancel: &AtomicBool) -> Result<()> {
    ensure!(!cancel.load(Ordering::Relaxed), "Operation cancelled");
    Ok(())
}

pub struct Http(Client);

impl Http {
    pub fn new() -> Result<Self> {
        let client = Client::builder()
            .redirect(reqwest::redirect::Policy::none())
            .connect_timeout(Duration::from_secs(12))
            .timeout(Duration::from_secs(60))
            .user_agent(concat!("VeltrixClient/", env!("CARGO_PKG_VERSION")))
            .build()?;
        Ok(Self(client))
    }

    pub fn bytes(&self, url: Url, limit: u64) -> Result<Vec<u8>> {
        let mut output = Vec::new();
        self.response(url)?
            .take(limit + 1)
            .read_to_end(&mut output)?;
        ensure!(
            output.len() as u64 <= limit,
            "Download exceeds its size limit"
        );
        Ok(output)
    }

    fn response(&self, url: Url) -> Result<reqwest::blocking::Response> {
        let response = self.0.get(url).send()?.error_for_status()?;
        ensure!(
            response.status().is_success(),
            "Unexpected download status {}",
            response.status()
        );
        Ok(response)
    }

    pub fn verified(
        &self,
        url: Url,
        path: &Path,
        sha1: &str,
        size: Option<u64>,
        limit: u64,
        cancel: &AtomicBool,
    ) -> Result<()> {
        ensure!(
            sha1.len() == 40 && sha1.bytes().all(|value| value.is_ascii_hexdigit()),
            "Invalid SHA-1 digest"
        );
        ensure!(
            size.is_none_or(|value| value <= limit),
            "Download exceeds its size limit"
        );
        check_cancel(cancel)?;
        match File::open(path) {
            Ok(file) => {
                let len = file.metadata()?.len();
                if len <= limit && size.is_none_or(|value| value == len) {
                    let (hash, _) = copy_hash(file, &mut io::sink(), limit, cancel)?;
                    if hash.eq_ignore_ascii_case(sha1) {
                        return Ok(());
                    }
                }
            }
            Err(error) if error.kind() == io::ErrorKind::NotFound => {}
            Err(error) => return Err(error.into()),
        }
        let parent = path
            .parent()
            .context("Download path has no parent directory")?;
        fs::create_dir_all(parent)?;
        let mut temp = tempfile::NamedTempFile::new_in(parent)?;
        let (hash, length) = copy_hash(
            self.response(url)?,
            &mut temp,
            size.unwrap_or(limit),
            cancel,
        )?;
        ensure!(
            size.is_none_or(|value| value == length),
            "Incorrect download size"
        );
        ensure!(
            hash.eq_ignore_ascii_case(sha1),
            "Download hash did not match"
        );
        check_cancel(cancel)?;
        temp.as_file().sync_all()?;
        temp.persist(path)?;
        Ok(())
    }
}

fn copy_hash(
    mut reader: impl Read,
    writer: &mut impl Write,
    limit: u64,
    cancel: &AtomicBool,
) -> Result<(String, u64)> {
    let mut buffer = [0; 64 * 1024];
    let mut hash = Sha1::new();
    let mut total = 0;
    loop {
        check_cancel(cancel)?;
        let count = reader.read(&mut buffer)?;
        if count == 0 {
            break;
        }
        total += count as u64;
        ensure!(total <= limit, "Download exceeds its size limit");
        hash.update(&buffer[..count]);
        writer.write_all(&buffer[..count])?;
    }
    Ok((format!("{:x}", hash.finalize()), total))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_unsafe_urls_and_windows_paths() {
        for url in [
            "http://allowed.test/a",
            "https://allowed.test.evil/a",
            "https://user@allowed.test/a",
            "https://allowed.test:444/a",
        ] {
            assert!(public_url(url, &["allowed.test"]).is_err());
        }
        for path in [
            "../game.jar",
            "C:/game.jar",
            "dir\\game.jar",
            "dir//game.jar",
            "/game.jar",
            "dir/NUL.txt",
            "dir/game.jar.",
            "dir/game.jar:alt",
        ] {
            assert!(child_path(Path::new("root"), path).is_err());
        }
        assert!(child_path(Path::new("root"), "net/fabricmc/a-1.0+build.jar").is_ok());
    }

    #[test]
    fn verification_checks_stream_size_and_cancellation() -> Result<()> {
        let cancel = AtomicBool::new(false);
        let (digest, length) = copy_hash(&b"abc"[..], &mut io::sink(), 3, &cancel)?;
        assert_eq!(digest, "a9993e364706816aba3e25717850c26c9cd0d89d");
        assert_eq!(length, 3);
        assert!(copy_hash(&b"abc"[..], &mut io::sink(), 2, &cancel).is_err());
        cancel.store(true, Ordering::Relaxed);
        assert!(copy_hash(&b""[..], &mut io::sink(), 0, &cancel).is_err());
        Ok(())
    }
}
