use std::io::{IsTerminal, StdoutLock, Write};

pub(crate) struct Logger {
    enabled: bool,
    stdout: StdoutLock<'static>,
}

impl Logger {
    pub(crate) fn new() -> Self {
        let stdout: StdoutLock<'_> = std::io::stdout().lock();
        let enabled = stdout.is_terminal();
        Self { enabled, stdout }
    }

    pub(crate) fn log(&mut self, data: &[f64]) -> std::io::Result<()> {
        if !self.enabled {
            return Ok(());
        }

        let out = &mut self.stdout;
        write!(out, "[")?;
        for (idx, number) in data.iter().enumerate() {
            if idx != 0 {
                write!(out, ", ")?;
            }
            write!(out, "{number:.2}")?;
        }
        writeln!(out, "]")?;
        Ok(())
    }
}
