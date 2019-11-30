using Pkg.Artifacts

const url = "https://www.issn.org/wp-content/uploads/2013/09/LTWA_20160915.txt"
const toml = joinpath(@__DIR__, "..", "Artifacts.toml")
const file = "LTWA.txt"
const key  = "LTWA"

h = artifact_hash(key, toml)

artifact_exists(h) ||
	create_artifact(dir -> download(url, joinpath(dir, file))) == h ||
		error("LTWA file has changed")

const path = joinpath(artifact_path(h), file)

open("deps.jl", "w") do io
	println(io, :(const ltwa_file = $path))
end
