using Test
using MultiFormats

# for i in ([0, 1, 127, 128, 255, 300, 16384] .|> UInt32)
	# @info i => bitstring.(Multiformats.UVarInt(i))
# end

@testset verbose=true "UVarInt Encode Decode" begin

	for i in ([0, 1, 127, 128, 255, 300, 16384] .|> UInt32)
		@test i == UVarIntDecode(UVarInt(i))
	end

end


