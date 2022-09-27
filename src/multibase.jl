using CSV
using DataFrames

# TODO artifact or a permanent location
basetable = download("https://raw.githubusercontent.com/multiformats/multibase/master/multibase.csv")

multibaseTable = CSV.read(open(basetable), DataFrame, stripwhitespace=true)

allowmissing(multibaseTable)

# Base Header
quote
	@enum BaseHeader $(
		(
			names(multibaseTable) .|> (x) -> "Base"*x .|> uppercase .|> Symbol
		)...
	)
end |> eval


# Base Status
baseStatusList = select(multibaseTable, "status").status .|> (x) -> "Base_"*x

quote
	@enum BaseStatus $(
		(
			unique(baseStatusList)  .|> uppercase .|> Symbol
		)...
	)
end |> eval


# Base Code
# TODO temporary 
baseCodeList = begin 
	codeUntyped = []
	codes = select(multibaseTable, "code").code
	for (idx, code) in enumerate(codes)
		push!(codeUntyped, (length(code) > 1 ? Meta.parse(code) : code[1]))
	end
	codeUntyped
end


# Base descriptions
baseDescriptions = select(multibaseTable, "description").description

abstract type AbstractMultiBase end

encodingNames = select(multibaseTable, "encoding").encoding
encodingSymbols = encodingNames .|> (x)->replace(x, "-"=>"_") .|> Symbol

for (idx, name) in enumerate(encodingNames)
	sName = "Base-"*name
	structName = join(split(sName, "-") |> (x) -> map(uppercasefirst, x)) |> Symbol

	description = baseDescriptions[idx]
	code = baseCodeList[idx]
	status = baseStatusList[idx] .|> uppercase .|> Symbol
	
	mName = replace(name, "-" => "_")

	quote 
		struct $structName <: AbstractMultiBase
		end

		getBaseName(a::$structName) = $name
		getBaseName(a::Type{$structName}) = $name
		getBaseName(a::Val{Symbol($mName)}) = $name
		getBaseName(a::Val{$code}) = $name
		

		getBaseSymbol(a::$structName) = Symbol($mName)
		getBaseSymbol(a::Type{$structName}) = Symbol($mName)
		getBaseSymbol(a::Val{Symbol($mName)}) = a
		getBaseSymbol(a::Val{$code}) = a
		
		getBase(a::Val{Symbol($mName)}) = $structName
		getBase(a::Val{$code}) = $structName
		
		getBaseCode(a::$structName) = $code
		getBaseCode(a::Type{$structName}) = $code
		getBaseCode(a::Val{Symbol($mName)}) = getBaseCode(getBase(a))
		getBaseCode(a::Val{$code}) = getBaseCode(getBase(a))
			
		getBaseStatus(a::$structName) = $status
		getBaseStatus(a::Type{$structName}) = $status
		getBaseStatus(a::Val{Symbol($mName)}) = getBaseStatus(getBase(a))
		getBaseStatus(a::Val{$code}) = getBaseStatus(getBase(a))
		
		getBaseDescription(a::$structName) = $description
		getBaseDescription(a::Type{$structName}) = $description
		getBaseDescription(a::Val{Symbol($mName)}) = getBaseDescription(getBase(a))
		getBaseDescription(a::Val{$code}) = getBaseDescription(getBase(a))

		# TODO
		Base.show(a::$structName) = begin
			"Base : $structName $(getBaseStatus(a)), $(getBaseCode(a))"
		end		

		# TODO
		Base.display(a::$structName) = begin
			"Base : $structName $(getBaseStatus(a)), $(getBaseCode(a))"
		end	
	end |> eval
end

base(name::Symbol) = getBase(Val(name))
base(id::Union{Unsigned, Char}) = getBase(Val(id))

function base(code::String)
	if code == "0x00"
		return base(0x00)
	else
		return base(code[1])
	end
end

baseCode(name::Symbol) = getBaseCode(Val(name))
baseCode(id::Union{Unsigned, Char}) = getBaseCode(Val(id))
baseName(name::Symbol) = getBaseName(Val(name))
baseName(id::Union{Unsigned, Char}) = getBaseName(Val(id))
baseSymbol(name::Symbol) = getBaseSymbol(Val(name))
baseSymbol(id::Union{Unsigned, Char}) = getBaseSymbol(Val(id))
baseStatus(name::Symbol) = getBaseStatus(Val(name))
baseStatus(id::Union{Unsigned, Char}) = getBaseStatus(Val(id))
baseDescription(name::Symbol) = getBaseDescription(Val(name))
baseDescription(ud::Union{Unsigned, Char}) = getBaseDescription(Val(id))


# TODO list is right now just a place holder like emoji needs work
encodeString(a::Val{:base2}) = "01"
encodeString(a::Val{:base8}) = "01234567"
encodeString(a::Val{:base10}) = "0123456789"
encodeString(a::Val{:base16}) = "0123456789abcdef"
encodeString(a::Val{:base16upper}) = "0123456789ABCDEF"
encodeString(a::Val{:base32hex}) = "0123456789abcdefghijklmnopqrstuv"
encodeString(a::Val{:base32hexupper}) = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
encodeString(a::Val{:base32hexpad}) = "0123456789abcdefghijklmnopqrstuv="
encodeString(a::Val{:base32hexpadupper}) = "0123456789ABCDEFGHIJKLMNOPQRSTUV="
encodeString(a::Val{:base32}) = "abcdefghijklmnopqrstuvwxyz234567"
encodeString(a::Val{:base32pad}) = "abcdefghijklmnopqrstuvwxyz234567="
encodeString(a::Val{:base32upper}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
encodeString(a::Val{:base32padupper}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567="
encodeString(a::Val{:base32z}) = "ybndrfg8ejkmcpqxot1uwisza345h769"
encodeString(a::Val{:base36}) = "0123456789abcdefghijklmnopqrstuvwxyz"
encodeString(a::Val{:base36upper}) = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
encodeString(a::Val{:base58flickr}) = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"
encodeString(a::Val{:base58btc}) = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
encodeString(a::Val{:base64}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
encodeString(a::Val{:base64pad}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
encodeString(a::Val{:base64url}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
encodeString(a::Val{:base64urlpad}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="
encodeString(a::Val{:proquint}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="
encodeString(a::Val{:base256emoji}) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="

# symbol to val dispatch
encodeString(a::Symbol) = encodeString(Val(a))


# TODO not used can be removed maybe
function buildEncodingTable(baseEnc::Symbol)
	encodeDict = Dict{UInt8, UInt8}()
	decodeDict = Dict{UInt8, UInt8}()
	encString = encodeString(baseEnc)
	for (idx, char) in enumerate(encString)
		encodeDict[UInt8(idx-1)] = UInt8(char)
		decodeDict[UInt8(char)] = UInt8(idx-1) 
	end
	return (encodeDict, decodeDict)
end


for enc in encodingSymbols
	# TODO skipping identity for now
	if enc == :identity
		continue
	end
	encName = Symbol(enc, :Enc, :Dict)
	decName = Symbol(enc, :Dec, :Dict)
	encString = encodeString(enc)
	quote
		$encName = Dict{UInt8, UInt8}()
		$decName = Dict{UInt8, UInt8}()
		for (idx, char) in enumerate($encString)
			$encName[UInt8(idx-1)] = UInt8(char)
			$decName[UInt8(char)] = UInt8(idx-1)
		end
	end |> eval

end


# TODO not used
function multiEncode(::Type{BaseType}, bytes::Vector{UInt8}) where BaseType<:AbstractMultiBase
	pushfirst!(baseCode(BaseType), bytes)
end

# TODO not used
function multiDecode(::Type{BaseType}, bytes::Vector{UInt8}) where BaseType<:AbstractMultiBase
	popfirst!(baseCode(BaseType), bytes)
end

function multiEncode(symbol::Symbol, bytes::Vector{UInt8})
	encoder = Symbol(symbol, :Enc, :Dict) |> eval
	# TODO we will have to fill with pad values based on encoder
	encodedArray = zeros(UInt8, div(div(length(bytes)*4, 3, RoundUp), 4, RoundUp)*4 |> Int)
	mask = 0x3f |> UInt32
	for (idx, byteArray) in enumerate(Base.Iterators.partition(bytes, 3))
		word = zero(UInt32)
		for (idx, byte) in enumerate(byteArray)
			word += ((byte |> UInt32) << (8*(idx-1)))
		end
		for segment in 1:4
			encodedArray[(idx-1)*4 + segment] = encoder[(word&mask) |> UInt8]
			word >>= 6
		end
	end
	return encodedArray
end

function multiDecode(symbol::Symbol, bytes::Vector{UInt8})
	decoder = Symbol(symbol, :Dec, :Dict) |> eval
	# TODO 
	decodedArray = zeros(UInt8, div(div(length(bytes)*3, 4, RoundUp), 3, RoundUp)*3 |> Int)
	mask = 0xff |> UInt32
	for (idx, byteArray) in enumerate(Base.Iterators.partition(bytes, 4))
		word = zero(UInt32)
		for (idx, byte) in enumerate(byteArray)
			word += ((decoder[(byte&mask)] |> UInt32) << (6*(idx - 1)))
		end
		for segment in 1:3
			decodedArray[(idx-1)*3 + segment] = ((word&mask) |> UInt8)
			word >>= 8
		end
	end
	return decodedArray
end

function multiWrap(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [baseCode(symbol)]) |> reverse
	pushfirst!(bytes, code...)
end

function multiUnwrap(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [baseCode(symbol)]) |> reverse
	@assert code == bytes[1:length(code)] "Given bytes doesnot match encoding $symbol"
	for i in code
		r = popfirst!(bytes)
		@assert r == i "Removed bytes content!!!"
	end
	bytes
end

export base, baseName, baseSymbol, baseCode, 
	baseStatus, baseDescription,
	multiEncode, multiDecode
