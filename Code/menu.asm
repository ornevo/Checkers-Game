; startMenu PROCEDURE HEADER
; 	parameters: none
; 	return: void

proc startMenu
  push ax
  push bx
  push cx
  push dx

  call renderMenu
  xor bx, bx ; will hold which option is currently on (0 for player, 1 for AI)
  SMInputListening:

    ; bring the cursor again
    mov ax, 1
    int 33h

    call getMouseAction

    ; hide the cursor, so we will not get the cursor color
      mov ax, 2
      int 33h

    cmp cx, -1 ; if enter was clicked
      je SMAfterInput

    ; get the color of the clicked pixel
    mov ah, 0Dh
    mov bh, 0
    int 10h ; now, al contains the color

    cmp al, RMArrowColor
     jne dSMDontSwitchOptions

     cmp cx, 100
      jbe SMChaneToPlayerGM
      cmp bx, 1
        je SMInputListening ; if AI is already the shown option, do not re-render
        inc bx ; make bx 1
      jmp SMRnderGameMode
    SMChaneToPlayerGM:
      cmp bx, 0
        je SMInputListening ; if player is already the shown option, do not re-render
      dec bx
    SMRnderGameMode:
      push bx ; the option
      call renderAsGameMode

   dSMDontSwitchOptions:

  jmp SMInputListening
  SMAfterInput:

    ; bring the cursor again
    mov ax, 1
    int 33h

    mov byte ptr [PvWhat], bl

  pop dx
  pop cx
  pop bx
  pop ax
  ret
endp startMenu

; renderMenu PROCEDURE HEADER
; 	parameters: none
; 	return: void

RMMarginTop       equ 20
RMMarginLeft      equ 53
RMBlockSize       equ 3
RMMaxNumOfLetters equ 8
RMArrowColor     equ 44

proc renderMenu
  push dx
  push bx
  push ax
  push si

  ; hide the cursor before printing: will not print on cursor location otherwise
    mov ax, 2
    int 33h

  mov ax, 0
  RMHrLoop:

    push ax
    push RMMarginTop + 5*3 + 3*3
    mov bx, 1
    and bx, ax
    cmp bx, 1
      je RMRed
      push 1
      jmp RMCallDrawCircle
    RMRed:
      push 4

    RMCallDrawCircle:
    call drawCircle

  add ax, 21
  cmp ax, 310
  jb RMHrLoop

  ; printing the menu
    ; render the title
      push 15
      push offset titleLine1
      push RMMarginLeft
      push RMMarginTop
        call renderWord

    ; render the PLAYER word
      push 15
      push offset playerLine1
      push RMMarginLeft
      push RMMarginTop + 60
        call renderWord

    ; render the VS word
      push 15
      push offset vsLine1
      push RMMarginLeft
      push RMMarginTop + 60 + 5*3 + 3
        call renderWord

    ; arrows
      push RMArrowColor
      push 1
      push RMMarginLeft + 3
      push RMMarginTop + 60 + 5*3 + 3 + 46
        call drawTriangle

      push RMArrowColor
      push 0
      push RMMarginLeft + 8*3*8 + 5
      push RMMarginTop + 60 + 5*3 + 3 + 46
        call drawTriangle

    ; render options box
      push 0
      call renderAsGameMode

    ; bring the cursor again
      mov ax, 1
      int 33h

  pop si
  pop ax
  pop bx
  pop dx
  ret
endp renderMenu

; renderWord PROCEDURE HEADER
; 	parameters: color, offset, x, y
; 	return: void

  RWColor equ  [bp+10]
  RWOffset equ  [bp+8]
  RWX      equ  [bp+6]
  RWY      equ  [bp+4]

proc renderWord
  push bp
  mov bp, sp
  push dx
  push bx
  push ax
  push si

  mov si, RWOffset
  mov ax, RWY ; the y
  mov dx, RWX ; the x

  RMPrintingLoop:

    mov bl, [si]
    add dx, RMBlockSize * 8 ; 53+3*8

    mov cx, 8
    RMBitLoop:

      shr bl, 1
      jnc RMDontRender
        push RMBlockSize
        push RMBlockSize
        push dx
        push ax
        push RWColor ; white
        call drawSquare
      RMDontRender:
      sub dx, RMBlockSize

    loop RMBitLoop

    add dx, 8 * RMBlockSize + 2

    mov bx, RWX
      add bx, 8 * ( RMMaxNumOfLetters * RMBlockSize) ; 53 + 8*8*3 = 245
    cmp dx, bx
      jbe RMNotNextLine

      mov dx, RWX
      add ax, RMBlockSize

      RMNotNextLine:

    inc si

    mov bx, RWOffset
      add bx, 5 * RMMaxNumOfLetters
    cmp si, bx
      jb RMPrintingLoop


  pop si
  pop ax
  pop bx
  pop dx
  pop bp
  ret 8
endp renderWord

; renderAsGameMode PROCEDURE HEADER
; 	parameters: the option (0 for player, 1 for AI)
; 	return: void

RAGMOption equ [bp+4]
optionsY equ 139
optionsX equ 72

proc renderAsGameMode
  push bp
  mov bp, sp
  push ax

  push 34
  push 8*8*3+7-19-6
  push optionsX
  push optionsY
  push 2; 48
    call drawSquare

  mov ax, offset playerTallLine1
  cmp word ptr RAGMOption, 1
    jne RAGMDonNotChangeToPvP
    mov ax, offset AILine1

  RAGMDonNotChangeToPvP:

  push 0
  push ax
  push RMMarginLeft
  push optionsY + 2
    call renderWord

  add ax, 5*8
  push 0
  push ax
  push RMMarginLeft
  push optionsY + 2 + 5*3
    call renderWord

  pop ax
  pop bp
  ret 2
endp renderAsGameMode

; exitGameMenu PROCEDURE HEADER
; 	parameters: none
; 	return: void
;
; set position:
; mov ah, 2
; mov bh, 0
; mov dh, 10
; mov dl, (80-35)/2
; int 10h

  proc exitGameMenu

    ; border
      push 80
      push 160
      push (320-160)/2
      push (200-80)/2
      push 3
      call drawSquare

    ; inner color
      push 80-6
      push 160-6
      push (320-160)/2 + 3
      push (200-80)/2 + 3
      push 0
      call drawSquare

    ; write the title
      push 15
      push offset exitTitle1
      push RMMarginLeft
      push 70
      call renderWord

    ; write the options
      push 15
      push offset exitOption1
      push RMMarginLeft
      push 110
      call renderWord

    mov EGMCurrOption, 0
    push 2
    push 5*3 * 2
    push RMMarginLeft + 8*3*5 + 5*2
    push 110 + 5*3 + 4
    push 11
    call drawSquare

    EGMLoop: ; at D90
      mov ah, 1
      int 16h
        jz EGMLoop ; if no button clicked, wait for action
      ; get button clicked
        mov ah, 0
        int 16h
        cmp al, 121 ; if Y
          je EGMChangeOption
        cmp al, 110 ; if n
          je EGMChangeOption
        cmp al, 0Dh ; if enter
          je EGMSelectedOption
      jmp EGMLoop

      EGMChangeOption: ; will change to the one in al
        ; delete the orev underscore
          push 2
          push 160-6
          push (320-160)/2 + 3
          push 110 + 5*3 + 4
          push 0
          call drawSquare

          jmp GMEAfterUglyPieceOfCode

        ; I know its ugly, but I have to stuck this piece of code here. otherwise, it will be out of jumping range...
                      EGMSelectedOption:
                      cmp EGMCurrOption, 1
                        jne EGMFinish
                      call finishProgram
        ; end of that

        GMEAfterUglyPieceOfCode:

        mov EGMCurrOption, 0 ; move 'no' to the selection as default
        push 2 ; push the underscore height
        push 5*3 * 2 ; push the underscore width

        ; now, will push the x according to the option. if y, move 'yes' to the selection
        cmp al, 121 ; if y
          jne EGMChangeToNo
          mov EGMCurrOption, 1
          push RMMarginLeft + 8*3*2 + 2*2
          jmp EGMAgterSettingX
        EGMChangeToNo:
          push RMMarginLeft + 8*3*5 + 5*2

        EGMAgterSettingX:
        push 110 + 5*3 + 4
        push 11
        call drawSquare

        jmp EGMLoop

      EGMFinish:

      call renderBoard

    ret
  endp exitGameMenu
