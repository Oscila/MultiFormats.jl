using Test

for (root, dirs, files) in walkdir(".")
	for file in files
		if file == "runtests.jl"
			continue
		end
		include(file)
	end
end
