<a id="lake"></a>

# ProofScript — 24.1. Lake

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Lake and Elan in the source are Lean tools. Their commands, configuration and APIs remain native-host reference documentation. ProofScript may use npm package metadata, lockfiles and generated canonical sources, but that does not turn a Lake API into a PSC API. Pin source edition, grammar, semantic commit, dependencies, axiom policy, runtime and target separately.

**Compiler and coverage boundary.** Reference-tool execution does not imply a standalone dependency on Lean at runtime. Self-hosting and repeatable builds are engineering evidence, not compiler-preservation proofs.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Build-Tools-and-Distribution/Lake/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Build-Tools-and-Distribution/Lake/index.html). Source Git blob: `f41eea647d9429423a57c2093124295349d2487f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="LAKE"></a>
<a id="ELAN_HOME"></a>
<a id="ELAN"></a>
<a id="LAKE_HOME"></a>
<a id="LEAN_SYSROOT"></a>
<a id="LAKE_OVERRIDE_LEAN"></a>
<a id="LEAN"></a>
<a id="LEAN_CC"></a>
<a id="LEAN_AR"></a>
<a id="CC"></a>
<a id="AR"></a>
<a id="LAKE_NO_CACHE"></a>
<a id="LAKE_ARTIFACT_CACHE"></a>
<a id="LAKE_CACHE_KEY"></a>
<a id="LAKE_CACHE_ARTIFACT_ENDPOINT"></a>
<a id="LAKE_CACHE_REVISION_ENDPOINT"></a>
<a id="lake-flag--version"></a>
<a id="lake-flag--help"></a>
<a id="lake-flag-h"></a>
<a id="lake-option--dir"></a>
<a id="lake-option-d"></a>
<a id="lake-option--file"></a>
<a id="lake-option-f"></a>
<a id="lake-flag--old"></a>
<a id="lake-flag--rehash"></a>
<a id="lake-flag-H"></a>
<a id="lake-flag--allow-empty"></a>
<a id="lake-flag--update"></a>
<a id="lake-option--packages"></a>
<a id="lake-flag--reconfigure"></a>
<a id="lake-flag-R"></a>
<a id="lake-flag--keep-toolchain"></a>
<a id="lake-flag--no-build"></a>
<a id="lake-flag--no-cache"></a>
<a id="lake-flag--try-cache"></a>
<a id="lake-flag--quiet"></a>
<a id="lake-flag-q"></a>
<a id="lake-flag--verbose"></a>
<a id="lake-flag-v"></a>
<a id="lake-flag--ansi"></a>
<a id="lake-flag--no-ansi"></a>
<a id="lake-option--log-level"></a>
<a id="lake-option--fail-level"></a>
<a id="lake-flag--iofail"></a>
<a id="lake-flag--wfail"></a>
<a id="lake-option-o"></a>
<a id="lake-flag--builtin-lint"></a>
<a id="lake-flag--builtin-only"></a>
<a id="lake-option--linters"></a>
<a id="lake-option--lint-only"></a>
<a id="lake-flag--record-exceptions"></a>
<a id="lake-option--scope"></a>
<a id="lake-option--package"></a>
<a id="lake-option--max-revs"></a>
<a id="lake-option--mappings-only"></a>
<a id="lake-option--force-download"></a>
<a id="lake-option--repo"></a>
<a id="lake-option--toolchain"></a>
<a id="lake-option--platform"></a>
<a id="lake-flag--no-overwrite"></a>
<a id="lake-flag--force-overwrite"></a>
<a id="lake-option--rev"></a>
<a id="lakefile___toml"></a>
<a id="lakefile___lean"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 24.1. Lake

Lake is the standard Lean build tool. It is responsible for:

- Configuring builds and building Lean code
- Fetching and building external dependencies
- Integrating with Reservoir, the Lean package server
- Running tests, linters, and other development workflows

Lake is extensible. It provides a rich API that can be used to define incremental build tasks for software artifacts that are not written in Lean, to automate administrative tasks, and to integrate with external workflows. For build configurations that do not need these features, Lake provides a declarative configuration language that can be written either in TOML or as a Lean file.

This section describes Lake's [command-line interface](index.md#lake-cli), [configuration files](index.md#lake-config), and [internal API](index.md#lake-api). All three share a set of concepts and terminology.

<a id="lake-vocab"></a>
### 24.1.1. Concepts and Terminology

A 
<a id="--tech-term-package"></a>
*package* is the basic unit of Lean code distribution. A single package may contain multiple libraries or executable programs. A package consist of a directory that contains a [package configuration](index.md#--tech-term-package-configuration) file together with source code. Packages may 
<a id="--tech-term-require"></a>
*require* other packages, in which case those packages' code (more specifically, their [targets](index.md#--tech-term-target)) are made available. The 
<a id="--tech-term-direct-dependencies"></a>
*direct dependencies* of a package are those that it requires, and the 
<a id="--tech-term-transitive-dependencies"></a>
*transitive dependencies* are the direct dependencies of a package together with their transitive dependencies. Packages may either be obtained from [Reservoir](https://reservoir.lean-lang.org/), the Lean package repository, or from a manually-specified location. 
<a id="--tech-term-Git-dependencies"></a>
*Git dependencies* are specified by a Git repository URL along with a revision (branch, tag, or hash) and must be cloned locally prior to build, while local 
<a id="--tech-term-path-dependencies"></a>
*path dependencies* are specified by a path relative to the package's directory.

A 
<a id="--tech-term-workspace"></a>
*workspace* is a directory on disk that contains a working copy of a [package](index.md#--tech-term-package)'s source code and the source code of all [transitive dependencies](index.md#--tech-term-transitive-dependencies) that are not specified as local paths. The package for which the workspace was created is the 
<a id="--tech-term-root-package"></a>
*root package*. The workspace also contains any built [artifacts](index.md#--tech-term-artifact) for the package, enabling [incremental builds](index.md#--tech-term-incremental-build). Dependencies and artifacts do not need to be present for a directory to be considered a workspace; commands such as [`lake update`](index.md#update) and [`lake build`](index.md#build) produce them if they are missing. Lake is typically used in a workspace.[`lake init`](index.md#init) and [`lake new`](index.md#new), which create workspaces, are exceptions. Workspaces typically have the following layout:

- `lean-toolchain`: The [toolchain file](../Managing-Toolchains-with-Elan/index.md#--tech-term-toolchain-file).
- `lakefile.toml` or `lakefile.lean`: The [package configuration](index.md#--tech-term-package-configuration) file for the root package.
- `lake-manifest.json`: The root package's [manifest](index.md#--tech-term-manifest).
- `.lake/`: Intermediate state managed by Lake, such as built [artifacts](index.md#--tech-term-artifact) and dependency source code.

   

  - `.lake/lakefile.olean`: The root package's configuration, cached.
  - `.lake/packages/`: The workspace's 
    <a id="--tech-term-package-directory"></a>
    *package directory*, which contains copies of all non-local transitive dependencies of the root package, with their built artifacts in their own `.lake` directories.
  - `.lake/build/`: The 
    <a id="--tech-term-build-directory"></a>
    *build directory*, which contains built artifacts for the root package:

     

    - `.lake/build/bin`: The package's 
      <a id="--tech-term-binary-directory"></a>
      *binary directory*, which contains built executables.
    - `.lake/build/lib`: The package's *library directory*, which contains built libraries and [`.olean` files](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file).
    - `.lake/build/ir`: The package's intermediate result directory, which contains generated intermediate artifacts, primarily C code.

<a id="workspace-layout"></a>
  Workspace Layout 

A 
<a id="--tech-term-package-configuration"></a>
*package configuration* file specifies the dependencies, settings, and targets of a package. Packages can specify configuration options that apply to all their contained targets. They can be written in two formats:

- The [TOML format](index.md#lake-config-toml) (`lakefile.toml`) is used for fully declarative package configurations.
- The [Lean format](index.md#lake-config-lean) (`lakefile.lean`) additionally supports the use of Lean code to configure the package in ways not supported by the declarative options.

A 
<a id="--tech-term-manifest"></a>
*manifest* tracks the specific versions of other packages that are used in a package. Together, a manifest and a [package configuration](index.md#--tech-term-package-configuration) file specify a unique set of transitive dependencies for the package. Before building, Lake synchronizes the local copy of each dependency with the version specified in the manifest. If no manifest is available, Lake fetches the latest matching versions of each dependency and creates a manifest. It is an error if the package names listed in the manifest do not match those used by the package; the manifest must be updated using [`lake update`](index.md#update) prior to building. Manifests should be considered part of the package's code and should normally be checked into source control.

A 
<a id="--tech-term-target"></a>
*target* represents an output that can be requested by a user. A persistent build output, such as object code, an executable binary, or an [`.olean` file](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file), is called an 
<a id="--tech-term-artifact"></a>
*artifact*. In the process of producing an artifact, Lake may need to produce further artifacts; for example, compiling a Lean program into an executable requires that it and its dependencies be compiled to object files, which are themselves produced from C source files, which result from elaborating Lean sourcefiles and producing [`.olean` files](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file). Each link in this chain is a target, and Lake arranges for each to be built in turn. At the start of the chain are the 
<a id="--tech-term-initial-targets"></a>
*initial targets*:

- [*Packages*](index.md#--tech-term-package) are units of Lean code that are distributed as a unit.
- <a id="--tech-term-Libraries"></a>
  *Libraries* are collections of Lean [module](../../Source-Files-and-Modules/index.md#--tech-term-module)s, organized hierarchically under one or more 
  <a id="--tech-term-module-roots"></a>
  *module roots*.
- <a id="--tech-term-Executables"></a>
  *Executables* consist of a *single* module that defines `main`.
- <a id="--tech-term-External-libraries"></a>
  *External libraries* are non-Lean **static** libraries that will be linked to the binaries of the package and its dependents, including both their shared libraries and executables.
- <a id="--tech-term-Custom-targets"></a>
  *Custom targets* contain arbitrary code to run a build, written using Lake's internal API.

In addition to their Lean code, packages, libraries, and executables contain configuration settings that affect subsequent build steps. Packages may specify a set of 
<a id="--tech-term-default-targets"></a>
*default targets*. Default targets are the initial targets in the package that are to be built in contexts where a package is specified but specific targets are not.

The 
<a id="--tech-term-log"></a>
*log* contains information produced during a build. Logs are saved so they can be replayed during [incremental builds](index.md#--tech-term-incremental-build). Messages in the log have four levels, ordered by severity:

1. *Trace messages* contain internal build details that are often specific to the machine on which the build is running, including the specific invocations of Lean and other tools that are passed to the shell.
2. *Informational messages* contain general informational output that is not expected to indicate a problem with the code, such as the results of a [`#eval`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___eval) command.
3. *Warnings* indicate potential problems, such as unused variable bindings.
4. *Errors* explain why parsing and elaboration could not complete.

By default, trace messages are hidden and the others are shown. The threshold can be adjusted using the `--log-level` option, the `--verbose` flag, or the `--quiet` flag.

<a id="package-overrides"></a>
#### 24.1.1.1. Package  Overrides

Together, the [package configuration](index.md#--tech-term-package-configuration) and [manifest](index.md#--tech-term-manifest) describe the exact manner by which Lake expects to acquire dependencies. Usually, this involves making a local copy of a remote Git repository over the network. Lake terminates with an error if the remote repository cannot be accessed. Because the sources of dependencies are predictable, builds are reproducible across systems; packages are retrieved in the same way from the same sources on all machines.

Nonetheless, there are situations where it is infeasible to acquire package dependencies the same way the original developers did. For example, some companies require that all dependencies are audited prior to use, and not everyone always has access to the Internet while working. In these situations, it is necessary to acquire packages in some other way.

Lake's 
<a id="--tech-term-package-overrides"></a>
*package overrides* allow a package dependency to be redirected from one source to another without modifying any [package configurations](index.md#--tech-term-package-configuration) or [manifests](index.md#--tech-term-manifest). They do not allow packages to be added to or removed from the [workspace](index.md#--tech-term-workspace). All transitive dependencies in the workspace respect the redirection. The package overrides file is a JSON file that contains an alternate list of package entries. These entries will take precedence over those in the package's [manifest](index.md#--tech-term-manifest). This file can be provided to Lake either via the `--packages` option or by placing it at a fixed path within the Lake workspace: `.lake/package-overrides.json`.

The syntax of package entries in the package overrides file mirrors that of the [manifest](index.md#--tech-term-manifest). Thus, it is possible to copy an entry from a manifest into a package overrides file (and vice versa). One way to determine the necessary syntax for a package entry is to add a temporary dependency to a [package configuration](index.md#--tech-term-package-configuration) that matches the desired configuration, run [`lake update`](index.md#update) to generate a manifest with that dependency, and then copy the entry from the manifest into the package overrides file.

<a id="Making-Remote-Dependencies-Local"></a>
Making Remote Dependencies Local 

Consider a use case where programs are being developed in a restricted enviroment without network access (e.g., for security reasons). The team wishes to compile a small tool written in Lean that depends on the [`@leanprover/Cli`](https://reservoir.lean-lang.org/@leanprover/Cli) library to provide a simple command-line interface. That tool's [manifest](index.md#--tech-term-manifest) thus looks something like this:

```text
{
  "version": "1.2.0",
  "packagesDir": ".lake/packages",
  "packages": [{
    "url": "https://github.com/leanprover/lean4-cli",
    "type": "git",
    "subDir": null,
    "scope": "leanprover",
    "rev": "0000000000000000000000000000000000000000",
    "name": "Cli",
    "manifestFile": "lake-manifest.json",
    "inputRev": null,
    "inherited": false,
    "configFile": "lakefile.toml"
  }],
  "name": "myTool",
  "lakeDir": ".lake",
  "fixedToolchain": false
}
```

This manifest would instruct Lake to download the `Cli` package from the indicated GitHub URL when building this tool. However, the restricted environment does not have network access, so the build will fail unless Lake uses a local copy instead. This can be done with the following [package overrides](index.md#--tech-term-package-overrides) file:

```text
{
  "version": "1.2.0",
  "packages": [{
    "type": "path",
    "dir": "/etc/lean-packages/Cli",
    "name": "Cli",
    "manifestFile": "lake-manifest.json",
    "inherited": false,
    "configFile": "lakefile.toml"
  }]
}
```

With this, Lake will instead resolve the `Cli` dependency to the local package located at the path `/etc/lean-packages/Cli`.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Concepts-and-Terminology--Builds"></a>
#### 24.1.1.2. Builds

Producing a desired [artifact](index.md#--tech-term-artifact), such as a [`.olean` file](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file) or an executable binary, is called a 
<a id="--tech-term-build"></a>
*build*. Builds are triggered by the [`lake build`](index.md#build) command or by other commands that require an artifact to be present, such as [`lake exe`](index.md#exe). A build consists of the following steps:

<a id="--tech-term-Configuring"></a>
Configuring the package

If [package configuration](index.md#--tech-term-package-configuration) file is newer than the cached configuration file `lakefile.olean`, then the package configuration is re-elaborated. This also occurs when the cached file is missing or when the `--reconfigure` or `-R` flag is provided. Changes to options using `-K` do not trigger re-elaboration of the configuration file; `-R` is necessary in these cases.

  Computing dependencies

The set of artifacts that are required to produce the desired output are determined, along with the [targets](index.md#--tech-term-target) and [facets](index.md#--tech-term-facet) that produce them. This process is recursive, and the result is a *graph* of dependencies. The dependencies in this graph are distinct from those declared for a package: packages depend on other packages, while build targets depend on other build targets, which may be in the same package or in a different one. One facet of a given target may depend on other facets of the same target. Lake automatically analyzes the imports of Lean modules to discover their dependencies, and the `extraDepTargets` field can be used to add additional dependencies to a target.

  Replaying traces

Rather than rebuilding everything in the dependency graph from scratch, Lake uses saved 
<a id="--tech-term-trace-files"></a>
*trace files* to determine which artifacts require building. During a build, Lake records which source files or other artifacts were used to produce each artifact, saving a hash of each input; these 
<a id="--tech-term-traces"></a>
*traces* are saved in the [build directory](index.md#--tech-term-build-directory).More specifically, each artifact's trace file contains a Merkle tree hash mixture of its inputs' hashes. If the inputs are all unmodified, then the corresponding artifact is not rebuilt. Trace files additionally record the [log](index.md#--tech-term-log) from each build task; these outputs are replayed as if the artifact had been built anew. Reusing prior build products when possible is called an 
<a id="--tech-term-incremental-build"></a>
*incremental build*.

  Building artifacts

When all unmodified dependencies in the dependency graph have been replayed from their trace files, Lake proceeds to build each artifact. This involves running the appropriate build tool on the input files and saving the artifact and its trace file, as specified in the corresponding facet.

Lake uses two separate hash algorithms. Text files are hashed after normalizing newlines, so that files that differ only by platform-specific newline conventions are hashed identically. Other files are hashed without any normalization.

Along with the trace files, Lean caches input hashes. Whenever an artifact is built, its hash is saved in a separate file that can be re-read instead of computing the hash from scratch. This is a performance optimization. This feature can be disabled, causing all hashes to be recomputed from their inputs, using the `--rehash` command-line option.

During a build, the following directories are provided to the underlying build tools:

- The 
  <a id="--tech-term-source-directory"></a>
  *source directory* contains Lean source code that is available for import.
- The 
  <a id="--tech-term-library-directories"></a>
  *library directories* contain [`.olean` files](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file) along with the shared and static libraries that are available for linking; it normally consists of the [root package](index.md#--tech-term-root-package)'s library directory (found in `.lake/build/lib`), the library directories for the other packages in the workspace, the library directory for the current Lean toolchain, and the system library directory.
- The 
  <a id="--tech-term-Lake-home"></a>
  *Lake home* is the directory in which Lake is installed, including binaries, source code, and libraries. The libraries in the Lake home are needed to elaborate Lake configuration files, which have access to the full power of Lean.

<a id="lake-facets"></a>
#### 24.1.1.3. Facets

A 
<a id="--tech-term-facet"></a>
*facet* describes the production of a target from another. Conceptually, any target may have facets. However, executables, external libraries, and custom targets provide only a single implicit facet. Packages, libraries, and modules have multiple facets that can be requested by name when invoking [`lake build`](index.md#build) to select the corresponding target.

When no facet is explicitly requested, but an initial target is designated, [`lake build`](index.md#build) produces the initial target's 
<a id="--tech-term-default-facet"></a>
*default facet*. Each type of initial target has a corresponding default facet (e.g. producing an executable binary from an executable target or building a package's [default targets](index.md#--tech-term-default-targets)); other facets may be explicitly requested in the [package configuration](index.md#--tech-term-package-configuration) or via Lake's [command-line interface](index.md#lake-cli). Lake's internal API may be used to write custom facets.

The facets available for packages are:

  `extraDep`

The default facets of the package's extra dependency targets, specified in the `extraDepTargets` field.

  `deps`

The package's [direct dependencies](index.md#--tech-term-direct-dependencies).

  `transDeps`

The package's [transitive dependencies](index.md#--tech-term-transitive-dependencies), topologically sorted.

  `optCache`

A package's optional cached build archive (e.g., from Reservoir or GitHub). Will **not** cause the whole build to fail if the archive cannot be fetched.

  `cache`

A package's cached build archive (e.g., from Reservoir or GitHub). Will cause the whole build to fail if the archive cannot be fetched.

  `optBarrel`

A package's optional cached build archive (e.g., from Reservoir or GitHub). Will **not** cause the whole build to fail if the archive cannot be fetched.

  `barrel`

A package's cached build archive (e.g., from Reservoir or GitHub). Will cause the whole build to fail if the archive cannot be fetched.

  `optRelease`

A package's optional build archive from a GitHub release. Will **not** cause the whole build to fail if the release cannot be fetched.

  `release`

A package's build archive from a GitHub release. Will cause the whole build to fail if the archive cannot be fetched.

The facets available for libraries are:

  `leanArts`

The artifacts that the Lean compiler produces for the library or executable ([`*.olean`](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file), `*.ilean`, and `*.c` files).

  `static`

The static library produced by the C compiler from the `leanArts` (that is, a `*.a` file).

  `static.export`

The static library produced by the C compiler from the `leanArts` (that is, a `*.a` file), with exported symbols.

  `shared`

The shared library produced by the C compiler from the `leanArts` (that is, a `*.so`, `*.dll`, or `*.dylib` file, depending on the platform).

  `extraDep`

A Lean library's `extraDepTargets` and those of its package.

Executables have a single `exe` facet that consists of the executable binary.

The facets available for modules are:

  `lean`

The module's Lean source file.

  `leanArts` (default)

The module's Lean artifacts (`*.olean`, `*.ilean`, `*.c` files).

  `deps`

The module's dependencies (e.g., imports or shared libraries).

  `depHash`

A hash of a module's build dependencies (e.g., imports, source, plugins).

  `depTrace`

A Lake build trace data structure (i.e., composite hash and modification time) of a module's build dependencies (e.g., imports, source, plugins).

  `olean`

The module's [`.olean` file](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file).

  `ilean`

The module's `.ilean` file, which is metadata used by the Lean language server.

  `header`

The parsed module header of the module's source file.

  `input`

The module's processed Lean source file. Combines tracing the file with parsing its header.

  `imports`

The immediate imports of the Lean module, but not the full set of transitive imports.

  `precompileImports`

The transitive imports of the Lean module, compiled to object code.

  `transImports`

The transitive imports of the Lean module, as [`.olean` files](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file).

  `allImports`

Both the immediate and transitive imports of the Lean module.

  `setup`

All of a module's dependencies: transitive local imports and shared libraries to be loaded with `--load-dynlib`. Returns the list of shared libraries to load along with their search path.

  `ir`

The `.ir` file produced for modules that use the [module system](../../Source-Files-and-Modules/index.md#module-structure).

  `ir.sig`

The `.ir.sig` file produced for modules that use the [module system](../../Source-Files-and-Modules/index.md#module-structure).

  `c`

The C file produced by the Lean compiler.

  `bc`

LLVM bitcode file, produced by the Lean compiler.

  `c.o`

The compiled object file, produced from the C file. On Windows, this is equivalent to `.c.o.noexport`, while it is equivalent to `.c.o.export` on other platforms.

  `c.o.export`

The compiled object file, produced from the C file, with Lean symbols exported.

  `c.o.noexport`

The compiled object file, produced from the C file, without Lean symbols exported.

  `bc.o`

The compiled object file, produced from the LLVM bitcode file.

  `o`

The compiled object file for the configured backend.

  `dynlib`

A shared library (e.g., for the Lean option `--load-dynlib`).

  `ltar`

A compressed archive (produced via `leantar`) of the module's build artifacts.

  `linkInfoExport`

A structured representation of the linker arguments, static objects, and dynamic libraries needed to link a module and its dependencies. Objects have Lean symbols exported.

  `linkInfoNoExport`

A structured representation of the linker arguments, static objects, and dynamic libraries needed to link a module and its dependencies. Objects do not Lean symbols exported.

<a id="lake-scripts"></a>
#### 24.1.1.4. Scripts

Lake [package configuration](index.md#--tech-term-package-configuration) files may include 
<a id="--tech-term-Lake-scripts"></a>
*Lake scripts*, which are embedded programs that can be executed from the command line. Scripts are intended to be used for project-specific tasks that are not already well-served by Lake's other features. While ordinary executable programs are run in the `IO` [monad](../../Functors___-Monads-and--do--Notation/index.md#--tech-term-Monad), scripts are run in `ScriptM`, which extends `IO` with information about the workspace. Because they are Lean definitions, Lake scripts can only be defined in the Lean configuration format.

<a id="test-lint-drivers"></a>
#### 24.1.1.5. Test and Lint Drivers

A 
<a id="--tech-term-test-driver"></a>
*test driver* runs the tests for a package. It can be an executable target, a [Lake script](index.md#--tech-term-Lake-scripts), or a library. Lake itself isn't a test framework: the [`lake test`](index.md#test) command just locates the configured target, builds it, and (for executables and scripts) runs it. Library drivers are exercised purely by elaboration, so they aren't run as a separate step. Assertions, test discovery, and reporting are up to the target itself, whether that's a third-party testing library or hand-written checks.

For executables and scripts, Lake treats a nonzero exit code as a test failure. For libraries, any elaboration error counts as a test failure, including failures of `#guard`-style commands.

A 
<a id="--tech-term-lint-driver"></a>
*lint driver* is similar, but it's run by [`lake lint`](index.md#lint) and checks the package for stylistic issues and other problems that aren't *errors* but indicate likely problems. Lint drivers can only be executables or scripts, not libraries.

<a id="lake-test-driver-config"></a>
##### 24.1.1.5.1. Configuring a Test Driver

In a `lakefile.toml`, set `testDriver` to the name of an executable target, library target, or script defined in the same configuration:

<a id="Test-Driver-_LPAR_-lakefile___toml-_RPAR_"></a>
Test Driver (`lakefile.toml`) 

```text
name = "my-package"
testDriver = "my-package-tests"

[[lean_exe]]
name = "my-package-tests"
root = "Tests"
```

In a `lakefile.lean`, either set the `testDriver` field on the `package` declaration (as above), or tag a script, executable, or library declaration with the `test_driver` attribute. The attribute form is often convenient because it places the marker next to the target.

<a id="Test-Driver-_LPAR_-lakefile___lean-_RPAR_"></a>
Test Driver (`lakefile.lean`) 
<a id="Lake___CustomOut____FLQQ_my-package-tests_FLQQ_-_LPAR_in-Test-Driver-_LPAR_-lakefile___lean-_RPAR__RPAR_"></a>


```lean
import Lake
open Lake DSL

package «my-package» where
  testDriver := "my-package-tests"

lean_exe «my-package-tests» where
  root := `Tests
```

Only one declaration per package can be tagged with `test_driver`. It is an error to use both the `test_driver` attribute and a non-empty `testDriver` field in the same Lake configuration file.

A test driver may also be a target in a package dependency that is transitively [required](index.md#--tech-term-require). To use a target from another package, use `<pkg>/<name>` as the value of `testDriver`, where `<pkg>` is the name of the package in which the target is found..

<a id="lake-test-running"></a>
##### 24.1.1.5.2. Running Tests

The [`lake test`](index.md#test) command runs the configured driver for the [root package](index.md#--tech-term-root-package) only. Test drivers for dependencies are not run.

If the test driver is an executable or a script, Lake passes the arguments from `testDriverArgs` first, then anything after `--` on the command line. For example,

```text
lake test -- --filter Foo --verbose
```

passes `--filter Foo --verbose` to the driver after whatever `testDriverArgs` is already configured. Lake builds executable drivers before running them.

If the test driver is a library, arguments are not accepted. Lake reports an error if `testDriverArgs` is non-empty or if any arguments follow `--`. To run the tests, the library is just [elaborated](../../Terms/index.md#--tech-term-elaborator).

[`lake check-test`](index.md#check-test) terminates with exit code 0 (that is, successfully) if a test driver is configured for the root package. It doesn't check that the named target actually exists.

<a id="lake-lint-drivers"></a>
##### 24.1.1.5.3. Lint Drivers

Lint drivers are configured and run similarly to [test drivers](index.md#lake-test-driver-config). The Lake configuration file specifies a target that serves as the lint driver, and [`lake lint`](index.md#lint) runs it. This target must be an executable or a script; unlike test drivers, lint drivers may not be libraries.

In a TOML-format Lake configuration file, the package-level field `lintDriver` specifies the name of the lint driver target.

<a id="Lint-Driver-_LPAR_-lakefile___toml-_RPAR_"></a>
Lint Driver (`lakefile.toml`) 

This minimal `lakefile.toml` configures a lint driver:

```text
name = "my-package"
lintDriver = "my-package-lint"

[[lean_exe]]
name = "my-package-lint"
root = "Lint"
```

In a `lakefile.lean`, either set the `lintDriver` field on the `package` declaration, or tag a script or executable declaration with the `lint_driver` attribute. The attribute form is often convenient because it places the marker next to the target.

<a id="Lint-Driver-_LPAR_-lakefile___lean-_RPAR_"></a>
Lint Driver (`lakefile.lean`) 
<a id="Lake___CustomOut____FLQQ_my-package-lint_FLQQ_-_LPAR_in-Lint-Driver-_LPAR_-lakefile___lean-_RPAR__RPAR_"></a>


```lean
import Lake
open Lake DSL

package «my-package» where
  lintDriver := "my-package-lint"

lean_exe «my-package-lint» where
  root := `Lint
```

Only one declaration per package can be tagged with `lint_driver`. It is an error to use both the `lint_driver` attribute and a non-empty `lintDriver` field in the same Lake configuration file.

A lint driver in a dependency package can be referenced with the same `<pkg>/<name>` syntax used for test drivers.

[`lake lint`](index.md#lint) runs the configured driver, passing `lintDriverArgs` first, then anything after `--` on the command line:

```text
lake lint -- --warnings-as-errors
```

Lake also has a separate 
<a id="--tech-term-builtin-linter"></a>
*builtin linter* that operates on Lean modules directly, independent of any configured driver. Builtin linting is enabled by the `--builtin-lint` and related flags (see [`lake lint`](index.md#lint)), or by setting `builtinLint` to `true` in the package configuration. When builtin linting is active, positional `MODULE` arguments before `--` select which modules to lint, and they are *not* passed to the configured driver. So `lake lint Mathlib` triggers builtin linting on `Mathlib`, whereas `lake lint -- Mathlib` passes `Mathlib` to the driver. The two mechanisms are independent and can run together: when both apply, Lake runs the builtin linter first and then the driver.

[`lake check-lint`](index.md#check-lint) exits with code 0 (that is, successfully) if a lint driver is configured for the root package or if `builtinLint` is set to `true` in its configuration.

<a id="lake-github"></a>
#### 24.1.1.6. GitHub Release Builds

Lake supports uploading and downloading build artifacts (i.e., the archived build directory) to/from the GitHub releases of packages. This enables end users to fetch pre-built artifacts from the cloud without needed to rebuild the package from source themselves. The `LAKE_NO_CACHE` environment variable can be used to disable this feature.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Concepts-and-Terminology--GitHub-Release-Builds--Downloading"></a>
##### 24.1.1.6.1. Downloading

To download artifacts, one should configure the package options `releaseRepo` and `buildArchive` to point to the GitHub repository hosting the release and the correct artifact name within it (if the defaults are not sufficient). Then, set `preferReleaseBuild := true` to tell Lake to fetch and unpack it as an extra package dependency.

Lake will only fetch release builds as part of its standard build process if the package wanting it is a dependency (as the root package is expected to modified and thus not often compatible with this scheme). However, should one wish to fetch a release for a root package (e.g., after cloning the release's source but before editing), one can manually do so via `lake build :release`.

Lake internally uses `curl` to download the release and `tar` to unpack it, so the end user must have both tools installed in order to use this feature. If Lake fails to fetch a release for any reason, it will move on to building from the source. This mechanism is not technically limited to GitHub: any Git host that uses the same URL scheme works as well.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Concepts-and-Terminology--GitHub-Release-Builds--Uploading"></a>
##### 24.1.1.6.2. Uploading

To upload a built package as an artifact to a GitHub release, Lake provides the [`lake upload`](index.md#upload) command as a convenient shorthand. This command uses `tar` to pack the package's build directory into an archive and uses `gh release upload` to attach it to a pre-existing GitHub release for the specified tag. Thus, in order to use it, the package uploader (but not the downloader) needs to have `gh`, the GitHub CLI, installed and in `PATH`.

<a id="lake-cache"></a>
#### 24.1.1.7. Artifact Caches

**This is an experimental feature that is still undergoing development.**

Lake supports a 
<a id="--tech-term-local-artifact-cache"></a>
*local artifact cache* that stores individual build products, tracking the complete set of inputs that gave rise to them. Each [toolchain](../index.md#--tech-term-toolchain) has its own cache because intermediate build products are not compatible between toolchain versions. However, a toolchain's cache is shared between all local [workspaces](index.md#--tech-term-workspace) that use it, so common dependencies don't need to be rebuilt. If two separate workspaces with the same toolchain depend on the same package, then they can share each others' build products.

Because it is an experimental feature, the local cache is disabled by default. It is only enabled when the `LAKE_ARTIFACT_CACHE` environment variable is set to `true` or when the `enableArtifactCache` field is set to `true` in the [configuration file](index.md#lake-config).

<a id="lake-cache-remote"></a>
##### 24.1.1.7.1. Remote Artifact Caches

Build products can be retrieved from remote cache servers and placed into the local cache. This makes it possible to completely avoid local builds. The [`lake cache get`](index.md#cache-get) command is used to download artifacts into the local cache.

Compared to [GitHub release builds](index.md#lake-github), the remote artifact cache is much more fine-grained. It tracks build products at the level of individual source files, [`.olean` files](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file), and object code, rather than at the level of entire packages.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Concepts-and-Terminology--Artifact-Caches--Mappings"></a>
##### 24.1.1.7.2. Mappings

When passed the `-o` option, [`lake build`](index.md#build) tracks the inputs used to generate each build product. These are stored to a 
<a id="--tech-term-mappings-file"></a>
*mappings file* in JSON lines format, where each line of the file must be a valid JSON object. A mappings file tracks a single build, and includes all intermediate and final build products for the workspace's [root package](index.md#--tech-term-root-package), but not for its dependencies. This includes build products that were already up to date and not regenerated. The [`lake cache put`](index.md#cache-put) command uploads the build products in the mappings file to the remote from the local cache to the remote cache.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Concepts-and-Terminology--Artifact-Caches--Configuration"></a>
##### 24.1.1.7.3. Configuration

Remote artifact caches are configured using the following environment variables:

- `LAKE_CACHE_KEY`
- `LAKE_CACHE_ARTIFACT_ENDPOINT`
- `LAKE_CACHE_REVISION_ENDPOINT`

<a id="lake-cli"></a>
### 24.1.2. Command-Line Interface

Lake's command-line interface is structured into a series of subcommands. All of the subcommands share the ability to be configured by certain environment variables and global command-line options. Each subcommand should be understood as a utility in its own right, with its own required argument syntax and documentation.

Some of Lake's commands delegate to other command-line utilities that are not included in a Lean distribution. These utilities must be available on the `PATH` in order to use the corresponding features:

- `git` is required in order to access Git dependencies.
- `tar` is required to create or extract cloud build archives, and `curl` is required to fetch them.
- `gh` is required to upload build artifacts to GitHub releases.

Lean distributions include a C compiler toolchain.

<a id="lake-environment"></a>
#### 24.1.2.1. Environment Variables

When invoking the Lean compiler or other tools, Lake sets or modifies a number of environment variables.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 These values are system-dependent. Invoking [`lake env`](index.md#env) without any arguments displays the environment variables and their values. Otherwise, the provided command is invoked in Lake's environment.

The following variables are set, overriding previous values:

| `LAKE` | The detected Lake executable |
| --- | --- |
| `LAKE_HOME` | The detected [Lake home](index.md#--tech-term-Lake-home) |
| `LEAN_SYSROOT` | The detected Lean [toolchain](../index.md#--tech-term-toolchain) directory |
| `LEAN_AR` | The detected Lean `ar` binary |
| `LEAN_CC` | The detected C compiler (if not using the bundled one) |

The following variables are augmented with additional information:

| `LEAN_PATH` | Lake's and the [workspace](index.md#--tech-term-workspace)'s Lean [library directories](index.md#--tech-term-library-directories) are added. |
| --- | --- |
| `LEAN_SRC_PATH` | Lake's and the [workspace](index.md#--tech-term-workspace)'s [source directories](index.md#--tech-term-source-directory) are added. |
| `PATH` | Lean's, Lake's, and the [workspace](index.md#--tech-term-workspace)'s [binary directories](index.md#--tech-term-binary-directory) are added. On Windows, Lean's and the [workspace](index.md#--tech-term-workspace)'s [library directories](index.md#--tech-term-library-directories) are also added. |
| `DYLD_LIBRARY_PATH` | On macOS, Lean's and the [workspace](index.md#--tech-term-workspace)'s [library directories](index.md#--tech-term-library-directories) are added. |
| `LD_LIBRARY_PATH` | On platforms other than Windows and macOS, Lean's and the [workspace](index.md#--tech-term-workspace)'s [library directories](index.md#--tech-term-library-directories) are added. |

Lake itself can be configured with the following environment variables:

| `ELAN_HOME` | The location of the [Elan](../Managing-Toolchains-with-Elan/index.md#elan) installation, which is used for [automatic toolchain updates](index.md#automatic-toolchain-updates). |
| --- | --- |
| `ELAN` | The location of the `elan` binary, which is used for [automatic toolchain updates](index.md#automatic-toolchain-updates). If it is not set, an occurrence of `elan` must exist on the `PATH`. |
| `LAKE_HOME` | The location of the Lake installation. This environment variable is only consulted when Lake is unable to determine its installation path from the location of the `lake` executable that's currently running. |
| `LEAN_SYSROOT` | The location of the Lean installation, used to find the Lean compiler, the standard library, and other bundled tools. Lake first checks whether its binary is colocated with a Lean install, using that installation if so. If not, or if `LAKE_OVERRIDE_LEAN` is true, then Lake consults `LEAN_SYSROOT`. If this is not set, Lake consults the `LEAN` environment variable to find the Lean compiler, and attempts to find the Lean installation relative to the compiler. If `LEAN` is set but empty, Lake considers Lean to be disabled. If `LEAN_SYSROOT` and `LEAN` are unset, the first occurrence of `lean` on the `PATH` is used to find the installation. |
| `LEAN_CC` and `LEAN_AR` | If `LEAN_CC` and/or `LEAN_AR` is set, its value is used as the C compiler or `ar` command when building libraries. If not, Lake will fall back to the bundled tool in the Lean installation. If the bundled tool is not found, the value of `CC` or `AR`, followed by a `cc` or `ar` on the `PATH`, are used. |
| `LAKE_NO_CACHE` | If true, Lake does not use cached builds from [Reservoir](https://reservoir.lean-lang.org/) or [GitHub](index.md#lake-github). This environment variable can be overridden using the `--try-cache` command-line option. |
| `LAKE_ARTIFACT_CACHE` | If true, Lake uses the artifact cache. This is an experimental feature. |
| `LAKE_CACHE_KEY` | Defines an authentication key for the [remote artifact cache](index.md#lake-cache-remote). |
| `LAKE_CACHE_ARTIFACT_ENDPOINT` | The base URL for the [remote artifact cache](index.md#lake-cache-remote) used for artifact uploads. If set, then `LAKE_CACHE_REVISION_ENDPOINT` must also be set. If neither of these are set, Lake will use Reservoir instead. |
| `LAKE_CACHE_REVISION_ENDPOINT` | The base URL for the [remote artifact cache](index.md#lake-cache-remote) used to upload the [input/output mappings](index.md#--tech-term-mappings-file) for each artifact. If set, then `LAKE_CACHE_ARTIFACT_ENDPOINT` must also be set. If neither of these are set, Lake will use Reservoir instead. |

Lake considers an environment variable to be true when its value is `y`, `yes`, `t`, `true`, `on`, or `1`, compared case-insensitively. It considers a variable to be false when its value is `n`, `no`, `f`, `false`, `off`, or `0`, compared case-insensitively. If the variable is unset, or its value is neither true nor false, a default value is used.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Options"></a>
#### 24.1.2.2. Options

Lake's command-line interface provides a number of global options as well as subcommands that perform important tasks. Single-character flags cannot be combined; `-HR` is not equivalent to `-H -R`.

  `--version`

Lake outputs its version and exits without doing anything else.

  `--help` or `-h`

Lake outputs its version along with usage information and exits without doing anything else. Subcommands may be used with `--help`, in which case usage information for the subcommand is output.

  `--dir=DIR` or `-d=DIR`

Use the provided directory as location of the package instead of the current working directory. This is not always equivalent to changing to the directory first, because the version of `lake` indicated by the current directory's [toolchain file](../Managing-Toolchains-with-Elan/index.md#--tech-term-toolchain-file) will be used, rather than that of `DIR`.

  `--file=FILE` or `-f=FILE`

Use the specified [package configuration](index.md#--tech-term-package-configuration) file instead of the default.

  `--old`

Only rebuild modified modules, ignoring transitive dependencies. Modules that import the modified module will not be rebuilt. In order to accomplish this, file modification times are used instead of hashes to determine whether a module has changed.

  `--rehash` or `-H`

Ignore cached file hashes, recomputing them. Lake uses hashes of dependencies to determine whether to rebuild an artifact. These hashes are cached on disk whenever a module is built. To save time during builds, these cached hashes are used instead of recomputing each hash unless `--rehash` is specified.

  `--allow-empty`

Accept builds that produce no output when no [default targets](index.md#--tech-term-default-targets) are configured.

  `--update`

Update dependencies after the [package configuration](index.md#--tech-term-package-configuration) is loaded but prior to performing other tasks, such as a build. This is equivalent to running `lake update` before the selected command, but it may be faster due to not having to load the configuration twice.

  `--packages=FILE`

Uses the specified [package overrides](index.md#--tech-term-package-overrides) file. Can be specified multiple times to add more overrides (with later overrides taking precedence). The complete set of package overrides will also include those from `.lake/package-overrides.json` (if any). However, the ones provided by this option take precedence.

  `--reconfigure` or `-R`

Normally, the [package configuration](index.md#--tech-term-package-configuration) file is [elaborated](../../Notations-and-Macros/Elaborators/index.md#--tech-term-elaborators) when a package is first configured, with the result cached to a [`.olean` file](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file) that is used for future invocations until the package configuration Providing this flag causes the configuration file to be re-elaborated.

  `--keep-toolchain`

By default, Lake attempts to update the local [workspace](index.md#--tech-term-workspace)'s [toolchain file](../Managing-Toolchains-with-Elan/index.md#--tech-term-toolchain-file). Providing this flag disables [automatic toolchain updates](index.md#automatic-toolchain-updates).

  `--no-build`

Lake exits immediately if a build target is not up-to-date, returning a non-zero exit code.

  `--no-cache`

Instead of using available cloud build caches, build all packages locally. Build caches are not downloaded.

  `--try-cache`

attempt to download build caches for supported packages

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Controlling-Output"></a>
#### 24.1.2.3. Controlling Output

These options provide allow control over the [log](index.md#--tech-term-log) that is produced while building. In addition to showing or hiding messages, a build can be made to fail when warnings or even information is emitted; this can be used to enforce a style guide that disallows output during builds.

  `--quiet`, `-q`

Hides informational logs and the progress indicator.

  `--verbose`, `-v`

Shows trace logs (typically command invocations) and built [targets](index.md#--tech-term-target).

  `--ansi`, `--no-ansi`

Enables or disables the use of [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code) that add colors and animations to Lake's output.

  `--log-level=LV`

Sets the minimum level of [logs](index.md#--tech-term-log) to be shown when builds succeed. `LV` may be `trace`, `info`, `warning`, or `error`, compared case-insensitively. When a build fails, all levels are shown. The default log level is `info`.

  `--fail-level=LV`

Sets the threshold at which a message in the [log](index.md#--tech-term-log) causes a build to be considered a failure. If a message is emitted to the log with a level that is greater than or equal to the threshold, the build fails. `LV` may be `trace`, `info`, `warning`, or `error`, compared case-insensitively; it is `error` by default.

  `--iofail`

Causes builds to fail if any I/O or other info is logged. This is equivalent to `--fail-level=info`.

  `--wfail`

Causes builds to fail if any warnings are logged. This is equivalent to `--fail-level=warning`.

<a id="automatic-toolchain-updates"></a>
#### 24.1.2.4. Automatic Toolchain Updates

The [`lake update`](index.md#update) command checks for changes to dependencies, fetching their sources and updating the [manifest](index.md#--tech-term-manifest) accordingly. By default, [`lake update`](index.md#update) also attempts to update the [root package](index.md#--tech-term-root-package)'s [toolchain file](../Managing-Toolchains-with-Elan/index.md#--tech-term-toolchain-file) when a new version of a dependency specifies an updated toolchain. This behavior can be disabled with the `--keep-toolchain` flag.

If multiple dependencies specify newer toolchains, Lake selects the newest compatible toolchain, if it exists. To determine the newest compatible toolchain, Lake parses the toolchain listed in the packages' `lean-toolchain` files into four categories:

- Releases, which are compared by version number (e.g., `v4.4.0` < `v4.8.0` and `v4.6.0-rc1` < `v4.6.0`)
- Nightly builds, which are compared by date (e.g., `nightly-2024-01-10` < `nightly-2024-10-01`)
- Builds from pull requests to the Lean compiler, which are incomparable
- Other versions, which are also incomparable

Toolchain versions from multiple categories are incomparable. If there is not a single newest toolchain, Lake will print a warning and continue updating without changing the toolchain.

If Lake does find a new toolchain, then it updates the [workspace](index.md#--tech-term-workspace)'s `lean-toolchain` file accordingly and restarts the [`lake update`](index.md#update) using the new toolchain's Lake. If [Elan](../Managing-Toolchains-with-Elan/index.md#elan) is detected, it will spawn the new Lake process via `elan run` with the same arguments Lake was initially run with. If Elan is missing, it will prompt the user to restart Lake manually and exit with a special error code (namely, `4`). The Elan executable used by Lake can be configured using the `ELAN` environment variable.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Creating-Packages"></a>
#### 24.1.2.5. Creating Packages

<a id="new"></a>

**Lake command**

```text
lake new name [template][.language]
```

Running [`lake new`](index.md#new) creates an initial Lean package in a new directory. This command is equivalent to creating a directory named `name` and then running [`lake init`](index.md#init)

<a id="init"></a>

**Lake command**

```text
lake init name [template][.language]
```

Running [`lake init`](index.md#init) creates an initial Lean package in the current directory. The package's contents are based on a template, with the names of the [package](index.md#--tech-term-package), its [targets](index.md#--tech-term-target), and their [module roots](index.md#--tech-term-module-roots) derived from the name of the current directory.

The `template` may be:

  `std` (default)

Creates a package that contains a library and an executable.

  `exe`

Creates a package that contains only an executable.

  `lib`

Creates a package that contains only a library.

  `math`

Creates a package that contains a library that depends on [Mathlib](https://github.com/leanprover-community/mathlib4).

The `language` selects the file format used for the [package configuration](index.md#--tech-term-package-configuration) file and may be `lean` or `toml` (the default).

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Building-and-Running"></a>
#### 24.1.2.6. Building and Running

<a id="build"></a>

**Lake command**

```text
lake build [targets...] [-o mappings]
```

Builds the specified facts of the specified targets.

Each of the `targets` is specified by a string of the form:

`[[@]package[/]][target|[+]module][:facet]`

The optional `@` and `+` markers can be used to disambiguate packages and modules from file paths as well as executables, and libraries, which are specified by name as `target`. If not provided, `package` defaults to the [workspace](index.md#--tech-term-workspace)'s [root package](index.md#--tech-term-root-package). If the same target name exists in multiple packages in the workspace, then the first occurrence of the target name found in a topological sort of the package dependency graph is selected. Module targets may also be specified by their filename, with an optional facet after a colon.

The available [facets](index.md#--tech-term-facet) depend on whether a package, library, executable, or module is to be built. They are listed in [the section on facets](index.md#lake-facets).

When using the [local artifact cache](index.md#lake-cache), the `-o` option saves a [mappings file](index.md#--tech-term-mappings-file) that tracks the inputs and outputs of each step in the build. This file can be used with [`lake cache get`](index.md#cache-get) and [`lake cache put`](index.md#cache-put) to interact with a remote cache. The mappings file is in JSON Lines format, with one valid JSON object per line, and its filename extension is conventionally `.jsonl`.

<a id="Target-and-Facet-Specifications"></a>
Target and Facet Specifications 

| `a` | The [default facet](index.md#--tech-term-default-facet)(s) of target `a` |
| --- | --- |
| `@a` | The [default targets](index.md#--tech-term-default-targets) of [package](index.md#--tech-term-package) `a` |
| `+A` | The Lean artifacts of module `A` (because the default facet of modules is `leanArts`) |
| `@a/b` | The default facet of target `b` of package `a` |
| `@a/+A:c` | The C file compiled from module `A` of package `a` |
| `:foo` | The [root package](index.md#--tech-term-root-package)'s facet `foo` |
| `A/B/C.lean:o` | The compiled object code for the module in the file `A/B/C.lean` |

<a id="check-build"></a>

**Lake command**

```text
lake check-build
```

Exits with code 0 if the [workspace](index.md#--tech-term-workspace)'s [root package](index.md#--tech-term-root-package) has any [default targets](index.md#--tech-term-default-targets) configured. Errors (with exit code 1) otherwise.

[`lake check-build`](index.md#check-build) does **not** verify that the configured default targets are valid. It merely verifies that at least one is specified.

<a id="query"></a>

**Lake command**

```text
lake query [targets...]
```

Builds a set of targets, reporting progress on standard error and outputting the results on standard out. Target results are output in the same order they are listed and end with a newline. If `--json` is set, results are formatted as JSON. Otherwise, they are printed as raw strings.

Targets which do not have output configured will be printed as an empty string or `null`. For executable targets, the output is the path to the built executable.

Targets are specified using the same syntax as in [`lake build`](index.md#build).

<a id="exe"></a>

**Lake command**

```text
lake exe exe-target [args...]
```

**Alias:** `lake exec`

Looks for the executable target `exe-target` in the workspace, builds it if it is out of date, and then runs it with the given `args` in Lake's environment.

See [`lake build`](index.md#build) for the syntax of target specifications and [`lake env`](index.md#env) for a description of how the environment is set up.

<a id="clean"></a>

**Lake command**

```text
lake clean [packages...]
```

If no package is specified, deletes the [build directories](index.md#--tech-term-build-directory) of every package in the workspace. Otherwise, it just deletes those of the specified `packages`.

<a id="env"></a>

**Lake command**

```text
lake env [cmd [args...]]
```

When `cmd` is provided, it is executed in [the Lake environment](index.md#lake-environment) with arguments `args`.

If `cmd` is not provided, Lake prints the environment in which it runs tools. This environment is system-specific.

<a id="lean"></a>

**Lake command**

```text
lake lean file [-- args...]
```

Builds the imports of the given `file` and then runs `lean` on it using the [workspace](index.md#--tech-term-workspace)'s [root package](index.md#--tech-term-root-package)'s additional Lean arguments and the given `args`, in that order. The `lean` process is executed in [Lake's environment](index.md#lake-environment).

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Module-Imports"></a>
#### 24.1.2.7. Module Imports

<a id="shake"></a>

**Lake command**

```text
lake shake [options...] [module ...]
```

Checks the current project for unused imports by analyzing generated [`.olean` files](../../Elaboration-and-Compilation/index.md#--tech-term-___olean-file) to deduce required imports, ensuring that every import contributes some constant or other elaboration dependency.

If a `module` is specified, then it and all files that are transitively reachable from it are checked. Otherwise, the package's [default targets](index.md#--tech-term-default-targets) are checked.

Source files can contain special comments to control the behavior of [`lake shake`](index.md#shake):

  `module -- shake: keep-downstream`

Preserves this module in all downstream modules.

  `module -- shake: keep-all`

Preserves all existing imports in this module.

  `import X -- shake: keep`

Preserves this specific import.

The `options` may be:

  `--force`

Skip the `lake build --no-build` sanity check

  `--keep-implied`

Preserve imports implied by other imports

  `--keep-prefix`

Prefer parent module imports over specific submodules

  `--keep-public`

Preserve all `public` imports for API stability

  `--add-public`

Add new imports as `public` if they were in the original public closure

  `--explain`

Show which constants require each import

  `--fix`

Apply suggested fixes directly to source files

  `--gh-style`

Output in GitHub problem matcher format

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Development-Tools"></a>
#### 24.1.2.8. Development Tools

Lake includes support for specifying standard development tools and workflows. On the command line, these tools can be invoked using the appropriate `lake` subcommands.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Development-Tools--Tests-and-Linters"></a>
##### 24.1.2.8.1. Tests and Linters

<a id="test"></a>

**Lake command**

```text
lake test [-- args...]
```

Test the workspace's root package using its configured [test driver](index.md#--tech-term-test-driver).

A test driver that is an executable will be built and then run with the package configuration's `testDriverArgs` plus the CLI `args`. A test driver that is a [Lake script](index.md#--tech-term-Lake-scripts) is run with the same arguments as an executable test driver. A library test driver will just be built; it is expected that tests are implemented such that failures cause the build to fail via elaboration-time errors.

<a id="lint"></a>

**Lake command**

```text
lake lint [options...] [module...] [-- args...]
```

By default, lint the workspace's root package using its configured lint driver. If `builtinLint` is set to `true` in the package configuration, builtin lints also run.

Positional `module` arguments narrow only the builtin lints; if omitted, the workspace's default target roots are used. The lint driver is invoked with `lintDriverArgs` from the package config plus any arguments after `--`; the `module` list is not passed to it.

Builtin linting builds the targeted modules with the requested linter options enabled. It is triggered by `--builtin-lint`, `--builtin-only`, `--linters`, or `--lint-only`, as well as by setting `builtinLint` to `true` in the package configuration. By contrast, running the lint driver does not automatically trigger a build of anything but the lint driver itself.

The set of environment linters to be run on a declaration is determined by the linter options that were in effect when that declaration was built, whether they were set by `set_option` in the source or on the command line. Both `--linters` and `--lint-only` override those options for the lint build.

The `options` may be:

  `--builtin-lint`

Run builtin environment and text linters.

  `--builtin-only`

Run only builtin linters, skipping the lint driver.

  `--linters` `<spec>`

Override linter options for the lint build. The `<spec>` is a comma-separated list of linter option names, each optionally prefixed with `-` to disable it. A name that begins with `.` is shorthand for the `linter.` prefix, so that `.foo` means `linter.foo`, as in `--linters=.foo,-linter.bar`. This option may be repeated; for a given linter, later entries override earlier ones.

  `--lint-only` `<spec>`

Like `--linters`, but report only the linters that `<spec>` positively enables, suppressing every other linter, including default-on linters that are not named. `linter.all` and linter sets are expanded. Switching between `--linters` and `--lint-only` replaces the prior spec.

  `--record-exceptions`

Record each linter warning as a `set_option <linter> false in` exception by editing the offending source files in place, silencing the warning for that declaration. This implies `--builtin-lint`.

A lint driver can be configured by either setting the `lintDriver` package configuration option or by tagging a script or executable with the `@[lint_driver]` attribute. A definition in a dependency can be used as a lint driver by using the `<pkg>/<name>` syntax for the `lintDriver` configuration option.

A script lint driver will be run with the package configuration's `lintDriverArgs` plus the CLI `args`. An executable lint driver will be built and then run like a script.

<a id="check-test"></a>

**Lake command**

```text
lake check-test
```

Check if there is a properly configured test driver

Exits with code 0 if the workspace's root package has a properly configured lint driver. Errors (with code 1) otherwise.

Does NOT verify that the configured test driver actually exists in the package or its dependencies. It merely verifies that one is specified.

This is useful for distinguishing between failing tests and incorrectly configured packages.

<a id="check-lint"></a>

**Lake command**

```text
lake check-lint
```

Check if there is a properly configured lint driver

Exits with code 0 if the workspace's root package has a properly configured lint driver. Errors (with code 1) otherwise.

Does NOT verify that the configured lint driver actually exists in the package or its dependencies. It merely verifies that one is specified.

This is useful for distinguishing between failing lints and incorrectly configured packages.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Development-Tools--Scripts"></a>
##### 24.1.2.8.2. Scripts

<a id="script-list"></a>

**Lake command**

```text
lake script list
```

**Alias:** `lake scripts`

Lists the available [scripts](index.md#lake-scripts) in the workspace.

<a id="script-run"></a>

**Lake command**

```text
lake script run [[package/]script [args...]]
```

**Alias:** `lake run`

This command runs the `script` of the workspace (or the specified `package`), passing `args` to it.

A bare [`lake run`](index.md#script-run) command will run the default script(s) of the root package(with no arguments).

<a id="script-doc"></a>

**Lake command**

```text
lake script doc script
```

Prints the documentation comment for `script`.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Development-Tools--Language-Server"></a>
##### 24.1.2.8.3. Language Server

<a id="serve"></a>

**Lake command**

```text
lake serve [-- args...]
```

Runs the Lean language server in the workspace's root project with the [package configuration](index.md#--tech-term-package-configuration)'s `moreServerArgs` field and `args`.

This command is typically invoked by editors or other tooling, rather than manually.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Dependency-Management"></a>
#### 24.1.2.9. Dependency Management

<a id="update"></a>

**Lake command**

```text
lake update [packages...]
```

Updates the Lake package [manifest](index.md#--tech-term-manifest) (i.e., `lake-manifest.json`), downloading and upgrading packages as needed. For each new (transitive) [Git dependency](index.md#--tech-term-Git-dependencies), the appropriate commit is cloned into a subdirectory of the workspace's [package directory](index.md#--tech-term-package-directory). No copy is made of local dependencies.

If a set of packages `packages` is specified, then these dependencies are upgraded to the latest version compatible with the package's configuration (or removed if removed from the configuration). If there are dependencies on multiple versions of the same package, an arbitrary version is selected.

A bare [`lake update`](index.md#update) will upgrade all dependencies.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Packaging-and-Distribution"></a>
#### 24.1.2.10. Packaging and Distribution

<a id="upload"></a>

**Lake command**

```text
lake upload tag
```

Packs the root package's `buildDir` into a `tar.gz` archive using `tar` and then uploads the asset to the pre-existing [GitHub](https://github.com/) release `tag` using [`gh`](https://cli.github.com/). Other hosts are not yet supported.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Packaging-and-Distribution--Cached-Cloud-Builds"></a>
##### 24.1.2.10.1. Cached Cloud Builds

**These commands are still experimental.** They are likely change in future versions of Lake based on user feedback. Packages that use Reservoir cloud build archives should enable the `platformIndependent` setting.

<a id="pack"></a>

**Lake command**

```text
lake pack [archive.tar.gz]
```

Packs the root package's [build directory](index.md#--tech-term-build-directory) into a gzipped tar archive using `tar`. If a path for the archive is not specified, the archive in the package's Lake directory (`.lake`) and named according to its `buildArchive` setting. This command does not build any artifacts: it only archives what is present. Users should ensure that the desired artifacts are present before running this command.

<a id="unpack"></a>

**Lake command**

```text
lake unpack [archive.tar.gz]
```

Unpacks the contents of the gzipped tar archive `archive.tgz` into the root package's [build directory](index.md#--tech-term-build-directory). If `archive.tgz` is not specified, the package's `buildArchive` setting is used to determine a filename, and the file is expected in package's Lake directory (`.lake`).

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Local-Caches"></a>
#### 24.1.2.11. Local Caches

[`lake cache get`](index.md#cache-get), [`lake cache put`](index.md#cache-put), and [`lake cache add`](index.md#cache-add) are used to interact with remote cache servers. These commands are **experimental**, and are only useful if the [local cache](index.md#lake-cache) is enabled.

These commands can be configured to use a 
<a id="--tech-term-cache-scope"></a>
cache scope, which is a server-specific identifier for a set of build outputs for a package. On Reservoir, scopes are currently identical with GitHub repositories, but may include toolchain and platform information in the future. Other remote caches may use any scope scheme that they want. Cache scopes are specified using the `--scope` option. Cache scopes are not identical to the scopes used to require packages from Reservoir.

<a id="cache-get"></a>

**Lake command**

```text
lake cache get [mappings] [--max-revs= cn] [--rev= commit-hash] [--package= name] [--service= name] [--repo= github-repo] [--platform= target-triple] [--toolchain=name] [--scope= remote-scope] [--mappings-only] [--force-download]
```

Downloads build outputs for packages in the workspace from a remote cache service to the local Lake [artifact cache](index.md#--tech-term-local-artifact-cache). The cache service used can be specified via the `--service` option. Otherwise, Lake will use the system default, or, if none is configured, Reservoir. See [`lake cache services`](index.md#cache-services) for more information on how to configure services.

By default, Lake will use Reservoir to download outputs for each package in the root's dependency tree in order. Non-Reservoir dependencies will be skipped. If an input-to-outputs `mappings` file, a `remote-scope`, or a `github-repo` is provided, Lake will instead download build outputs for the root package. In either case, `--package` restricts the download to the outputs of the named package.

For Reservoir, setting `--repo` will cause Lake to look up outputs for the package by a repository name, rather than the package's. This can be used to download outputs for a fork of the Reservoir package (if such artifacts are available). The `--platform` and `--toolchain` options can be used to download artifacts for a different platform/toolchain configuration than Lake detects. For a custom endpoint, the full prefix Lake uses can be set via `--scope`.

If `--rev` is not set, Lake uses the package's current revision to look up artifacts. Lake will download the artifacts for the most recent commit with available mappings. It will backtrack up to `--max-revs`, which defaults to 100. If set to 0, Lake will search the repository's whole history, or as far back as Git will allow.

By default, Lake will download both the input-to-output mappings and the output artifacts for packages. Using `--mappings-only` will cause Lake to only download the mappings and delay downloading artifacts until they are needed. Using `--force-download` will redownload existing files.

While downloading, Lake will continue on when a download for an artifact fails or if the download process for a whole package fails. However, it will report this and exit with a nonzero status code in such cases.

<a id="cache-put"></a>

**Lake command**

```text
lake cache put mappings [--service= name] [--scope= remote-scope] [--repo= github-repo] [--toolchain= name] [--platform= target-triple]
```

Uploads the input-to-outputs mappings contained in the specified file along with the corresponding output artifacts to a remote cache. The cache service used can be specified via the `--service` option. If not specified, Lake will use the system default, or error if none is configured. See [`lake cache services`](index.md#cache-services) for more information on how to configure services.

Files are uploaded using the AWS Signature Version 4 authentication protocol via `curl`. Thus, the service should generally be an S3-compatible bucket. The authentication key is set via the `LAKE_CACHE_KEY` environment variable.

Since Lake does not currently use cryptographically secure hashes for artifacts and outputs, uploads to the cache are prefixed with a scope to avoid clashes. The scope is controlled by the following options:

| `--scope``=``<remote-scope>` | Uses the provided scope `<remote-scope>` verbatim |
| --- | --- |
| `--repo``=``<github-repo>` | Uses the repository, toolchain, and platform as a scope |
| `--toolchain``=``<name>` | With `--repo`, sets the toolchain |
| `--platform``=``<target-triple>` | With `--repo`, sets the platform |

With `--repo`, Lake will produce a scope by augmenting the repository with toolchain and platform information as it deems necessary. With `--scope`, Lake will use the specified scope verbatim.

Artifacts are uploaded to the artifact endpoint with a file name derived from their Lake content hash (and prefixed by the repository or scope). The mappings file is uploaded to the revision endpoint with a file name derived from the package's current Git revision (and prefixed by the full scope). As such, the command will warn if the work tree currently has changes.

<a id="cache-add"></a>

**Lake command**

```text
lake cache add mappings [--package= name] [--service= name] [--scope= remote-scope] [--repo= github-repo] [--no-overwrite]
```

Reads a list of input-to-output mappings from the provided file and adds them to the local Lake cache. Mappings already in the cache are overwritten unless `--no-overwrite` is specified. The mappings are added for the root package unless `--package` is specified.

If `--service` is provided, the output artifacts can then be fetched lazily from that service during a Lake build. The service must either be `reservoir` or be configured through the Lake system configuration (see [`lake cache services`](index.md#cache-services) for details).

Since Lake does not currently use cryptographically secure hashes for artifacts and outputs, artifacts in a cache service are prefixed with a scope to avoid clashes. For Reservoir, this scope can either be a package (set via `--scope`) or a repository (set via `--repo`). For S3 services, both options are synonymous.

<a id="cache-clean"></a>

**Lake command**

```text
lake cache clean
```

Deletes the configured Lake [artifact cache](index.md#--tech-term-local-artifact-cache) directory. If a workspace configuration exists, this will delete the cache directory it uses. Otherwise, it will delete the default Lake cache directory for the system.

<a id="cache-services"></a>

**Lake command**

```text
lake cache services
```

Prints the name of each configured remote cache service (one per line). Additional services can be added by modifying the system Lake configuration file, which is usually located at `~/.lake/config.toml` but can be set via the `LAKE_CONFIG` environment variable.

The configuration of the system cache could look something like the following:

```text
cache.defaultService = "my-s3"
cache.defaultUploadService = "my-s3"

[[cache.service]]
name = "my-s3"
kind = "s3"
artifactEndpoint = "https://my-s3.com/a0"
revisionEndpoint = "https://my-s3.com/r0"
```

If no `cache.defaultService` is configured, Lake will use Reservoir by default.

<a id="cache-stage"></a>

**Lake command**

```text
lake cache stage mappings staging-directory [--force-overwrite]
```

Creates `staging-directory` and copies the `mappings` file to it. After this, it copies all artifacts described within the mappings file from the cache to the staging directory. Artifacts already in the staging directory are not overwritten unless `--force-overwrite` is specified. It is an error if any of the artifacts described cannot be found in the cache.

<a id="cache-unstage"></a>

**Lake command**

```text
lake cache unstage staging-directory [--force-overwrite]
```

Copies the mappings and artifacts stored in `staging-directory` (e.g., via [`lake cache stage`](index.md#cache-stage)) back into the cache.

Reads the mappings file located at `outputs.jsonl` within the staging directory and writes the mappings to the Lake cache. Then, it copies the described artifacts from the staging directory into the cache. Mappings and artifacts already in the cache are not overwritten unless `--force-overwrite` is specified.

<a id="cache-put-staged"></a>

**Lake command**

```text
lake cache put-staged staging-directory [--rev= commit-hash] [--service= name] [--scope= remote-scope] [--repo= github-repo] [--toolchain= name] [--platform= target-triple]
```

Uploads the mappings and artifacts stored in `staging-directory` (e.g., via [`lake cache stage`](index.md#cache-stage)) to a remote service. This works like [`lake cache put`](index.md#cache-put), except that the outputs are taken from the staging directory rather than from the Lake [artifact cache](index.md#--tech-term-local-artifact-cache).

This command does not configure the workspace, so it does not execute arbitrary user code. As a result, the package's platform and toolchain settings are not detected automatically for `--repo`, and they must be specified with `--platform` and `--toolchain` if they are needed.

By default, Lake detects the target revision from the workspace directory's current Git revision. Outputs can be uploaded for a different revision by specifying it with `--rev`.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Command-Line-Interface--Configuration-Files"></a>
#### 24.1.2.12. Configuration Files

<a id="translate-config"></a>

**Lake command**

```text
lake translate-config lang [out-file]
```

Translates the loaded package's configuration into another of Lake's supported configuration languages (i.e., either `lean` or `toml`). The produced file is written to `out-file` or, if not provided, the path of the configuration file with the new language's extension. If the output file already exists, Lake will error.

Translation is lossy. It does not preserve comments or formatting and non-declarative configuration is discarded.

<a id="lake-config"></a>
### 24.1.3. Configuration File Format

Lake offers two formats for [package configuration](index.md#--tech-term-package-configuration) files:

  TOML

The TOML configuration format is fully declarative. Projects that don't include custom targets, facets, or scripts can use the TOML format. Because TOML parsers are available for a wide variety of languages, using this format facilitates integration with tools that are not written in Lean.

  Lean

The Lean configuration format is more flexible and allows for custom targets, facets, and scripts. It features an embedded domain-specific language for describing the declarative subset of configuration options that is available from the TOML format. Additionally, the Lake API can be used to express build configurations that are outside of the possibilities of the declarative options.

The command [`lake translate-config`](index.md#translate-config) can be used to automatically convert between the two formats.

Both formats are processed similarly by Lake, which extracts the [package configuration](index.md#--tech-term-package-configuration) from the configuration file in the form of internal structure types. When the package is [configured](index.md#--tech-term-Configuring), the resulting data structures are written to `lakefile.olean` in the [build directory](index.md#--tech-term-build-directory).

<a id="lake-config-toml"></a>
#### 24.1.3.1. Declarative TOML Format

TOML[*Tom's Obvious Minimal Language*](https://toml.io/en/) is a standardized format for configuration files. configuration files describe the most-used, declarative subset of Lake [package configuration](index.md#--tech-term-package-configuration) files. TOML files denote *tables*, which map keys to values. Values may consist of strings, numbers, arrays of values, or further tables. Because TOML allows considerable flexibility in file structure, this reference documents the values that are expected rather than the specific syntax used to produce them.

The contents of `lakefile.toml` should denote a TOML table that describes a Lean package. This configuration consists of both scalar fields that describe the entire package, as well as the following fields that contain arrays of further tables:

- `require`
- `lean_lib`
- `lean_exe`

Fields that are not part of the configuration tables described here are presently ignored. To reduce the risk of typos, this is likely to change in the future. Field names not used by Lake should not be used to store metadata to be processed by other tools.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Declarative-TOML-Format--Package-Configuration"></a>
##### 24.1.3.1.1. Package Configuration

The top-level contents of `lakefile.toml` specify the options that apply to the package itself, including metadata such as the name and version, the locations of the files in the [workspace](index.md#--tech-term-workspace), compiler flags to be used for all [targets](index.md#--tech-term-target), and The only mandatory field is `name`, which declares the package's name.

<a id="Lake___PackageConfig"></a>

**TOML table**

```text
Package Configuration
```

A `Package`'s declarative configuration.

**Metadata:**

These options describe the package. They are used by [Reservoir](https://reservoir.lean-lang.org/) to index and display packages. If a field is left out, Reservoir may use information from the package's GitHub repository to fill in details.

<a id="Lake___PackageConfig-name"></a>
`name`

**Contains:** The package name

The package's name.

<a id="Lake___PackageConfig-version"></a>
`version`

**Contains:** Version string

The package version. Versions have the form:

```text
v!"<major>.<minor>.<patch>[-<specialDescr>]"
```

A version with a `-` suffix is considered a "prerelease".

Lake suggest the following guidelines for incrementing versions:

- **Major version increment** *(e.g., v1.3.0 → v2.0.0)* Indicates significant breaking changes in the package. Package users are not expected to update to the new version without manual intervention.
- **Minor version increment** *(e.g., v1.3.0 → v1.4.0)* Denotes notable changes that are expected to be generally backwards compatible. Package users are expected to update to this version automatically and should be able to fix any breakages and/or warnings easily.
- **Patch version increment** *(e.g., v1.3.0 → v1.3.1)* Reserved for bug fixes and small touchups. Package users are expected to update automatically and should not expect significant breakage, except in the edge case of users relying on the behavior of patched bugs.

**Note that backwards-incompatible changes may occur at any version increment.** The is because the current nature of Lean (e.g., transitive imports, rich metaprogramming, reducibility in proofs), makes it infeasible to define a completely stable interface for a package. Instead, the different version levels indicate a change's intended significance and how difficult migration is expected to be.

Versions of form the `0.x.x` are considered development versions prior to first official release. Like prerelease, they are not expected to closely follow the above guidelines.

Packages without a defined version default to `0.0.0`.

<a id="Lake___PackageConfig-versionTags"></a>
`versionTags`

**Contains:** String pattern

Git tags of this package's repository that should be treated as versions. Package indices (e.g., Reservoir) can make use of this information to determine the Git revisions corresponding to released versions.

Defaults to tags that are "version-like". That is, start with a `v` followed by a digit.

<a id="Lake___PackageConfig-description"></a>
`description`

**Contains:** String

A short description for the package (e.g., for Reservoir).

<a id="Lake___PackageConfig-keywords"></a>
`keywords`

**Contains:** Array of strings

Custom keywords associated with the package. Reservoir can make use of a package's keywords to group related packages together and make it easier for users to discover them.

Good keywords include the domain (e.g., `math`, `software-verification`, `devtool`), specific subtopics (e.g., `topology`, `cryptology`), and significant implementation details (e.g., `dsl`, `ffi`, `cli`). For instance, Lake's keywords could be `devtool`, `cli`, `dsl`, `package-manager`, and `build-system`.

<a id="Lake___PackageConfig-homepage"></a>
`homepage`

**Contains:** String

A URL to information about the package.

Reservoir will already include a link to the package's GitHub repository (if the package is sourced from there). Thus, users are advised to specify something else for this (if anything).

<a id="Lake___PackageConfig-license"></a>
`license`

**Contains:** String

The package's license (if one). Should be a valid [SPDX License Expression](https://spdx.github.io/spdx-spec/v3.0/annexes/SPDX-license-expressions/).

Reservoir requires that packages uses an OSI-approved license to be included in its index, and currently only supports single identifier SPDX expressions. For, a list of OSI-approved SPDX license identifiers, see the [SPDX LIcense List](https://spdx.org/licenses/).

<a id="Lake___PackageConfig-licenseFiles"></a>
`licenseFiles`

**Contains:** Array of paths

Files containing licensing information for the package.

These should be the license files that users are expected to include when distributing package sources, which may be more then one file for some licenses. For example, the Apache 2.0 license requires the reproduction of a `NOTICE` file along with the license (if such a file exists).

Defaults to `#["LICENSE"]`.

<a id="Lake___PackageConfig-readmeFile"></a>
`readmeFile`

**Contains:** Path

The path to the package's README.

A README should be a Markdown file containing an overview of the package. Reservoir displays the rendered HTML of this file on a package's page. A nonstandard location can be used to provide a different README for Reservoir and GitHub.

Defaults to `README.md`.

<a id="Lake___PackageConfig-reservoir"></a>
`reservoir`

**Contains:** Boolean

Whether Reservoir should include the package in its index. When set to `false`, Reservoir will not add the package to its index and will remove it if it was already there (when Reservoir is next updated).

**Layout:**

These options control the top-level directory layout of the package and its build directory. Further paths specified by libraries, executables, and targets within the package are relative to these directories.

<a id="Lake___PackageConfig-srcDir"></a>
`srcDir`

**Contains:** Path

The directory containing the package's Lean source files. Defaults to the package's directory.

(This will be passed to `lean` as the `-R` option.)

<a id="Lake___PackageConfig-buildDir"></a>
`buildDir`

**Contains:** Path

The directory to which Lake should output the package's build results. Defaults to `defaultBuildDir` (i.e., `.lake/build`).

<a id="Lake___PackageConfig-nativeLibDir"></a>
`nativeLibDir`

**Contains:** Path

The build subdirectory to which Lake should output the package's native libraries (e.g., `.a`, `.so`, `.dll` files). Defaults to `defaultNativeLibDir` (i.e., `lib`).

<a id="Lake___PackageConfig-binDir"></a>
`binDir`

**Contains:** Path

The build subdirectory to which Lake should output the package's binary executable. Defaults to `defaultBinDir` (i.e., `bin`).

<a id="Lake___PackageConfig-irDir"></a>
`irDir`

**Contains:** Path

The build subdirectory to which Lake should output the package's intermediary results (e.g., `.c` and `.o` files). Defaults to `defaultIrDir` (i.e., `ir`).

<a id="Lake___PackageConfig-packagesDir"></a>
`packagesDir`

**Contains:** Path

The directory to which Lake should download remote dependencies. Defaults to `defaultPackagesDir` (i.e., `.lake/packages`).

**Building and Running:**

These options configure how code is built and run in the package. Libraries, executables, and other [targets](index.md#--tech-term-target) within a package can further add to parts of this configuration.

<a id="Lake___PackageConfig-extraDepTargets"></a>
`extraDepTargets`

**Contains:** Array of strings

An `Array` of target names to build whenever the package is used.

<a id="Lake___PackageConfig-precompileModules"></a>
`precompileModules`

**Contains:** Boolean

Whether to compile each of the package's module into a native shared library that is loaded whenever the module is imported. This speeds up evaluation of metaprograms and enables the interpreter to run functions marked `@[extern]`.

Defaults to `false`.

<a id="Lake___PackageConfig-defaultTargets"></a>
`defaultTargets`

**Contains:** default targets' names (array)

The names of the package's targets to build by default (i.e., on a bare `lake build` of the package).

<a id="Lake___PackageConfig-moreGlobalServerArgs"></a>
`moreGlobalServerArgs`

**Contains:** Array of strings

Additional arguments to pass to the Lean language server (i.e., `lean --server`) launched by `lake serve`, both for this package and also for any packages browsed from this one in the same session.

<a id="Lake___PackageConfig-leanLibDir"></a>
`leanLibDir`

**Contains:** Path

The build subdirectory to which Lake should output the package's binary Lean libraries (e.g., `.olean`, `.ilean` files). Defaults to `defaultLeanLibDir` (i.e., `lib`).

<a id="Lake___PackageConfig-buildType"></a>
`buildType`

**Contains:** one of `"debug"`, `"relWithDebInfo"`, `"minSizeRel"`, `"release"`

The mode in which the modules should be built (e.g., `debug`, `release`). Defaults to `release`.

<a id="Lake___PackageConfig-leanOptions"></a>
`leanOptions`

**Contains:** Array of Lean options

An `Array` of additional options to pass to both the Lean language server (i.e., `lean --server`) launched by `lake serve` and to `lean` when compiling a module's Lean source files.

<a id="Lake___PackageConfig-moreLeanArgs"></a>
`moreLeanArgs`

**Contains:** Array of strings

Additional arguments to pass to `lean` when compiling a module's Lean source files.

<a id="Lake___PackageConfig-weakLeanArgs"></a>
`weakLeanArgs`

**Contains:** Array of strings

Additional arguments to pass to `lean` when compiling a module's Lean source files.

Unlike `moreLeanArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeanArgs`.

<a id="Lake___PackageConfig-moreLeancArgs"></a>
`moreLeancArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when compiling a module's C source files generated by `lean`.

Lake already passes some flags based on the `buildType`, but you can change this by, for example, adding `-O0` and `-UNDEBUG`.

<a id="Lake___PackageConfig-moreServerOptions"></a>
`moreServerOptions`

**Contains:** Array of Lean options

Additional options to pass to the Lean language server (i.e., `lean --server`) launched by `lake serve`.

<a id="Lake___PackageConfig-weakLeancArgs"></a>
`weakLeancArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when compiling a module's C source files generated by `lean`.

Unlike `moreLeancArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeancArgs`.

<a id="Lake___PackageConfig-moreLinkArgs"></a>
`moreLinkArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of the linked objects.

<a id="Lake___PackageConfig-weakLinkArgs"></a>
`weakLinkArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of the linked objects.

Unlike `moreLinkArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLinkArgs`.

<a id="Lake___PackageConfig-platformIndependent"></a>
`platformIndependent`

**Contains:** Boolean (optional)

Asserts whether Lake should assume Lean modules are platform-independent.

- If `false`, Lake will add `System.Platform.target` to the module traces within the code unit (e.g., package or library). This will force Lean code to be re-elaborated on different platforms.
- If `true`, Lake will exclude platform-dependent elements (e.g., precompiled modules, external libraries) from a module's trace, preventing re-elaboration on different platforms. Note that this will not effect modules outside the code unit in question. For example, a platform-independent package which depends on a platform-dependent library will still be platform-dependent.
- If `none`, Lake will construct traces as natural. That is, it will include platform-dependent artifacts in the trace if they module depends on them, but otherwise not force modules to be platform-dependent.

There is no check for correctness here, so a configuration can lie and Lake will not catch it. Defaults to `none`.

**Testing and Linting:**

The CLI commands [`lake test`](index.md#test) and [`lake lint`](index.md#lint) use definitions configured by the [workspace](index.md#--tech-term-workspace)'s [root package](index.md#--tech-term-root-package) to perform testing and linting. The code that is run to perform tests and linting is referred to as the test or lint driver. In Lean configuration files, these can be specified by applying the `@[test_driver]` or `@[lint_driver]` attributes to a [Lake script](index.md#--tech-term-Lake-scripts) or an executable or library target. In both Lean and TOML configuration files, they can also be configured by setting these options. A target or script `TGT` from a dependency `PKG` can be specified as a test or lint driver using the string `"PKG/TGT"`

<a id="Lake___PackageConfig-testDriver"></a>
`testDriver`

**Contains:** String

The name of the script, executable, or library by `lake test` when this package is the workspace root. To point to a definition in another package, use the syntax `<pkg>/<def>`.

A script driver will be run by `lake test` with the arguments configured in `testDriverArgs` followed by any specified on the CLI (e.g., via `lake lint -- <args>...`). An executable driver will be built and then run like a script. A library will just be built.

<a id="Lake___PackageConfig-testDriverArgs"></a>
`testDriverArgs`

**Contains:** Array of strings

Arguments to pass to the package's test driver. These arguments will come before those passed on the command line via `lake test -- <args>...`.

<a id="Lake___PackageConfig-lintDriver"></a>
`lintDriver`

**Contains:** String

The name of the script or executable used by `lake lint` when this package is the workspace root. To point to a definition in another package, use the syntax `<pkg>/<def>`.

A script driver will be run by `lake lint` with the arguments configured in `lintDriverArgs` followed by any specified on the CLI (e.g., via `lake lint -- <args>...`). An executable driver will be built and then run like a script.

<a id="Lake___PackageConfig-lintDriverArgs"></a>
`lintDriverArgs`

**Contains:** Array of strings

Arguments to pass to the package's linter. These arguments will come before those passed on the command line via `lake lint -- <args>...`.

<a id="Lake___PackageConfig-builtinLint"></a>
`builtinLint`

**Contains:** Boolean (optional)

Whether to run Lake's built-in linter on the package.

- `true` — Always run built-in lints. When a lint driver is also configured, built-in lints run before the driver.
- `false` — Never run built-in lints by default. `lake check-lint` will exit with a nonzero code if no lint driver is configured either.
- `none` (default) — Currently equivalent to `false`. In a future release, `none` will run built-in lints when no lint driver is configured (i.e., act like `true` as a fallback).

**Cloud Releases:**

These options define a cloud release for the package, as described in the section on [GitHub release builds](index.md#lake-github).

<a id="Lake___PackageConfig-releaseRepo"></a>
`releaseRepo`

**Contains:** String (optional)

The URL of the GitHub repository to upload and download releases of this package. If `none` (the default), for downloads, Lake uses the URL the package was download from (if it is a dependency) and for uploads, uses `gh`'s default.

<a id="Lake___PackageConfig-buildArchive"></a>
`buildArchive`

**Contains:** String (optional)

A custom name for the build archive for the GitHub cloud release. If `none` (the default), Lake defaults to `{(pkg-)name}-{System.Platform.target}.tar.gz`.

<a id="Lake___PackageConfig-preferReleaseBuild"></a>
`preferReleaseBuild`

**Contains:** Boolean

Whether to prefer downloading a prebuilt release (from GitHub) rather than building this package from the source when this package is used as a dependency.

**Other Fields:**

<a id="Lake___PackageConfig-bootstrap"></a>
`bootstrap`

**Contains:** Boolean

**For internal use.** Whether this package is Lean itself.

<a id="Lake___PackageConfig-enableArtifactCache"></a>
`enableArtifactCache`

**Contains:** Boolean (optional)

Whether to enables Lake's local, offline artifact cache for the package.

Artifacts (i.e., build products) of packages will be shared across local copies by storing them in a cache associated with the Lean toolchain. This can significantly reduce initial build times and disk space usage when working with multiple copies of large projects or large dependencies.

As a caveat, build targets which support the artifact cache will not be stored in their usual location within the build directory. Thus, projects with custom build scripts that rely on specific location of artifacts may wish to disable this feature.

If `none` (the default), this will fallback to (in order):

- The `LAKE_ARTIFACT_CACHE` environment variable (if set).
- The workspace root's `enableArtifactCache` configuration (if set and this package is a dependency).
- **Lake's default**: The package can use artifacts from the cache, but cannot write to it.

<a id="Lake___PackageConfig-restoreAllArtifacts"></a>
`restoreAllArtifacts`

**Contains:** Boolean (optional)

Whether, when the local artifact cache is enabled, Lake should copy all cached artifacts into the build directory. This ensures the build results are available to external consumers who expect them in the build directory.

If `none` (the default), this will fallback to (in order):

- The `LAKE_RESTORE_ARTIFACTS` environment variable (if set).
- The workspace root's `restoreAllArtifacts` configuration (if set and this package is a dependency).
- **Lake's default**: `false`.

<a id="Lake___PackageConfig-libPrefixOnWindows"></a>
`libPrefixOnWindows`

**Contains:** Boolean

Whether native libraries (of this package) should be prefixed with `lib` on Windows.

Unlike Unix, Windows does not require native libraries to start with `lib` and, by convention, they usually do not. However, for consistent naming across all platforms, users may wish to enable this.

Defaults to `false`.

<a id="Lake___PackageConfig-allowImportAll"></a>
`allowImportAll`

**Contains:** Boolean

Whether downstream packages can `import all` modules of this package.

If enabled, downstream users will be able to access the `private` internals of modules, including definition bodies not marked as `@[expose]`. This may also, in the future, prevent compiler optimization which rely on `private` definitions being inaccessible outside their own package.

Defaults to `false`.

<a id="Lake___PackageConfig-fixedToolchain"></a>
`fixedToolchain`

**Contains:** Boolean

Whether this package is expected to function only on a single toolchain (the package's toolchain).

This informs Lake's toolchain update procedure (in `lake update`) to prioritize this package's toolchain. It also avoids the need to separate input-to-output mappings for this package by toolchain version in the Lake cache.

Defaults to `false`.

<a id="Lake___PackageConfig-moreLinkObjs"></a>
`moreLinkObjs`

**Contains:** Array of paths

Additional target objects to use when linking (both static and shared). These will come *after* the paths of native facets.

<a id="Lake___PackageConfig-moreLinkLibs"></a>
`moreLinkLibs`

**Contains:** Array of dynamic libraries

Additional target libraries to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of other link objects.

<a id="Lake___PackageConfig-requiresModuleSystem"></a>
`requiresModuleSystem`

**Contains:** Boolean

Whether this package or library should be considered designed for use with the module system.

If enabled, Lake emits a warning whenever a module imports a module of this code unit without itself using the module system (i.e., without a `module` header). This applies both to downstream consumers and to non-module files within the same package, signalling that the code unit's API expects the visibility and elaboration semantics of the module system.

Importers can opt out of the warning by setting `allowNonModules := true` on their own package or library.

Defaults to `false`.

<a id="Lake___PackageConfig-allowNonModules"></a>
`allowNonModules`

**Contains:** Boolean

Whether this package or library permits non-module-system files without warning.

By default, when a non-module-system file in this code unit imports a module from a code unit that has set `requiresModuleSystem` (which may include this one itself), Lake emits a warning. Setting this to `true` suppresses those warnings, declaring that the code unit is knowingly mixing non-module-system files with module-system dependencies.

Defaults to `false`.

<a id="Minimal-TOML-Package-Configuration"></a>
Minimal TOML Package Configuration 

The minimal TOML configuration for a Lean [package](index.md#--tech-term-package) sets only the package's name, using the default values for all other fields. This package contains no [targets](index.md#--tech-term-target), so there is no code to be built.

```text
name = "example-package"
```

<a id="Library-TOML-Package-Configuration"></a>
Library TOML Package Configuration 

The minimal TOML configuration for a Lean [package](index.md#--tech-term-package) sets the package's name and defines a library target. This library is named `Sorting`, and its modules are expected under the `Sorting.*` hierarchy.

```text
name = "example-package"
defaultTargets = ["Sorting"]

[[lean_lib]]
name = "Sorting"
```

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Declarative-TOML-Format--Dependencies"></a>
##### 24.1.3.1.2. Dependencies

Dependencies are specified in the `[[require]]` field array of a package configuration, which specifies both the name and the source of each package. There are three kinds of sources:

- [Reservoir](https://reservoir.lean-lang.org/), or an alternative package registry
- Git repositories, which may be local paths or URLs
- Local paths

<a id="Lake___Dependency"></a>

**TOML table**

```text
Requiring Packages — [[require]]
```

A `Dependency` of a package. It specifies a package which another package depends on. This encodes the information contained in the `require` DSL syntax.

The `path` and `git` fields specify an explicit source for a dependency. If neither are provided, then the dependency is fetched from [Reservoir](https://reservoir.lean-lang.org/), or an alternative registry if one has been configured. The `scope` field is required when fetching a package from Reservoir.

**Fields:**

<a id="Lake___Dependency-path"></a>
`path`

**Contains:** Path

A dependency on the local filesystem, specified by its path.

<a id="Lake___Dependency-git"></a>
`git`

**Contains:** Git specification

A dependency in a Git repository, specified either by its URL as a string or by a table with the keys:

- `url`: the repository URL
- `subDir`: the subdirectory of the Git repository that contains the package's source code

<a id="Lake___Dependency-rev"></a>
`rev`

**Contains:** Git revision

For Git or Reservoir dependencies, this field specifies the Git revision, which may be a branch name, a tag name, or a specific hash. On Reservoir, the `version` field takes precedence over this field.

<a id="Lake___Dependency-source"></a>
`source`

**Contains:** Package Source

A dependency source, specified as a self-contained table, which is used when neither the `git` nor the `path` key is present. The key `type` should be either the string `"git"` or the string `"path"`. If the type is `"path"`, then there must be a further key `"path"` whose value is a string that provides the location of the package on disk. If the type is `"git"`, then the following keys should be present:

- `url`: the repository URL
- `rev`: the Git revision, which may be a branch name, a tag name, or a specific hash (optional)
- `subDir`: the subdirectory of the Git repository that contains the package's source code

<a id="Lake___Dependency-version"></a>
`version`

**Contains:** version as string

The target version of the dependency.

<a id="Lake___Dependency-name"></a>
`name`

**Contains:** String

The package name of the dependency. This name must match the one declared in its configuration file, as that name is used to index its target data types. For this reason, the package name must also be unique across packages in the dependency graph.

<a id="Lake___Dependency-scope"></a>
`scope`

**Contains:** String

An additional qualifier used to distinguish packages of the same name in a Lake registry. On Reservoir, this is the package owner.

<a id="Requiring-Packages-from-Reservoir"></a>
Requiring Packages from Reservoir 

The package `example` can be required from Reservoir using this TOML configuration:

```text
[[require]]
name = "example"
version = "≥2.12.0"
scope = "exampleDev"
```

<a id="Requiring-Packages-from-Git"></a>
Requiring Packages from Git 

The package `example` can be required from a Git repository using this TOML configuration:

```text
[[require]]
name = "example"
git = "https://git.example.com/example.git"
rev = "main"
version = "≥2.12.0"
```

In particular, the package will be checked out from the `main` branch, and the version number specified in the package's [configuration](index.md#--tech-term-package-configuration) should be at least `2.12.0`.

<a id="Requiring-Packages-from-a-Git-tag"></a>
Requiring Packages from a Git tag 

The package `example` can be required from the tag `v2.12` in a Git repository using this TOML configuration:

```text
[[require]]
name = "example"
git = "https://git.example.com/example.git"
rev = "v2.12"
```

The version number specified in the package's [configuration](index.md#--tech-term-package-configuration) is not used.

<a id="Requiring-Reservoir-Packages-from-a-Git-tag"></a>
Requiring Reservoir Packages from a Git tag 

The package `example`, found using Reservoir, can be required from the tag `v2.12` in its Git repository using this TOML configuration:

```text
[[require]]
name = "example"
rev = "v2.12"
scope = "exampleDev"
```

The version number specified in the package's [configuration](index.md#--tech-term-package-configuration) is not used.

<a id="Requiring-Packages-from-Paths"></a>
Requiring Packages from Paths 

The package `example` can be required from the local path `../example` using this TOML configuration:

```text
[[require]]
name = "example"
path = "../example"
```

Dependencies on local paths are useful when developing multiple packages in a single repository, or when testing whether a change to a dependency fixes a bug in a downstream package.

<a id="Sources-as-Tables"></a>
Sources as Tables 

The information about the package source can be written in an explicit table.

```text
[[require]]
name = "example"
source = {type = "git", url = "https://example.com/example.git"}
```

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Declarative-TOML-Format--Library-Targets"></a>
##### 24.1.3.1.3. Library Targets

Library targets are expected in the `lean_lib` array of tables.

<a id="Lake___LeanLibConfig"></a>

**TOML table**

```text
Library Targets — [[lean_lib]]
```

A Lean library's declarative configuration.

**Fields:**

<a id="Lake___LeanLibConfig-name"></a>
`name`

**Contains:** The library name

The library's name, which is typically the same as its single module root.

<a id="Lake___LeanLibConfig-srcDir"></a>
`srcDir`

**Contains:** Path

The subdirectory of the package's source directory containing the library's Lean source files. Defaults simply to said `srcDir`.

(This will be passed to `lean` as the `-R` option.)

<a id="Lake___LeanLibConfig-roots"></a>
`roots`

**Contains:** Array of strings

The root module(s) of the library. Submodules of these roots (e.g., `Lib.Foo` of `Lib`) are considered part of the library. Defaults to a single root of the target's name.

<a id="Lake___LeanLibConfig-libName"></a>
`libName`

**Contains:** String

The name of the library artifact. Used as a base for the file names of its static and dynamic binaries. Defaults to the mangled name of the target.

<a id="Lake___LeanLibConfig-libPrefixOnWindows"></a>
`libPrefixOnWindows`

**Contains:** Boolean

Whether static and shared binaries of this library should be prefixed with `lib` on Windows.

Unlike Unix, Windows does not require native libraries to start with `lib` and, by convention, they usually do not. However, for consistent naming across all platforms, users may wish to enable this.

Defaults to `false`.

<a id="Lake___LeanLibConfig-needs"></a>
`needs`

**Contains:** Array of targets

An `Array` of targets to build before the executable's modules.

<a id="Lake___LeanLibConfig-extraDepTargets"></a>
`extraDepTargets`

**Contains:** Array of strings

**Deprecated. Use `needs` instead.** An `Array` of target names to build before the library's modules.

<a id="Lake___LeanLibConfig-precompileModules"></a>
`precompileModules`

**Contains:** Boolean

Whether to compile each of the library's modules into a native shared library that is loaded whenever the module is imported. This speeds up evaluation of metaprograms and enables the interpreter to run functions marked `@[extern]`.

Defaults to `false`.

<a id="Lake___LeanLibConfig-defaultFacets"></a>
`defaultFacets`

**Contains:** Array of strings

An `Array` of library facets to build on a bare `lake build` of the library. For example, `#[LeanLib.sharedFacet]` will build the shared library facet.

<a id="Lake___LeanLibConfig-allowImportAll"></a>
`allowImportAll`

**Contains:** Boolean

Whether downstream packages can `import all` modules of this library.

If enabled, downstream users will be able to access the `private` internals of modules, including definition bodies not marked as `@[expose]`. This may also, in the future, prevent compiler optimization which rely on `private` definitions being inaccessible outside their own package.

Defaults to `false`.

<a id="Lake___LeanLibConfig-buildType"></a>
`buildType`

**Contains:** one of `"debug"`, `"relWithDebInfo"`, `"minSizeRel"`, `"release"`

The mode in which the modules should be built (e.g., `debug`, `release`). Defaults to `release`.

<a id="Lake___LeanLibConfig-leanOptions"></a>
`leanOptions`

**Contains:** Array of Lean options

An `Array` of additional options to pass to both the Lean language server (i.e., `lean --server`) launched by `lake serve` and to `lean` when compiling a module's Lean source files.

<a id="Lake___LeanLibConfig-moreLeanArgs"></a>
`moreLeanArgs`

**Contains:** Array of strings

Additional arguments to pass to `lean` when compiling a module's Lean source files.

<a id="Lake___LeanLibConfig-weakLeanArgs"></a>
`weakLeanArgs`

**Contains:** Array of strings

Additional arguments to pass to `lean` when compiling a module's Lean source files.

Unlike `moreLeanArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeanArgs`.

<a id="Lake___LeanLibConfig-moreLeancArgs"></a>
`moreLeancArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when compiling a module's C source files generated by `lean`.

Lake already passes some flags based on the `buildType`, but you can change this by, for example, adding `-O0` and `-UNDEBUG`.

<a id="Lake___LeanLibConfig-moreServerOptions"></a>
`moreServerOptions`

**Contains:** Array of Lean options

Additional options to pass to the Lean language server (i.e., `lean --server`) launched by `lake serve`.

<a id="Lake___LeanLibConfig-weakLeancArgs"></a>
`weakLeancArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when compiling a module's C source files generated by `lean`.

Unlike `moreLeancArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeancArgs`.

<a id="Lake___LeanLibConfig-moreLinkObjs"></a>
`moreLinkObjs`

**Contains:** Array of paths

Additional target objects to use when linking (both static and shared). These will come *after* the paths of native facets.

<a id="Lake___LeanLibConfig-moreLinkLibs"></a>
`moreLinkLibs`

**Contains:** Array of dynamic libraries

Additional target libraries to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of other link objects.

<a id="Lake___LeanLibConfig-moreLinkArgs"></a>
`moreLinkArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of the linked objects.

<a id="Lake___LeanLibConfig-weakLinkArgs"></a>
`weakLinkArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of the linked objects.

Unlike `moreLinkArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLinkArgs`.

<a id="Lake___LeanLibConfig-platformIndependent"></a>
`platformIndependent`

**Contains:** Boolean (optional)

Asserts whether Lake should assume Lean modules are platform-independent.

- If `false`, Lake will add `System.Platform.target` to the module traces within the code unit (e.g., package or library). This will force Lean code to be re-elaborated on different platforms.
- If `true`, Lake will exclude platform-dependent elements (e.g., precompiled modules, external libraries) from a module's trace, preventing re-elaboration on different platforms. Note that this will not effect modules outside the code unit in question. For example, a platform-independent package which depends on a platform-dependent library will still be platform-dependent.
- If `none`, Lake will construct traces as natural. That is, it will include platform-dependent artifacts in the trace if they module depends on them, but otherwise not force modules to be platform-dependent.

There is no check for correctness here, so a configuration can lie and Lake will not catch it. Defaults to `none`.

<a id="Lake___LeanLibConfig-dynlibs"></a>
`dynlibs`

**Contains:** Array of dynamic libraries

<a id="Lake___LeanLibConfig-plugins"></a>
`plugins`

**Contains:** Array of dynamic libraries

<a id="Lake___LeanLibConfig-requiresModuleSystem"></a>
`requiresModuleSystem`

**Contains:** Boolean

Whether this package or library should be considered designed for use with the module system.

If enabled, Lake emits a warning whenever a module imports a module of this code unit without itself using the module system (i.e., without a `module` header). This applies both to downstream consumers and to non-module files within the same package, signalling that the code unit's API expects the visibility and elaboration semantics of the module system.

Importers can opt out of the warning by setting `allowNonModules := true` on their own package or library.

Defaults to `false`.

<a id="Lake___LeanLibConfig-allowNonModules"></a>
`allowNonModules`

**Contains:** Boolean

Whether this package or library permits non-module-system files without warning.

By default, when a non-module-system file in this code unit imports a module from a code unit that has set `requiresModuleSystem` (which may include this one itself), Lake emits a warning. Setting this to `true` suppresses those warnings, declaring that the code unit is knowingly mixing non-module-system files with module-system dependencies.

Defaults to `false`.

<a id="Minimal-Library-Target"></a>
Minimal Library Target 

This library declaration supplies only a name:

```text
[[lean_lib]]
name = "TacticTools"
```

The library's source is located in the package's default source directory, in the module hierarchy rooted at `TacticTools`.

<a id="Configured-Library-Target"></a>
Configured Library Target 

This library declaration supplies more options:

```text
[[lean_lib]]
name = "TacticTools"
srcDir = "src"
precompileModules = true
```

The library's source is located in the directory `src`, in the module hierarchy rooted at `TacticTools`. If its modules are accessed at elaboration time, they will be compiled to native code and linked in, rather than run in the interpreter.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Declarative-TOML-Format--Executable-Targets"></a>
##### 24.1.3.1.4. Executable Targets

<a id="Lake___LeanExeConfig"></a>

**TOML table**

```text
Executable Targets — [[lean_exe]]
```

A Lean executable's declarative configuration.

**Fields:**

<a id="Lake___LeanExeConfig-name"></a>
`name`

**Contains:** The executable's name

The executable's name.

<a id="Lake___LeanExeConfig-srcDir"></a>
`srcDir`

**Contains:** Path

The subdirectory of the package's source directory containing the executable's Lean source file. Defaults simply to said `srcDir`.

(This will be passed to `lean` as the `-R` option.)

<a id="Lake___LeanExeConfig-root"></a>
`root`

**Contains:** String

The root module of the binary executable. Should include a `main` definition that will serve as the entry point of the program.

The root is built by recursively building its local imports (i.e., fellow modules of the workspace).

Defaults to the name of the target.

<a id="Lake___LeanExeConfig-exeName"></a>
`exeName`

**Contains:** String

The name of the binary executable. Defaults to the target name with any `.` replaced with a `-`.

<a id="Lake___LeanExeConfig-needs"></a>
`needs`

**Contains:** Array of targets

An `Array` of targets to build before the executable's modules.

<a id="Lake___LeanExeConfig-extraDepTargets"></a>
`extraDepTargets`

**Contains:** Array of strings

**Deprecated. Use `needs` instead.** An `Array` of target names to build before the executable's modules.

<a id="Lake___LeanExeConfig-supportInterpreter"></a>
`supportInterpreter`

**Contains:** Boolean

Enables the executable to interpret Lean files (e.g., via `Lean.Elab.runFrontend`) by exposing symbols within the executable to the Lean interpreter.

Implementation-wise, on Windows, the Lean shared libraries are linked to the executable and, on other systems, the executable is linked with `-rdynamic`. This increases the size of the binary on Linux and, on Windows, requires `libInit_shared.dll` and `libleanshared.dll` to be co-located with the executable or part of `PATH` (e.g., via `lake exe`). Thus, this feature should only be enabled when necessary.

Defaults to `false`.

<a id="Lake___LeanExeConfig-buildType"></a>
`buildType`

**Contains:** one of `"debug"`, `"relWithDebInfo"`, `"minSizeRel"`, `"release"`

The mode in which the modules should be built (e.g., `debug`, `release`). Defaults to `release`.

<a id="Lake___LeanExeConfig-leanOptions"></a>
`leanOptions`

**Contains:** Array of Lean options

An `Array` of additional options to pass to both the Lean language server (i.e., `lean --server`) launched by `lake serve` and to `lean` when compiling a module's Lean source files.

<a id="Lake___LeanExeConfig-moreLeanArgs"></a>
`moreLeanArgs`

**Contains:** Array of strings

Additional arguments to pass to `lean` when compiling a module's Lean source files.

<a id="Lake___LeanExeConfig-weakLeanArgs"></a>
`weakLeanArgs`

**Contains:** Array of strings

Additional arguments to pass to `lean` when compiling a module's Lean source files.

Unlike `moreLeanArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeanArgs`.

<a id="Lake___LeanExeConfig-moreLeancArgs"></a>
`moreLeancArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when compiling a module's C source files generated by `lean`.

Lake already passes some flags based on the `buildType`, but you can change this by, for example, adding `-O0` and `-UNDEBUG`.

<a id="Lake___LeanExeConfig-moreServerOptions"></a>
`moreServerOptions`

**Contains:** Array of Lean options

Additional options to pass to the Lean language server (i.e., `lean --server`) launched by `lake serve`.

<a id="Lake___LeanExeConfig-weakLeancArgs"></a>
`weakLeancArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when compiling a module's C source files generated by `lean`.

Unlike `moreLeancArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeancArgs`.

<a id="Lake___LeanExeConfig-moreLinkObjs"></a>
`moreLinkObjs`

**Contains:** Array of paths

Additional target objects to use when linking (both static and shared). These will come *after* the paths of native facets.

<a id="Lake___LeanExeConfig-moreLinkLibs"></a>
`moreLinkLibs`

**Contains:** Array of dynamic libraries

Additional target libraries to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of other link objects.

<a id="Lake___LeanExeConfig-moreLinkArgs"></a>
`moreLinkArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of the linked objects.

<a id="Lake___LeanExeConfig-weakLinkArgs"></a>
`weakLinkArgs`

**Contains:** Array of strings

Additional arguments to pass to `leanc` when linking (e.g., for shared libraries or binary executables). These will come *after* the paths of the linked objects.

Unlike `moreLinkArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLinkArgs`.

<a id="Lake___LeanExeConfig-platformIndependent"></a>
`platformIndependent`

**Contains:** Boolean (optional)

Asserts whether Lake should assume Lean modules are platform-independent.

- If `false`, Lake will add `System.Platform.target` to the module traces within the code unit (e.g., package or library). This will force Lean code to be re-elaborated on different platforms.
- If `true`, Lake will exclude platform-dependent elements (e.g., precompiled modules, external libraries) from a module's trace, preventing re-elaboration on different platforms. Note that this will not effect modules outside the code unit in question. For example, a platform-independent package which depends on a platform-dependent library will still be platform-dependent.
- If `none`, Lake will construct traces as natural. That is, it will include platform-dependent artifacts in the trace if they module depends on them, but otherwise not force modules to be platform-dependent.

There is no check for correctness here, so a configuration can lie and Lake will not catch it. Defaults to `none`.

<a id="Lake___LeanExeConfig-dynlibs"></a>
`dynlibs`

**Contains:** Array of dynamic libraries

<a id="Lake___LeanExeConfig-plugins"></a>
`plugins`

**Contains:** Array of dynamic libraries

<a id="Lake___LeanExeConfig-requiresModuleSystem"></a>
`requiresModuleSystem`

**Contains:** Boolean

Whether this package or library should be considered designed for use with the module system.

If enabled, Lake emits a warning whenever a module imports a module of this code unit without itself using the module system (i.e., without a `module` header). This applies both to downstream consumers and to non-module files within the same package, signalling that the code unit's API expects the visibility and elaboration semantics of the module system.

Importers can opt out of the warning by setting `allowNonModules := true` on their own package or library.

Defaults to `false`.

<a id="Lake___LeanExeConfig-allowNonModules"></a>
`allowNonModules`

**Contains:** Boolean

Whether this package or library permits non-module-system files without warning.

By default, when a non-module-system file in this code unit imports a module from a code unit that has set `requiresModuleSystem` (which may include this one itself), Lake emits a warning. Setting this to `true` suppresses those warnings, declaring that the code unit is knowingly mixing non-module-system files with module-system dependencies.

Defaults to `false`.

<a id="Minimal-Executable-Target"></a>
Minimal Executable Target 

This executable declaration supplies only a name:

```text
[[lean_exe]]
name = "trustworthytool"
```

The executable's `main` function is expected in a module named `trustworthytool.lean` in the package's default source file path. The resulting executable is named `trustworthytool`.

<a id="Configured-Executable-Target"></a>
Configured Executable Target 

The name `trustworthy-tool` is not a valid Lean name due to the dash (`-`). To use this name for an executable target, an explicit module root must be supplied. Even though `trustworthy-tool` is a perfectly acceptable name for an executable, the target also specifies that the result of compilation and linking should be named `tt`.

```text
[[lean_exe]]
name = "trustworthy-tool"
root = "TrustworthyTool"
exeName = "tt"
```

The executable's `main` function is expected in a module named `TrustworthyTool.lean` in the package's default source file path.

<a id="lake-config-lean"></a>
#### 24.1.3.2. Lean Format

The Lean format for Lake [package configuration](index.md#--tech-term-package-configuration) files provides a domain-specific language for the declarative features that are supported in the TOML format. Additionally, it provides the ability to write Lean code to implement any necessary build logic that is not expressible declaratively. The Lean configuration file is named `lakefile.lean`.

Because the Lean format is a Lean source file, it can be edited using all the features of the Lean language server. Additionally, Lean's metaprogramming framework allows elaboration-time side effects to be used to implement features such as configuration steps that are conditional on the current platform. However, a consequence of the Lean configuration format being a Lean file is that it is not feasible to process such files using tools that are not themselves written in Lean.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Declarative-Fields"></a>
##### 24.1.3.2.1. Declarative Fields

The declarative subset of the Lean configuration format uses sequences of declaration fields to specify configuration options.

<a id="Lake___DSL___declField"></a>

**syntax**

**Declarative Fields**

A field assignment in a declarative configuration.

<a id="Lake___DSL___declField-next"></a>

```ebnf
declField ::=
    ident := term
```

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Packages"></a>
##### 24.1.3.2.2. Packages

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Package Configuration**

<a id="Lake___DSL___packageCommand"></a>

```ebnf
command ::= ...
    | docComment?
      (@[ attrInstance,* ])?
      package identOrStr
```

<a id="Lake___DSL___packageCommand-next"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      package identOrStr where
        declField*
```

<a id="Lake___DSL___packageCommand-next-next"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      package identOrStr {
        declField;*
      }
      (where
        letRecDecl;*)?
```

There can only be one `package` declaration per Lake configuration file. The defined package configuration will be available for reference as `_package`.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Post-Update Hooks**

<a id="Lake___DSL___postUpdateDecl"></a>

```ebnf
command ::= ...
    | post_update simpleBinder? (declValSimple
       | declValDo)
```

Declare a post-`lake update` hook for the package. Runs the monadic action is after a successful `lake update` execution in this package or one of its downstream dependents.

**Example**

This feature enables Mathlib to synchronize the Lean toolchain and run `cache get` after a `lake update`:

```text
lean_exe cache
post_update pkg do
  let wsToolchainFile := (← getRootPackage).dir / "lean-toolchain"
  let mathlibToolchain ← IO.FS.readFile <| pkg.dir / "lean-toolchain"
  IO.FS.writeFile wsToolchainFile mathlibToolchain
  let exeFile ← runBuild cache.fetch
  let exitCode ← env exeFile.toString #["get"]
  if exitCode ≠ 0 then
    error s!"{pkg.name}: failed to fetch cache"
```

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Dependencies"></a>
##### 24.1.3.2.3. Dependencies

Dependencies are specified using the [`require`](index.md#Lake___DSL___requireDecl) declaration.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Requiring Packages**

<a id="Lake___DSL___requireDecl"></a>

```ebnf
command ::= ...
    | docComment
      require depName (@ git? term)? fromClause? (with term)?
```

The `@` clause specifies a package version, which is used when requiring a package from [Reservoir](https://reservoir.lean-lang.org/). The version may either be a string that specifies the version declared in the package's `version` field, or a specific Git revision. Git revisions may be branch names, tag names, or commit hashes.

The optional 

```ebnf
fromClause
```

 specifies a package source other than Reservoir, which may be either a Git repository or a local path.

The [`with`](index.md#Lake___DSL___requireDecl) clause specifies a `NameMap String` of Lake options that will be used to configure the dependency. This is equivalent to passing `-K` options to [`lake build`](index.md#build) when building the dependency on the command line.

<a id="fromClause"></a>

**syntax**

**Package Sources**

Specifies a specific source from which to draw the package dependency. Dependencies that are downloaded from a remote source will be placed into the workspace's `packagesDir`.

**Path Dependencies**

```text
from <path>
```

Lake loads the package located at a fixed `path` relative to the requiring package's directory.

**Git Dependencies**

```text
from git <url> [@ <rev>] [/ <subDir>]
```

Lake clones the Git repository available at the specified fixed Git `url`, and checks out the specified revision `rev`. The revision can be a commit hash, branch, or tag. If none is provided, Lake defaults to `master`. After checkout, Lake loads the package located in `subDir` (or the repository root if no subdirectory is specified).

<a id="Lake___DSL___fromClause"></a>

```ebnf
fromClause ::=
    from term
```

<a id="Lake___DSL___fromClause-next"></a>

```ebnf
fromClause ::= ...
    | from git term (@ term)? (/ term)?
```

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Targets"></a>
##### 24.1.3.2.4. Targets

[Targets](index.md#--tech-term-target) are typically added to the set of default targets by applying the `default_target` attribute, rather than by explicitly listing them.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Specifying Default Targets**

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | default_target
```

Marks a target as a default, to be built when no other target is specified.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Targets--Libraries"></a>
###### 24.1.3.2.4.1. Libraries

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Library Targets**

To define a library in which all configurable fields have their default values, use `lean_lib` with no further fields.

<a id="Lake___DSL___leanLibCommand"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      lean_lib identOrStr
```

The default configuration can be modified by providing the new values.

<a id="Lake___DSL___leanLibCommand-next"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      lean_lib identOrStr where
        declField*
```

<a id="Lake___DSL___leanLibCommand-next-next"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      lean_lib identOrStr {
        declField;*
      }
      (where
        letRecDecl;*)?
```

The fields of `lean_lib` are those of the `LeanLibConfig` structure.

<a id="Lake___LeanLibConfig___mk"></a>

**structure**

```text
Lake.LeanLibConfig (name : Lean.Name) : Type
```

A Lean library's declarative configuration.

**Constructor**

```text
Lake.LeanLibConfig.mk
```

**Extends**

- <a id="0-Lake.LeanConfig-Lake.LeanLibConfig"></a>
  `Lake.LeanConfig`

**Fields**

```text
buildType : Lake.BuildType
```

 Inherited from 

1. `Lake.LeanConfig`

```text
leanOptions : Array Lean.LeanOption
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLeanArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
weakLeanArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLeancArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreServerOptions : Array Lean.LeanOption
```

 Inherited from 

1. `Lake.LeanConfig`

```text
weakLeancArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLinkObjs : Lake.TargetArray System.FilePath
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLinkLibs : Lake.TargetArray Lake.Dynlib
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLinkArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
weakLinkArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
backend : Lake.Backend
```

 Inherited from 

1. `Lake.LeanConfig`

```text
platformIndependent : Option Bool
```

 Inherited from 

1. `Lake.LeanConfig`

```text
dynlibs : Lake.TargetArray Lake.Dynlib
```

 Inherited from 

1. `Lake.LeanConfig`

```text
plugins : Lake.TargetArray Lake.Dynlib
```

 Inherited from 

1. `Lake.LeanConfig`

```text
requiresModuleSystem : Bool
```

 Inherited from 

1. `Lake.LeanConfig`

```text
allowNonModules : Bool
```

 Inherited from 

1. `Lake.LeanConfig`

```text
srcDir : System.FilePath
```

The subdirectory of the package's source directory containing the library's Lean source files. Defaults simply to said `srcDir`.

(This will be passed to `lean` as the `-R` option.)

```text
roots : Array Lean.Name
```

The root module(s) of the library. Submodules of these roots (e.g., `Lib.Foo` of `Lib`) are considered part of the library. Defaults to a single root of the target's name.

```text
globs : Array Lake.Glob
```

An `Array` of module `Glob`s to build for the library. Defaults to a `Glob.one` of each of the library's `roots`.

Submodule globs build every source file within their directory. Local imports of glob'ed files (i.e., fellow modules of the workspace) are also recursively built.

```text
libName : String
```

The name of the library artifact. Used as a base for the file names of its static and dynamic binaries. Defaults to the mangled name of the target.

```text
libPrefixOnWindows : Bool
```

Whether static and shared binaries of this library should be prefixed with `lib` on Windows.

Unlike Unix, Windows does not require native libraries to start with `lib` and, by convention, they usually do not. However, for consistent naming across all platforms, users may wish to enable this.

Defaults to `false`.

```text
needs : Array Lake.PartialBuildKey
```

An `Array` of targets to build before the executable's modules.

```text
extraDepTargets : Array Lean.Name
```

**Deprecated. Use `needs` instead.** An `Array` of target names to build before the library's modules.

```text
precompileModules : Bool
```

Whether to compile each of the library's modules into a native shared library that is loaded whenever the module is imported. This speeds up evaluation of metaprograms and enables the interpreter to run functions marked `@[extern]`.

Defaults to `false`.

```text
defaultFacets : Array Lean.Name
```

An `Array` of library facets to build on a bare `lake build` of the library. For example, `#[LeanLib.sharedFacet]` will build the shared library facet.

```text
nativeFacets : Bool → Array (Lake.ModuleFacet System.FilePath)
```

The module facets to build and combine into the library's static and shared libraries. If `shouldExport` is true, the module facets should export any symbols a user may expect to lookup in the library. For example, the Lean interpreter will use exported symbols in linked libraries.

Defaults to a singleton of `Module.oExportFacet` (if `shouldExport`) or `Module.oFacet`. That is, the object files compiled from the Lean sources, potentially with exported Lean symbols.

```text
allowImportAll : Bool
```

Whether downstream packages can `import all` modules of this library.

If enabled, downstream users will be able to access the `private` internals of modules, including definition bodies not marked as `@[expose]`. This may also, in the future, prevent compiler optimization which rely on `private` definitions being inaccessible outside their own package.

Defaults to `false`.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Targets--Executables"></a>
###### 24.1.3.2.4.2. Executables

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Executable Targets**

To define an executable in which all configurable fields have their default values, use `lean_exe` with no further fields.

<a id="Lake___DSL___leanExeCommand"></a>

```ebnf
command ::= ...
    | docComment? attributes?
      lean_exe identOrStr
```

The default configuration can be modified by providing the new values.

<a id="Lake___DSL___leanExeCommand-next"></a>

```ebnf
command ::= ...
    | docComment? attributes?
      lean_exe identOrStr where
        declField*
```

<a id="Lake___DSL___leanExeCommand-next-next"></a>

```ebnf
command ::= ...
    | docComment? attributes?
      lean_exe identOrStr {
        declField;*
      }
      (where
        letRecDecl;*)?
```

The fields of `lean_exe` are those of the `LeanExeConfig` structure.

<a id="Lake___LeanExeConfig___mk"></a>

**structure**

```text
Lake.LeanExeConfig (name : Lean.Name) : Type
```

A Lean executable's declarative configuration.

**Constructor**

```text
Lake.LeanExeConfig.mk
```

**Extends**

- <a id="0-Lake.LeanConfig-Lake.LeanExeConfig"></a>
  `Lake.LeanConfig`

**Fields**

```text
buildType : Lake.BuildType
```

 Inherited from 

1. `Lake.LeanConfig`

```text
leanOptions : Array Lean.LeanOption
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLeanArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
weakLeanArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLeancArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreServerOptions : Array Lean.LeanOption
```

 Inherited from 

1. `Lake.LeanConfig`

```text
weakLeancArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLinkObjs : Lake.TargetArray System.FilePath
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLinkLibs : Lake.TargetArray Lake.Dynlib
```

 Inherited from 

1. `Lake.LeanConfig`

```text
moreLinkArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
weakLinkArgs : Array String
```

 Inherited from 

1. `Lake.LeanConfig`

```text
backend : Lake.Backend
```

 Inherited from 

1. `Lake.LeanConfig`

```text
platformIndependent : Option Bool
```

 Inherited from 

1. `Lake.LeanConfig`

```text
dynlibs : Lake.TargetArray Lake.Dynlib
```

 Inherited from 

1. `Lake.LeanConfig`

```text
plugins : Lake.TargetArray Lake.Dynlib
```

 Inherited from 

1. `Lake.LeanConfig`

```text
requiresModuleSystem : Bool
```

 Inherited from 

1. `Lake.LeanConfig`

```text
allowNonModules : Bool
```

 Inherited from 

1. `Lake.LeanConfig`

```text
srcDir : System.FilePath
```

The subdirectory of the package's source directory containing the executable's Lean source file. Defaults simply to said `srcDir`.

(This will be passed to `lean` as the `-R` option.)

```text
root : Lean.Name
```

The root module of the binary executable. Should include a `main` definition that will serve as the entry point of the program.

The root is built by recursively building its local imports (i.e., fellow modules of the workspace).

Defaults to the name of the target.

```text
exeName : String
```

The name of the binary executable. Defaults to the target name with any `.` replaced with a `-`.

```text
needs : Array Lake.PartialBuildKey
```

An `Array` of targets to build before the executable's modules.

```text
extraDepTargets : Array Lean.Name
```

**Deprecated. Use `needs` instead.** An `Array` of target names to build before the executable's modules.

```text
supportInterpreter : Bool
```

Enables the executable to interpret Lean files (e.g., via `Lean.Elab.runFrontend`) by exposing symbols within the executable to the Lean interpreter.

Implementation-wise, on Windows, the Lean shared libraries are linked to the executable and, on other systems, the executable is linked with `-rdynamic`. This increases the size of the binary on Linux and, on Windows, requires `libInit_shared.dll` and `libleanshared.dll` to be co-located with the executable or part of `PATH` (e.g., via `lake exe`). Thus, this feature should only be enabled when necessary.

Defaults to `false`.

```text
nativeFacets : Bool → Array (Lake.ModuleFacet System.FilePath)
```

The module facets to build and combine into the executable. If `shouldExport` is true, the module facets should export any symbols a user may expect to lookup in the executable. For example, the Lean interpreter will use exported symbols in the executable. Thus, `shouldExport` will be `true` if `supportInterpreter := true`.

Defaults to a singleton of `Module.oExportFacet` (if `shouldExport`) or `Module.oFacet`. That is, the object file compiled from the Lean source, potentially with exported Lean symbols.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Targets--External-Libraries"></a>
###### 24.1.3.2.4.3. External Libraries

Because external libraries may be written in any language and require arbitrary build steps, they are defined as programs written in the `FetchM` monad that produce a `Job`. External library targets should produce a build job that carries out the build and then returns the location of the resulting static library. For the external library to link properly when `precompileModules` is on, the static library produced by an `extern_lib` target must follow the platform's naming conventions for libraries (i.e., be named foo.a on Windows or libfoo.a on Unix-like systems). The utility function `Lake.nameToStaticLib` converts a library name into its proper file name for current platform.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**External Library Targets**

<a id="Lake___DSL___externLibCommand"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      extern_lib identOrStr simpleBinder? := term
      (where letRecDecl*)?
```

Define a new external library target for the package. Has one form:

```text
extern_lib «target-name» (pkg : NPackage _package.name) :=
  /- build term of type `FetchM (Job FilePath)` -/
```

The `pkg` parameter (and its type specifier) is optional. It is of type `NPackage _package.name` to provably demonstrate the package provided is the package in which the target is defined.

The term should build the external library's **static** library.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Targets--Custom-Targets"></a>
###### 24.1.3.2.4.4. Custom Targets

Custom targets may be used to define any incrementally-built artifact whatsoever, using the Lake API.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Custom Targets**

<a id="Lake___DSL___targetCommand"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      target identOrStr simpleBinder? : term := term
      (where letRecDecl*)?
```

Define a new external library target for the package. Has one form:

```text
extern_lib «target-name» (pkg : NPackage _package.name) :=
  /- build term of type `FetchM (Job FilePath)` -/
```

The `pkg` parameter (and its type specifier) is optional. It is of type `NPackage _package.name` to provably demonstrate the package provided is the package in which the target is defined.

The term should build the external library's **static** library.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Targets--Custom-Facets"></a>
###### 24.1.3.2.4.5. Custom Facets

Custom facets allow additional artifacts to be incrementally built from a module, library, or package.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Custom Package Facets**

Package facets allow the production of an artifact or set of artifacts from a whole package. The Lake API makes it possible to query a package for its libraries; thus, one common use for a package facet is to build a given facet of each library.

<a id="Lake___DSL___packageFacetDecl"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      package_facet identOrStr simpleBinder? : term := term
      (where letRecDecl*)?
```

Define a new package facet. Has one form:

```text
package_facet «facet-name» (pkg : Package) : α :=
  /- build term of type `FetchM (Job α)` -/
```

The `pkg` parameter (and its type specifier) is optional.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Custom Library Facets**

Library facets allow the production of an artifact or set of artifacts from a library. The Lake API makes it possible to query a library for its modules; thus, one common use for a library facet is to build a given facet of each module.

<a id="Lake___DSL___libraryFacetDecl"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      library_facet identOrStr simpleBinder? : term := term
      (where letRecDecl*)?
```

Define a new library facet. Has one form:

```text
library_facet «facet-name» (lib : LeanLib) : α :=
  /- build term of type `FetchM (Job α)` -/
```

The `lib` parameter (and its type specifier) is optional.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Custom Module Facets**

Module facets allow the production of an artifact or set of artifacts from a module, typically by invoking a command-line tool.

<a id="Lake___DSL___moduleFacetDecl"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      module_facet identOrStr simpleBinder? : term := term
      (where letRecDecl*)?
```

Define a new module facet. Has one form:

```text
module_facet «facet-name» (mod : Module) : α :=
  /- build term of type `FetchM (Job α)` -/
```

The `mod` parameter (and its type specifier) is optional.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Configuration-Value-Types"></a>
##### 24.1.3.2.5. Configuration Value Types

<a id="Lake___BuildType___debug"></a>

**inductive type**

```text
Lake.BuildType : Type
```

Lake equivalent of CMake's [`CMAKE_BUILD_TYPE`](https://stackoverflow.com/a/59314670).

**Constructors**

```text
Lake.BuildType.debug : Lake.BuildType
```

Debug optimization, asserts enabled, custom debug code enabled, and debug info included in executable (so you can step through the code with a debugger and have address to source-file:line-number translation). For example, passes `-O0 -g` when compiling C code.

```text
Lake.BuildType.relWithDebInfo : Lake.BuildType
```

Optimized, *with* debug info, but no debug code or asserts (e.g., passes `-O3 -g -DNDEBUG` when compiling C code).

```text
Lake.BuildType.minSizeRel : Lake.BuildType
```

Same as `release` but optimizing for size rather than speed (e.g., passes `-Os -DNDEBUG` when compiling C code).

```text
Lake.BuildType.release : Lake.BuildType
```

High optimization level and no debug info, code, or asserts (e.g., passes `-O3 -DNDEBUG` when compiling C code).

In Lake's DSL, 
<a id="--tech-term-globs"></a>
*globs* are patterns that match sets of module names. There is a coercion from names to globs that match the name in question, and there are two postfix operators for constructing further globs.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Glob Syntax**

The glob pattern `N.*` matches `N` or any submodule for which `N` is a prefix.

<a id="Manual___FreeSyntax___done-next"></a>

```ebnf
term ::= ...
    | name.*
```

The glob pattern `N.+` matches any submodule for which `N` is a strict prefix, but not `N` itself.

<a id="Manual___FreeSyntax___done-next-next"></a>

```ebnf
term ::= ...
    | name.+
```

Whitespace is not permitted between the name and `.*` or `.+`.

<a id="Lake___Glob___one"></a>

**inductive type**

```text
Lake.Glob : Type
```

A specification of a set of module names.

**Constructors**

```text
Lake.Glob.one : Lean.Name → Lake.Glob
```

Selects just the specified module name.

```text
Lake.Glob.submodules : Lean.Name → Lake.Glob
```

Selects all submodules of the specified module, but not the module itself.

```text
Lake.Glob.andSubmodules : Lean.Name → Lake.Glob
```

Selects the specified module and all submodules.

<a id="Lean___LeanOption___mk"></a>

**structure**

```text
Lean.LeanOption : Type
```

An option that is used by Lean as if it was passed using `-D`.

**Constructor**

```text
Lean.LeanOption.mk
```

**Fields**

```text
name : Lean.Name
```

The option's name.

```text
value : Lean.LeanOptionValue
```

The option's value.

<a id="Lake___Backend___c"></a>

**inductive type**

```text
Lake.Backend : Type
```

Compiler backend with which to compile Lean.

**Constructors**

```text
Lake.Backend.c : Lake.Backend
```

Force the C backend.

```text
Lake.Backend.llvm : Lake.Backend
```

Force the LLVM backend.

```text
Lake.Backend.default : Lake.Backend
```

Use the default backend. Can be overridden by more specific configuration.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Scripts"></a>
##### 24.1.3.2.6. Scripts

Lake scripts are used to automate tasks that require access to a package configuration but do not participate in incremental builds of artifacts from code. Scripts run in the `ScriptM` monad, which is `IO` with an additional [reader monad](../../Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#--tech-term-Reader-monads) [transformer](../../Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#--tech-term-monad-transformer) that provides access to the package configuration. In particular, a script should have the type `List String → ScriptM UInt32`. Workspace information in scripts is primarily accessed via the `MonadWorkspace ScriptM` instance.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Script Declarations**

<a id="Lake___DSL___scriptDecl"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      script identOrStr simpleBinder? :=
        term
      (where
        letRecDecl*)?
```

Define a new Lake script for the package.

**Example**

```lean
/-- Display a greeting -/
script «script-name» (args) do
  if h : 0 < args.length then
    IO.println s!"Hello, {args[0]'h}!"
  else
    IO.println "Hello, world!"
  return 0
```

<a id="Lake___ScriptM"></a>

**def**

```text
Lake.ScriptM (α : Type) : Type
```

The type of a `Script`'s monad.

It is an `IO` monad equipped information about the Lake configuration.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Default Scripts**

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | default_script
```

Marks a [Lake script](index.md#--tech-term-Lake-scripts) as the [package](index.md#--tech-term-package)'s default.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Configuration-File-Format--Lean-Format--Utilities"></a>
##### 24.1.3.2.7. Utilities

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**The Current Directory**

<a id="Lake___DSL___dirConst"></a>

```ebnf
term ::= ...
    | __dir__
```

A macro that expands to the path of package's directory during the Lakefile's elaboration.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Configuration Options**

<a id="Lake___DSL___getConfig"></a>

```ebnf
term ::= ...
    | get_config? ident
```

A macro that expands to the specified configuration option (or `none`, if the option has not been set) during the Lakefile's elaboration.

Configuration arguments are set either via the Lake CLI (by the `-K` option) or via the `with` clause in a `require` statement.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Compile-Time Conditionals**

<a id="Lake___DSL___metaIf"></a>

```ebnf
command ::= ...
    | meta if term then
        cmdDo
      (else cmdDo)?
```

The `meta if` command has two forms:

```text
meta if <c:term> then <a:command>
meta if <c:term> then <a:command> else <b:command>
```

It expands to the command `a` if the term `c` evaluates to true (at elaboration time). Otherwise, it expands to command `b` (if an `else` clause is provided).

One can use this command to specify, for example, external library targets only available on specific platforms:

```text
meta if System.Platform.isWindows then
extern_lib winOnlyLib := ...
else meta if System.Platform.isOSX then
extern_lib macOnlyLib := ...
else meta if System.Platform.isLinux then
extern_lib linuxOnlyLib := ...
```

<a id="cmdDo"></a>

**syntax**

**Command Sequences**

<a id="Lake___DSL___cmdDo"></a>

```ebnf
cmdDo ::= ...
    | command
```

<a id="Lake___DSL___cmdDo-next"></a>

```ebnf
cmdDo ::= ...
    | do
        command
        command*
```

The `do` command syntax groups multiple similarly indented commands together. The group can then be passed to another command that usually only accepts a single command (e.g., `meta if`).

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Compile-Time Side Effects**

<a id="Lake___DSL___runIO"></a>

```ebnf
term ::= ...
    | run_io doSeq
```

Executes a term of type `IO α` at elaboration-time and produces an expression corresponding to the result via `ToExpr α`.

<a id="lake-api"></a>
### 24.1.4. Script API Reference

In addition to ordinary `IO` effects, Lake scripts have access to the Lake environment (which provides information about the current toolchain, such as the location of the Lean compiler) and the current workspace. This access is provided in `ScriptM`.

<a id="Lake___ScriptM-next"></a>

**def**

```text
Lake.ScriptM (α : Type) : Type
```

The type of a `Script`'s monad.

It is an `IO` monad equipped information about the Lake configuration.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Script-API-Reference--Accessing-the-Environment"></a>
#### 24.1.4.1. Accessing the Environment

Monads that provide access to information about the current Lake environment (such as the locations of Lean, Lake, and other tools) have `MonadLakeEnv` instances. This is true for all of the monads in the Lake API, including `ScriptM`.

<a id="Lake___MonadLakeEnv"></a>

**def**

```text
Lake.MonadLakeEnv.{u} (m : Type → Type u) : Type u
```

A monad equipped with a (read-only) detected environment for Lake.

<a id="Lake___getLakeEnv"></a>

**def**

```text
Lake.getLakeEnv.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m] :
  m Lake.Env
```

Gets the current Lake environment.

<a id="Lake___getNoCache"></a>

**def**

```text
Lake.getNoCache.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] [Lake.MonadBuild m] : m Bool
```

Returns the `LAKE_NO_CACHE`/`` Lake configuration.

<a id="Lake___getTryCache"></a>

**def**

```text
Lake.getTryCache.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] [Lake.MonadBuild m] : m Bool
```

Returns whether the `LAKE_NO_CACHE`/`` Lake configuration is **NOT** set.

<a id="Lake___getPkgUrlMap"></a>

**def**

```text
Lake.getPkgUrlMap.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m (Lean.NameMap String)
```

Returns the `LAKE_PACKAGE_URL_MAP` for the Lake environment. Empty if none.

<a id="Lake___getElanToolchain"></a>

**def**

```text
Lake.getElanToolchain.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m String
```

Returns the name of Elan toolchain for the Lake environment. Empty if none.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Script-API-Reference--Accessing-the-Environment--Search-Path-Helpers"></a>
##### 24.1.4.1.1. Search Path Helpers

<a id="Lake___getEnvLeanPath"></a>

**def**

```text
Lake.getEnvLeanPath.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.SearchPath
```

Returns the detected `LEAN_PATH` value of the Lake environment.

<a id="Lake___getEnvLeanSrcPath"></a>

**def**

```text
Lake.getEnvLeanSrcPath.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.SearchPath
```

Returns the detected `LEAN_SRC_PATH` value of the Lake environment.

<a id="Lake___getEnvSharedLibPath"></a>

**def**

```text
Lake.getEnvSharedLibPath.{u_1} {m : Type → Type u_1}
  [Lake.MonadLakeEnv m] [Functor m] : m System.SearchPath
```

Returns the detected `sharedLibPathEnvVar` value of the Lake environment.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Script-API-Reference--Accessing-the-Environment--Elan-Install-Helpers"></a>
##### 24.1.4.1.2. Elan Install Helpers

<a id="Lake___getElanInstall___"></a>

**def**

```text
Lake.getElanInstall?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m (Option Lake.ElanInstall)
```

Returns the detected Elan installation (if one).

<a id="Lake___getElanHome___"></a>

**def**

```text
Lake.getElanHome?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m (Option System.FilePath)
```

Returns the root directory of the detected Elan installation (i.e., `ELAN_HOME`).

<a id="Lake___getElan___"></a>

**def**

```text
Lake.getElan?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m (Option System.FilePath)
```

Returns the path of the `elan` binary in the detected Elan installation.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Script-API-Reference--Accessing-the-Environment--Lean-Install-Helpers"></a>
##### 24.1.4.1.3. Lean Install Helpers

<a id="Lake___getLeanInstall"></a>

**def**

```text
Lake.getLeanInstall.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m Lake.LeanInstall
```

Returns the detected Lean installation.

<a id="Lake___getLeanSysroot"></a>

**def**

```text
Lake.getLeanSysroot.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Returns the root directory of the detected Lean installation.

<a id="Lake___getLeanSrcDir"></a>

**def**

```text
Lake.getLeanSrcDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Returns the Lean source directory of the detected Lean installation.

<a id="Lake___getLeanLibDir"></a>

**def**

```text
Lake.getLeanLibDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Returns the Lean library directory of the detected Lean installation.

<a id="Lake___getLeanIncludeDir"></a>

**def**

```text
Lake.getLeanIncludeDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Returns the C include directory of the detected Lean installation.

<a id="Lake___getLeanSystemLibDir"></a>

**def**

```text
Lake.getLeanSystemLibDir.{u_1} {m : Type → Type u_1}
  [Lake.MonadLakeEnv m] [Functor m] : m System.FilePath
```

Returns the system library directory of the detected Lean installation.

<a id="Lake___getLean"></a>

**def**

```text
Lake.getLean.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Returns the path of the `lean` binary in the detected Lean installation.

<a id="Lake___getLeanc"></a>

**def**

```text
Lake.getLeanc.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Returns the path of the `leanc` binary in the detected Lean installation.

<a id="Lake___getLeanSharedLib"></a>

**def**

```text
Lake.getLeanSharedLib.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Returns the path of the primary core shared library (i.e., `libleanshared`) in the detected Lean installation.

<a id="Lake___getLeanAr"></a>

**def**

```text
Lake.getLeanAr.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Get the path of the `ar` binary in the detected Lean installation.

<a id="Lake___getLeanCc"></a>

**def**

```text
Lake.getLeanCc.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Get the path of C compiler in the detected Lean installation.

<a id="Lake___getLeanCc___"></a>

**def**

```text
Lake.getLeanCc?.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m (Option String)
```

Get the optional `LEAN_CC` compiler override of the detected Lean installation.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Script-API-Reference--Accessing-the-Environment--Lake-Install-Helpers"></a>
##### 24.1.4.1.4. Lake Install Helpers

<a id="Lake___getLakeInstall"></a>

**def**

```text
Lake.getLakeInstall.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m Lake.LakeInstall
```

Get the detected Lake installation.

<a id="Lake___getLakeHome"></a>

**def**

```text
Lake.getLakeHome.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Get the root directory of the detected Lake installation (e.g., `LAKE_HOME`).

<a id="Lake___getLakeSrcDir"></a>

**def**

```text
Lake.getLakeSrcDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Get the source directory of the detected Lake installation.

<a id="Lake___getLakeLibDir"></a>

**def**

```text
Lake.getLakeLibDir.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Get the Lean library directory of the detected Lake installation.

<a id="Lake___getLake"></a>

**def**

```text
Lake.getLake.{u_1} {m : Type → Type u_1} [Lake.MonadLakeEnv m]
  [Functor m] : m System.FilePath
```

Get the path of the `lake` binary in the detected Lake installation.

<a id="The-Lean-Language-Reference--Build-Tools-and-Distribution--Lake--Script-API-Reference--Accessing-the-Workspace"></a>
#### 24.1.4.2. Accessing the Workspace

Monads that provide access to information about the current Lake workspace have `MonadWorkspace` instances. In particular, there are instances for `ScriptM` and `LakeM`.

<a id="Lake___MonadWorkspace___mk"></a>

**type class**

```text
Lake.MonadWorkspace.{u} (m : Type → Type u) : Type u
```

A monad equipped with a (read-only) Lake `Workspace`.

**Instance Constructor**

```text
Lake.MonadWorkspace.mk.{u}
```

**Methods**

```text
getWorkspace : m Lake.Workspace
```

Gets the current Lake workspace.

<a id="Lake___getRootPackage"></a>

**def**

```text
Lake.getRootPackage.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] : m Lake.Package
```

Returns the root package of the context's workspace.

<a id="Lake___findPackageByName___"></a>

**def**

```text
Lake.findPackageByName?.{u_1} {m : Type → Type u_1}
  [Lake.MonadWorkspace m] [Functor m] (name : Lean.Name) :
  m (Option Lake.Package)
```

Returns the first package in the workspace (if any) that has been assigned the `name`.

This can be used to find the package corresponding to a user-provided name. If the package's unique identifier is already available, use `findPackageByKey?`instead.

<a id="Lake___findPackageByKey___"></a>

**def**

```text
Lake.findPackageByKey?.{u_1} {m : Type → Type u_1}
  [Lake.MonadWorkspace m] [Functor m] (keyName : Lean.Name) :
  m (Option (Lake.NPackage keyName))
```

Returns the unique package in the workspace (if any) that is identified by `keyName`.

<a id="Lake___findModule___"></a>

**def**

```text
Lake.findModule?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] (name : Lean.Name) : m (Option Lake.Module)
```

Locate the named, buildable, importable, local module in the workspace.

<a id="Lake___findLeanExe___"></a>

**def**

```text
Lake.findLeanExe?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] (name : Lean.Name) : m (Option Lake.LeanExe)
```

Try to find a Lean executable in the workspace with the given name.

<a id="Lake___findLeanLib___"></a>

**def**

```text
Lake.findLeanLib?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] (name : Lean.Name) : m (Option Lake.LeanLib)
```

Try to find a Lean library in the workspace with the given name.

<a id="Lake___findExternLib___"></a>

**def**

```text
Lake.findExternLib?.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] (name : Lean.Name) : m (Option Lake.ExternLib)
```

Try to find an external library in the workspace with the given name.

<a id="Lake___getLeanPath"></a>

**def**

```text
Lake.getLeanPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] : m System.SearchPath
```

Returns the paths added to `LEAN_PATH` by the context's workspace.

<a id="Lake___getLeanSrcPath"></a>

**def**

```text
Lake.getLeanSrcPath.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] : m System.SearchPath
```

Returns the paths added to `LEAN_SRC_PATH` by the context's workspace.

<a id="Lake___getSharedLibPath"></a>

**def**

```text
Lake.getSharedLibPath.{u_1} {m : Type → Type u_1}
  [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath
```

Returns the paths added to the shared library path by the context's workspace.

<a id="Lake___getAugmentedLeanPath"></a>

**def**

```text
Lake.getAugmentedLeanPath.{u_1} {m : Type → Type u_1}
  [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath
```

Returns the augmented `LEAN_PATH` set by the context's workspace.

<a id="Lake___getAugmentedLeanSrcPath"></a>

**def**

```text
Lake.getAugmentedLeanSrcPath.{u_1} {m : Type → Type u_1}
  [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath
```

Returns the augmented `LEAN_SRC_PATH` set by the context's workspace.

<a id="Lake___getAugmentedSharedLibPath"></a>

**def**

```text
Lake.getAugmentedSharedLibPath.{u_1} {m : Type → Type u_1}
  [Lake.MonadWorkspace m] [Functor m] : m System.SearchPath
```

Returns the augmented shared library path set by the context's workspace.

<a id="Lake___getAugmentedEnv"></a>

**def**

```text
Lake.getAugmentedEnv.{u_1} {m : Type → Type u_1} [Lake.MonadWorkspace m]
  [Functor m] : m (Array (String × Option String))
```

Returns the augmented environment variables set by the context's workspace.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
A field assignment in a declarative configuration.
```


### Display 2


````text
Defines the configuration of a Lake package.  Has many forms:

```lean
package «pkg-name»
package «pkg-name» { /- config opts -/ }
package «pkg-name» where /- config opts -/
```

There can only be one `package` declaration per Lake configuration file.
The defined package configuration will be available for reference as `_package`.
````


### Display 3


```text
A `docComment` parses a "documentation comment" like `/-- foo -/`. This is not treated like
a regular comment (that is, as whitespace); it is parsed and forms part of the syntax tree structure.

At parse time, `docComment` checks the value of the `doc.verso` option. If it is true, the contents
are parsed as Verso markup. If not, the contents are treated as plain text or Markdown. Use
`plainDocComment` to always treat the contents as plain text.

A plain text doc comment node contains a `/--` atom and then the remainder of the comment, `foo -/`
in this example. Use `TSyntax.getDocString` to extract the body text from a doc string syntax node.
A Verso comment node contains the `/--` atom, the document's syntax tree, and a closing `-/` atom.
```


### Display 4


```text
`letRecDecl` matches the body of a let-rec declaration: a doc comment, attributes, and then
a let declaration without the `let` keyword, such as `/-- foo -/ @[simp] bar := 1`.
```


### Display 5


````text
Declare a post-`lake update` hook for the package.
Runs the monadic action is after a successful `lake update` execution
in this package or one of its downstream dependents.

**Example**

This feature enables Mathlib to synchronize the Lean toolchain and run
`cache get` after a `lake update`:

```
lean_exe cache
post_update pkg do
  let wsToolchainFile := (← getRootPackage).dir / "lean-toolchain"
  let mathlibToolchain ← IO.FS.readFile <| pkg.dir / "lean-toolchain"
  IO.FS.writeFile wsToolchainFile mathlibToolchain
  let exeFile ← runBuild cache.fetch
  let exitCode ← env exeFile.toString #["get"]
  if exitCode ≠ 0 then
    error s!"{pkg.name}: failed to fetch cache"
```
````


### Display 6


````text
Adds a new package dependency to the workspace. The general syntax is:

```
require ["<scope>" /] <pkg-name> [@ [git]? <version>]
  [from <source>] [with <options>]
```

The `from` clause tells Lake where to locate the dependency.
See the `fromClause` syntax documentation (e.g., hover over it) to see
the different forms this clause can take.

Without a `from` clause, Lake will lookup the package in the default
registry (i.e., Reservoir) and use the information there to download the
package at the requested `version`. The `scope` is used to disambiguate between
packages in the registry with the same `pkg-name`. In Reservoir, this scope
is the package owner (e.g., `leanprover` of `@leanprover/doc-gen4`).

The `with` clause specifies a `NameMap String` of Lake options
used to configure the dependency. This is equivalent to passing `-K`
options to the dependency on the command line.
````


### Display 7


```text
The version of the package to require.
To specify a Git revision, use the syntax `@ git <rev>`.
```


### Display 8


````text
Specifies a specific source from which to draw the package dependency.
Dependencies that are downloaded from a remote source will be placed
into the workspace's `packagesDir`.

**Path Dependencies**

```
from <path>
```

Lake loads the package located at a fixed `path` relative to the
requiring package's directory.

**Git Dependencies**

```
from git <url> [@ <rev>] [/ <subDir>]
```

Lake clones the Git repository available at the specified fixed Git `url`,
and checks out the specified revision `rev`. The revision can be a commit hash,
branch, or tag. If none is provided, Lake defaults to `master`. After checkout,
Lake loads the package located in `subDir` (or the repository root if no
subdirectory is specified).
````


### Display 9


```text
A `NameMap String` of Lake options used to configure the dependency.
This is equivalent to passing `-K` options to the dependency on the command line.
```


### Display 10


````text
Define a new Lean library target for the package.
Can optionally be provided with a configuration of type `LeanLibConfig`.
Has many forms:

```lean
lean_lib «target-name»
lean_lib «target-name» { /- config opts -/ }
lean_lib «target-name» where /- config opts -/
```
````


### Display 11


````text
Define a new Lean binary executable target for the package.
Can optionally be provided with a configuration of type `LeanExeConfig`.
Has many forms:

```lean
lean_exe «target-name»
lean_exe «target-name» { /- config opts -/ }
lean_exe «target-name» where /- config opts -/
```
````


### Display 12


````text
Define a new external library target for the package. Has one form:

```lean
extern_lib «target-name» (pkg : NPackage _package.name) :=
  /- build term of type `FetchM (Job FilePath)` -/
```

The `pkg` parameter (and its type specifier) is optional.
It is of type `NPackage _package.name` to provably demonstrate the package
provided is the package in which the target is defined.

The term should build the external library's **static** library.
````


### Display 13


```text
Termination hints are `termination_by` and `decreasing_by`, in that order.
```


### Display 14


````text
Define a new custom target for the package. Has one form:

```lean
target «target-name» (pkg : NPackage _package.name) : α :=
  /- build term of type `FetchM (Job α)` -/
```

The `pkg` parameter (and its type specifier) is optional.
It is of type `NPackage _package.name` to provably demonstrate the package
provided is the package in which the target is defined.
````


### Display 15


````text
Define a new package facet. Has one form:

```lean
package_facet «facet-name» (pkg : Package) : α :=
  /- build term of type `FetchM (Job α)` -/
```

The `pkg` parameter (and its type specifier) is optional.
````


### Display 16


````text
Define a new library facet. Has one form:

```lean
library_facet «facet-name» (lib : LeanLib) : α :=
  /- build term of type `FetchM (Job α)` -/
```

The `lib` parameter (and its type specifier) is optional.
````


### Display 17


````text
Define a new module facet. Has one form:

```lean
module_facet «facet-name» (mod : Module) : α :=
  /- build term of type `FetchM (Job α)` -/
```

The `mod` parameter (and its type specifier) is optional.
````


### Display 18


````text
Define a new Lake script for the package.

**Example**

```
/-- Display a greeting -/
script «script-name» (args) do
  if h : 0 < args.length then
    IO.println s!"Hello, {args[0]'h}!"
  else
    IO.println "Hello, world!"
  return 0
```
````


### Display 19


```text
A macro that expands to the path of package's directory
during the Lakefile's elaboration.
```


### Display 20


```text
A macro that expands to the specified configuration option (or `none`,
if the option has not been set) during the Lakefile's elaboration.

Configuration arguments are set either via the Lake CLI (by the `-K` option)
or via the `with` clause in a `require` statement.
```


### Display 21


````text
The `meta if` command has two forms:

```lean
meta if <c:term> then <a:command>
meta if <c:term> then <a:command> else <b:command>
```

It expands to the command `a` if the term `c` evaluates to true
(at elaboration time). Otherwise, it expands to command `b` (if an `else`
clause is provided).

One can use this command to specify, for example, external library targets
only available on specific platforms:

```lean
meta if System.Platform.isWindows then
extern_lib winOnlyLib := ...
else meta if System.Platform.isOSX then
extern_lib macOnlyLib := ...
else meta if System.Platform.isLinux then
extern_lib linuxOnlyLib := ...
```
````


### Display 22


```text
The `do` command syntax groups multiple similarly indented commands together.
The group can then be passed to another command that usually only accepts a
single command (e.g., `meta if`).
```


### Display 23


```text
Executes a term of type `IO α` at elaboration-time
and produces an expression corresponding to the result via `ToExpr α`.
```


## Inherited reference figures

These figures describe the native reference, not a claim about an implemented PSC runtime.

![Workspace lean-toolchain Root package Package configuration file (lakefile.lean) Libraries Executables Manifest (lake-manifest.json) Lake Directory (.](../../../assets/figures/figure-04.svg)

Caption labels: Workspace lean-toolchain Root package Package configuration file (lakefile.lean) Libraries Executables Manifest (lake-manifest.json) Lake Directory (.lake) Packages Dependency 1 Package configuration file Libraries Executables Artifacts Dependency 2 Package configuration file Libraries Executables Artifacts ⋯ Artifacts Built libraries Built executables
