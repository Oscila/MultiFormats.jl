
mutable struct Buffer <: IO
    data::Vector{UInt8}
    ptr::Ptr{UInt8}
    size::Int

    function Buffer(bufsize)
        data = Vector{UInt8}(undef, bufsize)
        return new(data, pointer(data), 0)
    end
end


Base.empty!(buffer::Buffer) = buffer.size = 0
Base.getindex(buffer::Buffer, i::Integer) = unsafe_load(buffer.ptr, i)
Base.setindex!(buffer::Buffer, v::UInt8, i::Integer) = unsafe_store!(buffer.ptr, v, i)
Base.firstindex(buffer::Buffer) = 1
Base.lastindex(buffer::Buffer) = buffer.size
Base.pointer(buffer::Buffer) = buffer.ptr
capacity(buffer::Buffer) = Int(pointer(buffer.data, lastindex(buffer.data) + 1) - buffer.ptr)


function consumed!(buffer::Buffer, n::Integer)
    @assert n ≤ buffer.size
    buffer.ptr += n
    buffer.size -= n
end


function read_to_buffer(io::IO, buffer::Buffer)
    offset = buffer.ptr - pointer(buffer.data)
    copyto!(buffer.data, 1, buffer.data, offset + 1, buffer.size)
    buffer.ptr = pointer(buffer.data)
    if !eof(io)
        n = min(bytesavailable(io), capacity(buffer) - buffer.size)
        unsafe_read(io, buffer.ptr + buffer.size, n)
        buffer.size += n
    end
    return
end


encodeString(a::Val{:base64}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
encodeString(a::Symbol) = encodeString(Val(a))


encode(symbol::Symbol, x::UInt8) = encode(Val(symbol), x::UInt8)
encode(::Val{:base64}, x::UInt8) = encodeString(:base64)[(x&0x3f) + 1]


struct Base64EncodePipe <: IO
    io::IO
    buffer::Buffer

    function Base64EncodePipe(io::IO)
        # The buffer size must be at least 3.
        buffer = Buffer(512)
        pipe = new(io, buffer)
        finalizer(_ -> close(pipe), buffer)
        return pipe
    end
end


function Base.unsafe_write(pipe::Base64EncodePipe, ptr::Ptr{UInt8}, n::UInt)::UInt
	ioBuffer = pipe.io
	pad = '='
	nWrites = 0
	bufSize = div(512, 3, RoundDown)*3
	outSize = div(div(bufSize*4, 3, RoundUp), 4, RoundUp)*4 |> Int
	buffer = Vector{UInt8}(undef, outSize)
	bytes = unsafe_wrap(Vector{UInt8}, ptr, n)
	padCount = Ref(0)
	for (bIdx, bufRange) in enumerate(Base.Iterators.partition(1:n, bufSize))
		for (pIdx, ptrRange) in enumerate(Base.Iterators.partition(bufRange, 3))
			padCount[] = 3 - length(ptrRange)
			word = zero(UInt32)
	 		for (idx, ptrIdx) in enumerate(ptrRange)
				word += ((bytes[ptrIdx] |> UInt32) << (8*(4 - idx)))
			end
			for segment in 1:(4-padCount[])
				buffer[(pIdx-1)*4 + segment] = encode(Val(:base64), ((word) >> 26) |> UInt8)
				word <<= 6
			end
			for segment in 1:padCount[]
				buffer[(pIdx-1)*4 + length(ptrRange) + segment + 1] = pad
			end
			nWrites+=(3-padCount[])
		end
		write(ioBuffer, buffer[1: (div(div(length(bufRange)*4, 3, RoundUp), 4, RoundUp)*4 |> Int)])
	end
	return nWrites
end


# 
# function Base.unsafe_write(pipe::Base64EncodePipe, ptr::Ptr{UInt8}, n::UInt)::UInt
	# ioBuffer = pipe.io
	# pad = '='
	# ptrs = 0:n-1
	# nWrites = 0
	# bufSize = n
	# outSize = div(div(bufSize*4, 3, RoundUp), 4, RoundUp)*4 |> Int
	# buffer = Vector{UInt8}(undef, outSize)
	# bytes = unsafe_wrap(Vector{UInt8}, ptr, n)
	# padCount = Ref(0)
	# for (bIdx, bufRange) in enumerate(Base.Iterators.partition(1:n, bufSize))
		# for (pIdx, ptrRange) in enumerate(Base.Iterators.partition(bufRange, 3))
			# padCount[] = 3 - length(ptrRange)
			# word = zero(UInt32)
	 		# for (idx, ptrIdx) in enumerate(ptrRange)
				# word += ((bytes[(ptrIdx % (bufSize)) + 1] |> UInt32) << (8*(4 - idx)))
			# end
			# for segment in 1:(4-padCount[])
				# buffer[(pIdx-1)*4 + segment] = encode(Val(:base64), ((word) >> 26) |> UInt8)
				# word <<= 6
			# end
			# for segment in 1:padCount[]
				# buffer[(pIdx-1)*3 + length(ptrRange) + segment-1] = pad
			# end
			# nWrites += (3-padCount[])
		# end
		# write(ioBuffer, buffer)
	# end
	# return nWrites
# end


# function Base.write(pipe::Base64EncodePipe, x::UInt8)
    # buffer = pipe.buffer
    # buffer[buffer.size+=1] = x
    # if buffer.size == 3
        # unsafe_write(pipe, C_NULL, 0)
    # end
    # return 1
# end

function Base.close(pipe::Base64EncodePipe)
		
end



ioencoder = Base64EncodePipe(io);


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

using BenchmarkTools

a = rand(44323)

using Base64

bout = @time @benchmark Base64.base64encode(a)

bout

b64out = @time @benchmark b64out = base64encode(a)

b64out
