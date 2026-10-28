# Changes

Notes of what changed in each version, to be completed from the history of the repository (the older entries are
still in `CHANGES.rst`).

## Unreleased

### The hooks of a command: pre, post, success and fail (2026-10-28)

Every command now has the same four hooks, which the user defines in `~/.config/ian` or in the project's `.ian`
file (see the *hooks* section of `README.rst`):

- `ian-<cmd>-pre-hook`: before the command.
- `ian-<cmd>-post-hook`: after the command, whatever it did.
- `ian-<cmd>-success-hook`: after `post`, only when the command succeeded.
- `ian-<cmd>-fail-hook`: after `post`, only when it failed.

The commands that only show information have no hooks: `help`, `name`, `summary`, `config`, `binary-contents`,
`pool-ls` and `ls`.

Each command runs through `run-cmd` (`ian-hooks.sh`), which calls its hooks, also when a command is run by another
one: `ian build` runs the hooks of `orig`, which runs those of `clean`, and, with `-i`, those of `install`. The
command runs in a subshell, so that an `exit` of a failed assertion does not skip its `post` and `fail` hooks, and
each hook runs in a subshell too, in the package root directory, so that a hook that changes directory or exits
affects neither ian nor the hooks that follow. A hook still cannot stop its command: its exit code is ignored.

The hooks of previous versions still run, in the place of the hook that replaces each one and warning that they
are deprecated. If both a deprecated hook and its replacement are defined, only the replacement runs and ian warns
that the deprecated one was discarded.

| deprecated              | replaced by               |
|-------------------------|---------------------------|
| `ian-clean-hook`        | `ian-clean-post-hook`     |
| `ian-release-hook`      | `ian-release-post-hook`   |
| `ian-build-hook`        | `ian-build-post-hook`     |
| `ian-build-start-hook`  | `ian-build-pre-hook`      |
| `ian-build-end-hook`    | `ian-build-success-hook`  |
| `ian-install-hook`      | `ian-install-post-hook`   |
| `ian-upload-start-hook` | `ian-upload-pre-hook`     |
| `ian-upload-end-hook`   | `ian-upload-success-hook` |
| `ian-remove-hook`       | `ian-remove-post-hook`    |

Two of them do not run exactly where they used to: `ian-build-start-hook` now runs before the whole `build`
command (before the orig and the build dependencies), and not just before `dpkg-buildpackage`; and
`ian-clean-hook` after the `clean` command instead of at its end. `ian-build-end-hook` and `ian-upload-end-hook`
became `success` hooks, and not `post` ones, because they were only called when the command succeeded.

Tests: `test/ian-hooks-tests.sh`.

### The vagrant commands are gone (2026-10-28)

`vagrant-provision`, `vagrant-build` and `vagrant-clean` removed, with `ian-vagrant.sh` and `vagrant/`. They
built i386 packages in amd64, an architecture Debian no longer releases, and the boxes were Debian 10 (EOL).
Use `sbuild` for clean or foreign architecture builds, and `ian upload <arch>` for binaries built elsewhere.
