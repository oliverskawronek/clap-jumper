SuperStrict

Import brl.math
Import "Math.bmx"

Function SphereIntersectsBox:Int(sx:Float, sy:Float, sz:Float, rs:Float, ..
		bx:Float, by:Float, bz:Float, width:Float, height:Float, depth:Float)
	' Kollision in der XZ-Ebene (Top)
	If Not CircleIntersectsRectangle(sx, sz, rs, bx, bz, width, depth) Then Return False
	' Kollision in der XY-Ebene (Front)
	If Not CircleIntersectsRectangle(sx, sy, rs, bx, by, width, height) Then Return False
	' Kollision in der YZ-Ebene (Left)
	If Not CircleIntersectsRectangle(sy, sz, rs, by, bz, height, depth) Then Return False
	Return True
End Function

' Sphere (sx, sy, sz, rs)
' Cylinder (cx, cy, cz, rc, h)
Function SphereIntersectsCylinder:Int(sx:Float, sy:Float, sz:Float, rs:Float, ..
		cx:Float, cy:Float, cz:Float, rc:Float, h:Float)
	' Kollision in der XZ-Ebene (Top)
	If Not CircleIntersectsCircle(sx, sz, rs, cx, cz, rc) Then Return False
	' Kollision in der XY-Ebene (Front)
	If Not CircleIntersectsRectangle(sx, sy, rs, cx, cy, 2*rc, h) Then Return False
	' Kollision in der YZ-Ebene (Left)
	If Not CircleIntersectsRectangle(sz, sy, rs, cz, cy, 2*rc, h) Then Return False
	Return True
End Function

Function CircleIntersectsRectangle:Int(cx:Float, cy:Float, r:Float, ..
		rx:Float, ry:Float, width:Float, height:Float)
	' Top
	If CircleIntersectsHorizontal(cx, cy, r, rx - width/2, rx + width/2, ry + height/2) Then Return True
	' Bottom
	If CircleIntersectsHorizontal(cx, cy, r, rx - width/2, rx + width/2, ry - height/2) Then Return True
	' Left
	If CircleIntersectsVertical(cx, cy, r, rx - width/2, ry - height/2, ry + height/2) Then Return True
	' Right
	If CircleIntersectsVertical(cx, cy, r, rx + width/2, ry - height/2, ry + height/2) Then Return True

	If CircleInRectangle(cx, cy, r, rx, ry, width, height) Then Return True
	If RectangleIntersectsCircle(cx, cy, r, rx, ry, width, height) Then Return True
	Return False
End Function

' Circle (cx, cy, r)
' Horizontal line segment (x1, x2, y)
Function CircleIntersectsHorizontal:Int(cx:Float, cy:Float, r:Float, ..
		x1:Float, x2:Float, y:Float)
	Local diffY:Float = cy - y
	Local distY:Float = Abs(diffY)
	If distY <= r Then
		Local phi:Float = ASin(diffY/r)
		Local rh:Float = r*Cos(phi)
		Local cx1:Float = cx - rh
		Local cx2:Float = cx + rh
		Return (cx1 <= x1 And x1 <= cx2) Or (cx1 <= x2 And x2 <= cx2) Or (cx1 >= x1 And cx2 <= x2)
	Else
		Return False		
	EndIf
End Function

' Circle (cx, cy, r)
' Vertical line segment (x, y1, y2)
Function CircleIntersectsVertical:Int(cx:Float, cy:Float, r:Float, ..
		x:Float, y1:Float, y2:Float)
	Local diffX:Float = cx - x
	Local distX:Float = Abs(diffX)
	If distX <= r Then
		Local phi:Float = ACos(diffX/r)
		Local rh:Float = r*Sin(phi)
		Local cy1:Float = cy - rh
		Local cy2:Float = cy + rh
		Return (cy1 <= y1 And y1 <= cy2) Or (cy1 <= y2 And y2 <= cy2) Or (cy1 >= y1 And cy2 <= y2)
	Else
		Return False		
	EndIf
End Function

' Circle (cx, cy, r)
' Rectangle (rx, ry, width, height)
Function CircleInRectangle:Int(cx:Float, cy:Float, r:Float, ..
		rx:Float, ry:Float, width:Float, height:Float)
	Return cx - r >= rx - width/2 And cx + r <= rx + width/2 And cy - r >= ry - height/2 And cy + r <= ry + height/2
End Function

' Circle (cx, cy, r)
' Rectangle (rx, ry, width, height)
Function RectangleIntersectsCircle:Int(cx:Float, cy:Float, r:Float, ..
		rx:Float, ry:Float, width:Float, height:Float)
	' Links Oben
	If PointInCircle(cx, cy, r, rx - width/2, ry - height/2) Then Return True
	' Rechts Oben
	If PointInCircle(cx, cy, r, rx + width/2, ry - height/2) Then Return True
	' Links Unten
	If PointInCircle(cx, cy, r, rx - width/2, ry + height/2) Then Return True
	' Rechts Unten
	If PointInCircle(cx, cy, r, rx + width/2, ry + height/2) Then Return True
End Function

' Circle (cx, cy, r)
' Point (x, y)
Function PointInCircle:Int(cx:Float, cy:Float, r:Float, ..
		x:Float, y:Float)
	Return Sqr((cx-x)^2 + (cy-y)^2) <= r
End Function

' Rectangle (bx, by, width, height)
' Point (x, y)
Function PointInRectangle:Int(bx:Float, by:Float, width:Float, height:Float, ..
		x:Float, y:Float)
	Return bx - width/2 <= x And x <= bx + width/2 And ..
			by - height/2 <= y And y <= by + height/2
End Function

Function CircleIntersectsCircle:Int(cx1:Float, cy1:Float, r1:Float, ..
		cx2:Float, cy2:Float, r2:Float)
	Return Sqr((cx1-cx2)^2 + (cy1-cy2)^2) <= (r1 + r2)
End Function
