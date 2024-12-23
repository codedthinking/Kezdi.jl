# JuliaConSubmission

This repository is an example for a proceeding submission at JuliaCon.
Feel free to use the template in `/paper` to prepare yours.
For more information, check out the [author's guide](https://juliacon.github.io/proceedings-guide/author/) and [proceedings.juliacon.org](http://proceedings.juliacon.org).

## Importing into your project

**Important** do no fork this repo to create a JuliaCon submission.
The JuliaCon paper should live in the repository of the software you are presenting in a `/paper` folder at the top-level.
If you do not want to introduce a `/paper` folder in your software, you can do so in an arbitrary branch.

## Paper dependencies

The document can be built locally, the following dependencies need to be installed:
- Ruby
- latexmk

## Build process

Build the paper using:
```
$ latexmk -bibtex -pdf paper.tex
```

Clean up temporary files using:
```
$ latexmk -c
```

## Paper metadata

**IMPORTANT**
Some information for building the document (such as the title and keywords)
is provided through the `paper.yml` file and not through the usual `\title`
command. Respecting the process is important to avoid build errors when
submitting your work.

## Get from OverLeaf

The paper folder can be downloaded from [OverLeaf](https://www.overleaf.com/read/dcvvhkyynmzt).
