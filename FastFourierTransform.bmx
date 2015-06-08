SuperStrict

Import "Util.bmx"

Type TFastFourierTransform
	Field size:Int
	Field imaginary:Float[]
	Field real:Float[]
	
	Field reverse:Int[]
	Field sinLookup:Float[]
	Field cosLookup:Float[]
	
	Function Create:TFastFourierTransform(size:Int)
		Local fft:TFastFourierTransform = New TFastFourierTransform
		If Not IsPowerOfTwo(size) Then Throw "size " + size + " is not a power of two"
		
		fft.size = size
		fft.imaginary = New Float[size]
		fft.real = New Float[size]
		
		fft.reverse = New Int[size]
		fft.reverse[0] = 0
		Local limit:Int = 1, bit:Int = size/2
		While limit < size
			For Local i:Int = 0 Until limit
				fft.reverse[i + limit] = fft.reverse[i] + bit
			Next

			limit = Rol(limit, 1)
			bit = Ror(bit, 1)
		Wend
		
		fft.sinLookup = New Float[size]
		fft.cosLookup = New Float[size]
		fft.fillLookupTables()
		
		Return fft
	End Function
	
	Method fillLookupTables()
		For Local i:Int = 0 Until size
			Local rad:Float = -Pi/i
			Local deg:Float = RadToDeg(rad)
			sinLookup[i] = Sin(deg)
			cosLookup[i] = Cos(deg)
		Next
	End Method
	
	' Forward transform of a real valued signal
	Method forwardReal(samples:Float[])
		If samples.length <> size Then Throw "samples size " + samples.length + " <> size " + size
		bitReverseSamplesReal(samples)
		fft() 
	End Method
	
	' Forward transform of a complex valued signal
	Method forwardComplex(real:Float[], imaginary:Float[])
		If real.length <> size Or imaginary.length <> size Then Throw "length of real and imaginary must be " + size
		bitReverseSamplesComplex(real, imaginary)
		fft()
	End Method
	
	Method backwardReal(samples:Float[])
		If samples.length <> size Then Throw "samples size " + samples.length + " <> size " + size
		bitReverseSamplesReal(samples)
		fft()
		For Local i:Int = 0 Until size
			real[i] :/ size
			imaginary[i] :/ -size
		Next
	End Method
	
	Method backwardComplex(real:Float[], imaginary:Float[])
		If real.length <> size Or imaginary.length <> size Then Throw "length of real and imaginary must be " + size
		bitReverseAndConjugateSamples(real, imaginary)
		fft()
		For Local i:Int = 0 Until size
			real[i] :/ size
			imaginary[i] :/ -size
		Next
	End Method
	
	Method GetSize:Int()
		Return size
	End Method
	
	Method bitReverseSamplesReal(samples:Float[])
		For Local i:Int = 0 Until size
			real[i] = samples[reverse[i]]
			imaginary[i] = 0.0
		Next
	End Method
	
	Method bitReverseSamplesComplex(real:Float[], imaginary:Float[])
		For Local i:Int = 0 Until size
			Self.real[i] = real[reverse[i]]
			Self.imaginary[i] = imaginary[reverse[i]]
		Next
	End Method
	
	Method bitReverseAndConjugateSamples(real:Float[], imaginary:Float[])
		For Local i:Int = 0 Until size
			Self.real[i] = real[reverse[i]]
			Self.imaginary[i] = -imaginary[reverse[i]]
		Next
	End Method

	Method fft()
		Local halfSize:Int = 1
		While halfSize < size
			Local phaseShiftStepR:Float = cosLookup[halfSize]
			Local phaseShiftStepI:Float = sinLookup[halfSize]

			Local currentPhaseShiftR:Float = 1.0
			Local currentPhaseShiftI:Float = 0.0
			For Local fftStep:Int = 0 Until halfSize
				Local i:Int = fftStep
				While i < size
					Local off:Int = i + halfSize
					Local tr:Float = currentPhaseShiftR*real[off] - currentPhaseShiftI*imaginary[off]
					Local ti:Float = currentPhaseShiftR*imaginary[off] + currentPhaseShiftI*real[off]
					real[off] = real[i] - tr
					imaginary[off] = imaginary[i] - ti
					real[i] :+ tr
					imaginary[i] :+ ti
					
					i :+ 2*halfSize
				Wend

				Local tmpR:Float = currentPhaseShiftR
				currentPhaseShiftR = tmpR*phaseShiftStepR - currentPhaseShiftI*phaseShiftStepI
				currentPhaseShiftI = tmpR*phaseShiftStepI + currentPhaseShiftI*phaseShiftStepR
			Next
			
			halfSize :* 2
		Wend
	End Method

	Method fillMagnitudeSpectrum(spectrum:Float[], firstHalfOnly:Int=True)
		Local n:Int
		If firstHalfOnly Then
			n = size/2
		Else
			n = size
		EndIf
		For Local k:Int = 0 Until n
			spectrum[k] = Sqr(real[k]*real[k] + imaginary[k]*imaginary[k])
		Next
	End Method 
	
	Method normalizeMagnitudeSpectrum(spectrum:Float[], firstHalfOnly:Int=True, realValuedInput:Int=True)
		Local scale:Float
		If realValuedInput Then
			scale = 2.0 / size
		Else
			scale = 1.0 / size
		EndIf
		Local n:Int
		If firstHalfOnly Then
			n = size/2
		Else
			n = size
		EndIf
		For Local k:Int = 0 Until n
			spectrum[k] :* scale
		Next
	End Method 
	
	Method binToFrequency:Double(i:Int, size:Int, sampleRate:Double)
		Local bandWidth:Double = getBandWidth(size, sampleRate);
		Return i * bandWidth
	End Method 
	
	Method frequencyToBin:Int(frequency:Double, size:Int, sampleRate:Double)
		Return size * (frequency / sampleRate) ' todo round
	End Method 
	
	Method getBandWidth:Double(size:Int, sampleRate:Double)
		Return (2.0/size) * (sampleRate/2.0)
	End Method 
End Type
