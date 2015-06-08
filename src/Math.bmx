SuperStrict

Import brl.math

Type TVector
	Field x : Float
	Field y : Float
	Field z : Float
	
	Function Create:TVector(x:Float, y:Float, z:Float)
		Local vec:TVector = New TVector
		vec.x = x
		vec.y = y
		vec.z = z
		Return vec
	End Function
	
	Method Set(origin:TVector)
		Self.x = origin.x
		Self.y = origin.y
		Self.z = origin.z
	End Method
	
	Method MakeZero()
		Self.x = 0
		Self.y = 0
		Self.z = 0
	End Method
	
	Method Add:TVector(b:TVector, r:TVector=Null)
		If r = Null Then r = New TVector
		r.x = Self.x + b.x
		r.y = Self.y + b.y
		r.z = Self.z + b.z
		Return r
	End Method
	
	Method Sub:TVector(b:TVector, r:TVector=Null)
		If r = Null Then r = New TVector
		r.x = Self.x - b.x
		r.y = Self.y - b.y
		r.z = Self.z - b.z
		Return r
	End Method
	
	Method Scale:TVector(c:Float, r:TVector=Null)
		If r = Null Then r = New TVector
		r.x = c*Self.x
		r.y = c*Self.y
		r.z = c*Self.z
		Return r
	End Method
	
	Method DotProduct:Float(b:TVector)
		Return Self.x*b.x + Self.y*b.y + Self.z*b.z
	End Method

	Method Normalize:TVector(r:TVector = Null)
		If r = Null Then r = New TVector
		Local length:Float = Self.Length()
		
		r.x = Self.x/length
		r.y = Self.y/length
		r.z = Self.z/length
		Return r
	End Method

	Method Length:Float()
		Return Sqr(Self.x*Self.x + Self.y*Self.y + Self.z*Self.z)
	End Method
End Type

Type TLine
	Field a:TVector
	Field b:TVector

	Function CreateFromVectors:TLine(a:TVector, b:TVector)
		Local line:TLine = New TLine
		line.a = a
		line.b = b
		Return line
	End Function

	Function CreateFromCoords:TLine(x1:Float, y1:Float, z1:Float, x2:Float, y2:Float, z2:Float)
		Return TLine.CreateFromVectors(TVector.Create(x1, y1, z1), TVector.Create(x2, y2, z2))
	End Function

	Method Project:TVector(p:TVector, r:TVector=Null)
		If r = Null Then r = New TVector

		Local diff:TVector = Self.b.Sub(Self.a)
		Local t:Float = p.Sub(Self.a).DotProduct(diff)/diff.Length()^2
		Self.a.Add(diff.Scale(t), r)

		Return r
	End Method
End Type

Function Median:Float(x:Float[])
	Local minimum:Float = x[0]
	Local maximum:Float = x[0]
	For Local i:Int = 0 Until x.length
		If x[i] < minimum Then minimum = x[i]
		If x[i] > maximum Then maximum = x[i]
	Next

	Local lessCount:Int, equalCount:Int, greaterCount:Int
	Local maxLtGuess:Float, minGtGuess:Float
	Repeat
		Local guess:Float = (minimum + maximum)/2.0

		lessCount = 0
		equalCount = 0
		greaterCount = 0

		maxLtGuess = minimum
		minGtGuess = maximum
		For Local i:Int = 0 Until x.length
			If x[i] < guess Then
				lessCount :+1
				If x[i] > maxLtGuess Then maxLtGuess = x[i]
			Else If x[i] > guess Then
				greaterCount :+1
				If x[i] < minGtGuess Then minGtGuess = x[i]
			Else
				equalCount :+1
			EndIf
		Next

		If lessCount <= (x.length + 1) / 2 And greaterCount <= (x.length + 1) / 2 Then
			' Ende
			If lessCount >= (x.length + 1) / 2 Then
				Return maxLtGuess
			Else If lessCount + equalCount >= (x.length + 1) / 2 Then
				Return guess
			Else
				Return minGtGuess
			EndIf
		Else If lessCount > greaterCount Then
			maximum = maxLtGuess
		Else
			minimum = minGtGuess
		EndIf
	Forever
End Function

Function RMS:Float(x:Float[])
	If x.length = 0 Then Return 0

	Local sum:Float = 0
	For Local i:Int = 0 Until x.length
		sum :+ x[i]*x[i]
	Next
	Return Sqr(sum/x.length)
End Function