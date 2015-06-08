SuperStrict

Import "Audio.bmx"

Type TClapListener
	Method OnClap(begin:Long, state:Int) Abstract
End Type

Type TClapSwitch Extends TOnsetListener
	Const ON:Int = 1
	Const OFF:Int = 2

	Field sampleRate:Double
	Field state:Int = OFF
	Field onsets:Long[] = New Long[3]
	Field listeners:TList = CreateList()

	Function Create:TClapSwitch(sampleRate:Double)
		Local switch:TClapSwitch = New TClapSwitch
		switch.sampleRate = sampleRate
		switch.onsets[2] = -9999
		Return switch
	End Function
	
	Method AddListener(listener:TClapListener)
		listeners.AddLast(listener)
	End Method
	
	Method RemoveListener(listener:TClapListener)
		ListRemove(listeners, listener)
	End Method

	Method OnOnset(begin:Long, novelty:Float)
		PutOnset(begin)
		
		Local timeDiffBefore:Double = SamplesToSeconds(onsets[1] - onsets[0])
		Local timeDiffBetween:Double = SamplesToSeconds(onsets[2] - onsets[1])
		
		If timeDiffBefore > 1.0 And timeDiffBetween < 0.5 Then
			If IsOn() Then
				state = OFF
			Else
				state = ON
			EndIf
			Local middle:Long = onsets[1] + (onsets[2] - onsets[1])/2
			NotifyClap(middle, state)
		EndIf
	End Method
	
	Method NotifyClap(begin:Long, state:Int)
		For Local listener:TClapListener = EachIn listeners
			listener.OnClap(begin, state)
		Next
	End Method
	
	Method SamplesToSeconds:Double(samples:Long)
		Return samples/sampleRate
	End Method
	
	Method PutOnset(begin:Long)
		For Local i:Int = 0 To onsets.length - 2
			onsets[i] = onsets[i + 1]
		Next
		onsets[onsets.length-1] = begin
	End Method
	
	Method IsOn:Int()
		Return state = ON
	End Method
	
	Method IsOff:Int()
		Return state = OFF
	End Method
End Type
