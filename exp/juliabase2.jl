
encodeString(a::Val{:base64}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
encodeString(a::Symbol) = encodeString(Val(a))


encode(symbol::Symbol, x::UInt8) = encode(Val(symbol), x::UInt8)
encode(::Val{:base64}, x::UInt8) = encodeString(:base64)[(x&0x3f) + 1]


struct Base64EncodePipe <: IO
    io::IO
    function Base64EncodePipe(io::IO)
        # The buffer size must be at least 3.
        pipe = new(io)
        return pipe
    end
end

function Base.unsafe_write(pipe::Base64EncodePipe, ptr::Ptr{UInt8}, n::UInt)::UInt
	encodedArray = pipe.io
	pad = '='
	padCount = 0
	bytes = unsafe_wrap(Vector{UInt8}, ptr, n)
	nCount = 0 |> UInt
	for (idx, byteArray) in enumerate(Base.Iterators.partition(bytes, 3))
		padCount = 3 - length(byteArray)
		word = zero(UInt32)
 		for (idx, byte) in enumerate(byteArray)
			word += ((byte |> UInt32) << (8*(4 - idx)))
		end
		for segment in 1:(4-padCount)
			write(encodedArray, encode(Val(:base64), ((word) >> 26) |> UInt8))
			word <<= 6
		end
		for segment in 1:padCount
			write(encodedArray, pad)
		end
		n+=3
	end
	return nCount
end


function Base.close(pipe::Base64EncodePipe)

end


function base64encode(f::Function, args...; context=nothing)
    s = IOBuffer()
    b = Base64EncodePipe(s)
    if context === nothing
        f(b, args...)
    else
        f(IOContext(b, context), args...)
    end
    close(b)
    return String(take!(s))
end

base64encode(args...; context=nothing) = base64encode(write, args...; context=context)

base64encode("Hello")

using BenchmarkTools

@time @benchmark base64encode("Hello")
