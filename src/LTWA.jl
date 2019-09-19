module LTWA

using DelimitedFiles, StringEncodings

export abbreviate

try
	include("../deps/deps.jl")
	@assert @isdefined ltwa_file
catch
	error("Package LTWA is not built properly, try rebuilding it and trying again")
end

const ltwa_list = Vector{Tuple{String,Union{String,Missing},Vector{Symbol}}}()
const ltwa_edict = Dict{String, Tuple{Union{String,Missing},Vector{Symbol}}}()
const ltwa_pdict = Dict{String, Tuple{Union{String,Missing}, Vector{Symbol}}}()
const ltwa_sdict = Dict{String, Tuple{Union{String,Missing}, Vector{Symbol}}}()
const ltwa_idict = Dict{String, Tuple{Union{String,Missing}, Vector{Symbol}}}()
const ltwa_blank = (missing, Symbol[])

const drop_eset = Set(String["of", "and", "the", "de", "le"])
const drop_pset = Set(String["l'"])

begin
	@debug "precompiling lists and stuff"
	empty!(ltwa_list)
	empty!(ltwa_edict)
	empty!(ltwa_pdict)
	empty!(ltwa_sdict)
	data = readdlm(open(ltwa_file, enc"UTF-16"), '\t', String, skipstart=1)
	for (word, _abbrv, _langs) in zip(eachcol(data)...)
		abbrv = _abbrv=="n.a." ? missing : _abbrv
		langs = map(Symbol ∘ strip, split(_langs, ','))
		entry = (abbrv, langs)
		push!(ltwa_list, (word, entry...))
		if startswith(word,'-') && endswith(word,'-')
			ltwa_idict[word[nextind(word,1):prevind(word,end)]] = entry
		elseif startswith(word, '-')
			ltwa_sdict[word[nextind(word,1):end]] = entry
		elseif endswith(word, '-')
			ltwa_pdict[word[1:prevind(word,end)]] = entry
		else
			ltwa_edict[word] = entry
		end
	end
	nothing
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

function abbreviate(title::AbstractString; opts...)
	abbrvstring(map(w -> _abbreviateword(w; opts...), split(title)))
end

function _abbreviateword(word::AbstractString; dropset=drop_eset)::AbbrvWord
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

function abbreviateword_exact(word::AbstractString, dict::Dict=ltwa_edict)
	a = get(dict, word, ltwa_blank)[1]
	a === missing || return mkabbrv(a)
	missing
end

function abbreviateword_prefix(word::AbstractString, dict::Dict=ltwa_pdict)
	i = lastindex(word)
	iend = firstindex(word)
	while i ≥ iend
		a = get(dict, word[iend:i], ltwa_blank)[1]
		a === missing || return mkabbrv(a, suffix=word[nextind(word,i):end])
		i = prevind(word, i)
	end
	missing
end

function abbreviateword_suffix(word::AbstractString, dict::Dict=ltwa_sdict)
	i = firstindex(word)
	iend = lastindex(word)
	while i ≤ iend
		a = get(dict, word[i:iend], ltwa_blank)[1]
		a === missing || return mkabbrv(a, prefix=word[1:prevind(word,i)])
		i = nextind(word, i)
	end
	missing
end

function abbreviateword_infix(word::AbstractString, dict::Dict=ltwa_idict)
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
