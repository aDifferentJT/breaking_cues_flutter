# Building the SMuFL specification

The SMuFL specification is published using [mdBook](https://rust-lang.github.io/mdBook/), an open source package for producing books using Markdown sources.

This document describes the build process for the SMuFL specification.

## Repository layout

**_config.yml** contains some basic [Jekyll configuration](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/about-github-pages-and-jekyll) for GitHub Pages. We use the **exclude** directive to tell Jekyll not to build certain files/folders in the repository.

**BUILDING.md** is this document.

**drafts** contains published drafts of the SMuFL specification. Each draft version should be contained in a subfolder named _version-date_, e.g. **1.4-2021-01-03**. The contents of each subfolder is a complete set of GitBook (for versions up to 1.4) or mdBook (for 1.5 or later) output.

**gitbook** contains a single file **index.html**. Because of limitations in GitHub Pages, we use an old-fashioned HTML meta tag with http-equiv attribute to redirect visitors who land at https://w3c.github.io/smufl to the latest version of the specification, which is found at **/latest**.

**index.html** similarly redirects to **/latest**.

**latest** contains the mdBook output for the current state of the specification.

**mdbook** contains the input and configuration files used to build the mdBook output.

**metadata** contains the latest versions of the standard SMuFL metadata files.

**README.md** is a brief description of this repository.

**releases** contains published versions of the SMuFL specification. Each published version should be in a subfolder named _version_, e.g. **1.4**. The contents of each subfolder is a complete set of GitBook (for versions up to 1.4) or mdBook (for 1.5 or later) output.

**scripts** contains some useful scripts for working with SMuFL fonts in different font editing software.

**w3c.json** contains configuration data used by the W3C organisation to manage their many GitHub repositories.

## Prerequisites

* [Install mdBook](https://rust-lang.github.io/mdBook/guide/installation.html)

## Updating the specification

The working folder is **mdbook/src**. This contains all of the Markdown sources for the specification.

The structure of the book is described in **SUMMARY.md**. To add one or more new pages to the specification, it must be added to this file.

The configuration for the overall book is **mdbook/book.toml**, a configuration file in [TOML](https://toml.io/en/), but it should not normally be necessary to adjust this configuration file.

The **theme** folder contains overrides to mdBook's default theme. It is advised only to include files that differ from the default theme, to be able to take advantage of improvements and fixes added to the default theme.

mdBook has a very handy local web server that updates the book live as the Markdown source files and theme data are updated. To run the local web server and preview the book, using Terminal:

```
mdbook serve --open
```

This will open the default web browser and point it at the local web server.

## Building the specification

To build the book, using Terminal:

```
cd mdbook
mdbook build
```

This creates a folder called **book**. Rename this folder to **latest** and replace the existing **latest** folder in the root of the repository with this folder.

Now commit and push to the **gh-pages** branch.
