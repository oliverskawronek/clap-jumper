SuperStrict

Import "Util.bmx"

Type TPcmCodec
	Const SIGNED_8_BIT:Int = 1
	Const UNSIGNED_8_BIT:Int = 2
	Const SIGNED_16_BIT_LITTLE_ENDIAN:Int = 3
	Const SIGNED_16_BIT_BIG_ENDIAN:Int = 4
	Const UNSIGNED_16_BIT_LITTLE_ENDIAN:Int = 5
	Const UNSIGNED_16_BIT_BIG_ENDIAN:Int = 6

	Field format:Int

	Function Create:TPcmCodec(format:Int)
		Select format
			Case SIGNED_8_BIT
			Case UNSIGNED_8_BIT
			Case SIGNED_16_BIT_LITTLE_ENDIAN
			Case SIGNED_16_BIT_BIG_ENDIAN
			Case UNSIGNED_16_BIT_LITTLE_ENDIAN
			Case UNSIGNED_16_BIT_BIG_ENDIAN
			Default
				Throw "Unsupported format " + format
		End Select
		Local codec:TPcmCodec = New TPcmCodec
		codec.format = format
		Return codec
	End Function

	Method getSampleSizeInBytes:Int()
		Select format
			Case SIGNED_8_BIT Return 1
			Case UNSIGNED_8_BIT Return 1
			Case SIGNED_16_BIT_LITTLE_ENDIAN Return 2
			Case SIGNED_16_BIT_BIG_ENDIAN Return 2
			Case UNSIGNED_16_BIT_LITTLE_ENDIAN Return 2
			Case UNSIGNED_16_BIT_BIG_ENDIAN Return 2
			Default Throw "Unsupported format " + format
		End Select
	End Method

	Method decodeMono:Float(buffer:Byte Ptr, offset:Int)
		Local sample:Float
		Select format
			Case SIGNED_8_BIT
				Return decodeSigned8Bit(buffer, offset)
			Case UNSIGNED_8_BIT
				Return decodeUnsigned8Bit(buffer, offset)
			Case SIGNED_16_BIT_LITTLE_ENDIAN
				Return decodeSigned16BitLittleEndian(buffer, offset)
			Case SIGNED_16_BIT_BIG_ENDIAN
				Return decodeSigned16BitBigEndian(buffer, offset)
			Case UNSIGNED_16_BIT_LITTLE_ENDIAN
				Return decodeUnsigned16BitLittleEndian(buffer, offset)
			Case UNSIGNED_16_BIT_BIG_ENDIAN
				Return decodeUnsigned16BitBigEndian(buffer, offset)
		End Select

		Return Clamp(sample, -1, 1)
	End Method
	
	Function decodeSigned8Bit:Float(buffer:Byte Ptr, offset:Int)
		Local sampleInt:Int = buffer[offset];
		Local sample:Float = Float(sampleInt) / Float($7f)
		Return sample
	End Function

	Function decodeUnsigned8Bit:Float(buffer:Byte Ptr, offset:Int)
		Local sampleInt:Int = (buffer[offset] & $ff) - $80;
		Local sample:Float = Float(sampleInt) / Float($7f)
		Return sample
	End Function
	
	Function decodeSigned16BitBigEndian:Float(buffer:Byte Ptr, offset:Int)
		Local lowerB:Byte, higherB:Byte
		higherB = buffer[offset]
		lowerB = buffer[offset + 1]
		Local sampleInt:Int = (higherB Shl 8) | (lowerB & $ff)
		If sampleInt & $8000 Then sampleInt = $FFFF8000 | (sampleInt & $7FFF)
		Local sample:Float = Float(sampleInt) / Float($7fff)
		Return sample
	End Function

	Function decodeSigned16BitLittleEndian:Float(buffer:Byte Ptr, offset:Int)
		Local lowerB:Byte, higherB:Byte
		higherB = buffer[offset + 1]
		lowerB = buffer[offset]
		Local sampleInt:Int = (higherB Shl 8) | (lowerB & $ff)
		If sampleInt & $8000 Then sampleInt = $FFFF8000 | (sampleInt & $7FFF)
		Local sample:Float = Float(sampleInt) / Float($7fff)
		Return sample
	End Function

	Function decodeUnsigned16BitBigEndian:Float(buffer:Byte Ptr, offset:Int)
		Local lowerB:Byte, higherB:Byte
		higherB = buffer[offset]
		lowerB = buffer[offset + 1]
		Local sampleInt:Int = (((higherB & $ff) Shl 8) | (lowerB & $ff)) - $8000
		Local sample:Float = Float(sampleInt) / Float($7fff)
		Return sample
	End Function

	Function decodeUnsigned16BitLittleEndian:Float(buffer:Byte Ptr, offset:Int)
		Local lowerB:Byte, higherB:Byte
		higherB = buffer[offset + 1]
		lowerB = buffer[offset]
		Local sampleInt:Int = (((higherB & $ff) Shl 8) | (lowerB & $ff)) - $8000
		Local sample:Float = Float(sampleInt) / Float($7fff)
		Return sample
	End Function
End Type
