; RENDERBOARD PROCEDURE HEADER
; 	parameters: none
; 	return: void

  proc renderBoard
    push ax
    push bx

    mov bx, offset row1
    renderBoardPanelsLoop:

      push bx
      call renderPanel

    ; check if arraived to the last panel, and loop again if it didn't
    inc bx
    cmp bx, 8*8 + offset row1
      jb renderBoardPanelsLoop

    pop bx
    pop ax
    ret
  endp

  ; RENDERPANEL PROCEDURE HEADER
  ; 	parameters: the panel dataseg location (board location...)
  ; 	return: void

  DSBoardLocation equ [bp+4]

  proc renderPanel
      push bp
      mov bp, sp
      push ax
      push bx
      push cx
      push dx

      ; hide the cursor before printing: will not print on cursor location otherwise
      mov ax, 2
      int 33h

      mov bx, DSBoardLocation
      ; getting the value of the panel, and printing accordingly
      mov al, byte ptr [bx] ; holds the panel value
      xor ch,ch ; cx will store the color, and i'll change only cl. so ch should be 0
      shr al, 1 ; so that the right bit - the panel color - will be in the carry flag
      jnc notWhiteEmpty
        mov cl, [white]
        jmp GPSelectedCheck
      notWhiteEmpty:
        mov cl, [black]

      ; check if selected or marked
      GPSelectedCheck:
        shr al, 3 ; if selected, the carry will be 1. so check if it is.
          jnc GPMarkedCheck
          mov cl, [selectedColor]
          jmp printSquare

        GPMarkedCheck:
        shr al, 1 ; if marked, the carry will be 1. so check if it is.
          jnc printSquare
          mov cl, [markedColor]


      printSquare: ; now, printing the panel
        push panelSize-1 ; height
        push panelSize-1 ; width

        push bx ; dataseg location for datasegLocationToPixelLocation
        call datasegLocationToPixelLocation
          push ax ; x
          push bx ; y
          push cx ; color

        call drawSquare

      ; I will push the X and Y for the player before checking the player, because the player check changes ax
      push ax ; x
      push bx ; y

      push DSBoardLocation
      call getPlayer ; will return the player code in ax

      ; now, we will check the player code returned, and act accordingly
        cmp ax, NO_PLAYER_CODE
          je noPlayerHere

        cmp ax, PLAYER_1_CODE
          jne GPColorPlayer2
          mov dl, [player1Color]
          jmp GPPrintCircle
        GPColorPlayer2:
          mov dl, [player2Color]

      ; checking for a player, and printing if there
      GPPrintCircle:
          xor dh, dh
          push dx ; color
          call drawCircle
          jmp PPDone

      noPlayerHere: ; we need to pop th x and y that are still in the stack, since we didn't called draw circle, that should have poped them
        pop ax
        pop bx

      PPDone:

      ; bring the cursor back again
      mov ax, 1
      int 33h

      pop dx
      pop cx
      pop bx
      pop ax
      pop bp
    ret 2
  endp renderPanel
