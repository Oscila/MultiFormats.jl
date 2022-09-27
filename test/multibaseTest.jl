using MultiFormats

inputString = "lffsdasdf work."

io = IOBuffer()
write(io, inputString)
seek(io, 0)

buf = read(io)

encbytes = MultiFormats.multiEncode(:base64, buf)

encbytes .|> Char |> String

decbytes = MultiFormats.multiDecode(:base64, encbytes)

outputString = decbytes .|> Char |> String

inputString == strip(outputString, '\0')
