<a id="elan"></a>
<a id="ELAN_HOME-next"></a>

# ProofScript — 24.2. Managing Toolchains with Elan

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Lake and Elan in the source are Lean tools. Their commands, configuration and APIs remain native-host reference documentation. ProofScript may use npm package metadata, lockfiles and generated canonical sources, but that does not turn a Lake API into a PSC API. Pin source edition, grammar, semantic commit, dependencies, axiom policy, runtime and target separately.

**Compiler and coverage boundary.** Reference-tool execution does not imply a standalone dependency on Lean at runtime. Self-hosting and repeatable builds are engineering evidence, not compiler-preservation proofs.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.html). Source Git blob: `cf935eb8b2a2b3c1f8e81cf93c0259d11b5ab767`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="ELAN_HOME"></a>
<a id="elan-flag--help"></a>
<a id="elan-flag-h"></a>
<a id="elan-flag--verbose"></a>
<a id="elan-flag-v"></a>
<a id="elan-flag--version"></a>
<a id="elan-flag-V"></a>
<a id="elan-flag--delete"></a>
<a id="elan-flag--json"></a>
<a id="elan-flag--nonexistent"></a>
<a id="elan-option--path"></a>
<a id="elan-flag--install"></a>

---

## 24.2. Managing Toolchains with Elan

Elan is the Lean toolchain manager. It is responsible both for installing [toolchains](../index.md#--tech-term-toolchain) and for running their constituent programs. Elan makes it possible to seamlessly work on a variety of projects, each of which is designed to be built with a particular version of Lean, without having to manually install and select toolchain versions. Each project is typically configured to use a particular version, which is transparently installed as needed, and changes to the Lean version are tracked automatically.

<a id="elan-toolchain-versions"></a>
### 24.2.1. Selecting Toolchains

When using Elan, the version of each tool on the `PATH` is a proxy that invokes the correct version. The proxy determines the appropriate toolchain version for the current context, ensures that it is installed, and then invokes the underlying tool in the appropriate toolchain installation. These proxies can be instructed to use a specific version by passing it as an argument prefixed with `+`, so `lake +4.0.0` invokes `lake` version `4.0.0`, after installing it if necessary.

<a id="elan-channels"></a>
#### 24.2.1.1. Toolchain Identifiers

Toolchains are specified by providing a toolchain identifier that is either a 
<a id="--tech-term-channel"></a>
*channel*, which identifies a particular type of Lean release, and optionally an origin, or a 
<a id="--tech-term-custom-toolchain-name"></a>
*custom toolchain name* established by [`elan toolchain link`](index.md#toolchain-link). Channels may be:

  `stable`

The latest stable Lean release. Elan automatically tracks stable releases and offers to upgrade when a new one is released.

  `beta`

The latest release candidate. Release candidates are builds of Lean that are intended to become the next stable release. They are made available for widespread user testing.

  `nightly`

The latest nightly build. Nightly builds are useful for experimenting with new Lean features to provide feedback to the developers.

  A version number or specific nightly release

Each Lean version number identifies a channel that contains only that release. The version number may optionally be preceded with a `v`, so `v4.17.0` and `4.17.0` are equivalent. Similarly, `nightly-YYYY-MM-DD` specifies the nightly release from the specified date. A project's [toolchain file](index.md#--tech-term-toolchain-file) should typically contain a specific version of Lean, rather than a general channel, to make it easier to coordinate between developers and to build and test older versions of the project. An archive of Lean releases and nightly builds is maintained.

  A custom local toolchain

The command [`elan toolchain link`](index.md#toolchain-link) can be used to establish a custom toolchain name in Elan for a local build of Lean. This is especially useful when working on the Lean compiler itself.

Specifying an 
<a id="--tech-term-origin"></a>
*origin* instructs Elan to install Lean toolchains from a particular source. By default, this is the official project repository on GitHub, identified as [`leanprover/lean4`](https://github.com/leanprover/lean4/releases). If specified, an origin should precede the channel, with a colon, so `stable` is equivalent to `leanprover/lean4:stable`. When installing nightly releases, `-nightly` is appended to the origin, so `leanprover/lean4:nightly-2025-03-25` consults the [`leanprover/lean4-nightly`](https://github.com/leanprover/lean4-nightly/releases) repository to download releases. Origins are not used for custom toolchain names.

<a id="elan-toolchain-config"></a>
#### 24.2.1.2. Determining the Current Toolchain

Elan associates toolchains with directories, and uses the toolchain of the most recent parent directory of the current working directory that has a configured toolchain. A directory's toolchain may result from a toolchain file or from an override configured with [`elan override`](index.md#elan-override).

The current toolchain is determined by first searching for a configured toolchain for the current directory, walking up through parent directories until a toolchain version is found or there are no more parents. A directory has a configured toolchain if there is a configured [toolchain override](index.md#--tech-term-toolchain-override) for the directory or if it contains a `lean-toolchain` file. More recent parents take precedence over their ancestors, and if a directory has both an override and a toolchain file, then the override takes precedence. If no directory toolchain is found, then Elan's configured 
<a id="--tech-term-default-toolchain"></a>
*default toolchain* is used as a fallback.

The most common way to configure a Lean toolchain is with a 
<a id="--tech-term-toolchain-file"></a>
*toolchain file*. The toolchain file is a text file named `lean-toolchain` that contains a single line with a valid [toolchain identifier](index.md#elan-channels). This file is typically located in the root directory of a project and checked in to version control with the code, ensuring that everyone working on the project uses the same version. Updating to a new Lean toolchain requires only editing this file, and the new version is automatically downloaded and run the next time a Lean file is opened or built.

In certain advanced use cases where more flexibility is required, a 
<a id="--tech-term-toolchain-override"></a>
*toolchain override* can be configured. Like toolchain files, overrides associate a toolchain version with a directory and its children. Unlike toolchain files, overrides are stored in Elan's configuration rather than in a local file. They are typically used when a specific local configuration is required that does not make sense for other developers, such as testing a project with a locally-built Lean compiler.

<a id="elan-dir"></a>
### 24.2.2. Toolchain Locations

By default, Elan stores installed toolchains in `.elan/toolchains` in the user's home directory, and its proxies are kept in `.elan/bin`, which is added to the path when Elan is installed. The environment variable `ELAN_HOME` can be used to change this location. It should be set both prior to installing Elan and in all sessions that use Lean in order to ensure that Elan's files are found.

<a id="elan-cli"></a>
### 24.2.3. Command-Line Interface

In addition to the proxies that automatically select, install, and invoke the correct versions of Lean tools, Elan provides a command-line interface for querying and configuring its settings. This tool is called `elan`. Like [Lake](../Lake/index.md#lake), its command-line interface is structured around subcommands.

Elan can be invoked with following flags:

  `--help` or `-h`

Describes the current subcommand in detail.

  `--verbose` or `-v`

Enables verbose output.

  `--version` or `-V`

Displays the Elan version.

<a id="elan-show"></a>
#### 24.2.3.1. Querying Toolchains

The [`elan show`](index.md#show-next) command displays the current toolchain (as determined by the current directory) and lists all installed toolchains.

<a id="show-next"></a>

**Elan command**

```text
elan show
```

Shows the name of the active toolchain and the version of `lean`.

If there are multiple toolchains installed, then they are all listed.

Here is typical output from [`elan show`](index.md#show-next) in a project with a `lean-toolchain` file:

```text
installed toolchains
--------------------

leanprover/lean4:nightly-2025-03-25
leanprover/lean4:v4.17.0  (resolved from default 'stable')
leanprover/lean4:v4.16.0
leanprover/lean4:v4.9.0

active toolchain
----------------

leanprover/lean4:v4.9.0 (overridden by '/PATH/TO/PROJECT/lean-toolchain')
Lean (version 4.9.0, arm64-apple-darwin23.5.0, commit 8f9843a4a5fe, Release)
```

The `installed toolchains` section lists all the toolchains currently available on the system. The `active toolchain` section identifies the current toolchain and describes how it was selected. In this case, the toolchain was selected due to a `lean-toolchain` file.

<a id="elan-default"></a>
#### 24.2.3.2. Setting the Default Toolchain

Elan's configuration file specifies a [default toolchain](index.md#--tech-term-default-toolchain) to be used when there is no `lean-toolchain` file or [toolchain override](index.md#--tech-term-toolchain-override) for the current directory. Rather than manually editing the file, this value is typically changed using the [`elan default`](index.md#default) command.

<a id="default"></a>

**Elan command**

```text
elan default toolchain
```

Sets the default toolchain to `toolchain`, which should be a [valid toolchain identifier](index.md#elan-channels) such as `stable`, `nightly`, or `4.17.0`.

<a id="elan-toolchain"></a>
#### 24.2.3.3. Managing Installed Toolchains

The `elan toolchain` family of subcommands is used to manage the installed toolchains. Toolchains are stored in Elan's [toolchain directory](index.md#elan-dir).

Installed toolchains can take up substantial disk space. Elan tracks the Lean projects in which it is invoked, saving a list. This list of projects can be used to determine which toolchains are in active use and automatically delete unused toolchain versions with [`elan toolchain gc`](index.md#toolchain-gc).

<a id="toolchain-list"></a>

**Elan command**

```text
elan toolchain list
```

Lists the currently-installed toolchains. This is a subset of the output of [`elan show`](index.md#show-next).

<a id="toolchain-install"></a>

**Elan command**

```text
elan toolchain install toolchain
```

Installs the indicated `toolchain`. The toolchain's name should be [an identifier that's suitable for inclusion in a `lean-toolchain` file](index.md#elan-channels).

<a id="toolchain-uninstall"></a>

**Elan command**

```text
elan toolchain uninstall toolchain
```

Uninstalls the indicated `toolchain`. The toolchain's name should the name of an installed toolchain. Use [`elan toolchain list`](index.md#toolchain-list) to see the installed toolchains with their names.

<a id="toolchain-link"></a>

**Elan command**

```text
elan toolchain link local-name path
```

Creates a new local toolchain named `local-name`, using the Lean toolchain found at `path`.

<a id="toolchain-gc"></a>

**Elan command**

```text
elan toolchain gc [--delete] [--json]
```

This command is still considered experimental.

Determines which of the installed toolchains are in use, offering to delete those that are not. All the installed toolchains are listed, separated into those that are in use and those that are not.

A toolchain is classified as “in use” if

- it is the default toolchain,
- it is registered as an override, or
- there is a directory with a `lean-toolchain` file referencing the toolchain and elan has been used in the directory before.

For safety reasons, [`elan toolchain gc`](index.md#toolchain-gc) will not actually delete any toolchains unless the `--delete` flag is passed. This may be relaxed in the future when the implementation is deemed sufficiently mature. The `--json` flag causes [`elan toolchain gc`](index.md#toolchain-gc) to emit the list of used and unused toolchains in a JSON format that's suitable for other tools.

<a id="elan-override"></a>
#### 24.2.3.4. Managing Directory Overrides

Directory-specific [toolchain overrides](index.md#--tech-term-toolchain-override) are a local configuration that takes precedence over `lean-toolchain` files. The `elan override` commands manage overrides.

<a id="override-list"></a>

**Elan command**

```text
elan override list
```

Lists all the currently configured directory overrides in two columns. The left column contains the directories in which the Lean version is overridden, and the right column lists the toolchain version.

<a id="override-set"></a>

**Elan command**

```text
elan override set toolchain
```

Sets `toolchain` as an override for the current directory.

<a id="override-unset"></a>

**Elan command**

```text
elan override unset [--nonexistent] [--path path]
```

If `--nonexistent` flag is provided, all overrides that are configured for directories that don't currently exist are removed. If `--path` is provided, then the override set for `path` is removed. Otherwise, the override for the current directory is removed.

<a id="elan-run"></a>
#### 24.2.3.5. Running Tools and Commands

The commands in this section provide the ability to run a command in a specific toolchain and to locate a tool from a particular toolchain on disk. This can be useful when experimenting with different Lean versions, for cross-version testing, and for integrating Elan with other tools.

<a id="run"></a>

**Elan command**

```text
elan run [--install] toolchain command ...
```

Configures an environment to use the given toolchain and then runs the specified program. The toolchain will be installed if the `--install` flag is provided. The command may be any program; it does not need to be a command that's part of a toolchain such as `lean` or `lake`. This can be used for testing arbitrary toolchains without setting an override.

<a id="which"></a>

**Elan command**

```text
elan which command
```

Displays the full path to the toolchain-specific binary for `command`.

<a id="elan-self"></a>
#### 24.2.3.6. Managing Elan

Elan can manage its own installation. It can upgrade itself, remove itself, and help configure tab completion for many popular shells.

<a id="self-update"></a>

**Elan command**

```text
elan self update
```

Downloads and installs updates to Elan itself.

<a id="self-uninstall"></a>

**Elan command**

```text
elan self uninstall
```

Uninstalls Elan.

<a id="completions"></a>

**Elan command**

```text
elan completions shell
```

Generates shell completion scripts for Elan, enabling tab completion for Elan commands in a variety of shells. See the output of `elan help completions` for a description of how to install them.
