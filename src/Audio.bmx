SuperStrict

Import vertex.openal
Import "PcmCodec.bmx"
Import "FloatRingBuffer.bmx"
Import "FastFourierTransform.bmx"
Import "Math.bmx"

Type TAudio
	Function Init()
		TOpenAL.Open()
		TOpenAL.InitAL()
		TOpenAL.InitALC()
	End Function
	
	Function Close()
		TOpenAL.Close()
	End Function
End Type

' Capture device
Type TRecorder
	Const SAMPLE_RATE:Int = 44100

	Field recorder:Byte Ptr
	Field codec:TPcmCodec
	Field buffer:Byte[]
	Field frameManager:TFrameManager
 
	Global T:String
	' Returns a list of recorder specifier
	Function Enumerate:String[]()
		Local List       : Byte Ptr, ..
		      Specifiers : String[], ..
		      Specifier  : String

		' Getting null-terminated specifier list
		List = alcGetString(Null, ALC_CAPTURE_DEVICE_SPECIFIER)
		If Not List Then
			Local ErrorCode:Int
		
			ErrorCode = alcGetError(Null)
			If ErrorCode <> ALC_NO_ERROR Then
				Throw("Can't enumerate recorder list~n" + ..
				      " (ALC Error Code = " + ErrorCode + ")")
			Else
				Return Null
			EndIf
		EndIf

		' Separate specifier by null character
		While List[0]
			Specifiers = Specifiers[..Specifiers.Length + 1]
			Specifiers[Specifiers.Length - 1] = String.FromCString(List)
			List :+ Specifiers[Specifiers.Length - 1].Length + 1
		Wend

		Return Specifiers
	End Function

	' Returns default recorder specifier
	Function DefaultRecorder:String()
		Local Specifier : Byte Ptr

		Specifier = alcGetString(Null, ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER)
		If Not Specifier Then
			Local ErrorCode:Int
		
			ErrorCode = alcGetError(Null)
			If ErrorCode <> ALC_NO_ERROR Then
				Throw("Unable to detect default recorder~n" + ..
				      " (ALC Error Code = " + ErrorCode + ")")
			Else
				Throw("Unable to detect default recorder")
			EndIf
		EndIf
		
		Return String.FromCString(Specifier)
	End Function

	Method addListener(listener:TFrameListener, specification:TFrameSpecification)
		frameManager.addListener(listener, specification)
	End Method

	Method removeListener(listener:TFrameListener)
		frameManager.removeListener(listener)
	End Method

	Method Open(Name:String=Null)
		codec = TPcmCodec.Create(TPcmCodec.SIGNED_16_BIT_LITTLE_ENDIAN)

		Local sampleSize:Int = codec.getSampleSizeInBytes()
		Local seconds:Float = 3 ' buffer time [s]
		
		recorder = alcCaptureOpenDevice(Name, SAMPLE_RATE, AL_FORMAT_MONO16, seconds*SAMPLE_RATE*sampleSize)
		If Not recorder Then
			Local ErrorCode:Int

			ErrorCode = alcGetError(Null)
			If ErrorCode <> ALC_NO_ERROR Then
				Throw("Unable to open recorder~n" + ..
				      " (ALC Error Code = " + ErrorCode + ")")
			Else
				Throw("Unable to open recorder")
			EndIf
		EndIf
		
		buffer = New Byte[seconds*SAMPLE_RATE*sampleSize]
		frameManager = TFrameManager.Create(SAMPLE_RATE)
	End Method

	' Start recording
	Method Start()
		If Not recorder Then Throw("There is no recorder to start")
		alcCaptureStart(recorder)
	End Method

	' Stop recording
	Method Stop()
		If Not recorder Then Throw("There is no recorder to stop")
		alcCaptureStop(recorder)
	End Method

	Method Delete()
		Self.Close()
	End Method

	' Shutdown recorder
	Method Close()
		If recorder Then
			Self.Stop()
			alcCaptureCloseDevice(recorder)
			recorder = Null
		EndIf
	End Method

	Method Process()
		If Not recorder Then Throw("There is no recorder to process")

		Local sampleSize:Int = codec.getSampleSizeInBytes()
		Local numAvailableSamples:Int
		alcGetIntegerv(recorder, ALC_CAPTURE_SAMPLES, 4, Varptr(numAvailableSamples))

		Local numBytesToRead:Int = Min(numAvailableSamples*sampleSize, buffer.length)
		Local numSamplesToRead:Int = numBytesToRead/sampleSize
		alcCaptureSamples(recorder, buffer, numSamplesToRead)

		For Local i:Int = 0 Until numSamplesToRead
			Local offset:Int = i*sampleSize
			Local sample:Float = codec.decodeMono(buffer, offset)
			frameManager.putMonoSample(sample)
		Next

		frameManager.processFrames()
	End Method
End Type

Type TFrame
	Field begin:Long ' inkl
	Field finish:Long ' inkl
	Field sampleRate:Double
	Field samples:Float[]
End Type

Type TFrameSpecification
	Field size:Int
	Field hopSize:Int
	
	Method Equals:Int(other:TFrameSpecification)
		If other = Null Then
			Return False
		Else
			Return Self.size = other.size And Self.hopSize = other.hopSize
		EndIf
	End Method
End Type

Type TFrameListener
	Method onFrameAvailable(frame:TFrame) Abstract
End Type

Type TListenerInformation
	Field specification:TFrameSpecification
	Field nextFrameBegin:Long = 0
	
	Method getNextFrameBegin:Long()
			Return nextFrameBegin
	End Method

	Method nextFrame()
		nextFrameBegin :+ specification.hopSize
	End Method
End Type

Type TListenerPair
	Field key:TFrameListener
	Field value:TListenerInformation
End Type

Type TFrameManager
	Const BUFFER_LENGTH:Float = 5 ' [s]
	
	Field sampleRate : Double
	Field sampleBuffer : TFloatRingBuffer
	Field listenerInformations : TList = CreateList()
	
	Function Create:TFrameManager(sampleRate:Double)
		Local fm:TFrameManager = New TFrameManager
		fm.sampleRate = sampleRate
		Local capacity:Int = Ceil(BUFFER_LENGTH*sampleRate)
		fm.sampleBuffer = TFloatRingBuffer.Create(capacity)
		Return fm
	End Function 
	
	Method addListener(listener:TFrameListener, specification:TFrameSpecification)
		Local information:TListenerInformation = New TListenerInformation 
		information.specification = specification
		Local pair:TListenerPair = New TListenerPair
		pair.key = listener
		pair.value = information
		listenerInformations.AddLast(pair)
	End Method

	Method removeListener(listener:TFrameListener)
		Local toDelete:TListenerPair = Null
		For Local pair:TListenerPair = EachIn listenerInformations
			If pair.key = listener Then
				toDelete = pair
				Exit
			EndIf
		Next
		ListRemove(listenerInformations, toDelete)
	End Method
	
	Method putMonoSample(sample:Float)
		sampleBuffer.put(sample)
	End Method
	
	Method processFrames()
		Local bufferCount:Long = sampleBuffer.GetCount()
		Local bufferSize:Int = sampleBuffer.GetSize()

		For Local pair:TListenerPair = EachIn listenerInformations
			Local information:TListenerInformation = pair.value
			While isFrameAvailable(bufferCount, bufferSize, information)
				Local frameBegin:Long = information.getNextFrameBegin()
				Local frameSize:Int = information.specification.size

				Local samples:Float[] = New Float[frameSize]
				sampleBuffer.peak(frameBegin, samples, 0, frameSize)
				Local frame:TFrame = New TFrame
				frame.begin = frameBegin
				frame.finish = frameBegin + frameSize - 1
				frame.sampleRate = Self.sampleRate
				frame.samples = samples

				Local listener:TFrameListener = pair.key
				listener.onFrameAvailable(frame)

				information.nextFrame()
			Wend
		Next
	End Method

	Method isFrameAvailable:Int(bufferCount:Long, bufferSize:Int, information:TListenerInformation)
		Local oldestSample:Long = bufferCount - bufferSize
		Local newestSample:Long = bufferCount

		Local frameSize:Int = information.specification.size
		If information.nextFrameBegin >= oldestSample ..
				And (information.nextFrameBegin + frameSize) <= newestSample Then
			Return True
		Else
			Return False
		EndIf
	End Method
End Type

Type TOnsetListener
	Method OnOnset(begin:Long, novelty:Float) Abstract
End Type

Type TOnsetDetector Extends TFrameListener
	Field listeners:TList = CreateList()
	Field spec:TFrameSpecification
	Field fft:TFastFourierTransform
	Field lastRe:Float[]
	Field lastIm:Float[]
	Field currRe:Float[]
	Field currIm:Float[]
	Field baseThreshold:Float
	Field weight:Float
	Field novelties:TFloatRingBuffer
	Field noveltiesBuffer:Float[]
	
	Function Create:TOnsetDetector(windowSize:Int, baseThreshold:Float, weight:Float)
		Local detector:TOnsetDetector = New TOnsetDetector
		
		detector.spec = CreateSpecification()
		detector.fft = TFastFourierTransform.Create(detector.spec.size)
		detector.lastRe = New Float[detector.spec.size]
		detector.lastIm = New Float[detector.spec.size]
		detector.currRe = New Float[detector.spec.size]
		detector.currIm = New Float[detector.spec.size]
		detector.baseThreshold = baseThreshold
		detector.weight = weight
		detector.novelties = TFLoatRingBuffer.Create(windowSize)
		detector.noveltiesBuffer = New Float[windowSize]
		
		Return detector
	End Function
	
	Method AddListener(listener:TOnsetListener)
		Self.listeners.AddLast(listener)
	End Method
	
	Method RemoveListener(listener:TOnsetListener)
		ListRemove(Self.listeners, listener)
	End Method
	
	Method OnFrameAvailable(frame:TFrame)
		fft.forwardReal(frame.samples)
		MemCopy currRe, fft.real, currRe.length*4
		MemCopy currIm, fft.imaginary, currIm.length*4
		
		Local distance:Float = ComputeDistance()
		novelties.Put(distance)
		If novelties.GetSize() = novelties.GetCapacity() Then
			novelties.peakLast(noveltiesBuffer, 0, novelties.GetCapacity())
			Local middle:Int = noveltiesBuffer.length/2
			Local x:Float[] = noveltiesBuffer
			Local localMax:Int = x[middle-1] < x[middle] And x[middle] > x[middle+1]
			If localMax Then
				Local median:Float = Median(noveltiesBuffer)
				Local threshold:Float = baseThreshold + weight*median
				Local isPeak:Int = x[middle] > threshold
				
				If isPeak Then
					Local time:Long = frame.begin - middle*spec.hopSize
					NotifyOnset(time, x[middle])
				EndIf
			EndIf
		EndIf
		MemCopy lastRe, currRe, currRe.length*4
		MemCopy lastIm, currIm, currIm.length*4
	End Method
	
	Method NotifyOnset(begin:Long, novelty:Float)
		For Local listener:TOnsetListener = EachIn listeners
			listener.OnOnset(begin, novelty)
		Next
	End Method
	
	Method Reset()
		lastRe = Null
		lastIm = Null
		novelties.Clear()
	End Method
	
	Method ComputeDistance:Float()
		Local numBins:Int = lastRe.length
		
		Local distance:Float = 0
		For Local k:Int = 0 Until numBins
			Local diffRe:Float = currRe[k] - lastRe[k]
			Local diffIm:Float = currIm[k] - lastIm[k]
			distance :+ Sqr(diffRe * diffRe + diffIm * diffIm)
		Next
		Return distance
	End Method

	Function CreateSpecification:TFrameSpecification()
		Local spec:TFrameSpecification = New TFrameSpecification
		spec.size = 512
		spec.hopSize = 512
		Return spec
	End Function
End Type