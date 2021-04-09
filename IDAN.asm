IDEAL
    MODEL small
    STACK 100h
    p386
DATASEG
	INCLUDE	"IMAGES.DAT"
	INCLUDE	"VARS.DAT"
	
CODESEG
;Menu Procedures
PROC HelpMenu
	XOR 	AX, AX
	MOV		AH, 9H
	MOV		DX, OFFSET Help_Title
	INT 	21H
	RET
ENDP HelpMenu


;/------------------------------------------------------------------\
;|							StartMenu								|
;| 					CALLS THE START MENU.							|
;|							ARGUMENTS:								|
;| DX - MENU TYPE: 0 = DEFUALT, 1 = NO INTRO, 2 = GAME OVER			|
;\------------------------------------------------------------------/
PROC StartMenu
	;TEXT MODE
	XOR		AX,	AX
	MOV		AL, 2D
	INT		10H
	
	XOR		AX,	AX
	MOV		AH, 9H
	PUSH 	DX
	CMP 	DX, 0
	JNE		StartMenuPostIntro
	;Print intro
	MOV		DX, OFFSET INTRO
	INT 	21H
	;Print game title screen
StartMenuPostIntro:
		
		MOV 	DX,	OFFSET TitleScreenMessage
		INT 	21H
		MOV 	DX,	OFFSET TitleScreenStart
		INT 	21H
		MOV 	DX,	OFFSET TitleScreenHelp
		INT 	21H
		MOV 	DX,	OFFSET TitleScreenExit
		INT 	21H
		;Get option
		XOR		AX, AX
		MOV		AH, 01D
		INT 	21H
		POP		DX
		
		CMP		AL, TitleScreenStartCHR
		JE		StartGame
		
		CMP		AL, TitleScreenHelpCHR
		JE		StartHelpMenu
		
		CMP		AL, TitleScreenExitCHR
		JE		Exit
		
		CALL 	StartMenu
	
	RET
ENDP StartMenu

;GAME
PROC Game
	;Graphics mode
	MOV		AX, 13H
	INT		10H
	;Player drawing and movement
	CALL	DrawPlayer
	XOR		AX, AX
	
	GamePlayerMovementHandler:
		;Check if a button is pressed
		MOV		AH,01H
		INT		16H
		JZ		GamePlayerMovementHandlerEND ;If nothing is pressed
		
		;Check what is pressed
		MOV		AH, 00H
		INT		16H
		
		CMP		AH, RIGHT_KEY
		JE		GameMoveRight
		
		CMP		AH, LEFT_KEY
		JE		GameMoveLEFT
		
		CMP		AH, ESC_KEY
		JE		GameESC
		
		CMP		AH, SPACEBAR
		JE 		GamePlayerShootingHandler
		
		JMP		GamePlayerMovementHandlerEND
		GameMoveRight:
			MOV		BX, GameBorderEndX
			CMP		[GamePlayerPosX],BX
			JE		GamePlayerMovementHandlerEND
			
			
			MOV		[GamePlayerClear], 1D
			CALL 	DrawPlayer
			
			MOV		[GamePlayerClear], 0
			MOV		BX,	[GamePlayerSpeed]
			ADD 	[GamePlayerPosX], BX
			CALL 	DrawPlayer
			JMP 	GamePlayerMovementHandlerEND
		GameMoveleft:
			MOV		BX, GameBorderStartX
			CMP		[GamePlayerPosX],BX
			JE		GamePlayerMovementHandlerEND
			
			
			MOV		[GamePlayerClear], 1D
			CALL 	DrawPlayer
			MOV		[GamePlayerClear], 0
			MOV		BX,	[GamePlayerSpeed]
			SUB 	[GamePlayerPosX], BX
			CALL 	DrawPlayer
			JMP 	GamePlayerMovementHandlerEND
		GameESC:
			MOV 	DL,	1
			CALL	StartMenu
			
		GamePlayerMovementHandlerEND:
			JMP		GamePlayerMoveShots
			
		GamePlayerShootingHandler:
			GamePlayerShoot:
				CALL PlayerShoot
			GamePlayerMoveShots:
				CMP		[GamePlayerBulletTimer], 0
				JNE		GamePlayerShootingHandlerEnd
				MOV		[GamePlayerBulletTimer],GamePlayerBulletDelay
				CALL 		MovePlayerBullets

		GamePlayerShootingHandlerEnd:
			DEC		[GamePlayerBulletTimer]
		GameEnemyMovementHandler:
		;to not move the enemies at the speed of light
			INC		[GameEnemyCurrentMovementCycles]
			CMP		[GameEnemyCurrentMovementCycles], GameEnemyMovemntCycles
			JB		GameEnemyMovementHandlerEND	
			
			;Clock solution - currently broken
			;MOV		CX, 1
			;CALL	WaitIntervals
			;If needs to move enemies
			
			MOV		[GameEnemyCurrentMovementCycles], 0D 
			;Clear the enemies
			MOV		[DrawEnemiesClear], 1D
			CALL 	DrawEnemies
			
			;Move the enemies
			MOV		[DrawEnemiesClear], 0D
			MOV		DX, [GameEnemyFirstX]
			
			;Check direction of the first
			CMP		[GameEnemyFirstDirection], 1
			JE		GameEnemyMovementHandlerMoveLeft
			;If right
			ADD		DX, GameEnemySpeed
			JMP		GameEnemyMovementHandlerAfterMove
			
			GameEnemyMovementHandlerMoveLeft:
				SUB		DX, GameEnemySpeed
				
			GameEnemyMovementHandlerAfterMove:
				CMP		DX, GameBorderEndX
				
				JA		GameEnemyMovementHandlerGoDown
				
				MOV		[GameEnemyFirstX],DX
				JMP		GameEnemyMovementDraw
				
				GameEnemyMovementHandlerGoDown:
					XOR		[GameEnemyFirstDirection], 1D ;Swap the direction
					
					MOV		DX, [GameEnemyMarginY]
					ADD		[GameEnemyFirstY], DX
				GameEnemyMovementDraw:
					CALL 	DrawEnemies
			GameEnemyMovementHandlerEND:
				JMP 	GamePlayerMovementHandler
	RET
ENDP Game
;START 	
start:
	MOV		AX,	@data
	MOV		DS, AX
	MOV		AX, 40H
	MOV		ES, AX
	
	XOR		DX, DX
	CALL	StartMenu
	
	StartGame:
		CALL	GAME
	
	StartHelpMenu:
		CALL	HelpMenu
	Exit:
			;READ KEY ===TEMP===
			;MOV		AH, 0ch
			;MOV		AL, 07h
			;INT		21H
			;IN 		AL,060h
		;=====================
		XOR		AX,	AX
		MOV		AL, 2D
		INT		10H
		MOV		AX, 4C00H
		INT		21H
			

	;General Procedures
	;/--`----------------------------------------------------------------\
	;|							PutPixel								|
	;| 					Puts a pixel in x,y								|
	;|							ARGUMENTS:								|
	;| [PixelX] The x coordinate										|
	;| [PixelY] The y coordinate										|
	;| [color] The color of the pixel									|
	;\------------------------------------------------------------------/
	PROC PutPixel
		PUSHA
		MOV		BH, 0h
		MOV		CX, [PixelX]
		MOV		DX, [PixelY]
		MOV		AL, [color]
		MOV		AH, 0ch
		INT		10H
		POPA
		RET
	ENDP PutPixel
	;/------------------------------------------------------------------\
	;|							DrawEnemies								|
	;| 				Draws enemies, pretty self explainatory...			|
	;\------------------------------------------------------------------/
	PROC DrawEnemies
		PUSHA		
		;REGISTERS USAGE
		;BL - direction
		;CX - ammount of enemies
		;DX - general use, mostly for positions
		MOV		DX, [GameEnemySizeX]
		MOV		[Draw2DSizeX], DX
		
		MOV		DX, [GameEnemySizeY]
		MOV		[Draw2DSizeY], DX
		
		XOR		BX, BX
		MOV		BL,	[GameEnemyFirstDirection]
		
		;Loop of enemies
		XOR		CX,CX
		MOV		CL,	[GameEnemyStartingAmmount]
		;Move to Draw2D variables the sizes and positions of the enemies
		MOV		DX, [GameEnemyFirstX]
		MOV		[Draw2DPosX], DX
		
		MOV		DX, [GameEnemyFirstY]
		MOV		[Draw2DPosY], DX
		
		MOV		DL, [DrawEnemiesClear]
		MOV		[Draw2DClear], DL
		
		DrawEnemiesDrawLoop:
			LEA 	SI, [EnemyModel]
			
			MOV		DX,	[Draw2DPosX]
			CMP		BL,	1 ;Check the direction of the enemy
			JE 		DrawEnemiesMoveLeft
			;If right
			ADD		DX, [GameEnemyMarginX]
			ADD		DX, [GameEnemySizeX]
			JMP		DrawEnemiesPostMovement
			DrawEnemiesMoveLeft:
				;If left
				SUB		DX, [GameEnemyMarginX]
				SUB		DX, [GameEnemySizeX]
				
			DrawEnemiesPostMovement:
				;Check if on borders
				CMP		DX,	GameBorderEndX
				JG		DrawEnemiesGoDownEndBorder
				CMP		DX,	GameBorderStartX
				JL		DrawEnemiesGoDownStartBorder
				
				;If there is enough space to draw the enemy
				MOV		[Draw2DPosX],DX 
				JMP 	DrawEnemiesLoopLoop
				;If there is NOT enough space to draw the enemy
				DrawEnemiesGoDownStartBorder: 
					ADD		DX, GameBorderEndX
					JMP		DrawEnemiesGoDownPost
				DrawEnemiesGoDownEndBorder:
					SUB		DX, GameBorderEndX
				DrawEnemiesGoDownPost:
					MOV		AX, GameBorderEndX
					SUB		AX, DX
					
					MOV		[Draw2DPosX], AX
					
					XOR		BL, 1; Swap direction
					MOV		DX,	[GameEnemyMarginY]
					ADD		[Draw2DPosY],DX
				
				DrawEnemiesLoopLoop:
					CALL Draw2D
					LOOP DrawEnemiesDrawLoop
		POPA
		RET
	ENDP DrawEnemies
	;/------------------------------------------------------------------\
	;|							DrawPlayer								|
	;| 				Draws the player in PlayerX,PlayerY					|
	;|							ARGUMENTS:								|
	;| [GamePlayerPosX] The x coordinate of the player					|
	;| [GamePlayerPosY] The y coordinate of the player					|
	;| [GamePlayerClear] if 1D, will clear the player area				|
	;\------------------------------------------------------------------/
	PROC DrawPlayer
		PUSHA
		MOV		DX, [GamePlayerPosX]
		MOV		[Draw2DPosX], DX
		
		MOV		DX, [GamePlayerPosY]
		MOV		[Draw2DPosY], DX
		
		MOV		DX, GamePlayerSizeX
		MOV		[Draw2DSizeX], DX
		
		MOV		DX, GamePlayerSizeY
		MOV		[Draw2DSizeY], DX
		
		LEA 	SI, [PLAYER]

		XOR		DX,DX
		MOV		DL, [GamePlayerClear]
		MOV		[Draw2DClear], DL
		
		CALL Draw2D
		POPA
		RET
	ENDP DrawPlayer
	;if player want to shoot, let them shoot!
	PROC PlayerShoot
		PUSHA
		;Check if can shoot (Number of bullets is not over the limit)
		XOR 	CH, CH
		MOV		CL, [GamePlayerCurrentBullets]
		CMP		CL, GamePlayerBulletsLimit
		JAE		PlayerShootEnd
		
		SHL		CL, 1 ; Beacuse GamePlayerBulletsPosX/Y is DW, multiplies by 2
		INC		[GamePlayerCurrentBullets]
		
		;Calculate X position
		
		MOV		DX, GamePlayerSizeX
		SHR		DX, 1					;Divide by two
		ADD		DX, [GamePlayerPosX]
		SUB		DX, GamePlayerBulletMarginX
		
		MOV		DI, OFFSET GamePlayerBulletsPosX
		ADD		DI, CX
		MOV		[DI], DX
		MOV		[Draw2DPosX], DX
		
		;Calculate Y position

		MOV		DX, [GamePlayerPosY]
		SUB		DX, GamePlayerSizeY
		SUB		DX, GamePlayerBulletMarginY
		
		MOV		DI, OFFSET GamePlayerBulletsPosY
		ADD		DI, CX
		MOV		[DI], DX
		MOV		[Draw2DPosY], DX
		
		MOV		DX, GamePlayerBulletSizeX
		MOV		[Draw2DSizeX], DX
		
		MOV		DX, GamePlayerBulletSizeY
		MOV		[Draw2DSizeY], DX
		
		MOV 	SI, OFFSET PlayerBullet
		MOV		[Draw2DClear], 0D
		CALL	Draw2D
		
		PlayerShootEnd:
			POPA
			RET
	ENDP PlayerShoot
	
	PROC MovePlayerBullets
		PUSHA
		XOR		CX, CX
		MOV		CL, [GamePlayerCurrentBullets]
		CMP		CL, 0
		JZ		MovePlayerBulletEnd
		MOV		CL, 0
		MovePlayerBulletLoop:
			;CLEAR THE BULLET
			MOV		DI, OFFSET GamePlayerBulletsPosX
			ADD		DI, CX
			MOV		DX, [DI]
			
			CMP		DX, GamePlayerBulletDeletedFlagPos
			JE		MovePlayerBulletLoopEnd
			
			MOV		[Draw2DPosX], DX
			
			MOV		DI, OFFSET GamePlayerBulletsPosY
			ADD		DI, CX
			MOV		DX, [DI]
			
			PUSH	DI
			MOV		[Draw2DPosY], DX
			
			MOV		DX, GamePlayerBulletSizeX
			MOV		[Draw2DSizeX], DX
		
			MOV		DX, GamePlayerBulletSizeY
			MOV		[Draw2DSizeY], DX
			
			MOV		[Draw2DClear], 1D
			MOV		SI, OFFSET PlayerBullet
			CALL	Draw2D
			;GamePlayerBulletsPosY adress
			
			POP 	DI
			SUB		[DI], GamePlayerBulletSpeed
			MOV		DX, [DI]
			CMP		DX, GameBorderStartY
			JL		MovePlayerBulletDeleteBullet
			;Can move the bullet

			MOV		[Draw2DPosY], DX
			MOV		[Draw2DClear], 0D
			MOV		SI, OFFSET PlayerBullet
			CALL	Draw2D
			JMP		MovePlayerBulletLoopEnd
			MovePlayerBulletDeleteBullet:
				MOV		DI, OFFSET GamePlayerBulletsPosX
				ADD		DI, CX
				MOV		[DI], GamePlayerBulletDeletedFlagPos
			
				MOV		DI, OFFSET GamePlayerBulletsPosY
				ADD		DI, CX
				MOV		[DI], GamePlayerBulletDeletedFlagPos
				
				DEC		[GamePlayerCurrentBullets]
			MovePlayerBulletLoopEnd:
				ADD		CL, 2D
				CMP		CL, GamePlayerBulletsLimit ; END CONDITION
				JBE		MovePlayerBulletLoop
				;LOOP		MovePlayerBulletLoop
			
		MovePlayerBulletEnd:
			POPA
			RET
	ENDP MovePlayerBullets
	;/------------------------------------------------------------------\
	;|							Draw2D									|
	;| 				Draws a 2D Array of a picture						|
	;|							ARGUMENTS:								|
	;| SI - The location of the array									|
	;| [Draw2DClear]-boolean flag - if equals to 1 will clear the image	|
	;| [Draw2DPosY] The y coordinate of the Picture						|
	;| [Draw2DPosX] The X coordinate of the Picture						|
	;| [Draw2DSizeX] The X size of the picture							|
	;| [Draw2DSizeY] The Y size of the picture							|
	;\------------------------------------------------------------------/
	PROC Draw2D
		PUSHA
		MOV		AX,	[Draw2DPosX]
		MOV		[PixelX], AX
		
		MOV		AX, [Draw2DPosY]
		MOV		[PixelY], AX
		
		MOV		CX,[Draw2DSizeY]
		
		MOV		[color], BackgroundColor
		LoopYD2D:
			PUSH	CX
			MOV		CX, [Draw2DSizeX]
			LoopXD2D:
				CMP		[Draw2DClear],1
				JE		D2DPostColorChangeDP
				MOV		BL, [SI]
				MOV		[color], BL
				D2DPostColorChangeDP:
					CALL 	PutPixel
					INC 	[PixelX]
					INC 	SI
					LOOP	LoopXD2D
					
			MOV		DX, [Draw2DSizeX]
			SUB		[PixelX],DX
			INC		[PixelY]
			POP		CX
		LOOP	LoopYD2D
		MOV		AX, [GamePlayerSizeY]
		SUB		[PixelY], AX
		POPA
		RET
	ENDP Draw2D
	
	;Wait 55ms CX times
	;Parameters: CX - times
	PROC WaitIntervals
		PUSHA
		MOV		BX, [CLOCK]
		WaitIntervalsLoop:
			CMP		[CLOCK], BX
			JE		WaitIntervalsLoop
			MOV		BX, [CLOCK]
			LOOP 	WaitIntervalsLoop
		POPA
		RET
	ENDP
END		start