; nextTurn PROCEDURE HEADER
; 	parameters: none
; 	return: void

	proc nextTurn
		push ax
		push bx
		push cx
		push dx

			NTGetMouseAgain:
				call deselect
				call getMouseAction

			; if the x is out of board, get mouse again
			cmp cx, marginLeft
				jb NTGetMouseAgain
			cmp cx, marginLeft + (panelSize * 8)
				ja NTGetMouseAgain

			; now, getting the dataseg location using two procedures
			push cx ; pixels x
			push dx ; pixels y
			call pixelLocationToDatasegLocation ; will return the dataseg location of the clicked panel, and store it in bx

			; checking if the panel is legal for selecting
				push bx
				call isLegalForSelection
				cmp ax, false
				je NTGetMouseAgain ; if the panel selected is not legal, get the mouse action again

			mov word ptr[selectedPanel], bx ; put in selectedPanel the selected pane dataseg address

			call markMovingPossiblities

			; making the panel selected, by turning its third bit on (look at the dataseg details)
			or byte ptr [bx], 1000b
				; render the changed panel
				push bx
				call renderPanel

			; move
			NTMovementMouseLoop:
				call getMouseAction
				; get the dataseg location
					push cx ; pixels x
					push dx ; pixels y
					call pixelLocationToDatasegLocation ; will return the dataseg location of the clicked panel, and store it in bx

					; check if its the same panel as selected, and if it is,
					; get the mouse again (without deselecting). needed to prevent double respond to a single click
						cmp bx, word ptr[selectedPanel]
							je NTMovementMouseLoop
					; if not the selected panel, check if a marked
						push bx
						call isMarkedPanel ; return in ax. if not marked, return false. if yes, return true
						cmp ax, false ; if not marked, deselect and get mouse selection again
							je NTGetMouseAgain

				; if arrived here, selected a marked panel
				NTLegalMovementPanel:
					push bx ; saving for later the panel to which we should move to (move proc)
          push bx ; saving for recursive eating, to know where the player is after moving
					push bx
						call getEatenPanel
						cmp bx, false ; if no player is eaten in the moving action, move and finish
							je NTMoveAndFinish

						NTPlayerWasEating:
							and byte ptr [bx], 01b ; remove the player from the eaten panel
							push bx
							call renderPanel

							call move
							call deselect

							pop bx
							mov word ptr[selectedPanel], bx
								call eatRecursive

							jmp NTFinish

			NTMoveAndFinish:

			call move ; the location was pushed before the eating checks
			pop bx

			NTFinish:

			pop dx
			pop cx
			pop bx
			pop ax
		ret
	endp nextTurn

	; eatRecursive PROCEDURE HEADER
	; 	parameters: none
	; 	return: void

	proc eatRecursive
		push ax

		mov bx, [selectedPanel]
		call markMovingPossiblities
		xor al, al ; to check if two sides have no eating possibility. ax will be increased each time I deselect, and if
							 ; its value is 2 after checkings, both directions have no eating possibility.

		; check if there is an eating possibility, and where there isn't, deselect
			cmp word ptr [EatingRightAdress], 0
				je ERDeselectRight
			ERCheckLeftEatingPoss:
			cmp word ptr [EatingLeftAdress], 0
				je ERDeselecLeft
			cmp byte ptr [recursiveEatingNoMove], 1 ; if no movement option, don't act
				je ERFinish

		jmp DSAfterDeselecting

		ERDeselectRight:
			push 0
			call deselectSide
			inc ax
			jmp ERCheckLeftEatingPoss
		ERDeselecLeft:
			push 1
			call deselectSide
			inc ax

		DSAfterDeselecting:
			; first, making sure that there is a eating possibility (why comparing ax to 2? check out the forth line in this procedure)
			cmp ax, 2
				je ERFinish
      ; making the panel selected, by turning its fourth bit on (look at the dataseg details)
      or byte ptr [bx], 1000b
        ; render the changed panel
        push bx
        call renderPanel

      ; getting mouse input
      ; from here on, very similar to nextTurn action
      ERMouseLoop:
      call getMouseAction
        ; get the dataseg location
          push cx ; pixels x
          push dx ; pixels y
          call pixelLocationToDatasegLocation ; will return the dataseg location of the clicked panel, and store it in bx

        ; check if its the same panel as selected, and if it is,
        ; get the mouse again (without deselecting). needed to prevent double respond to a single click
          cmp bx, word ptr[selectedPanel]
            je ERMouseLoop

        ; if not the selected panel, check if a marked
          push bx
          call isMarkedPanel ; return in ax. if not marked, return false. if yes, return true
          cmp ax, false ; if not marked, end the turn
            je ERFinish

        ; eating
          push bx ; saving for later the panel to which we should move to (move proc)
          push bx ; saving for recursive eating, to know where the player is after moving
          push bx
						call getEatenPanel ; now, the player we ate dataseg address in bx

          and byte ptr [bx], 01b ; remove the player from the eaten panel
          push bx
          call renderPanel

          call move
					call deselect

        ; call the eatRecursive proc again
          pop bx
          mov word ptr[selectedPanel], bx
						call deselect
            call eatRecursive

		ERFinish:

			call deselect

		pop ax
		ret
	endp eatRecursive

;===============================================================================
;																	HELPERS
;===============================================================================


; getEatenPanel PROCEDURE HEADER
; 	parameters: the moving-to panel adress
; 	return: the eaten panel address in bx, or false if not eaten

	GEPMovingToPanel equ [bp+4]

	proc getEatenPanel
		push bp
		mov bp, sp

		mov bx, GEPMovingToPanel

		; first, lets check if the player moved right or left
		cmp bx, [markedPanelRight]
			je GEPRightEatingCheck
			jmp GEPLeftEatingCheck

		; now, lets check if the movement is eating someone
			GEPRightEatingCheck:
				mov bx, word ptr [EatingRightAdress] ; keep the address of the eaten panel
				cmp bx, 0
					jne GEPPlayerWasEating
			jmp GEPReturnFalse

			GEPLeftEatingCheck:
				mov bx, word ptr [EatingLeftAdress] ; keep the address of the eaten panel
				cmp bx, 0
					jne GEPPlayerWasEating

			GEPReturnFalse:
				mov bx, false

			GEPPlayerWasEating:

		pop bp
		ret 2
	endp getEatenPanel

; move PROCEDURE HEADER
; 	parameters: dataseg address of the clicked panel, from where in selectedPanel
; 	return: void

	MDatasegAddress equ [bp+4]

	proc move
		push bp
		mov bp, sp
		push bx

		; check the player turn, and add player in the player turn color to the clicked panel
			mov bx, MDatasegAddress
			or byte ptr[bx], 10b
		; if player 2, change the panel player color
			push [selectedPanel]
			call getPlayer
			cmp ax, PLAYER_2_CODE
			jne MDontChangePlayerColor
			or byte ptr[bx], 100b

		MDontChangePlayerColor:
		push bx
		call renderPanel

		; deselect
			call deselect
		; remove player from the prev panel, and render it
			mov bx, [selectedPanel]
			and byte ptr[bx], 01b
			push bx
			call renderPanel

		pop bx
		pop bp
		ret 2
	endp move


; isMarkedPanel PROCEDURE HEADER
; 	parameters: dataseg address
; 	return: true / false in ax. Whether this panel is marked

	IMPDatasegAddress equ [bp+4]

	proc isMarkedPanel
		push bp
		mov bp, sp
		push bx

		mov ax, true
		mov bx, IMPDatasegAddress
		cmp word ptr[markedPanelRight], bx
			je IMPAfterCheck
		cmp word ptr[markedPanelLeft], bx
			je IMPAfterCheck
		mov ax, false

		IMPAfterCheck:

		pop bx
		pop bp
		ret 2
	endp isMarkedPanel

; getMouseAction PROCEDURE HEADER
; 	parameters: none
; 	return: the mouse click X in cx, and mouse click Y in dx
;		if clicked enter, will return -1 in cx. if clicked esc, will exit the program
	proc getMouseAction
		push bx
		push ax

		GMAWaitingForMouse:
			; check for mouse action, and check if its the left button
				mov ax, 3
				int 33h ; bx contains clicking status
				cmp bx, 1
					je mouseDetected ; keep waiting as long as the left mouse button wasn't clicked
			; check if Esc was pressed, and if it did, exit the game
				mov ah, 1
				int 16h
					jz GMAWaitingForMouse ; if no button clicked, wait for action
				; get button clicked
					mov ah, 0
					int 16h
					cmp al, 0Dh ; enter
						je GMAEnterPressed
					cmp al, 27
						jne GMAWaitingForMouse ; if buttonClicked != Esc, wait for action
			; here if Esc clicked. if in menu, quit. otherwise, ask if want to exit.
				cmp byte ptr [gameStage], 1
					je GMANotInMenu
					call finishProgram
				GMANotInMenu:
				call exitGameMenu

		GMAEnterPressed:
			mov cx, -1
			jmp GMAAfterDividing

		mouseDetected:
			shr cx, 1 ; divide cx by 2

		GMAAfterDividing:
		pop ax
		pop bx
		ret
	endp getMouseAction

	;===============================================================================
	;															 PANEL INTERPETATION
	;===============================================================================

	; getPlayer PROCEDURE HEADER
	; 	parameters: the panel dataseg location
	; 	return: the player code in ax (PLAYER_1_CODE, PLAYER_2_CODE, NO_PLAYER_CODE).

	GPDatasegAddress equ [bp+4]

	proc getPlayer
		push bp
		mov bp, sp
		push bx

		mov bx, GPDatasegAddress
		mov ax, [bx]
		shr ax, 1 ; check panel color
		jc notBlackPanel
			jmp GPReturnNoPlayer
		notBlackPanel:
			shr ax, 1 ; check if there if a player there
			jnc GPReturnNoPlayer
			shr ax, 1 ; check the player color
			jc GPReturnPlayer2 ; return accordingly
				mov ax, PLAYER_1_CODE
				jmp GPDone
			GPReturnPlayer2:
				mov ax, PLAYER_2_CODE
				jmp GPDone


		GPReturnNoPlayer:
			mov ax, NO_PLAYER_CODE ; if a black panel, the player can't be there
		GPDone:

		pop bx
		pop bp
		ret 2
	endp getPlayer


	; finishProgram PROCEDURE HEADER
	; 	parameters: none
	; 	return: void

	proc finishProgram
		; switch back to text mode
		mov ah,0
		mov al,2
		int 10h

		exit:
			mov ax, 4c00h
			int 21h

		ret
	endp finishProgram
