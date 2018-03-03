; markMovingPossiblities PROCEDURE HEADER
; 	parameters: none
; 	return: void

proc markMovingPossiblities
  push cx
  push ax
  push bx

  push [selectedPanel]
  call datasegLocationToTableLocation ; tableX => cx, tableY => ax

  xor bx, bx ; will store 2 if two directions have no eating option (not exactly, but thats the concept. I'll increase bx after the
             ; first check (if we should), and if its 1 after the second check and we should increase again, but I won't bother increasing.)
             ; in short: only if have no eating option to both sides, put 1 in recursiveEatingNoMove

  mov byte ptr [recursiveEatingNoMove],0
  push 0
  push cx ; table x
  push ax ; table y
  call markRightOrLeft

  cmp byte ptr [recursiveEatingNoMove], 1
    jne MMPDontInc
    inc bx
  MMPDontInc:

  mov byte ptr [recursiveEatingNoMove],0
  push 1
  push cx ; table x
  push ax ; table y
  call markRightOrLeft

  cmp byte ptr [recursiveEatingNoMove], 1
    jne MMPHaveEatingOptions
    cmp bx, 1
      jne MMPHaveEatingOptions
    jmp MMPFinish

  MMPHaveEatingOptions:
    mov byte ptr [recursiveEatingNoMove],0

  MMPFinish:

  pop bx
  pop ax
  pop cx
  ret
endp markMovingPossiblities


; markRightOrLeft PROCEDURE HEADER
; 	parameters: whichDirection(0 for right mark 1 for left), table x, table y
; 	return: void
;
; MRRecursiveRound = the recursive round (how many times the recursive action was called),

MRRecursiveRound equ byte ptr [recursiveEatingNoMove]
MRMarkSide equ [bp+8]
MRTableX equ [bp+6]
MRTableY equ [bp+4]

  proc markRightOrLeft
    push bp
    mov bp, sp
    push ax
    push bx

    cmp MRRecursiveRound, 2 ; if its two, the current panel is two panels away from the original one
;                             if moved two times forward, it can't be a eating possibility, since we can't eat two
      je ERNoEatingMovement
    inc MRRecursiveRound

    ; first, calc the y
      push MRTableY ; contain the y
      call getMarkY ; will add 1 to the y / subtract 1 according to the turn
      cmp ax, 9
        je MROLFinish ; if illegal y (getMarkY returns 9 if illegal, even if -1), do not mark

    ; now, ax has the y. init x:
      mov bx, MRTableX
      cmp byte ptr MRMarkSide, 0
        jne MRSetXLeft
        add bx, 1 ; if here, right
        cmp bx, 7
          ja MROLFinish ; check that legal

        push 0 ; to mark right direction, for later the mark method
          jmp MRAfterSetX

      MRSetXLeft:
        sub bx, 1
        cmp bx, -1
        je MROLFinish

        push 1 ; to mark left direction, for later the mark method

      MRAfterSetX:

        push bx ; table x
        push ax ; table y
        call mark

        ; if there are no moving eating possibilites, make recursiveEatingNoMove 1
          cmp word ptr [markedPanelLeft], 0
            jne MROLFinish
          cmp word ptr [markedPanelRight], 0
            jne MROLFinish

    ERNoEatingMovement:
      mov byte ptr [recursiveEatingNoMove], 1 ; if here, gone of the table, and this flag tells that there is no eating possibility here

    MROLFinish:

    pop bx
    pop ax
    pop bp
    ret 6
  endp markRightOrLeft

; getMarkY PROCEDURE HEADER
; 	parameters: selected table y
; 	return: the y in ax, or 9 if shouldn't mark

GMYBoardY equ [bp+4]

proc getMarkY
  push bp
  mov bp, sp

  mov ax, GMYBoardY
  ; check wether its player 1 or 2 (go down or up)
  cmp byte ptr[turn], PLAYER_1_TURN
  jne MRPlayer2Y
    add ax, 1
    cmp ax, 7
      ja returnDontMark ; if out of board, dont mark
    jmp MRAfterYInit
  MRPlayer2Y:
    sub ax, 1
    cmp ax, -1
      je returnDontMark ; if out of board, dont mark

    jmp MRAfterYInit

  returnDontMark:
    mov ax, 9

  MRAfterYInit:
  pop bp
ret 2
endp getMarkY

; mark PROCEDURE HEADER
; 	parameters: whichDirection(0 for right mark 1 for left),table x, table y
; 	return: void

  MarkSide   equ [bp+8]
  MarkTableX equ [bp+6]
  MarkTableY equ [bp+4]

  proc mark
    push bp
    mov bp, sp
    push bx

    push MarkTableX
    push MarkTableY
    call boardLocationToDatasegLocation ; address in bx

    ; check if there is a player there
      push bx
      call getPlayer
      cmp ax, NO_PLAYER_CODE
        jne MCheckForEating

    or byte ptr[bx], 10000b ; mark
    push MarkSide
    push bx
    call setMarkingIndicators

    MAfterMark:
      push bx
      call renderPanel
      jmp MAfterAllMarkings

    MCheckForEating: ; will be here if there is a player where we should mark
      dec ax ; so that it will fit to the turn codes
      cmp byte ptr[turn], al
        je MAfterAllMarkings ; if its a player in the same team, don't mark

      MMarkForEating: ; mark the place behind the player which can be eaten
        push MarkSide
        push MarkTableX
        push MarkTableY
        call markRightOrLeft

        ; putting in the appropriate variable that he is for eating
          mov di, MarkSide
          cmp di, 1
          jne rightEatingCase
            inc di
          rightEatingCase:
            mov word ptr EatingRightAdress[di], bx
            jmp MAfterAllMarkings

    MAfterAllMarkings:

    pop bx
    pop bp
  ret 6
  endp mark

  ; setMarkingIndicators PROCEDURE HEADER
  ; 	parameters: marking side, dataseg address
  ; 	return: void

  SMIMarkSide       equ [bp+6]
  SMIDatasegAddress equ [bp+4]

  proc setMarkingIndicators
    push bp
    mov bp, sp
    push di
    push bx

    mov bx, SMIDatasegAddress
    mov di, SMIMarkSide
    cmp di, 1 ; if left
    jne notLeftMarking
      inc di
    notLeftMarking:
    mov markedPanelRight[di], bx

    pop bx
    pop di
    pop bp
    ret 4
  endp setMarkingIndicators

  ; isLegalForSelection PROCEDURE HEADER
  ; 	parameters: dataseg location
  ; 	return: true or false in ax

    ILFSDatasegLocation equ [bp+4]

    proc isLegalForSelection
      push bp
      mov bp, sp
      push bx

      push ILFSDatasegLocation
      call getPlayer ; puts the player in this block in ax
        cmp ax, NO_PLAYER_CODE
        je ILFSReturnFalse ; if there is no player there, wait for other mouse action

      ; check if the player clicked is the player who owns the turn
      mov bl, turn
      inc bl ; so that if the turn is player 1, bl will be equal to PLAYER_1_CODE
      cmp bl, al ; cmp turn+1 with player clicked (if the same, will be equal)
        jne ILFSReturnFalse

      mov ax, true
      jmp ILFSDone

      ILFSReturnFalse:
        mov ax, false

      ILFSDone:

      pop bx
      pop bp
      ret 2
    endp isLegalForSelection

  ; deselect PROCEDURE HEADER
  ; 	parameters: none
  ; 	return: void

  proc deselect
    push bx

    ; the left marked panel
      push 1
      call deselectSide

    ; the right marked panel
      push 0
      call deselectSide

    ; the selected panel
    mov bx, [selectedPanel]
      and byte ptr [bx], 00000111b
      push bx
      call renderPanel

    ; "clean"
      mov byte ptr[EatingLeftAdress], 0
      mov byte ptr[EatingRightAdress], 0

    pop bx
    ret
  endp deselect

; deselectSide PROCEDURE HEADER
; 	parameters: whichDirection(0 for right mark 1 for left)
; 	return: void

DSSide equ [bp+4]

proc deselectSide
  push bp
  mov bp, sp
  push bx

  mov bx, [markedPanelLeft]
  cmp byte ptr DSSide, 0
    jne DSDontChangeToRight
    mov bx, [markedPanelRight]

  DSDontChangeToRight:
    and byte ptr[bx], 00001111b
    push bx
    call renderPanel

  cmp byte ptr DSSide, 0
    je DSClearRight
    mov byte ptr[markedPanelLeft], 0
    jmp DSFinish
  DSClearRight:
    mov byte ptr[markedPanelRight], 0

  DSFinish:
    mov byte ptr [recursiveEatingNoMove], 0

  pop bx
  pop bp
  ret 2
endp deselectSide
