//! Running commands, and telling the UI about them.
//!
//! Every external command goes through here so that:
//!   * it is written to the log verbatim, before it runs;
//!   * its output is streamed to the install log line by line;
//!   * the UI can show what is happening without the worker knowing about the
//!     UI.

use std::io::{BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::mpsc::Sender;
use std::sync::Mutex;

use anyhow::{bail, Context, Result};

/// Messages the worker sends back to the UI thread.
#[derive(Debug)]
pub enum Msg {
    /// A new phase started; the string is shown as the progress label.
    Phase(String),
    /// Rough completion, 0.0 ..= 1.0.
    Progress(f32),
    /// A line of output worth showing in the log pane.
    Line(String),
    /// The whole thing finished.
    Done,
    /// It did not. The string is the reason.
    Failed(String),
}

pub struct Runner {
    log_path: PathBuf,
    log: Mutex<std::fs::File>,
    tx: Sender<Msg>,
    dry_run: bool,
}

impl Runner {
    pub fn new(log_path: PathBuf, tx: Sender<Msg>, dry_run: bool) -> Result<Self> {
        if let Some(dir) = log_path.parent() {
            std::fs::create_dir_all(dir).ok();
        }
        let file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log_path)
            .with_context(|| format!("opening log {}", log_path.display()))?;
        Ok(Self {
            log_path,
            log: Mutex::new(file),
            tx,
            dry_run,
        })
    }

    pub fn dry_run(&self) -> bool {
        self.dry_run
    }

    pub fn log_path(&self) -> &Path {
        &self.log_path
    }

    fn emit(&self, msg: Msg) {
        let _ = self.tx.send(msg);
    }

    pub fn phase(&self, label: impl Into<String>) {
        let label = label.into();
        self.emit(Msg::Line(format!("── {label}")));
        self.emit(Msg::Phase(label));
    }

    pub fn progress(&self, v: f32) {
        self.emit(Msg::Progress(v.clamp(0.0, 1.0)));
    }

    pub fn info(&self, line: impl Into<String>) {
        self.emit(Msg::Line(line.into()));
    }

    fn write_log(&self, line: &str) {
        if let Ok(mut f) = self.log.lock() {
            let _ = writeln!(f, "{line}");
            let _ = f.flush();
        }
    }

    /// Run a command, stream its output, and fail on a non-zero exit.
    pub fn run<S: AsRef<str>>(&self, program: &str, args: &[S]) -> Result<()> {
        let rendered = format!(
            "{} {}",
            program,
            args.iter()
                .map(|a| a.as_ref())
                .collect::<Vec<_>>()
                .join(" ")
        );
        self.write_log(&format!("$ {rendered}"));
        self.info(format!("$ {rendered}"));

        if self.dry_run {
            self.info("  (dry run: not executed)");
            return Ok(());
        }

        let mut child = Command::new(program)
            .args(args.iter().map(|a| a.as_ref()))
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .with_context(|| format!("failed to start {program}"))?;

        let stdout = child.stdout.take();
        let stderr = child.stderr.take();

        let mut pipes: Vec<Box<dyn Read + Send>> = Vec::new();
        if let Some(s) = stdout {
            pipes.push(Box::new(s));
        }
        if let Some(s) = stderr {
            pipes.push(Box::new(s));
        }

        let mut handles = Vec::new();
        for pipe in pipes {
            let tx = self.tx.clone();
            let log_path = self.log_path.clone();
            handles.push(std::thread::spawn(move || {
                let reader = BufReader::new(pipe);
                for line in reader.lines().map_while(Result::ok) {
                    let _ = tx.send(Msg::Line(line.clone()));
                    if let Ok(mut f) = std::fs::OpenOptions::new()
                        .create(true)
                        .append(true)
                        .open(&log_path)
                    {
                        let _ = writeln!(f, "  {line}");
                    }
                }
            }));
        }

        let status = child.wait().with_context(|| format!("waiting for {program}"))?;
        for h in handles {
            let _ = h.join();
        }

        if !status.success() {
            self.write_log(&format!("!! {rendered} exited with {status}"));
            bail!("`{rendered}` failed with {status}");
        }
        Ok(())
    }

    /// Run a command, feeding it `input` on stdin. Used for passphrases and
    /// for anything that would otherwise have to be passed as an argument
    /// (and therefore show up in `ps`).
    pub fn run_stdin<S: AsRef<str>>(&self, program: &str, args: &[S], input: &str) -> Result<()> {
        let rendered = format!(
            "{} {}",
            program,
            args.iter()
                .map(|a| a.as_ref())
                .collect::<Vec<_>>()
                .join(" ")
        );
        self.write_log(&format!("$ {rendered}  # with stdin"));
        self.info(format!("$ {rendered}"));

        if self.dry_run {
            self.info("  (dry run: not executed)");
            return Ok(());
        }

        let mut child = Command::new(program)
            .args(args.iter().map(|a| a.as_ref()))
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .with_context(|| format!("failed to start {program}"))?;

        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(input.as_bytes())?;
            stdin.write_all(b"\n")?;
            drop(stdin);
        }

        let out = child.wait_with_output()?;
        for line in String::from_utf8_lossy(&out.stderr).lines() {
            self.info(format!("  {line}"));
            self.write_log(&format!("  {line}"));
        }
        if !out.status.success() {
            bail!("`{rendered}` failed with {}", out.status);
        }
        Ok(())
    }

    /// Run a command, capture its stdout, and return it. Failures are fatal.
    pub fn capture<S: AsRef<str>>(&self, program: &str, args: &[S]) -> Result<String> {
        let rendered = format!(
            "{} {}",
            program,
            args.iter()
                .map(|a| a.as_ref())
                .collect::<Vec<_>>()
                .join(" ")
        );
        self.write_log(&format!("$ {rendered}  # captured"));

        if self.dry_run {
            return Ok(String::new());
        }

        let out = Command::new(program)
            .args(args.iter().map(|a| a.as_ref()))
            .stdin(Stdio::null())
            .output()
            .with_context(|| format!("failed to start {program}"))?;
        if !out.status.success() {
            bail!("`{rendered}` failed with {}", out.status);
        }
        Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
    }

    /// Run a command and never fail — used for best-effort cleanup and for
    /// optional features that must not abort an install.
    pub fn try_run<S: AsRef<str>>(&self, program: &str, args: &[S]) -> bool {
        self.run(program, args).is_ok()
    }

    /// Write a file inside the target system.
    pub fn write_target(&self, root: &Path, relative: &str, contents: &str) -> Result<()> {
        let path = root.join(relative.trim_start_matches('/'));
        self.write_log(&format!("> write {}", path.display()));
        if self.dry_run {
            return Ok(());
        }
        if let Some(dir) = path.parent() {
            std::fs::create_dir_all(dir)
                .with_context(|| format!("creating {}", dir.display()))?;
        }
        std::fs::write(&path, contents).with_context(|| format!("writing {}", path.display()))?;
        Ok(())
    }

    pub fn finish(&self) {
        self.emit(Msg::Done);
    }

    pub fn fail(&self, e: &anyhow::Error) {
        self.write_log(&format!("!! {e:#}"));
        self.emit(Msg::Failed(format!("{e:#}")));
    }
}

/// Which of these programs are not on PATH?
pub fn missing_tools(tools: &[&str]) -> Vec<String> {
    tools
        .iter()
        .filter(|t| which(t).is_none())
        .map(|t| (*t).to_string())
        .collect()
}

pub fn which(program: &str) -> Option<PathBuf> {
    if program.contains('/') {
        let p = PathBuf::from(program);
        return p.is_file().then_some(p);
    }
    let path = std::env::var_os("PATH")?;
    std::env::split_paths(&path)
        .map(|d| d.join(program))
        .find(|p| p.is_file())
}
