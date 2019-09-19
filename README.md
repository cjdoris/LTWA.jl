# LTWA.jl

Julia package for accessing the [List of Title Word Abbreviations](https://www.issn.org/services/online-services/access-to-the-ltwa/) and computing abbreviations of titles.

## Installation

`] install https://github.com/cjdoris/LTWA.jl` or `Pkg.install("https://github.com/cjdoris/LTWA.jl")`.

## Usage

```julia
abbreviate(title :: AbstractString) :: String
```

An abbreviated version of `title`.

```julia
LTWA.ltwa_list :: Vector{Tuple{String, Union{Missing, String}, Vector{Symbol}}}
```

The LTWA as a vector of tuples `(pat, abbrv, langs)` where:
* `pat` is the pattern (a word, prefix, suffix or infix, depending on whether it starts or ends with a hyphen)
* `abbrv` is the abbreviated version, or `missing` if not available (i.e. "n.a." in the text version of the LTWA)
* `langs` are the associated languages

## Known limitations and deviations from ISO 4
* We don't always capitalize the first letter of the first word
* We try to abbreviate every word
* We don't remove commas or convert periods to commas
* The list of words we drop is very small
* We don't handle punctuation at all
