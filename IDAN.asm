IDEAL
    MODEL small
    STACK 100h
    p486
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
					
					MOV		DX, GameEnemyMarginY
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
		MOV		DX, GameEnemySizeX
		MOV		[Draw2DSizeX], DX
		
		MOV		DX, GameEnemySizeY
		MOV		[Draw2DSizeY], DX
		
		XOR		BX, BX
		MOV		BL,	[GameEnemyFirstDirection]
		MOV		[GameEnemiesPosPointer], 0D ;Reset the pointer
		;Loop of enemies
		XOR		CX,CX
		MOV		CL,	GameEnemyStartingAmmount
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
			ADD		DX, GameEnemyMarginX
			ADD		DX, GameEnemySizeX
			JMP		DrawEnemiesPostMovement
			DrawEnemiesMoveLeft:
				;If left
				SUB		DX, GameEnemyMarginX
				SUB		DX, GameEnemySizeX
				
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
					MOV		DX,	GameEnemyMarginY
					ADD		[Draw2DPosY],DX
					MOV		[GameEnemiesLowestEnemy], DX
				
				DrawEnemiesLoopLoop:
					
					MOV		DI,	OFFSET GameEnemiesPosX
					ADD		DI,	[GameEnemiesPosPointer]
					CMP		[WORD PTR DI], GameEnemyDeadFlag
					JE		DrawEnemiesLoopLoopEnd
					CALL 	Draw2D
					MOV		DX, [Draw2DPosX]
					MOV		[DI], DX

					MOV		DI, OFFSET GameEnemiesPosY
					ADD		DI, [GameEnemiesPosPointer]
					MOV		DX, [Draw2DPosY]
					MOV		[DI], DX
							
					DrawEnemiesLoopLoopEnd:
						ADD 	[GameEnemiesPosPointer], 2

						CMP		CX, 1
						JE		DrawEnemiesEnd
						DEC		CX
						;Bypass conditonal jump limit
						JMP		DrawEnemiesDrawLoop
		DrawEnemiesEnd:
		
		POPA
		RET
	ENDP DrawEnemies
	;Checks the collision of the enemies with the player's bullet
	;If it does, will remove the enemy.
	PROC EnemiesCollision
		PUSHA
		MOV		CX, GamePlayerBulletsLimit
		DEC		CX
		SHL		CX,1 ;Multiply by 2, sience the loop will decrease by 2 each iteration
		EnemiesCollisionLoop:
			MOV		DI, OFFSET GamePlayerBulletsPosY
			ADD		DI, CX
			;If bullet does not exist
			CMP		[WORD  PTR DI], GamePlayerBulletDeletedFlagPos
			JE		EnemiesCollisionLoopEnd

			MOV		DX, [GameEnemiesLowestEnemy]
			ADD		DX, GameEnemySizeY
			CMP		[DI],DX
			JAE	 	EnemiesCollisionLoopEnd ;if the bullet has not reached the lowest enemy, skip the check
			MOV		BX, GameEnemyStartingAmmount
			DEC		BX
			SHL		BX, 1		
			EnemiesCollisionLoopCheckEnemiesLoop:
				;SI - Enemy position pointer
				;DI - bullet pointer
				;BX - Enemy counter
				;DX - General Values
				;Much more efficent to first check Y then X than the other way around.
				EnemiesCollisionCheckY:
					MOV		DI, OFFSET GamePlayerBulletsPosY
					ADD		DI, CX					

					MOV		SI, OFFSET GameEnemiesPosX
					ADD		SI,	BX
					MOV		DX, [SI]
					ADD		DX, GameEnemySizeY
					;DX = Bottom Y coordinate of enemy
					;[DI] = Top Y coordinate of bullet
					CMP		DX,[DI]
					JA		EnemiesCollisionLoopCheckEnemiesLoopEnd

					MOV		DX, [DI]
					ADD		DX, GamePlayerBulletSizeY
					;DX = Bottom Y coordinate of bullet
					;[SI] = Top Y coordinate of enemy
					CMP		DX, [SI]
					JB		EnemiesCollisionLoopCheckEnemiesLoopEnd
				
				EnemiesCollisionCheckX:
					MOV		DI, OFFSET GamePlayerBulletsPosX
					ADD		DI, CX
					
					MOV		SI, OFFSET GameEnemiesPosX
					ADD		SI, BX

					;Check if enemy is alive
					CMP		[WORD PTR SI],GameEnemyDeadFlag
					JE		EnemiesCollisionLoopCheckEnemiesLoopEnd
					MOV		DX, [SI]
					CMP		[DI],	DX 
					JB		EnemiesCollisionLoopCheckEnemiesLoopEnd
					ADD		DX, GameEnemySizeX
					CMP		DX, BX
					JA		EnemiesCollisionLoopCheckEnemiesLoopEnd

				;TODO: Rework logic to collide

					EnemiesCollisionCollide:
						;Remove bullet data & sprite
						MOV		SI, OFFSET PlayerBullet

						MOV		DI, OFFSET GamePlayerBulletsPosY
						ADD		DI, CX
						MOV		DX, [DI]
						MOV		[Draw2DPosY], DX
						MOV		[WORD PTR DI], GamePlayerBulletDeletedFlagPos

						MOV		DI, OFFSET GamePlayerBulletsPosX
						ADD		DI, CX
						MOV		DX, [DI]
						MOV		[Draw2DPosX], DX
						MOV		[WORD PTR DI], GamePlayerBulletDeletedFlagPos

						MOV		[Draw2DSizeX], GamePlayerBulletSizeX
						MOV		[Draw2DSizeY], GamePlayerBulletSizeY
						MOV		[Draw2DClear], 1
						CALL	Draw2D
						
						DEC		[GamePlayerCurrentBullets]
						;Remove enemy data & sprite
						MOV		SI, OFFSET EnemyModel

						MOV		DI, OFFSET GameEnemiesPosX
						ADD		DI, BX
						MOV		DX, [DI]
						MOV		[Draw2DPosX], DX
						MOV		[WORD PTR DI], GameEnemyDeadFlag

						MOV		DI, OFFSET GameEnemiesPosY
						ADD		DI, BX
						MOV		DX, [DI]
						MOV		[Draw2DPosY], DX
						MOV		[WORD PTR DI], GameEnemyDeadFlag

						MOV		[Draw2DSizeX], GameEnemySizeX
						MOV		[Draw2DSizeY], GameEnemySizeY
						;Draw2Dclear is already 1 in memory
						CALL	Draw2D


				EnemiesCollisionLoopCheckEnemiesLoopEnd:
					SUB		BX, 2
					CMP		BX, 0
					JGE		EnemiesCollisionLoopCheckEnemiesLoop
			EnemiesCollisionLoopEnd:
				CMP		CX, 1
				JLE		EnemiesCollisionEnd
				SUB		CX,2
				JMP		EnemiesCollisionLoop
		EnemiesCollisionEnd:
		POPA
		RET
	ENDP EnemiesCollision
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
		JGE		PlayerShootEnd
		
		SHL		CL, 1 ; Beacuse GamePlayerBulletsPosX/Y is DW, multiplies by 2
		INC		[GamePlayerCurrentBullets]
		
		;Calculate X position
		
		MOV		DX, GamePlayerSizeX
		SHR		DX, 1					;Divide by two
		ADD		DX, [GamePlayerPosX]
		SUB		DX, GamePlayerBulletMarginX
		
		;Calculate the next free space
		MOV		SI, OFFSET GamePlayerBulletsPosX
		MOV		AX, 0002D
		MOV		BH, 1D ;DW Flag in malloc
		CALL	Malloc
		;Move values to memory
		MOV		[SI], DX
		MOV		[Draw2DPosX], DX
		;Calculate the delta between the adresses, to avoid calling malloc again
		SUB		SI, OFFSET GamePlayerBulletsPosX
		MOV		CX, SI
		
		
		;Calculate Y position and move to memory

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
		CALL	EnemiesCollision
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
			SUB		[WORD PTR DI], GamePlayerBulletSpeed
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
				MOV		[WORD PTR DI], GamePlayerBulletDeletedFlagPos
			
				MOV		DI, OFFSET GamePlayerBulletsPosY
				ADD		DI, CX
				MOV		[WORD PTR DI], GamePlayerBulletDeletedFlagPos

				DEC		[GamePlayerCurrentBullets]
			MovePlayerBulletLoopEnd:
				ADD		CL, 2D
				MOV		DL, GamePlayerBulletsLimit
				SHL		DL, 1
				CMP		CL,  DL ;If not the last bullet, loop
				JL		MovePlayerBulletLoop
			
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

	;/------------------------------------------------------------------\
	;|							Malloc									|
	;| 			Get a pointer to the first block of memory				|
	;| 			after SI That has at least AX ammount of free bytes		|
	;|							ARGUMENTS:								|
	;| SI - The starting location to search for							|
	;| AX - The number of bytes required								|
	;| BH - 0 - DB, 1 - DW												|
	;| 							RETURNS:								|
	;| SI - The starting location of the block							|
	;\------------------------------------------------------------------/
	PROC Malloc
		;Push registers that will be used
		PUSH	CX
		PUSH	BX
		PUSH	DI
		;Start of malloc procedure
		XOR		BL,BL
		MallocCheck:
			MOV		DI, SI
			MOV		CX, AX
			MallocCheckLoop:
				CMP		BL, [DI]
				JNE		MallocCurrentFail
				INC		DI
				LOOP	MallocCheckLoop
			;Succsesfully found
			JMP		MallocEnd
		MallocCurrentFail:
			CMP		BH, 1
			JE		MallocCurrentFailDW
			INC 	SI
			JMP		MallocCheck
			MallocCurrentFailDW:
			ADD		SI, 2
			JMP		MallocCheck
		MallocEnd:
			;Pop the registers
			POP		DI
			POP		BX
			POP		CX
			RET
	ENDP Malloc
END		start