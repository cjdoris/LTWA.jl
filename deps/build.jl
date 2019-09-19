const table_url = "https://www.issn.org/wp-content/uploads/2013/09/LTWA_20160915.txt"
const table_file = joinpath(@__DIR__, "LTWA_20160915.txt")

if !isfile(table_file)
	@info "Downloading $(repr(table_url)) to $(repr(table_file))"
	download(table_url, table_file)
end

@assert isfile(table_file)

open("deps.jl", "w") do io
	println(io, "const ltwa_file = $(repr(table_file))")
end
