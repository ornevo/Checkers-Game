;	NOTE: alt+x+enter for fullscreen in dosbox

MODEL small
STACK 100h
DATASEG

	; !IMPORTANT!: keep the board first in the dataseg
	; table panels value definitons:
	;		00 = black empty
	;		1 = white empty
	;			011 = white with player 1 in it
	;			111 = white with player 2 in it
	;		1xxx = selected (clicked on turn)
	;		10xxx = marked (for movement)
	;		is marked		is selected		Player2/Player1		there is a player? 		panel color
	;			 0/1					0/1							0/1		  				  0/1								  0/1

	row1 db 4 dup (0,    011b)
	row2 db 4 dup (011b, 0)
	row3 db 4 dup (0,    011b)
	row4 db 4 dup (1,    0)
	row5 db 4 dup (0,    1)
	row6 db 4 dup (111b, 0)
	row7 db 4 dup (0,    111b)
	row8 db 4 dup (111b, 0)

	turn db 1

	marginLeft 	equ 60		; (width-height)/2 = (320 - 200) / 2
	panelSize 	equ 25		;	boardSize/panelsAmount = 200/8
	; colors
		white 				db 15
		black 				db 0
		player1Color 	db 4  ; red
		player2Color 	db 1  ; blue
		selectedColor db 13 ; pink
		markedColor		db 14 ; yello

		PLAYER_1_CODE  equ 1
		PLAYER_2_CODE  equ 2
		AI_CODE 			 equ 2
		NO_PLAYER_CODE equ 0

		PLAYER_1_TURN equ 0
		PLAYER_2_TURN equ 1
		true equ 1
		false equ 0

	circle db 7, 11, 13, 15, 17, 19, 19, 7 dup (21), 19, 19, 17, 15, 13, 11, 7

	selectedPanel     dw 0 ; the dataseg address of the selected panel
	markedPanelRight  dw 0
	markedPanelLeft   dw 0
	EatingRightAdress dw 0
	EatingLeftAdress  dw 0

	recursiveEatingNoMove 		db 0 ; will be on if a recursive proc has gone off table, or when trying to eat 2 (good for checking eating possibities)

	; AI
	PWalkFrom dw -1
	PWalkTo		dw -1


	titleLine1 	db 	11111111b, 11100111b, 11111111b, 11111111b, 11000011b, 11111111b, 11111000b, 11111111b
	titleLine2 	db 	11100000b, 11100111b, 11100000b, 11100000b, 11001100b, 11100000b, 11001100b, 11000000b
	titleLine3 	db 	11100000b, 11111111b, 11111111b, 11100000b, 11110000b, 11111111b, 11111000b, 11111111b
	titleLine4 	db	11100000b, 11100111b, 11100000b, 11100000b, 11001100b, 11100000b, 11001100b, 00000011b
	titleLine5 	db	11111111b, 11100111b, 11111111b, 11111111b, 11000011b, 11111111b, 11000111b, 11111111b

	playerLine1 	db  00000000b, 11111110b, 11000000b, 00011000b, 11000011b, 11111111b, 11111000b, 00000000b
	playerLine2 	db	00000000b, 11000011b, 11000000b, 01100110b, 01100110b, 11100000b, 11001100b, 00000000b
	playerLine3 	db	00000000b, 11111110b, 11000000b, 11000011b, 00111100b, 11111111b, 11111000b, 00000000b
	playerLine4 	db	00000000b, 11000000b, 11111111b, 11111111b, 00011000b, 11100000b, 11001100b, 00000000b
	playerLine5 	db	00000000b, 11000000b, 11111111b, 11000011b, 00011000b, 11111111b, 11000111b, 00000000b

	vsLine1	db	00000000b, 00000000b, 00000000b, 11000011b, 11111111b, 00000000b, 00000000b, 00000000b
	vsLine2	db	00000000b, 00000000b, 00000000b, 11000011b, 11000000b, 00000000b, 00000000b, 00000000b
	vsLine3	db	00000000b, 00000000b, 00000000b, 01100110b, 11111111b, 00000000b, 00000000b, 00000000b
	vsLine4	db	00000000b, 00000000b, 00000000b, 00111100b, 00000011b, 00000000b, 00000000b, 00000000b
	vsLine5	db	00000000b, 00000000b, 00000000b, 00011000b, 11111111b, 00000000b, 00000000b, 00000000b

	AILine1  db 00000000b, 00000000b, 00000000b, 00011000b, 11111111b, 00000000b, 00000000b, 00000000b
	AILine2  db 00000000b, 00000000b, 00000000b, 01100110b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine3  db 00000000b, 00000000b, 00000000b, 11000011b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine4  db 00000000b, 00000000b, 00000000b, 11000011b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine5  db 00000000b, 00000000b, 00000000b, 11111111b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine6  db 00000000b, 00000000b, 00000000b, 11000011b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine7  db 00000000b, 00000000b, 00000000b, 11000011b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine8  db 00000000b, 00000000b, 00000000b, 11000011b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine9  db 00000000b, 00000000b, 00000000b, 11000011b, 00011000b, 00000000b, 00000000b, 00000000b
	AILine10 db 00000000b, 00000000b, 00000000b, 11000011b, 11111111b, 00000000b, 00000000b, 00000000b

	playerTallLine1 	db  00000000b, 11111100b, 11000000b, 00011000b, 11000011b, 11111111b, 11111100b, 00000000b
	playerTallLine2 	db	00000000b, 11000110b, 11000000b, 01100110b, 11000011b, 11111111b, 11000110b, 00000000b
	playerTallLine3 	db	00000000b, 11000011b, 11000000b, 11000011b, 01100110b, 11000000b, 11000011b, 00000000b
	playerTallLine4 	db	00000000b, 11000110b, 11000000b, 11000011b, 01100110b, 11000000b, 11000110b, 00000000b
	playerTallLine5 	db	00000000b, 11111100b, 11000000b, 11111111b, 00111100b, 11111111b, 11111100b, 00000000b
	playerTallLine6 	db  00000000b, 11000000b, 11000000b, 11000011b, 00011000b, 11111111b, 11110000b, 00000000b
	playerTallLine7 	db	00000000b, 11000000b, 11000000b, 11000011b, 00011000b, 11000000b, 11011000b, 00000000b
	playerTallLine8 	db	00000000b, 11000000b, 11000000b, 11000011b, 00011000b, 11000000b, 11001100b, 00000000b
	playerTallLine9 	db	00000000b, 11000000b, 11111111b, 11000011b, 00011000b, 11111111b, 11000110b, 00000000b
	playerTallLine10 	db	00000000b, 11000000b, 11111111b, 11000011b, 00011000b, 11111111b, 11000011b, 00000000b

	gameOverTitle1r1 	db  00000000b, 00000000b, 11111110b, 00011000b, 01000010b, 11111111b, 00000000b, 00000000b
	gameOverTitle1r2 	db	00000000b, 00000000b, 11000000b, 01100110b, 11100111b, 11100000b, 00000000b, 00000000b
	gameOverTitle1r3 	db	00000000b, 00000000b, 11001111b, 11000011b, 11011011b, 11111111b, 00000000b, 00000000b
	gameOverTitle1r4 	db	00000000b, 00000000b, 11000110b, 11111111b, 11011011b, 11100000b, 00000000b, 00000000b
	gameOverTitle1r5 	db	00000000b, 00000000b, 11111110b, 11000011b, 11000011b, 11111111b, 00000000b, 00000000b

	gameOverTitle2r1 	db  00000000b, 00000000b, 11111111b, 11000011b, 11111111b, 11111000b, 00000000b, 00000000b
	gameOverTitle2r2 	db	00000000b, 00000000b, 11000011b, 11000011b, 11100000b, 11001100b, 00000000b, 00000000b
	gameOverTitle2r3 	db	00000000b, 00000000b, 11000011b, 01100110b, 11111111b, 11111000b, 00000000b, 00000000b
	gameOverTitle2r4 	db	00000000b, 00000000b, 11000011b, 00111100b, 11100000b, 11001100b, 00000000b, 00000000b
	gameOverTitle2r5  db	00000000b, 00000000b, 11111111b, 00011000b, 11111111b, 11000111b, 00000000b, 00000000b

	exitTitle1 db  00000000b, 00000000b, 11111111b, 11000011b, 01111110b, 11111111b, 00000000b, 00000000b
	exitTitle2 db  00000000b, 00000000b, 11100000b, 01100110b, 00011000b, 00011000b, 00000000b, 00000000b
	exitTitle3 db  00000000b, 00000000b, 11111111b, 00111100b, 00011000b, 00011000b, 00000000b, 00000000b
	exitTitle4 db  00000000b, 00000000b, 11100000b, 01100110b, 00011000b, 00011000b, 00000000b, 00000000b
	exitTitle5 db  00000000b, 00000000b, 11111111b, 11000011b, 01111110b, 00011000b, 00000000b, 00000000b

	exitOption1 db  00000000b, 00000000b, 11000011b, 00000000b, 00000000b, 11110011b, 00000000b, 00000000b
	exitOption2 db  00000000b, 00000000b, 01100110b, 00000000b, 00000000b, 11011011b, 00000000b, 00000000b
	exitOption3 db  00000000b, 00000000b, 00111100b, 00000000b, 00000000b, 11011011b, 00000000b, 00000000b
	exitOption4 db  00000000b, 00000000b, 00011000b, 00000000b, 00000000b, 11011011b, 00000000b, 00000000b
	exitOption5 db  00000000b, 00000000b, 00011000b, 00000000b, 00000000b, 11011110b, 00000000b, 00000000b
		EGMCurrOption  dw 0

	PvWhat db ? ; if its 0, its PvP, and if 1, PvAI
	gameStage db 0 ; 0 for menu, 1 for in-game, 2 for game over

CODESEG

	include AI.asm
	include convert.asm
	include graphics.asm
	include logic.asm
	include menu.asm
	include renderer.asm
	include select.asm

	start:
		mov ax, @data
		mov ds, ax

		; switch to graphics mode
			mov ax, 13h
			int 10h

		; init mouse
			mov ax, 0
			int 33h

		; show it
			mov ax, 1
			int 33h

		call startMenu

		inc byte ptr [gameStage] ; inc game stage to 1 - in-game

		call renderBoard

		mov al, true
		mainGameLoop:
			call didGameOver
			cmp al, true
				jne gameIsNotOver
				jmp gameOverScreen
			gameIsNotOver:
			call nextTurnSet
			cmp byte ptr [PvWhat], 0
				je playVSPlayer

			cmp byte ptr [turn], PLAYER_2_TURN
			 	jne playVSPlayer

			call AITurn

			jmp mainGameLoop

			playVSPlayer:
			call nextTurn
		jmp mainGameLoop

		gameOverScreen:
		inc byte ptr [gameStage] ; inc game stage to 2 - game over

    ; hide the cursor
      mov ax, 2
      int 33h

		push 200
		push 320
		push 0
		push 0
		push 0
		call drawSquare

		; game over screen
		push 15
		push offset gameOverTitle1r1
		push RMMarginLeft
		push 80
			call renderWord
		push 15
		push offset gameOverTitle2r1
		push RMMarginLeft
		push 80 + 5*3 + 5
			call renderWord

    ; bring the cursor back again
      mov ax, 1
      int 33h

		call getMouseAction
		call finishProgram


	proc nextTurnSet

		xor byte ptr [turn], 1 ; flip the turn

		; calc the color of player
			xor bh, bh
			mov bl, [player1Color]
				cmp byte ptr [turn], PLAYER_1_TURN
					je NTSAfterColorSet
				player_2_turn_color:
					mov bl,  [player2Color]
			NTSAfterColorSet:

		; hide the cursor before printing: will not print on cursor location otherwise
			mov ax, 2
			int 33h

		; render panel left
			push 200
			push 60
			push 0
			push 0
			push bx
			call drawSquare

		; render panel right
			push 200
			push 60
			push 260
			push 0
			push bx
			call drawSquare

		; bring the cursor back again
			mov ax, 1
			int 33h

		ret
	endp nextTurnSet


	; a game is over when there are no more possible moves / no more players from a specific side

	DGOP1PlayersCount equ byte ptr [bp-2]
	DGOP2PlayersCount equ byte ptr [bp-4]
	DGOP1MovesCount 		equ byte ptr [bp-6]
	DGOP2MovesCount 		equ byte ptr [bp-8]

	proc didGameOver
		push bp
		mov bp, sp
		sub sp, 8
		push bx
		push cx
		push dx

		mov DGOP1PlayersCount, 0
		mov DGOP2PlayersCount, 0
		mov DGOP1MovesCount, 0
		mov DGOP2MovesCount, 0

		; looping over the possibles moves
		mov cx, 1 ; players at the first row can't move anyway
		DGOHeightLoop:

			mov dx, 0
			DGOWidthLoop:

				push dx
				push cx
				call boardLocationToDatasegLocation

				push bx
				call getPlayer
				cmp al, NO_PLAYER_CODE
					je DGONoPlayersInc

				cmp al, PLAYER_1_CODE
					je DGOIncPlayer1

				inc DGOP2PlayersCount
				cmp cx, 0
					je DGONoPlayersInc
				inc DGOP2MovesCount
				jmp DGONoPlayersInc

				DGOIncPlayer1:
					inc DGOP1PlayersCount
					cmp cx, 7
						je DGONoPlayersInc
					inc DGOP1MovesCount

				DGONoPlayersInc:

				inc dx
			cmp dx, 8
				jb DGOWidthLoop

			inc cx
		cmp cx, 8
			jb DGOHeightLoop

		mov al, false
		cmp DGOP1PlayersCount, 0
			je DGORetrunTrue
		cmp DGOP2PlayersCount, 0
			je DGORetrunTrue
		cmp DGOP1MovesCount, 0
			je DGORetrunTrue
		cmp DGOP2MovesCount, 0
			je DGORetrunTrue

		jmp DGOFinish

		DGORetrunTrue:
			mov al, true

		DGOFinish:

		pop dx
		pop cx
		pop bx
		add sp, 8
		pop bp
		ret
	endp didGameOver

END start
