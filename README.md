# LTWA.jl

Julia package for accessing the [List of Title Word Abbreviations](https://www.issn.org/services/online-services/access-to-the-ltwa/) and computing abbreviations of titles.

## Installation

`] install LTWA` or `Pkg.install("LTWA")`.

## Usage

```julia
abbreviate(title :: AbstractString) :: String
```

An abbreviation of `title`.

```julia
abbreviateword(word :: AbstractString) :: String
```

An abbreviation of `word`, which is assumed to be a single word.

```julia
LTWA.list :: Vector{Tuple{String, Union{Missing, String}, Set{Symbol}}}
```

The list as a vector of tuples `(pat, abbrv, langs)` where:
* `pat` is the pattern
* `abbrv` is the abbreviation (possibly `missing`)
* `langs` are the corresponding languages

## Examples
```julia
julia> using LTWA

julia> abbreviate("Journal of Statistical Software")
"J. Stat. Softw."
```

## Known limitations and deviations from ISO 4
(Feel free to open an [issue](https://github.com/cjdoris/LTWA.jl/issues)/PR)
* We don't always capitalize the first letter of the first word
* We try to abbreviate every word
* We don't remove commas or convert periods to commas
* The list of words we drop is very small
* We don't handle punctuation at all
