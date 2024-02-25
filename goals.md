## Why Julia? Why Kezdi.jl?
1. A single language for all scientific computing. Economists very often combine multiple languages to get their work done. [data from 200 replication packages] Data cleaning, statistical analysis and computational simulations are often done in different languages. This is not only inefficient, but also makes it difficult to reproduce and share research.
2. Reproducibility. An open source language with world-class environment and package management.
3. Performance. Scientists do not care much about speed. Code often takes weeks to run. [data from 200 replication packages] Performance matters for fast iteration, which can not only speed up the research process, but also make the code more reproducible.
4. Domain-specific syntax. Data analysis and statistics have their own conventions. Stata (R) provides an easy-to-use and easy-to-learn interface for data analysis. 
5. Consistent API. In any tool, let alone among multiple tools and languages, the APIs are often inconsistent. This makes it difficult to learn and use new tools.
6. Curated tools and methods. Adopting open source tools and methods is difficult. There are too many options, and it is difficult to know which ones are necessary, and which ones are reliable.
7. Proper abstractions. A complete language should provide proper abstractions for different tasks. Data structures, functions, modules, should come naturally to the user.

## Milestones
### `if`, `in`, `by` and options parsing
This should work for all commands:

```stata
by country: summarize gdp if gdp > 0, detail
```

### Variable scoping
```julia
@generate y = x^2
```
should look for `y` in the dataframe, `x` in the dataframe, but if not found, then in the global scope.

### Data manipulation commands
- generate
- replace
- egen
- collapse
- merge
- join
- append
- reshape

### Side effect commands
- tabulate
- table
- summarize
- display (shall we replace by print?)

### Curated statistical commands
Based on actual frequency of usage. 

## Architecture
### Multichannel communication
Stata has effectively multichannel communication between statements. Each statement manipulates the dataframe (channel 1), but can return values in `r()` or `e()` (two more channels). They can also have other side effects.

We may need to implement multi-channel piping (coroutines?) to bring back this feeling to users.

Normal piping takes df -> df functions only.