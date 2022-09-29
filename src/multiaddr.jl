using CSV
using DataFrames
using Downloads

# TODO artifact or a permanent location
protocoltable = Downloads.download("https://raw.githubusercontent.com/multiformats/multiaddr/master/protocols.csv")

multiprotocolTable = CSV.read(open(protocoltable), DataFrame, stripwhitespace=true)

allowmissing(multiprotocolTable)

# Protocol Header
quote
	@enum ProtocolHeader $(
		(
			names(multiprotocolTable) .|> (x) -> "Protocol"*x .|> uppercase .|> Symbol
		)...
	)
end |> eval


# Protocol Size
protocolSizeList = select(multiprotocolTable, "size").size .|> (x) -> "Protocol_"*x

quote
	@enum AddrSize $(
		(
			unique(protocolSizeList)  .|> uppercase .|> Symbol
		)...
	)
end |> eval


# Protocol Code
# TODO temporary 
protocolCodeList = select(multiprotocolTable, "code").code

# Protocol Comments
protocolComments = select(multiprotocolTable, "comment").comment

abstract type AbstractMultiAddrProtocol end
# abstract type AbstractMultiAddr end

for (idx, name) in enumerate(select(multiprotocolTable, "name").name)
	sName = "Protocol-"*name
	structName = join(split(sName, "-") |> (x) -> map(uppercasefirst, x)) |> Symbol

	comment = protocolComments[idx]
	code = protocolCodeList[idx]
	size = protocolSizeList[idx] .|> uppercase .|> Symbol
	
	mName = replace(name, "-" => "_")

	# TODO 421 code repeats and is in fovor of p2p over ipfs
	# we need to handle this for backcompatibility
	if name == "ipfs"
		continue
	end

	quote 
		struct $structName <: AbstractMultiAddrProtocol
		end

		getProtocolName(a::$structName) = $name
		getProtocolName(a::Type{$structName}) = $name
		getProtocolName(a::Val{Symbol($mName)}) = $name
		getProtocolName(a::Val{$code}) = $name
		

		getProtocolSymbol(a::$structName) = Symbol($mName)
		getProtocolSymbol(a::Type{$structName}) = Symbol($mName)
		getProtocolSymbol(a::Val{Symbol($mName)}) = a
		getProtocolSymbol(a::Val{$code}) = a
		
		getProtocol(a::Val{Symbol($mName)}) = $structName
		getProtocol(a::Val{$code}) = $structName
		
		getProtocolCode(a::$structName) = $code
		getProtocolCode(a::Type{$structName}) = $code
		getProtocolCode(a::Val{Symbol($mName)}) = getProtocolCode(getProtocol(a))
		getProtocolCode(a::Val{$code}) = getProtocolCode(getProtocol(a))
			
		getProtocolSize(a::$structName) = $size
		getProtocolSize(a::Type{$structName}) = $size
		getProtocolSize(a::Val{Symbol($mName)}) = getProtocolSize(getProtocol(a))
		getProtocolSize(a::Val{$code}) = getProtocolSize(getProtocol(a))
		
		getProtocolComment(a::$structName) = $comment
		getProtocolComment(a::Type{$structName}) = $comment
		getProtocolComment(a::Val{Symbol($mName)}) = getProtocolComment(getProtocol(a))
		getProtocolComment(a::Val{$code}) = getProtocolComment(getProtocol(a))

		# TODO
		Base.show(a::$structName) = begin
			"Protocol : $structName $(getProtocolSize(a)), $(getProtocolCode(a))"
		end		

		# TODO
		Base.display(a::$structName) = begin
			"Protocol : $structName $(getProtocolSize(a)), $(getProtocolCode(a))"
		end	
	end |> eval
end

protocol(name::Symbol) = getProtocol(Val(name))
protocol(id::Union{Unsigned, Char}) = getProtocol(Val(id))

function protocol(code::String)
	if code == "0x00"
		return protocol(0x00)
	else
		return protocol(code[1])
	end
end

protocolCode(name::Symbol) = getProtocolCode(Val(name))
protocolCode(id::Union{Unsigned, Char}) = getProtocolCode(Val(id))
protocolName(name::Symbol) = getProtocolName(Val(name))
protocolName(id::Union{Unsigned, Char}) = getProtocolName(Val(id))
protocolSymbol(name::Symbol) = getProtocolSymbol(Val(name))
protocolSymbol(id::Union{Unsigned, Char}) = getProtocolSymbol(Val(id))
protocolSize(name::Symbol) = getProtocolSize(Val(name))
protocolSize(id::Union{Unsigned, Char}) = getProtocolSize(Val(id))
protocolComment(name::Symbol) = getProtocolComment(Val(name))
protocolComment(ud::Union{Unsigned, Char}) = getProtocolComment(Val(id))

# TODO
function encodeProtocol(::Type{ProtocolType}, bytes::Vector{UInt8}) where ProtocolType<:AbstractMultiAddrProtocol
	pushfirst!(protocolCode(ProtocolType), bytes)
end

# TODO
function decodeProtocol(::Type{ProtocolType}, bytes::Vector{UInt8}) where ProtocolType<:AbstractMultiAddrProtocol
	popfirst!(protocolCode(ProtocolType), bytes)
end

function encodeProtocol(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [protocolCode(symbol)]) |> reverse
	pushfirst!(bytes, code...)
end

function decodeProtocol(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [ProtocolCode(symbol)]) |> reverse
	@assert code == bytes[1:length(code)] "Given bytes doesnot match encoding $symbol"
	for i in code
		r = popfirst!(bytes)
		@assert r == i "Removed bytes content!!!"
	end
	bytes
end

export protocol, protocolName, protocolSymbol, protocolCode, 
	protocolSize, protocolComment,
	encodeProtocol, decodeProtocol

