; DRAWTRIANGLE PROCEDURE HEADER
; 	parameters: color, facingDirection(0 for right mark 1 for left), x, y
; 	return: void
;   note: the height and width are 15

  DTColor equ [bp+10]
  DTDirection equ [bp+8]
  DTX equ [bp+6]
  DTY equ [bp+4]
  DTSize equ 25

  proc drawTriangle
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov bx, DTX

    mov cx, 1
    cmp word ptr DTDirection, 0
    jne DTDirIsLeft
      mov cx, DTSize
    DTDirIsLeft:

    DTWidthLoop:

      mov ax, DTY
      mov dx, DTSize ; calc the distance from the y this column
        sub dx, cx
        shr dx, 1
        add ax, dx

      push cx
      DTHeightLoop:

        push bx
        push ax
        push DTColor
        call drawPixel

        inc ax
      loop DTHeightLoop
      pop cx

      inc bx ; move one pixel right
      ; change the cx to the current column height of pixels
      add cx, 2
      cmp word ptr DTDirection, 0
      jne DTDirIsLeft2
        sub cx, 4
      DTDirIsLeft2:

    cmp cx, -1
      je DTFinish
    cmp cx, DTSize+2
      je DTFinish
    jmp DTWidthLoop

    DTFinish:

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 8
  endp drawTriangle

; DRAWCIRCLE PROCEDURE HEADER
; 	parameters: x, y, color
; 	return: void

  circleX equ [bp+8]
  circleY equ [bp+6]
  circleColor equ [bp+4]
  circleSize equ 21

  proc drawCircle
    push bp
    mov bp, sp
    push bx
    push ax
    push dx

    mov bx, offset circle
    circleHeightLoop:
      ; calc the y
        mov dx, bx
        sub dx, offset circle
        add dx, 2 ; margin top
        add dx, circleY

      ; calc where to start from
        mov ax, circleSize
        sub al, [bx] ; sub the amount of colored pixels
        mov bh, 2 ; to divide by 2
        div bh
        xor bh,bh
        add ax, 2 ; now, al contains the x cordinate. added 2 because the circle has a space of 2 from the sides of the panel
        add ax, circleX

      xor ch, ch
      mov cl, [bx]
      circleWidthLoop:
        push ax ; the x
        push dx ; the y
        push circleColor
        call drawPixel
        inc ax ; inc the x indicator
      loop circleWidthLoop

      inc bx ; the y indicator
    cmp bx, offset circle + circleSize
      jb circleHeightLoop

    pop dx
    pop ax
    pop bx
    pop bp
    ret 6
  endp drawCircle


; DRAWSQUARE PROCEDURE HEADER
; 	parameters: height, width, x, y, color
; 	return: void

  squareHeight equ [bp+12]
  squareWidth equ [bp+10]
  squareX equ [bp+8]
  squareY equ [bp+6]
  squareColor equ [bp+4]

  proc drawSquare
    push bp
    mov bp, sp
    push bx
    push ax

    ; init the start and end coordinates in bx(for y), ax(for x), squareWidth and squareHeight
      mov ax, squareX
      add squareWidth, ax ; to point the squareWidth on the right border x
      mov bx, squareY
      add squareHeight, bx ; to point the squareHeight on the bottom border y

    ; printing the square: looping on the height, and on each row, printing the line
    squareHeightLoop:

      mov ax, squareX
      squareWidthLoop: ; width loop

        push ax ; the pixel x
        push bx ; the pixel y
        push squareColor ; the pixel color
        call drawPixel

        inc ax
      cmp ax, squareWidth
        jbe squareWidthLoop

      inc bx
    cmp bx, squareHeight
      jbe squareHeightLoop

    pop ax
    pop bx
    pop bp
    ret 10
  endp drawSquare

; DRAWPIXEL PROCEDURE HEADER
; 	parameters: x,y,color
; 	return: void

  x equ [bp+8]
  y equ [bp+6]
  color equ [bp+4]

  proc drawPixel
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov bh, 0 ; page
    mov cx, x
    mov dx, y
    mov al, color
    mov ah, 0ch ; pixel printing
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6
  endp drawPixel
