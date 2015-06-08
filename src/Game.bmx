SuperStrict

Framework brl.blitz

Import sidesign.minib3d
Import "Collision.bmx"
Import "Math.bmx"
Import "Util.bmx"
Import "Audio.bmx"

Type TEntry
	Field key : String
	Field asset : Object
End Type

Type TAssets
	Global textures : TList = CreateList()
	Global images : TList = CreateList()

	Function LoadTexture:TTexture(key:String, file:String, flags:Int=1)
		Local texture:TTexture = TTexture.LoadTexture("assets/" + file, flags)
		If texture = Null Then Throw "Unable to load texture " + file 
		Local entry:TEntry = New TEntry
		entry.key = key
		entry.asset = texture
		
		Self.textures.AddLast(entry)
		Return texture
	End Function
	
	Function LoadImg:TImage(key:String, file:String)
		Local image:TImage = LoadImage("assets/" + file)
		If image = Null Then Throw "Unable to load image " + file 
		Local entry:TEntry = New TEntry
		entry.key = key
		entry.asset = image
		
		Self.images.AddLast(entry)
		Return image
	End Function

	Function GetTexture:TTexture(key:String)
		For Local entry:TEntry = EachIn Self.textures
			If key = entry.key Then Return TTexture(entry.asset)
		Next
		Return Null
	End Function

	Function GetImage:TImage(key:String)
		For Local entry:TEntry = EachIn Self.images
			If key = entry.key Then Return TImage(entry.asset)
		Next
		Return Null
	End Function
End Type

Type TWorld
	Global instance : TWorld = New TWorld
	
	Field lastTime : Float ' [s]
	Field platforms : TList = CreateList()
	Field camera : TCamera
	Field player : TPLayer
	Field start : TStart
	Field finish : TFinish
	Field sky : TEntity
	
	Method AddPlatform(platform:TPlatform)
		If platform = Null Then Throw "platform is null"

		Self.platforms.AddLast(platform)
	End Method
	
	Method Update(time:Float)
		Local delta : Float = time - lastTime
		For Local platform:TPlatform = EachIn platforms
			platform.Update(time, delta)
		Next
		Self.player.Update(time, delta)
		Self.start.update(time, delta)
		Self.finish.update(time, delta)
		
		UpdateCamera(time, delta)
		
		lastTime = time
	End Method
	
	Method UpdateCamera(time:Float, delta:Float)
		Local rZ:Float = player.GetZ() - 3
		Local cZ:Float = camera.EntityZ()
		Local rPitch:Float = DeltaPitch(camera, player.entity)
		Local cPitch:Float = camera.EntityPitch()
		Local rYaw:Float = DeltaYaw(camera, player.entity)
		Local cYaw:Float = camera.EntityYaw()
		
		camera.PositionEntity(camera.EntityX(), camera.EntityY(), cZ + (rZ - cZ)*delta*3)
		camera.RotateEntity(cPitch + (rPitch - cPitch)*delta*2, cYaw + (rYaw - cYaw)*delta*2, 0)
		sky.PositionEntity(camera.EntityX(True), camera.EntityY(True) - 250, camera.EntityZ(True))
	End Method
	
	Function Load()
		instance.start = TStart.Create(0, 0, -20)
		instance.finish = TFinish.Create(0, 0, 6)
		instance.AddPlatform(TPlatform.Create(3, 2*Pi/3, 0, -1, -13))
		instance.AddPlatform(TPlatform.Create(2.4, 2*Pi/1.2, 6, -0.5, -9))
		instance.AddPlatform(TPlatform.Create(3, 2*Pi/2.5, 2.5, 0.5, -3.5))
		instance.AddPlatform(TPlatform.Create(2, 2*Pi/1.5, -3.5, 0.3, 0.5))

		instance.player = TPlayer.Create()
		instance.player.entity.PositionEntity(0, 5, -19)

		instance.camera = TCamera.CreateCamera()
		instance.camera.CameraFogMode(True)
		instance.camera.CameraFogRange(100, 400)
		instance.camera.CameraFogColor(190, 220, 240)
		instance.camera.PositionEntity(-6, 10, -30)
		instance.camera.CameraClsColor(255, 255, 255)
		CameraLookAt(instance.camera, instance.player.entity)
		
		AmbientLight(150, 150, 150)
		
		Local sphere:TMesh = TMesh.CreateSphere(20)
		sphere.FlipMesh()
		sphere.ScaleMesh(500, 500, 500)
		sphere.EntityTexture(TAssets.GetTexture("sky"))
		sphere.EntityFX(1 | 2 | 8)
		instance.sky = sphere
	End Function
End Type

Type TGameObject
	Method Update(time:Float, delta:Float)
	End Method
End Type

Type TPlayer
	Const RADIUS : Float = 1 ' [m]
	Const MASS : Float = 1 ' [kg]

	Field collision:TWorldObject = Null

	Field entity : TEntity
	Field shadow : TEntity
	
	Field angleOffset : Float
	Field distanceXZ : Float
	
	Field jumpStart : Float ' [s]
	Field jumpDir:TVector = New Tvector
	
	Field finishTime:Int

	Function Create:TPlayer()
		Local player:TPlayer = New TPlayer
		Local sphere:TMesh = TMesh.CreateSphere(12)
		sphere.ScaleMesh(RADIUS, RADIUS, RADIUS)
		player.entity = sphere
		Local shadow:TMesh = CreateQuad(player.entity)
		shadow.ScaleMesh(RADIUS, 1, RADIUS)
		shadow.EntityTexture(TAssets.GetTexture("shadow"))
		shadow.PositionEntity(0, -RADIUS, 0)
		player.shadow = shadow
		player.jumpStart = MilliSecs()/1000
		Return player
	End Function
	
	Method Jump(strength:Float = 1)
		If Self.IsFlying() Then Return
		Assert Self.collision <> Null
		Local jumpDir:TVector = Self.collision.GetJumpDirection(Self)
		Self.jumpDir.Set(jumpDir.scale(strength))
		Self.jumpStart = MilliSecs()/1000.0
		Self.angleOffset = 0

		Self.entity.PositionEntity(Self.GetX(), Self.collision.GetY() + Self.collision.GetHeight()/2 + RADIUS + 0.1, Self.GetZ())
		Self.collision = Null
	End Method
	
	Method Update(time:Float, delta:Float)
		If Self.IsFlying() Then
			Self.UpdateFlying(time, delta)
		ElseIf TPlatform(Self.collision) Then
			Self.UpdateOnPlatform(TPlatform(Self.collision))
		ElseIf TStart(Self.collision) Then
			Self.UpdateOnStart(TStart(Self.collision))
		ElseIf TFinish(Self.collision) Then
			Self.UpdateOnFinish(TFinish(Self.collision))
		EndIf
		Self.UpdateShadow()
	End Method
	
	Method IsFlying:Int()
		Return Self.collision = Null
	End Method
	
	Method UpdateFlying(time:Float, delta:Float)
		Self.collision = Self.GetCollisionObject()
		If Self.collision <> Null Then
			If TPlatform(Self.collision) Then
				Local platform:TPlatform = TPlatform(Self.collision)
				Local sx:Float = Self.GetX()
				Local sz:Float = Self.GetZ()
				Local cx:Float = platform.GetX()
				Local cz:Float = platform.GetZ()
				Self.distanceXZ = Sqr((sx - cx)^2 + (sz - cz)^2)
				Local angle:Float = DegToRad(ATan2(sz - cz, sx - sx))
				Self.angleOffset = angle - platform.GetAngle()
			ElseIf TFinish(Self.collision) Then
				Self.finishTime = MilliSecs()
			EndIf
			Local x:Float = Self.GetX()
			Local y:Float = Self.collision.GetY() + Self.collision.GetHeight()/2 + RADIUS
			Local z:Float = Self.GetZ()
			Self.entity.PositionEntity(x, y, z)
		Else
			Local jumpTime:Float=MilliSecs()/1000.0 - Self.jumpStart
					
			Local velocity:TVector = New TVector
			velocity.x = Self.jumpDir.x*5
			velocity.y = -60*(jumpTime-0.3)
			velocity.z = Self.jumpDir.z*5

			Local position:TVector = TVector.Create(Self.GetX(), Self.GetY(), Self.GetZ())
			position.Add(velocity.Scale(delta), position)
			Self.entity.PositionEntity(position.x, position.y, position.z)
		EndIf
	End Method
	
	Method UpdateOnPlatform(platform:TPlatform)
		Local angle:Float = platform.getAngle() + Self.angleOffset
		Local degree:Float = RadToDeg(angle)
	
		Local x:Float = platform.GetX() + Self.distanceXZ*Cos(degree)
		Local y:Float = Self.GetY()
		Local z:Float = platform.GetZ() + Self.distanceXZ*Sin(degree)
		Self.entity.PositionEntity(x, y, z)
	End Method
	
	Method UpdateOnStart(start:TStart)
	End Method
	
	Method UpdateOnFinish(finish:TFinish)
	End Method

	Method UpdateShadow()
		Local receiver:TWorldObject = Self.GetShadowReceiver()
		If receiver <> Null Then
			Local distY:Float = GetShadowDistance(receiver)
			Local alpha:Float =  Clamp(1/Exp(3*Abs(distY)), 0, 1)
			Self.shadow.EntityAlpha(alpha)
			Local eps:Float = 0.001 ' Verhindert Z-Fighting
			Self.shadow.PositionEntity(0, -(distY + RADIUS) + eps, 0)
			Self.shadow.ShowEntity()
		Else
			Self.shadow.HideEntity()
		EndIf
	End Method
	
	Method GetShadowDistance:Float(receiver:TWorldObject)
		Return (Self.GetY() - receiver.GetY()) - (RADIUS + receiver.GetHeight()/2)
	End Method

	Method GetCollisionObject:TWorldObject()
		For Local platform:TPlatform = EachIn TWorld.instance.platforms
			If platform.Intersects(Self) Then Return platform
		Next
		If TWorld.instance.start.Intersects(Self) Then Return TWorld.instance.start
		If TWorld.instance.finish.Intersects(Self) Then Return TWorld.instance.finish
		Return Null	
	End Method
	
	Method GetShadowReceiver:TWorldObject()
		For Local platform:TPlatform = EachIn TWorld.instance.platforms
			If platform.IsShadowReceiver(Self) Then Return platform
		Next
		If TWorld.instance.start.IsShadowReceiver(Self) Then Return TWorld.instance.start
		If TWorld.instance.finish.IsShadowReceiver(Self) Then Return TWorld.instance.finish
		Return Null	
	End Method

	Method GetRadius:Float()
		Return RADIUS
	End Method
	
	Method GetMass:Float()
		Return MASS
	End Method

	Method GetX:Float()
		Return Self.entity.EntityX(True)
	End Method

	Method GetY:Float()
		Return Self.entity.EntityY(True)
	End Method

	Method GetZ:Float()
		Return Self.entity.EntityZ(True)
	End Method
End Type

Type TWorldObject Extends TGameObject
	Method Intersects:Int(player:TPlayer) Abstract
	Method IsShadowReceiver:Int(player:TPlayer) Abstract
	Method GetHeight:Float() Abstract
	Method GetX:Float() Abstract
	Method GetY:Float() Abstract
	Method GetZ:Float() Abstract
	Method GetJumpDirection:TVector(player:TPlayer) Abstract
End Type

Type TPlatform Extends TWorldObject
	Const HEIGHT : Float = 0.5
	Const COLLISION_TYPE : Int = 1

	Field angle : Float ' [Rad]
	Field angularVelocity : Float ' [Rad/s]
	Field radius : Float ' [m]
	Field entity : TEntity
	
	Function Create:TPlatform(radius:Float, angularVelocity:Float, x:Float, y:Float, z:Float)
		Local platform : TPlatform = New TPlatform
		platform.angle = 0
		platform.angularVelocity = angularVelocity
		platform.radius = radius
		
		Local cylinder:TMesh = TMesh.CreateCylinder(10)
		cylinder.ScaleMesh(radius, HEIGHT / 2, radius)
		platform.entity = cylinder
		platform.entity.PositionEntity(x, y, z)
		Local texture:TTexture = TAssets.GetTexture("stone")
		platform.entity.EntityTexture(texture)

		Return platform
	End Function
	
	Method Update(time:Float, delta:Float)
		Self.angle = time*Self.angularVelocity
		Local degree:Float = RadToDeg(Self.angle)
		Self.entity.RotateEntity(0, degree, 0)
	End Method
	
	Method Intersects:Int(player:TPlayer)
		' Sphere position
		Local sx:Float = player.GetX()
		Local sy:Float = player.GetY()
		Local sz:Float = player.GetZ()

		' cylinder position
		Local cx:Float = Self.GetX()
		Local cy:Float = Self.GetY()
		Local cz:Float = Self.GetZ()

		Return SphereIntersectsCylinder(sx, sy, sz, player.GetRadius(), cx, cy, cz, RADIUS - player.GetRadius()/2, HEIGHT)
	End Method
	
	Method IsShadowReceiver:Int(player:TPlayer)
		' Sphere position
		Local sx:Float = player.GetX()
		Local sy:Float = player.GetY()
		Local sz:Float = player.GetZ()

		' Cylinder position
		Local cx:Float = Self.GetX()
		Local cy:Float = Self.GetY()
		Local cz:Float = Self.GetZ()

		' Sphere above the cylinder?
		Local diffY:Float = sy - cy
		Local distY:Float = diffY - player.GetRadius() - HEIGHT/2
		If distY < 0.01 Then distY = 0
		Local above:Int = distY >= 0

		If above Then
			Return PointInCircle(cx, cz, RADIUS, sx, sz)
		Else
			Return False
		EndIf
	End Method

	Method GetShadowDistance:Float(player:TPlayer)
		Local sy:Float = player.GetY()
		Local cy:Float = Self.GetY()
		Local diffY:Float = sy - cy
		Return diffY - HEIGHT/2
	End Method

	Method GetHeight:Float()
		Return HEIGHT
	End Method
	
	Method GetJumpDirection:TVector(player:TPlayer)
		Local p:TVector = TVector.Create(player.GetX(), 0, player.GetZ())
		Local c:TVector = TVector.Create(Self.GetX(), 0, Self.GetZ())
		Local dir:TVector = p.Sub(c)
		
		Local r:Float = Max(dir.Length(), 0.5)
		Local centrigualForce:Float = player.GetMass() * Self.GetAngularVelocity() * r
		Local scale:Float = centrigualForce/12
		dir.Scale(scale, dir)

		Return dir
	End Method

	Method GetX:Float()
		Return Self.entity.EntityX(True)
	End Method

	Method GetY:Float()
		Return Self.entity.EntityY(True)
	End Method

	Method GetZ:Float()
		Return Self.entity.EntityZ(True)
	End Method
	
	Method GetAngle:Float()
		Return Self.angle
	End Method
	
	Method GetAngularVelocity:Float()
		Return Self.angularVelocity
	End Method
End Type

Type TStart Extends TWorldObject
	Const WIDTH:Float = 4
	Const DEPTH:Float = 4
	Const HEIGHT:Float = 1

	Field entity:TEntity
	
	Function Create:TStart (x:Float, y:Float, z:Float)
		Local start:TStart = New TStart
		Local box:TMesh = TMesh.CreateCube()
		box.ScaleMesh(WIDTH/2, HEIGHT/2, DEPTH/2)
		box.EntityTexture(TAssets.GetTexture("start"))
		box.PositionEntity(x, y, z)
		start.entity = box
		Return start
	End Function
	
	Method Update(time:Float, delta:Float)
	End Method

	Method Intersects:Int(player:TPlayer)
		' Sphere position
		Local sx:Float = player.GetX()
		Local sy:Float = player.GetY()
		Local sz:Float = player.GetZ()

		' Box position
		Local bx:Float = Self.GetX()
		Local by:Float = Self.GetY()
		Local bz:Float = Self.GetZ()

		Return SphereIntersectsBox(sx, sy, sz, player.GetRadius(), bx, by, bz, WIDTH - player.GetRadius(), HEIGHT, DEPTH - player.GetRadius())
	End Method
	
	Method IsShadowReceiver:Int(player:TPlayer)
		' Sphere position
		Local sx:Float = player.GetX()
		Local sy:Float = player.GetY()
		Local sz:Float = player.GetZ()

		' Box position
		Local bx:Float = Self.GetX()
		Local by:Float = Self.GetY()
		Local bz:Float = Self.GetZ()

		' Sphere above the box?
		Local diffY:Float = sy - by
		Local distY:Float = diffY - player.GetRadius() - HEIGHT/2
		If distY < 0.01 Then distY = 0
		Local above:Int = distY >= 0
		
		If above Then
			Return PointInRectangle(bx, bz, WIDTH, DEPTH, sx, sz)
		Else
			Return False
		EndIf
	End Method

	Method GetShadowDistance:Float(player:TPlayer)
		Local sy:Float = player.GetY()
		Local by:Float = Self.GetY()
		Local diffY:Float = sy - by
		Return diffY - HEIGHT
	End Method
	
	Method GetJumpDirection:TVector(player:TPlayer)
		Local dir:TVector = TVector.Create(0, 0, 1)
		dir.Normalize(dir)
		Return dir
	End Method
	
	Method GetHeight:Float()
		Return HEIGHT
	End Method

	Method GetX:Float()
		Return Self.entity.EntityX(True)
	End Method

	Method GetY:Float()
		Return Self.entity.EntityY(True)
	End Method

	Method GetZ:Float()
		Return Self.entity.EntityZ(True)
	End Method
End Type

Type TFinish Extends TWorldObject
	Const WIDTH:Float = 4
	Const DEPTH:Float = 4
	Const HEIGHT:Float = 1

	Field entity:TEntity
	
	Function Create:TFinish(x:Float, y:Float, z:Float)
		Local finish:TFinish = New TFinish
		Local box:TMesh = TMesh.CreateCube()
		box.ScaleMesh(WIDTH/2, HEIGHT/2, DEPTH/2)
		box.EntityTexture(TAssets.GetTexture("finish"), 0, 0)
		Local gloss:TTexture = TAssets.GetTexture("gloss")
		gloss.ScaleTexture(0.25, 0.25)
		gloss.TextureBlend(3)
		box.EntityTexture(gloss, 0, 1)
		
		box.PositionEntity(x, y, z)

		finish.entity = box
		Return finish
	End Function
	
	Method Update(time:Float, delta:Float)
		Local hue:Float = Clamp(Cos(Time*400)*50 + 180, 0, 360)
		Local r:Float, g:Float, b:Float
		HsvToRgb(hue, 0.7, 0.7, r, g, b)
		
		Self.entity.EntityColor(r*255, g*255, b*255)
	End Method

	Method Intersects:Int(player:TPlayer)
		' Sphere position
		Local sx:Float = player.GetX()
		Local sy:Float = player.GetY()
		Local sz:Float = player.GetZ()

		' Box position
		Local bx:Float = Self.GetX()
		Local by:Float = Self.GetY()
		Local bz:Float = Self.GetZ()

		Return SphereIntersectsBox(sx, sy, sz, player.GetRadius(), bx, by, bz, WIDTH - player.GetRadius(), HEIGHT, DEPTH - player.GetRadius())
	End Method
	
	Method IsShadowReceiver:Int(player:TPlayer)
		' Sphere position
		Local sx:Float = player.GetX()
		Local sy:Float = player.GetY()
		Local sz:Float = player.GetZ()

		' Box position
		Local bx:Float = Self.GetX()
		Local by:Float = Self.GetY()
		Local bz:Float = Self.GetZ()

		' Sphere above the box?
		Local diffY:Float = sy - by
		Local distY:Float = diffY - player.GetRadius() - HEIGHT/2
		If distY < 0.01 Then distY = 0
		Local above:Int = distY >= 0
		
		If above Then
			Return PointInRectangle(bx, bz, WIDTH, DEPTH, sx, sz)
		Else
			Return False
		EndIf
	End Method

	Method GetShadowDistance:Float(player:TPlayer)
		Local sy:Float = player.GetY()
		Local by:Float = Self.GetY()
		Local diffY:Float = sy - by
		Return diffY - HEIGHT
	End Method
	
	Method GetJumpDirection:TVector(player:TPlayer)
		Local dir:TVector = TVector.Create(0, 0, -1)
		dir.Normalize(dir)
		Return dir
	End Method
	
	Method GetHeight:Float()
		Return HEIGHT
	End Method

	Method GetX:Float()
		Return Self.entity.EntityX(True)
	End Method

	Method GetY:Float()
		Return Self.entity.EntityY(True)
	End Method

	Method GetZ:Float()
		Return Self.entity.EntityZ(True)
	End Method
End Type

Type TJumpListener Extends TOnsetListener
	Method OnOnset(begin:Long, novelty:Float)
		Local strength:Float = Clamp(novelty/1700, 0.1, 3.5)
		Print "jump with " + strength
		TWorld.instance.player.Jump(strength)
	End Method
End Type

TAudio.Init()
Local recorder:TRecorder = New TRecorder
Local detector:TOnsetDetector = TOnsetDetector.Create(10, 500, 1.5)
Local listener:TJumpListener = New TJumpListener
detector.AddListener(listener)

TGlobal.Graphics3D(800, 600, 60, 2)

Local stoneTexture:TTexture = TAssets.LoadTexture("stone", "stone.png")
stoneTexture.ScaleTexture(0.5, 0.5)
TAssets.LoadTexture("shadow", "shadow.png", 2)
TAssets.LoadTexture("start", "start.png")
TAssets.LoadTexture("finish", "finish.png")
TAssets.LoadTexture("sky", "sky.png")
Local glossTexture:TTexture = TAssets.LoadTexture("gloss", "gloss.png", 1|2|64)
Local deadImage:TImage = TAssets.LoadImg("dead", "dead.png")
SetImageHandle deadImage, ImageWidth(deadImage)/2, ImageHeight(deadImage)/2
Local starImage:TImage = TAssets.LoadImg("star", "star.png")
SetImageHandle starImage, ImageWidth(starImage)/2, ImageHeight(starImage)/2

TWorld.instance.Load()

Global light:TLight = TLight.CreateLight(1)
light.PositionEntity(0, 50, 0)
light.RotateEntity(80, 0, 0)
light.LightColor(80, 80, 80)

Local devices:String[] = recorder.Enumerate()
WriteStdout "Capture devices:~n"
For Local dev:String = EachIn devices
	WriteStdout dev + "~n"
Next
Local defaultRecorder:String = TRecorder.DefaultRecorder()
WriteStdout "Using: " + defaultRecorder + "~n"
recorder.Open(defaultRecorder)
recorder.AddListener(detector, detector.spec)
recorder.Start()

Global startTime : Long = MilliSecs()
Local start:Int = MilliSecs()
While Not KeyDown(KEY_ESCAPE)
	If MilliSecs() - start > 50 Then
		recorder.Process()
		start = MilliSecs()
	EndIf

	Local time : Float = (MilliSecs() - startTime) / 1000.0
	
	If KeyDown(KEY_LEFT) Then TWorld.instance.player.entity.MoveEntity(-0.1, 0, 0)
	If KeyDown(KEY_RIGHT) Then TWorld.instance.player.entity.MoveEntity(0.1, 0, 0)
	If KeyDown(KEY_UP) Then TWorld.instance.player.entity.MoveEntity(0, 0, 0.1)
	If KeyDown(KEY_DOWN) Then TWorld.instance.player.entity.MoveEntity(0, 0, -0.1)
	If KeyDown(KEY_Q) Then TWorld.instance.player.entity.MoveEntity(0, 0.05, 0)
	If KeyDown(KEY_A) Then TWorld.instance.player.entity.MoveEntity(0, -0.05, 0)
	
	If KeyDown(KEY_NUM8) Then TWorld.instance.camera.TurnEntity(0.9, 0, 0)
	If KeyDown(KEY_NUM2) Then TWorld.instance.camera.TurnEntity(-0.9, 0, 0)
	If KeyDown(KEY_NUM4) Then TWorld.instance.camera.TurnEntity(0, -0.9, 0)
	If KeyDown(KEY_NUM6) Then TWorld.instance.camera.TurnEntity(0, 0.9, 0)
	If KeyDown(KEY_W) Then TWorld.instance.camera.MoveEntity(0, 0.2, 0)
	If KeyDown(KEY_S) Then TWorld.instance.camera.MoveEntity(0, -0.2, 0)
	
	If KeyHit(KEY_SPACE) Then TWorld.instance.player.Jump()

	TWorld.instance.Update(time)
	
	TGlobal.UpdateWorld()
	TGlobal.RenderWorld()
	
	BeginMax2D()
	Local py:Float = TWorld.instance.player.GetY()
	If py < -10 Then
		SetBlend ALPHABLEND
		Local alpha:Float = Clamp((Abs(py) - 20)/150, 0, 1)
		Local scale:Float = 5 - alpha*4
		Local dead:TImage = TAssets.GetImage("dead")
		SetOrigin GraphicsWidth()/2, GraphicsHeight()/2
		
		SetScale scale, scale
		SetAlpha alpha
		DrawImage dead, 0, 0
		SetOrigin 0, 0
		SetAlpha 1
	Else If TWorld.instance.player.collision = TWorld.instance.finish Then
		SetBlend ALPHABLEND
		Local alpha:Float = Clamp((MilliSecs()-TWorld.instance.player.finishTime)/1000.0, 0, 1)
		Local scale:Float = 5 - alpha*4
		Local star:TImage = TAssets.GetImage("star")
		SetOrigin GraphicsWidth()/2, GraphicsHeight()/2
		
		SetScale scale, scale
		SetAlpha alpha
		DrawImage star, 0, 0
		SetOrigin 0, 0
		SetAlpha 1
	EndIf
	EndMax2D()
	
	Flip(True)
Wend

recorder.Stop()
recorder.Close()
TAudio.Close()
End


