# zsh configuration

Two tracked files:

- `zprofile` — PATH and exported environment. Login shells only.
- `zshrc` — aliases, keybindings, completion, plugins, prompt. Interactive shells.

## Installing

These files are **not** symlinked into `$HOME`. Instead the files in `$HOME` stay
local and untracked, and source these. Tools like Rancher Desktop append their own
managed blocks to `~/.zshrc` without asking; this way those edits land in the local
file instead of showing up as changes to this repo.

Add to `~/.zprofile`:

```zsh
source /path/to/this/repo/zshrc/zprofile
```

Add to `~/.zshrc`:

```zsh
source /path/to/this/repo/zshrc/zshrc
```

Anything machine-specific — work repo paths, tool-managed blocks — belongs directly
in those two local files, after the `source` line. There is no separate
`~/.zshrc.local`.

On macOS every terminal window and tab is a login shell, so a new tab is enough to
pick up `zprofile` changes. No need to quit the terminal.

## Dependencies

Nothing here installs software; the rc files only ever guard on what is present. To
get the full set:

```zsh
brew install eza fzf neovim starship zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode
```

Everything is optional and independently guarded — a machine missing any of these
still gets a working shell, just without that feature.

Note that `starship` may already be present as a hand-installed binary in
`/usr/local/bin`. If so, remove it in favour of the Homebrew one rather than keeping
two copies on PATH.

The starship prompt reads `~/.config/starship.toml`, which is symlinked to
`../starship/starship.toml` in this repo. That symlink is the one exception to the
"no symlinks into `$HOME`" rule above, because starship offers no include mechanism.

## Notes

History is deliberately not configured here. macOS `/etc/zshrc` already sets
`HISTFILE=~/.zsh_history`, `HISTSIZE=2000` and `SAVEHIST=1000`, which is fine; add
overrides to `zprofile` if that ever stops being true.

`zshrc/capabilities.md` records the audit of the older configs these files replace,
including which behaviours were kept and which were dropped, and a verification
checklist.
