
const MSB = 0b10000000

export UVarInt, UVarIntDecode

function UVarInt(n::Unsigned)
	(mask = (zero(n) | typemax(UInt8))) |> bitstring
	nbytes = sizeof(n)
	byteArray = UInt8[]
	if n == 0
		return push!(byteArray, n |> UInt8)
	end
	for idx in 1:nbytes
		if n == 0
			return byteArray
		end
		nMaskVal = (mask&n)
		byteVal = (nMaskVal |> UInt8) & ~MSB
		push!(byteArray, n >= MSB ? byteVal | MSB : byteVal)
		n >>= 7
	end
	return byteArray
end


function UVarIntDecode(array::AbstractArray)
	x = 0
	for (idx, byte) in enumerate(array)
		contBit = (byte .& MSB == MSB)
		byteVal = (contBit ? (byte .& ~MSB) : byte) |> Int64
		iVal = (byteVal << (7*(idx-1)))
		x += iVal
	end
	return x
end

