
  ; datasegLocationToPixelLocation PROCEDURE HEADER
  ; 	parameters: dataseg loction
  ; 	return: the x in ax, and the y in bx.
  ;
  ;   working according to this formula:
  ;     datasegLocation = the location in the dataseg
  ;     tableY  = datasegLocation / 8
  ;     tableX  = datasegLocation - tableY*8
  ;     pixelsX = tableX * panelSize + marginLeft
  ;     pixelsY = tableY * panelSize
  ;
  ;   where the table locations are cells numbers - first cell is 0,0 and last cell is 7,7

  datasegLocation equ [bp+4]

  proc datasegLocationToPixelLocation
    push bp
    mov bp, sp
    push cx

      push datasegLocation
      call datasegLocationToTableLocation ; now, tableX => cx && tableY => ax

      push cx ; table x
      push ax ; table y
      call tableLocationToPixelLocation

    pop cx
    pop bp
    ret 2
  endp datasegLocationToPixelLocation

;====================================================================================;

  ; tableLocationToPixelLocation PROCEDURE HEADER
  ; 	parameters: the tableX and tableY
  ; 	return: the pixel-x in ax, and the pixel-y in bx.
  ;
  ;   working according to this formula:
  ;     pixelsX = tableX * panelSize + marginLeft
  ;     pixelsY = tableY * panelSize

  TLTPLTableX equ [bp+6]
  TLTPLTableY equ [bp+4]

  proc tableLocationToPixelLocation
    push bp
    mov bp, sp

    ; multilpy them by the panel size
      ; multiply the tableY
        mov al, panelSize
        xor ah,ah
        mov bx, TLTPLTableY
        mul bl
        mov bx, ax ; bx holds the pixelY

      ; multiply the tableX, and add it the margin left
        mov cx, TLTPLTableX
        mov al, panelSize
        xor ah,ah
        mul cl
        add al, marginLeft ; ax holds the pixelX

    pop bp
    ret 4
  endp tableLocationToPixelLocation

;====================================================================================;

  ; datasegLocationToTableLocation PROCEDURE HEADER
  ; 	parameters: dataseg loction
  ; 	return: the table x in cx, and the table y in ax.
  ;
  ;   working according to this formula:
  ;     datasegLocation = the loocation in the dataseg
  ;     tableY  = tableLocation / 8
  ;     tableX  = tableLocation - tableY*8

  DLTTLDatasegLocation equ [bp+4]

  proc datasegLocationToTableLocation
    push bp
    mov bp, sp
    push bx

    ; first, to prevent division by 0, check
    cmp word ptr DLTTLDatasegLocation, 0
      jg DLTTLDontAutoSetTo0

      xor cx,cx
      xor ax,ax
      jmp DLTTLFinish

      DLTTLDontAutoSetTo0:

    ; calc the table y
      mov ax, DLTTLDatasegLocation
      mov bx, 8
      div bl ; now al stores the table y
      xor ah, ah
      push ax

    ; calc the table x
      mov cx, DLTTLDatasegLocation
      pop bx
      push bx
      mov ax, 8
      mul bl
      sub cx, ax ; now cx stores the table x
      pop ax

      DLTTLFinish:

      pop bx
    pop bp
    ret 2
  endp datasegLocationToTableLocation

;====================================================================================;

  ; pixelLocationToBoardLocation PROCEDURE HEADER
  ; 	parameters: pixelX,pixelY
  ; 	return: the board x in ax, and board y in bx
  ;
  ;   working according to this formula:
  ;     boardX = (pixelX-marginLeft)/panelSize

  PLTBLPixelX equ [bp+6]
  PLTBLPixelY equ [bp+4]

  proc pixelLocationToBoardLocation
    push bp
    mov bp, sp

      ; boardX calculation
      mov ax, PLTBLPixelX
      sub al, marginLeft
      mov bl, panelSize
      div bl ; now, al contain the table x
      xor ah, ah
      push ax ; to save it, since we are about to divide

      ; boardY calculation
      mov ax, PLTBLPixelY
      div bl ; still have the panel size from earlier
      xor ah, ah
      mov bx, ax ; now, bx contains the board y

      pop ax ; return to ax the board x

    pop bp
    ret 4
  endp pixelLocationToBoardLocation

;====================================================================================;

  ; boardLocationToDatasegLocation PROCEDURE HEADER
  ; AKA tableLocationToDatasegLocation
  ; 	parameters: boardX,boardY
  ; 	return: the dataseg lcation in bx
  ;
  ;   working according to this formula:
  ;     datasegLocation = tableX + tableY*8

  BLTDLBoardX equ [bp+6]
  BLTDLBoardY equ [bp+4]

  proc boardLocationToDatasegLocation
    push bp
    mov bp, sp
    push ax

    mov ax, BLTDLBoardY
    mov bl, 8
    mul bl
    add ax, BLTDLBoardX
    mov bx, ax

    pop ax
    pop bp
    ret 4
  endp boardLocationToDatasegLocation


;====================================================================================;

    ; pixelLocationToDatasegLocation PROCEDURE HEADER
    ; 	parameters: pixelX,pixelY
    ; 	return: the dataseg location in bx

    PLTDLPixelX equ [bp+6]
    PLTDLPixelY equ [bp+4]

    proc pixelLocationToDatasegLocation
      push bp
      mov bp,sp
      push ax

      push PLTDLPixelX ; pixels x
      push PLTDLPixelY ; pixels y
      call pixelLocationToBoardLocation ; will return the TABLE x and y
      push ax ; table x
      push bx ; table y
      call boardLocationToDatasegLocation ; will return the dataseg location of the clicked panel, and store it in bx

      pop ax
      pop bp
      ret 4
    endp pixelLocationToDatasegLocation
