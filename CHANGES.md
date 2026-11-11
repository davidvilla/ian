# Changes

Notes of what changed in each version, to be completed from the history of the repository (the older entries are
still in `CHANGES.rst`).

## Unreleased

### `ian build` builds from the orig by default; svn support removed (2026-11-11)

`ian build` now does by default what `-m` did: it builds in a temporary directory, from the orig plus `./debian`,
so it builds exactly what will be uploaded and leaves the working directory untouched (no `debian/tmp`, stamps or
applied patches). The new `-w` builds in the working directory, as `ian build` did before; native packages are
always built there. `-m` is still accepted, and does nothing.

When the orig comes from the working directory (`ian orig local`, or `-l`) and it already existed, `build` fails if
the working directory differs from it: it would build the code of the orig and miss the later changes. Run
`ian build -c` to create the orig again or, if it was already uploaded, make a new release.

The temporary directory is now removed, the files a previous build left in `debian/` are not copied into it, and
every file `dpkg-buildpackage` creates is copied back (`.udeb` included), but not `debian/files`.

`svn-buildpackage` is no longer supported, nor is the `pkg vcs` line of `ian summary`.

### `ian orig local` in a git repository: only the files git knows (2026-11-05)

In a git repository, `ian orig local` takes the files git knows (`git ls-files`), as they are in the working
tree, without `debian/`: not those it ignores or does not have, like a virtualenv (`.venv/`) or what the build
leaves, which made lintian take minutes checking the source package. Out of git it takes the folder, as before;
now it really leaves out the backups (`*~`) and `*.pyc`: their patterns kept a backslash and matched nothing.

### `ian ship` for packages with upstream versions: `ian release -u` (2026-11-03)

`ian release -u` takes the newest upstream version that uscan finds (`uscan --report --dehs`): if it is newer than
the current one, the new entry is `<upstream>-1`; otherwise it is the next debian revision, as `ian release -i`
does. It fails if uscan finds no version.

`ian ship` used to run `ian release-date -y` for every package, so a package whose version is upstream's (one with
`debian/watch`, like `3.81.1-1`) got a date version (`0.20261103-1`): lower than the current one and missing in
upstream, so `ian orig` could not download it. Now, when the detected orig mode is `uscan`, `ship` runs
`ian release -u -y` instead; with the `rule` and `local` modes it still runs `ian release-date -y`.

### New command `ian ship` (2026-11-01)

`ian ship` runs `ian clean`, `ian release-date -y`, `ian orig`, `ian build`, `ian install` and `ian upload`, and
stops at the first one that fails. The new changelog entry gets the default message, without opening the editor. If all of
them succeed and the package is in a git repository, it commits the changes with `git commit -am "new-release:
<version>"`. Each step
runs its own hooks, as well as those of `ship` itself.

### The hooks of a command: pre, post, success and fail (2026-10-28)

Every command now has the same four hooks, which the user defines in `~/.config/ian` or in the project's `.ian`
file (see the *hooks* section of `README.rst`):

- `ian-<cmd>-pre-hook`: before the command.
- `ian-<cmd>-post-hook`: after the command, whatever it did.
- `ian-<cmd>-success-hook`: after `post`, only when the command succeeded.
- `ian-<cmd>-fail-hook`: after `post`, only when it failed.

The commands that only show information have no hooks: `help`, `name`, `summary`, `config`, `binary-contents`,
`pool-ls` and `ls`.

Each command runs through `ian-run` (`ian-hooks.sh`), which calls its hooks, also when a command is run by another
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
