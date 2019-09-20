"""
An interface to the [List of Title Word Abbreviations](https://www.issn.org/services/online-services/access-to-the-ltwa/).

See [`abbreviate`](@ref), [`abbreviateword`](@ref) and [`list`](@ref).
"""
module LTWA

using DelimitedFiles, StringEncodings

export abbreviate

try
	include("../deps/deps.jl")
	@assert @isdefined ltwa_file
catch
	error("Package LTWA is not built properly, try rebuilding it and trying again")
end

"""
    list :: Vector{Tuple{String, Union{String, Missing}, Set{Symbol}}}

The list as a vector of tuples `(pat, abbrv, langs)` where:
* `pat` is the pattern
* `abbrv` is the abbreviation (possibly `missing`)
* `langs` are the corresponding languages
"""
const list = Vector{Tuple{String,Union{String,Missing}, Set{Symbol}}}()
const edict = Dict{String, Tuple{Union{String,Missing}, Set{Symbol}}}()
const pdict = Dict{String, Tuple{Union{String,Missing}, Set{Symbol}}}()
const sdict = Dict{String, Tuple{Union{String,Missing}, Set{Symbol}}}()
const idict = Dict{String, Tuple{Union{String,Missing}, Set{Symbol}}}()
const blank = (missing, Set{Symbol}())

const dropset = Set(String["of", "and", "the", "de", "le", "a", "for"])
const pdropset = Set(String["l'"])

@debug "precompiling lists and stuff"
empty!(list)
empty!(edict)
empty!(pdict)
empty!(sdict)
let data = readdlm(open(ltwa_file, enc"UTF-16"), '\t', String, skipstart=1)
	for (word, _abbrv, _langs) in zip(eachcol(data)...)
		abbrv = _abbrv=="n.a." ? missing : _abbrv
		langs = Set{Symbol}(map(Symbol, filter(!isempty, map(strip, split(_langs, ',')))))
		entry = (abbrv, langs)
		push!(list, (word, entry...))
		if startswith(word,'-') && endswith(word,'-')
			idict[word[nextind(word,1):prevind(word,end)]] = entry
		elseif startswith(word, '-')
			sdict[word[nextind(word,1):end]] = entry
		elseif endswith(word, '-')
			pdict[word[1:prevind(word,end)]] = entry
		else
			edict[word] = entry
		end
	end
end

struct AbbrvWord
	word :: String
	abbrv :: String
	nospaceleft :: Bool
	nospaceright :: Bool
end

AbbrvWord(word, abbrv; nospaceleft=false, nospaceright=false) = AbbrvWord(word, length(abbrv)<length(word) ? abbrv : word, nospaceleft, nospaceright)

Base.string(w::AbbrvWord) = w.word

function abbrvstring(ws::AbstractVector{AbbrvWord})
	ws = [w for w in ws if !isempty(w.abbrv)]
	parts = String[]
	for (i,w) in enumerate(ws)
		i == 1 || ws[i-1].nospaceright || w.nospaceleft || push!(parts, " ")
		push!(parts, w.abbrv)
	end
	join(parts)
end

"""
    abbreviate(title::AbstractString) :: String

An abbreviation of `title`.
"""
function abbreviate(title::AbstractString; opts...) :: String
	abbrvstring(map(w -> _abbreviateword(w; opts...), split(title)))
end

"""
    abbreviateword(word::AbstractString) :: String

An abbreviation of `word`, which is assumed to be a single word.
"""
abbreviateword(word) = _abbreviateword(word).abbrv

function _abbreviateword(word::AbstractString; dropset=dropset)::AbbrvWord
	# TODO: remove commas
	# TODO: change '.' to ',' (except in )
	# TODO: repeat the below with preceding/trailing punctuation removed
	word in dropset && return AbbrvWord(word, "")
	a = abbreviateword_part(word)
	a === missing || return AbbrvWord(word, a)
	if any(c -> isletter(c) && !islowercase(c), word)
		lowercase(word) in dropset && return AbbrvWord(word, "")
		a = abbreviateword_part(lowercase(word))
		a === missing || return AbbrvWord(word, matchcase(a, word))
	end
	AbbrvWord(word, word)
end

function abbreviateword_part(word::AbstractString)
	a = abbreviateword_exact(word)
	a === missing || return a
	a = abbreviateword_prefix(word)
	a === missing || return a
	a = abbreviateword_suffix(word)
	a === missing || return a
	a = abbreviateword_infix(word)
	a === missing || return a
	missing
end

function abbreviateword_exact(word::AbstractString, dict::Dict=edict)
	a = get(dict, word, blank)[1]
	a === missing || return mkabbrv(a)
	missing
end

function abbreviateword_prefix(word::AbstractString, dict::Dict=pdict)
	i = lastindex(word)
	iend = firstindex(word)
	while i ≥ iend
		a = get(dict, word[iend:i], blank)[1]
		a === missing || return mkabbrv(a, suffix=word[nextind(word,i):end])
		i = prevind(word, i)
	end
	missing
end

function abbreviateword_suffix(word::AbstractString, dict::Dict=sdict)
	i = firstindex(word)
	iend = lastindex(word)
	while i ≤ iend
		a = get(dict, word[i:iend], blank)[1]
		a === missing || return mkabbrv(a, prefix=word[1:prevind(word,i)])
		i = nextind(word, i)
	end
	missing
end

function abbreviateword_infix(word::AbstractString, dict::Dict=idict)
	for (w,(a,_)) in dict
		ii = findlast(w, word)
		ii === nothing || return mkabbrv(a, prefix=word[1:prevind(word,ii.start)], suffix=word[nextind(word,ii.stop):end])
	end
	missing
end

function matchcase(abbrv::AbstractString, orig::AbstractString)
	if all(c -> !isletter(c) || isuppercase(c), orig)
		uppercase(abbrv)
	elseif all(c -> !isletter(c) || islowercase(c), orig)
		lowercase(abbrv)
	elseif isuppercase(first(orig)) && all(c -> !isletter(c) || islowercase(c), orig[nextind(orig,1):end])
		uppercasefirst(abbrv)
	else
		# don't know what to do in this case
		# could check if abbrv is a prefix of orig and match each letter
		abbrv
	end
end

function mkabbrv(a::AbstractString; prefix="", suffix="")
	if startswith(a,'-') && endswith(a,'-')
		string(prefix, a[nextind(a,1):prevind(a,end)], suffix)
	elseif startswith(a,'-')
		string(prefix, a[nextind(a,1):end])
	elseif endswith(a,'-')
		string(a[1:prevind(a,end)], suffix)
	else
		a
	end
end

end # module
