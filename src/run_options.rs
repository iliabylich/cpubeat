use crate::sampler::{LiveSampler, Sampler, SyntheticSampler};

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub(crate) enum RunOptions {
    Live,
    Synthetic {
        do_syscall: bool,
        do_full_ui_update: bool,
    },
}

impl RunOptions {
    pub(crate) fn parse(var: Option<&str>) -> Self {
        let Some(var) = var else {
            return Self::Live;
        };

        let mut do_syscall = false;
        let mut do_full_ui_update = false;

        for part in var.split(',') {
            let Some((key, value)) = part.split_once('=') else {
                eprintln!("expected key=value, got {part:?}");
                std::process::exit(1);
            };

            let value = match value {
                "0" => false,
                "1" => true,
                _ => {
                    eprintln!("unknown value {value:?} for key {key:?}");
                    std::process::exit(1);
                }
            };

            match key {
                "syscall" => do_syscall = value,
                "ui" => do_full_ui_update = value,
                _ => {
                    eprintln!("unknown key {key:?}");
                    std::process::exit(1);
                }
            }
        }

        Self::Synthetic {
            do_syscall,
            do_full_ui_update,
        }
    }

    pub(crate) fn build_sampler(self) -> Box<dyn Sampler> {
        match self {
            Self::Live => Box::new(LiveSampler::new()),
            Self::Synthetic {
                do_syscall,
                do_full_ui_update,
            } => Box::new(SyntheticSampler::new(do_syscall, do_full_ui_update)),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::RunOptions;

    #[test]
    fn test_parse() {
        assert_eq!(RunOptions::parse(None), RunOptions::Live);

        assert_eq!(
            RunOptions::parse(Some("syscall=1,ui=0")),
            RunOptions::Synthetic {
                do_syscall: true,
                do_full_ui_update: false
            }
        );

        assert_eq!(
            RunOptions::parse(Some("syscall=0,ui=1")),
            RunOptions::Synthetic {
                do_syscall: false,
                do_full_ui_update: true
            }
        );
    }
}
