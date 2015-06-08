SuperStrict

Import brl.math
Import sidesign.minib3d

Function PrintLn(str:String)
	WriteStdout str + "~n"
End Function

Function IsPowerOfTwo:Int(i:Int)
		Return (i > 0) And (i & (i - 1)) = 0
End Function

Function GetNextPowerOfTwo:int(i:Int)
	If IsPowerOfTwo(i) Then Return i

	If i > 0 Then
		Local exponent:Int = 32 - NumberOfLeadingZeros(i)
		Return 1 Shl exponent ' = 2^exponent
	Else
		Return 1 ' = 2^0
	EndIf
End Function

Function NumberOfLeadingZeros:Int(i:Int)
	Local n:Int

	If i = 0 Then Return 32
	n = 0
	If i <= $0000FFFF Then
		i = n +16
		i = i Shl 16
	EndIf
	If i <= $00FFFFFF Then
		i = n + 8
		i = i Shl 8
	EndIf
	If i <= $0FFFFFFF Then
		i = n + 4
		i = i Shl 4
	EndIf
	If i <= $3FFFFFFF Then
		i = n + 2
		i = i Shl 2
	EndIf
	If i <= $7FFFFFFF Then
		i = n + 1
	EndIf
	Return n
End Function

Function Rol:Int(value:Int, shift:Int)
	Return (value Shl shift) | (value Shr (32 - shift))
End Function

Function Ror:Int(value:Int, shift:Int)
  Return (value Shr shift) | (value Shl (32 - shift))
End Function

Function RadToDeg:Float(rad:Float)
	Return rad / (2*Pi) * 360.0
End Function

Function DegToRad:Float(deg:Float)
	Return deg / 360.0 * (2*Pi)
End Function

Function CreateQuad:TMesh(parent:TEntity=Null)
	Local mesh:TMesh = TMesh.CreateMesh(parent)
	Local surface:TSurface = mesh.CreateSurface()
	
	Local v0:Int = surface.AddVertex(-1, 0, 1, 0, 0)
	Local v1:Int = surface.AddVertex( 1, 0, 1, 1, 0)
	Local v2:Int = surface.AddVertex( 1, 0, -1, 1, 1)
	Local v3:Int = surface.AddVertex(-1, 0, -1, 0, 1)
	surface.AddTriangle(v0, v1, v2)
	surface.AddTriangle(v2, v3, v0)
	
	Return mesh
End Function

Function CameraLookAt(camera:TCamera, entity:TEntity)
	Local pitch:Float = DeltaPitch(camera, entity)
	Local yaw:Float = DeltaYaw(camera, entity)
	camera.RotateEntity(pitch, yaw, 0)
End Function

Function HsvToRgb(h:Float, s:Float, v:Float, r:Float Var, g:Float Var, b:Float Var)
	Local hi:Int = Floor(h/60.0)
	Local f:Float = h/60.0-hi
	
	Local p:Float = v*(1-s)*255
	Local q:Float = v*(1-s*f)*255
	Local t:Float = v*(1-s*(1-f))*255

	If hi = 0 Or hi = 6 Then
		r = v ; g = t ; b = p
	ElseIf hi = 1 Then
		r = q ; g = v ; b = p
	ElseIf hi = 2 Then
		r = p ; g = v ; b = t
	ElseIf hi = 3 Then
		r = p ; g = q ; b = v
	ElseIf hi = 4 Then
		r = t ; g = p ; b = v
	ElseIf hi = 5 Then
		r = v ; g = p ; b = q
	EndIf
End Function

Function Clamp:Float(val:Float, minimum:Float, maximum:Float)
	If val < minimum Then
		Return minimum
	Else If val > maximum Then
		Return maximum
	Else
		Return val
	EndIf
End Function