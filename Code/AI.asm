  ; AITurn PROCEDURE HEADER
  ; parameters: none
  ; return: void

    AITMaxScore equ word ptr [bp-2]
    AITMaxBlock equ word ptr [bp-4]
    AITMaxDirection equ word ptr [bp-6]

    proc AITurn
      push bp
      mov bp, sp
      sub sp, 6 ; to save the max move's score as local variable

      push ax
      push bx
      push cx
      push dx
      push si

      ; first, check for Immediate Threats, and respond
      call IsImmediateThreat
      cmp al, true
        jne AITNoImmidThreat

        call preventBeingEaten
        cmp al, true
          je AITFinish

      AITNoImmidThreat:

      mov AITMaxScore, 0

      ; looping over the possibles moves
      mov cx, 1 ; players at the first row can't move anyway
      AITHeightLoop:

        mov dx, 0
        AITWidthLoop:

          ; first, get the dataseg location
            push dx
            push cx
            call boardLocationToDatasegLocation ; now the adress is in bx
            mov si, bx ; to use bx later for different things

          ; check if this block's player is ours.
            push si
            call getPlayer ; ax has the code
              cmp ax, AI_CODE
                jne AITSkipPanel

          ; now, I want to get this panel's move's scores.
            push dx
            push cx
            call getBlockMaxScore
            ; compare the current max with the curr
            cmp ax, AITMaxScore
              jb AITNotBiggerScore

              ; if the curr is bigger, set the max to be it
                mov AITMaxScore, ax
                mov AITMaxBlock, si
                mov AITMaxDirection, bx

            AITNotBiggerScore:

          AITSkipPanel:

          inc dx
        cmp dx, 8
          jb AITWidthLoop

        inc cx
      cmp cx, 8
        jb AITHeightLoop

      ; now, that we have the max move, lets move it
        ; first, get the board location
          push AITMaxBlock
          call datasegLocationToTableLocation ; x => cx, y => ax
        ; if its a regular movement, just move
          push ax ; save for later, since canMove overrides it

          push cx
          push ax
          push AITMaxDirection
          call canMove ; now we have true/false in al
            cmp al, false
              je AITEat ; if it's not a regular movement, its an eating one

          mov ax, AITMaxBlock
          mov word ptr [selectedPanel], ax
          ; set the x and y
          pop ax
          dec ax
          inc cx
          cmp AITMaxDirection, 1
            jne AITGoingRight
            sub cx, 2
          AITGoingRight:
          push cx
          push ax
          call boardLocationToDatasegLocation

          push bx
          call move

          jmp AITFinish

        AITEat:
          pop ax

          push AITMaxBlock
          push AITMaxDirection
          call AIEat

        AITFinish:

      pop si
      pop dx
      pop cx
      pop bx
      pop ax
      add sp, 6
      pop bp
      ret
    endp AITurn

    ; getBlockMaxScore PROCEDURE HEADER
    ; parameters: block x, block y
    ; returns: the score of the better side in ax, side direction in bx

    GBMSX equ [bp+6]
    GBMSY equ [bp+4]

    proc getBlockMaxScore
      push bp
      mov bp, sp
      push cx

      ; get the going right score
        push 0     ; for right
        push 3     ; for recursive rounds
        push GBMSX ; X
        push GBMSY ; Y
        call getNextScoreSide ; now ax stores the right

      ; push it to save for later
        push ax

      ; get the going left score
        push 1     ; for left
        push 3     ; for recursive rounds
        push GBMSX ; X
        push GBMSY ; Y
        call getNextScoreSide ; now ax stores the left

        pop cx
        mov bx, 1 ; left by default
        cmp ax, cx
          jae GBMSDontSwitch

          mov ax, cx
          mov bx, 0

        GBMSDontSwitch:

      pop cx
      pop bp
      ret 4
    endp getBlockMaxScore

  ; ==================== getScore procs ==================== ;

  ; getScore PROCEDURE HEADER
  ; parameters: recursiveRound(will stop at 1), fromX, fromY, toX, toY
  ; return: score in dx
  ;; returns the score of this move + next turn move / 2 + next next turn move / 4

    GSRound equ [bp+12]
    GSFromX equ [bp+10]
    GSFromY equ [bp+8]
    GSToX equ [bp+6]
    GSToY equ [bp+4]

    proc getScore
      push bp
      mov bp, sp
      push ax

      mov ax, 0

      push GSToX
      push GSToY
      call getOffensiveScore

      add ax, dx

      push GSFromX
      push GSFromY
      push GSToX
      push GSToY
      call getDefensiveScore

      add ax, dx
      mov dx, ax ; dx now contains the score

      ;  !== GETTING THE NEXT TURN'S SCORE, AND ADDING IT ==!  ;
      cmp word ptr GSRound, 1
        je GSFinish

      ; score for going left
        push 1
        push GSRound
        push GSToX
        push GSToY
        call getNextScoreSide
      add dx, ax

      ; score for going right
        push 0
        push GSRound
        push GSToX
        push GSToY
        call getNextScoreSide
      add dx, ax

      GSFinish:

      mov ax, dx

      pop ax
      pop bp
      ret 10
    endp getScore

  ; getNextScoreSide PROCEDURE HEADER
  ; 	parameters: side(0 for right, 1 for left), recursiveRound(not decreased, GNSS will dec)(will stop at 1), toX, toY
  ; 	return: score of the side in ax, already divided by 2

    GNSSSide equ [bp+10]
    GNSSRound equ [bp+8]
    GNSSToX equ [bp+6]
    GNSSToY equ [bp+4]

    proc getNextScoreSide
      push bp
      mov bp, sp
      push cx
      push dx

      push GNSSToX
      push GNSSToY
      push GNSSSide
      call canMove

      cmp al, true
        je GNSSCallNextGetScore
      ; if here, cant move there. here I'll check if can eat there

      push GNSSToX
      push GNSSToY
      call canEat
      cmp al, false
        jne GNSSFCheckEatingPoss

      mov ax, 0 ; if no move and no eat, return 0
      jmp GNSSFinish

      GNSSFCheckEatingPoss:
      ; now I'll check that the eating possibility it found is
      ; to the same direction we need

      push word ptr [PWalkTo]
      call datasegLocationToTableLocation

      cmp word ptr GNSSSide, 0
        je GNSSCheckIfRightDir
        ; check if the eating possibility is to the left
        cmp cx, GNSSToX
          jb GNSSCallNextGetScore
        jmp GNSSFinish

      GNSSCheckIfRightDir:
        ; check if the eating possibility is to the right
        cmp cx, GNSSToX
          jb GNSSFinish

      GNSSCallNextGetScore:

        push word ptr [PWalkTo]
        call datasegLocationToTableLocation

          mov dx, GNSSRound
          dec dx
        push dx ; recursive round
        push GNSSToX
        push GNSSToY
        push cx ; to x
        push ax ; to y
        call getScore

        mov ax, dx
        shr ax, 1

      GNSSFinish:

      pop dx
      pop cx
      pop bp
      ret 8
    endp getNextScoreSide

  ; getOffensiveScore PROCEDURE HEADER
  ; 	parameters: movingToX, movingToY
  ; 	return: score in dl, when default 50 and as higher, as better

    GFSToX equ [bp + 6]
    GFSToY equ [bp + 4]
    SCORE_FOR_EATING equ 8

    proc getOffensiveScore
      push bp
      mov bp, sp
      push ax
      push bx
      push cx

      xor dx,dx

      push GFSToX
      push GFSToY
      call boardLocationToDatasegLocation

      ; add temporarily an AI player there, to simulate the situation.
      ; we will remove him after finishing checking
      mov al, byte ptr [bx] ; save the prev value
      xor ah, ah
      push ax
      mov byte ptr [bx], 111b

      push GFSToX
      push GFSToY
      call canEat
      cmp al, false
        je GOSFinish

      push word ptr [PWalkTo]
      call datasegLocationToTableLocation
      push PLAYER_1_CODE
      push cx
      push ax
      call getBeingEatenTimes ; now, times we eat in dl

      mov ax, dx
      mov dx, 50
      shl ax, 3 ; multiply by 8
                ; I'm multiplying by 8 so it will have effect.
                ; since the eating will come one turn after the being eaten risk,
                ; it will have less effect if multiplied by 4 like being eaten
      add dx, ax

      GOSFinish:

      ; return the prev player there
      pop ax
      mov byte ptr [bx], al

      pop cx
      pop bx
      pop ax
      pop bp
      ret 4
    endp getOffensiveScore

  ; getDefensiveScore PROCEDURE HEADER
  ; 	parameters: movingFromX, movingFromY, movingToX, movingToY
  ; 	return: score in dl, when default 50, as higher, as better

    GDSFromX equ [bp + 10]
    GDSFromY equ [bp + 8]
    GDSToX equ [bp + 6]
    GDSToY equ [bp + 4]
    SCORE_FOR_BEING_EATEN equ 4

    proc getDefensiveScore
      push bp
      mov bp, sp
      push bx
      push ax
      push cx
      push si

      mov si, 50 ; will hold the score; default 50

      ; checking whether the movement is exposing anyone else for eating
      ; for that, we will temporarily remove the player from there(to check), and re-add it later
        push GDSFromX
        push GDSFromY
        call boardLocationToDatasegLocation

      ; save the previous value for later
        mov al, byte ptr [bx]
        xor ah,ah
        push ax

      ; simulate removing our player from there
        mov byte ptr [bx], 1

      ; calc where is the panel that we are potentially exposing
      mov cx, GDSFromX
      inc cx
      cmp cx, GDSToX
        jne GDSDontChange
        sub cx, 2
      GDSDontChange:

      push AI_CODE
      push cx ; x of the panel which we are not moving to (the one that we are potentially exposing)
      push GDSToY
      call getBeingEatenTimes ; now, dl hold the number of times that we are being eaten if moving

      ; move to si 50 - timesEaten * SCORE_FOR_BEING_EATEN
        mov al, dl
          mov dh, SCORE_FOR_BEING_EATEN
        mul dh
          xor dh, dh
        sub si, ax ; si contains the updated score

     ; now, dl contains the score after we subbed the score of "exposing others"
     ; the following code sub the amount of times we will be eaten if moving there
     ; to check how many times we are potentially being eaten, we must "hypothetically"
     ; put our player in the block its moving to
     ; for that, first, get its dataseg adress
      push GDSToX
      push GDSToY
      call boardLocationToDatasegLocation
      ; save the current value
      mov dl, byte ptr [bx]
      xor dh,dh
      push dx
      ; put there the player
      or byte ptr [bx], 111b

     push AI_CODE
     push GDSToX
     push GDSToY
     call getBeingEatenTimes

     ; move to dl 50 - timesEaten * SCORE_FOR_BEING_EATEN
     mov al, dl
     mov dh, SCORE_FOR_BEING_EATEN
     mul dh
     xor dh, dh
     sub si, ax ; si contains the updated score

     ; return original values to the panels
       ; return the original value to the 'TO' panel
         pop ax ; the previous value of the panel
         push GDSToX
         push GDSToY
           call boardLocationToDatasegLocation
           mov byte ptr [bx], al

       ; return the original value to the 'FROM' panel
         push GDSFromX
         push GDSFromY
          call boardLocationToDatasegLocation
          pop ax
          mov byte ptr[bx], al

      mov dx, si ; to return the score in dx, and not in si

      pop si
      pop cx
      pop ax
      pop bx
      pop bp
      ret 8
    endp getDefensiveScore

        ; ==================== helpers procs ==================== ;

        ; AIEat PROCEDURE HEADER
        ;   parameters: eatingPanelDatasegAdress, direction(0 for right, 1 for left)
        ;   return: void

        AIEDatasegAdd equ [bp+6]
        AIEDirection equ [bp+4]

        proc AIEat
          push bp
          mov bp, sp
          push ax
          push bx

          ; first, remove the player from its previous panel and render it
            mov bx, AIEDatasegAdd
            mov byte ptr [bx], 00000001b ; empty it
            push bx
            call renderPanel

          ; remove the player from the panel that we eat
            ; calc where is the panel we are eating
            sub bx, 7 ; bring it top-right
            sub bx, AIEDirection
            sub bx, AIEDirection ; now bx has the eaten panel
            ; remove it
            mov byte ptr [bx], 00000001b
            push bx
            call renderPanel

          ; add the player to its new panel
            ; calc the location
            sub bx, 7 ; bring it top-right
            sub bx, AIEDirection
            sub bx, AIEDirection ; now bx has the new panel
            ; add the player and render
            mov byte ptr [bx], 00000111b
            push bx
            call renderPanel

          ; check for double eating
            push bx
            call datasegLocationToTableLocation ; x => cx y => ax
            push cx
            push ax
            call canEat
              cmp al, false
                je AIEFinish
          ; if here, can eat again.
          ; call AIEat
            push bx
            ; calc the direction
            push 0 ; to the right by default
            sub bx, 16 ; bring it to the destination row
            cmp bx, word ptr [PWalkTo]
              jb AIEItIsToTheRight
              ; change direction to left
              pop ax
              push 1
            AIEItIsToTheRight:

            call AIEat

          AIEFinish:

          pop bx
          pop ax
          pop bp
          ret 4
        endp AIEat

        ; getBeingEatenTimes PROCEDURE HEADER
        ; 	parameters: beingEatenPlayerCode, panelX, panelY
        ; 	return: times in dl

        GBETBeingEatenPlayerCode equ [bp+8]
        GBETX equ [bp+6]
        GBETY equ [bp+4]

        proc getBeingEatenTimes
          push bp
          mov bp, sp
          push cx
          push ax
          push bx

            mov dl, 0
            ; now, check if exposed for eating
                push word ptr GBETBeingEatenPlayerCode
                push word ptr GBETX
                push word ptr GBETY
                call IsExposedForEating
                  cmp al, true
                  jne GBETReturn

            ; if there is an eating option, call getBeingEatenTimes on it, and add 1 to it
              ; simulate the eating player has moved to the after eating location
              mov bx, [PWalkTo]
              mov byte ptr [bx], 11b
              cmp byte ptr GBETBeingEatenPlayerCode, AI_CODE
                je GBETNotChangingToEatedByAI
                mov byte ptr [bx], 111b
              GBETNotChangingToEatedByAI:

              ; calc the amount of times being eaten to the right
              push bx ; contains the adress of the panel that the rival has moved to the after eating location
              call datasegLocationToTableLocation
              inc cx ; since going to the right
              inc ax
              cmp byte ptr GBETBeingEatenPlayerCode, AI_CODE
                je GBETNotChangingToEatedByAI2
                sub ax, 2
              GBETNotChangingToEatedByAI2:
              ; is out of board border?
              cmp word ptr ax, 7
                jge GBETCalcForLeft
              cmp word ptr ax, 0
                jle GBETCalcForLeft
              cmp word ptr cx, 7
                jge GBETCalcForLeft

              push GBETBeingEatenPlayerCode
              push cx
              push ax
              call getBeingEatenTimes ; times in dl

            GBETCalcForLeft:
            ; calc the amount of being eaten to the left
            sub cx, 2 ; since going to the left
            ; is out of board borders?
            cmp word ptr cx, 0
              jle GBETReturnPanelToOriginal

            push dx ; save the right going score
            push GBETBeingEatenPlayerCode
            push cx
            push ax
            call getBeingEatenTimes ; times in dl

            ; add the eating right num and eating left num, and add them 1
            mov al, dl
            pop dx
            add dl, al ; dl now contains the two sides together

            GBETReturnPanelToOriginal:
              inc dl ; for the time we ate at the beggining of this procs
              mov byte ptr [bx], 1

            GBETReturn:

          pop bx
          pop ax
          pop cx
          pop bp
          ret 6
        endp getBeingEatenTimes

  ; ==================== boolean procs ==================== ;

  ; IsImmediateThreat PROCEDURE HEADER
  ; 	parameters: none
  ; 	return: true/false in al, where the threat will eat to in PWalkTo and where the threat is in PWalkFrom

    proc IsImmediateThreat
      push bx
      push cx

      mov cx, 0
      IITPanelsHeightLoop:
        mov dx, 0
        IITPanelsWidthLoop:

          push dx
          push cx
          call boardLocationToDatasegLocation

          push bx
          call getPlayer
          cmp ax, AI_CODE
            jne IITNextPanel

          push AI_CODE ; who are we checking exposion for
          push dx
          push cx
          call IsExposedForEating
            cmp al, true
              jne IITNextPanel
          mov [PWalkFrom], bx
          jmp IITReturn


          IITNextPanel:
        inc dx
        cmp dx, 8
          jb IITPanelsWidthLoop
      inc cx
      cmp cx, 8
        jb IITPanelsHeightLoop

      mov al, false
      IITReturn:

      pop cx
      pop bx
      ret
    endp IsImmediateThreat

    ; sequance:
    ; 1. check if can eat.
    ; 2. check if another can move to block
    ; 3. check if can move by himself to save himself

    ; preventBeingEaten PROCEDURE HEADER
    ; 	parameters: where the threat is in PWalkTo
    ; 	return: true/false in al, saying wether we acted

    proc preventBeingEaten
      push bx
      push cx
      push dx
      push si

      ; check if can eat the threat
        mov bx, [PWalkFrom]
        push bx
        call datasegLocationToTableLocation ; X => cx, Y => ax
        mov dx, ax ; the proc  canEat overrides it, so I'll save ax in dx

        push cx
        push ax
        call canEat

        cmp al, true
          jne PBEDontEat

          push bx ; the 'to eat' adress
          ; to check which side we are eating, We'll get the 'to eat'
          ; table x location, and compare it with our x
          push 1
            push cx ; save our x
            push [PWalkFrom]
            call datasegLocationToTableLocation
            pop ax ; now, cx contain the 'to eat' x, and ax contains ours
            cmp ax, cx
              ja PBEEatingToTheLeft
              pop cx ; to pull out the 1
              push 0
            PBEEatingToTheLeft:
          call AIEat
          jmp PBEFinish

        PBEDontEat:

        ; check if another player can move to block the eating
        push bx
        call datasegLocationToTableLocation
        cmp ax, 6
          jae PBECantMoveToBlock

        ; check from what side is the threat
        mov ax, word ptr [PWalkTo]
        sub ax, 8
        cmp bx, ax
        ja PBEMoveToBlockLeft

        cmp cx, 6
          jae PBECantMoveToBlock

          push bx
          push 0
          call PBEMoveToBlockEating
          cmp al, true
            je PBEFinish

        jmp PBECantMoveToBlock

        PBEMoveToBlockLeft:
        cmp cx, 1
          jbe PBEMoveToBlockLeft

          push bx
          push 1
          call PBEMoveToBlockEating
          cmp al, true
            je PBEFinish

        PBECantMoveToBlock:

        ; check if can move away
        ; check for right
          push bx
          call datasegLocationToTableLocation ; X => cx, Y => ax
          push cx
          push ax
          push 0
          call canMove
          cmp al, false
            je PBECheckMovingLeft

          mov word ptr [selectedPanel], bx
          sub bx, 7 ; bring bx ti the 'moving right panel'
          push bx
          call move

          jmp PBEFinish

          PBECheckMovingLeft:
          ; check for left
            push bx
            call datasegLocationToTableLocation ; X => cx, Y => ax
            push cx
            push ax
            push 1
            call canMove
            cmp al, false
              je PBEReturnFalse

            mov word ptr [selectedPanel], bx
            sub bx, 9 ; bring bx ti the 'moving left panel'
            push bx
            call move

      PBEReturnFalse:
        mov al, false
        jmp PBEFinishForReal

      PBEFinish:

        mov al, true

      PBEFinishForReal:

      pop si
      pop dx
      pop cx
      pop bx
      ret
    endp preventBeingEaten

    ; PBEMoveToBlockEating PROCEDURE HEADER
    ; 	parameters: datasegment adress of the threatend panel, side from which to check movement (0:right of the panel, 1:left of it)
    ; 	return: true/false in al, representing wether we moved or not

    PBEMTBEDataseg equ [bp+6]
    PBEMTBESide equ word ptr [bp+4]

    proc PBEMoveToBlockEating
      push bp
      mov bp, sp
      push bx
      push cx
      push dx

      mov bx, PBEMTBEDataseg
      push bx
      call datasegLocationToTableLocation ; X => cx, Y => ax
      push 0 ; just to prevent popping too many stuff

      ; move ax and cx to the panel which we can move to to block
      inc ax
      dec cx
      cmp PBEMTBESide, 0
        jne PBEMTBECheckingLeft
        add cx, 2
      PBEMTBECheckingLeft:
      push cx
      push ax
      call boardLocationToDatasegLocation
      mov dx, ax ; save it, since getPlayer will override it
      pop ax
      push bx ; save it for later
      push bx
      call getPlayer
      ; if there is a player there, return false
      cmp al, NO_PLAYER_CODE
        jne PBEMTBEReturnFalse

      ; check if can block from the right
      inc dx
      inc cx
      cmp cx, 8
        jae PBEMTBEReturnFalse
      cmp dx, 8
        jae PBEMTBECheckLeftBlocking
      ; check that we have our player there
      push cx
      push dx
      call boardLocationToDatasegLocation
      push bx
      call getPlayer
        cmp al, AI_CODE
          jne PBEMTBECheckLeftBlocking
      push cx
      push dx
      push 1
      call canMove
        cmp al, true
          je PBEMTBEMoveAndReturnTrue

      PBEMTBECheckLeftBlocking:
      ; check if can block from the left
      sub cx, 2
      cmp cx, 0
        jl PBEMTBEReturnFalse
      push cx
      push dx
      call boardLocationToDatasegLocation
      push bx
      call getPlayer
        cmp al, AI_CODE
          jne PBEMTBEReturnFalse
      push cx
      push dx
      push 0
      call canMove
        cmp al, true
          jne PBEMTBEReturnFalse

      PBEMTBEMoveAndReturnTrue:
      pop ax ; holds the 'to' adress
      ; get the 'move to' dataseg adress
      push cx
      push dx
      call boardLocationToDatasegLocation
      mov word ptr [selectedPanel], bx
      push ax
      call move

        mov al, true
        jmp PBEMTBEFinish

      PBEMTBEReturnFalse:
        mov al, false
        pop bx

      PBEMTBEFinish:

      pop dx
      pop cx
      pop bx
      pop bp
      ret 4
    endp PBEMoveToBlockEating


    IEFEBPanelY equ [bp+6]
    IEFEBPanelX equ [bp+8]


  ; IsExposedForEating PROCEDURE HEADER
  ; 	parameters: whoWeAreCheckingFor(the player that we are checking if can be eaten, PLAYER_1_CODE / AI_CODE), panelX, panelY
  ; 	return: true/false in al, and to where in PWalkTo

    IEFEBPanelY equ [bp+4]
    IEFEBPanelX equ [bp+6]
    IEFEBWhoWeAreCheckingFor equ [bp+8]

    proc IsExposedForEating
      push bp
      mov bp, sp
      push bx
      push cx
      push dx

      mov al, false

      ; if near a side, return false
      cmp word ptr IEFEBPanelX, 0
        je IEFEReturn
      cmp word ptr IEFEBPanelX, 7
        je IEFEReturn
      cmp word ptr IEFEBPanelY, 7
        je IEFEReturn
      cmp word ptr IEFEBPanelY, 0
        je IEFEReturn

      ; if its not the player that is getting exposed (in the 'potentially eaten' panel), return false
      push IEFEBPanelX
      push IEFEBPanelY
      call boardLocationToDatasegLocation
        push bx
        call getPlayer
        cmp ax, IEFEBWhoWeAreCheckingFor
        je IEFEDontReturnFalse
        mov al, false
        jmp IEFEReturn
      IEFEDontReturnFalse:

      mov al, false

      ; saving the 'eating to Y' and 'eating from Y'
      mov bx, IEFEBPanelY ; will hold the 'eating to Y'
      inc bx
      cmp word ptr IEFEBWhoWeAreCheckingFor, AI_CODE
        je IEFENotAi1
        sub bx, 2 ; if its the AI eating the player, the TO Y is subtracted by 2
      IEFENotAi1: ; now, bx contains the 'eating to Y'
      ; Same thing with 'eating from Y' in cx
      mov cx, IEFEBPanelY
      dec cx
      cmp word ptr IEFEBWhoWeAreCheckingFor, AI_CODE
        je IEFENotAi2
        add cx, 2 ; if its the AI eating the player, the FROM Y is increased by 2
      IEFENotAi2: ; now, bx contains the 'eating to Y'

      mov dx, PLAYER_1_CODE ; will store the 'bad guys', the ones that eat
      cmp word ptr IEFEBWhoWeAreCheckingFor, PLAYER_1_CODE
        jne IEFEDontChangeBG
        mov dx, AI_CODE
      IEFEDontChangeBG:

      ; now, dx has the bad guys, cx has the 'from Y', and bx has the 'to Y'
      ; check top/bottom-left to top/bottom-right eating
        push dx ; bad guys
        mov ax, IEFEBPanelX
        inc ax
        push ax ; the 'to' x
        push bx ; the 'to' y
        mov ax, IEFEBPanelX
        dec ax
        push ax ; the 'from' x
        push cx ; the 'from' y
        call IsExposedForEatingSide
        cmp al, true
          je IEFEReturn

      ; check top/bottom-right to top/bottom-left eating
        push dx
        mov ax, IEFEBPanelX
        dec ax
        push ax
        push bx
        mov ax, IEFEBPanelX
        inc ax
        push ax
        push cx
        call IsExposedForEatingSide

      IEFEReturn:

      pop dx
      pop cx
      pop bx
      pop bp
      ret 6
    endp IsExposedForEating

  ; IsExposedForEatingSide PROCEDURE HEADER
  ; 	parameters: badGuysCode(PLAYER_1_CODE/AI_CODE), eatingToX, eatingToY, fromX, fromY
  ; 	return: true/false in al, and to where in PWalkTo

    IEFEBSFromY equ [bp+4]
    IEFEBSFromX equ [bp+6]
    IEFEBSToY equ [bp+8]
    IEFEBSToX equ [bp+10]
    IEFEBSBadGuys equ [bp+12]

    proc IsExposedForEatingSide
      push bp
      mov bp, sp
      push bx
      push dx

      mov dl, false

      ; get the player in the 'from' panel
        push IEFEBSFromX
        push IEFEBSFromY
        call boardLocationToDatasegLocation ; bx has the dataseg location
        push bx
        call getPlayer
        ; return false if its not an oppsite player
          cmp ax, word ptr IEFEBSBadGuys
            jne IEFEBSReturnFalse

      ; get the player in the 'to' panel
        push IEFEBSToX
        push IEFEBSToY
        call boardLocationToDatasegLocation
        push bx
        call getPlayer
        ; return false if its not an empty panel
          cmp ax, NO_PLAYER_CODE
            jne IEFEBSReturnFalse

      ; check if there is a player of the good ones in the middle
      ; We'll do it by getting the panel that is the average of the two X's and Y's
        ; average the x
          mov ax, IEFEBSFromX
          add ax, IEFEBSToX
          shr ax, 1 ; divide by 2
        ; average for y
          mov bx, IEFEBSFromY
          add bx, IEFEBSToY
          shr bx, 1 ; divide by 2
        ; get the player there, and make sure that he is not "bad guy"
          push ax
          push bx
          call boardLocationToDatasegLocation
          push bx
          call getPlayer

          cmp ax, IEFEBSBadGuys
            je IEFEBSReturnFalse ; if the 'eaten' panel has a "bad guy" in it, false
          cmp ax, NO_PLAYER_CODE
            je IEFEBSReturnFalse ; if there is no player there at all, false

        ; get the adress of the 'to' panel
          push IEFEBSToX
          push IEFEBSToY
          call boardLocationToDatasegLocation
        mov [PWalkTo], bx
        mov dl, true
        jmp IEFEBSFinish

      IEFEBSReturnFalse:
        mov dl, false

      IEFEBSFinish:
      mov al, dl

      pop dx
      pop bx
      pop bp
      ret 10
    endp IsExposedForEatingSide

  ; canEat PROCEDURE HEADER
  ; 	parameters: panelX, panelY
  ; 	return: true/false in al, and to where in PWalkTo

    CEPanelX equ [bp+6]
    CEPanelY equ [bp+4]

    proc canEat
      push bp
      mov bp, sp
      push bx

      mov al, false
      cmp word ptr CEPanelY, 2
        jb CEFinish

      ; check from here to right-top
      cmp word ptr CEPanelX, 6
        jae CECheckForLeftTop

      push AI_CODE
      mov bx, CEPanelX
      add bx, 2
      push bx
      mov bx, CEPanelY
      sub bx, 2
      push bx
      push CEPanelX
      push CEPanelY
      call IsExposedForEatingSide
      cmp al, true
        je CEFinish

      CECheckForLeftTop:

      ; check from here to left-top
      cmp word ptr CEPanelX, 1
        jbe CEFinish

      push AI_CODE
      mov bx, CEPanelX
      sub bx, 2
      push bx
      mov bx, CEPanelY
      sub bx, 2
      push bx
      push CEPanelX
      push CEPanelY
      call IsExposedForEatingSide

      CEFinish:

      pop bx
      pop bp
      ret 4
    endp canEat

    ; canMove PROCEDURE HEADER
    ; 	parameters: panelX, panelY, toLeftOrRight(0 for right mark 1 for left)
    ; 	return: true/false in al, and to where in PWalkTo

    CMPanelX equ [bp+8]
    CMPanelY equ [bp+6]
    CMDir equ [bp+4]

    proc canMove
      push bp
      mov bp,sp
      push bx

      mov ax, CMPanelX
      mov bx, CMPanely
      dec bx
      inc ax
      cmp word ptr CMDir, 1
      jne CMMoveToRight
        dec ax
        dec ax
      CMMoveToRight:

      cmp ax, -1
        je CMReturnFalse
      cmp ax, 8
        je CMReturnFalse
      cmp bx, -1
        je CMReturnFalse

      push ax
      push bx
      call boardLocationToDatasegLocation
      push bx
      call getPlayer

      cmp al, NO_PLAYER_CODE
        jne CMReturnFalse

      mov al, true
      mov word ptr [PWalkTo], bx
      jmp CMReturn

      CMReturnFalse:
        mov al, false

      CMReturn:

      pop bx
      pop bp
      ret 6
    endp canMove
