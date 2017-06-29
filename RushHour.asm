IDEAL
MODEL small
STACK 100h

; receives: list of registers
; pushing the given registers
macro doPush r1,r2,r3,r4,r5,r6,r7,r8,r9
        irp register,<r9,r8,r7,r6,r5,r4,r3,r2,r1>
                ifnb <register>
                        push register
                endif
        endm
endm doPush

; receives: list of registers
; popping the given registers
macro doPop r1,r2,r3,r4,r5,r6,r7,r8,r9
        irp register,<r9,r8,r7,r6,r5,r4,r3,r2,r1>
                ifnb <register>
                        pop register
                endif
        endm
endm doPop 

macro ScreenMode mode
	mov ax, mode
	int 10h
endm ScreenMode 

macro CreatePuzzle CurrentP, y, label1, p1, l1, p2, l2, p3, l3, p4, l4, p5, l5, p6, l6, p7, l7, p8, l8, p9, l9, p10, l10, p11, l11, p12, l12, p13, l13, p14, l14, p15, l15, p16, l16, p17, l17
	mov bl, CurrentP								; put in bl the number of the current puzzle
	n= CurrentP								
	n= n+1											; put in n the number of the next puzzle
	add bl, '0'										; put in bl the ascii code of the current puzzle
	cmp al, bl										; check if the console pressed on the current puzzle
	jnz label1
	CreateLevel	p1, l1, p2, l2, p3, l3, p4, l4, p5, l5, p6, l6, p7, l7, p8, l8, p9, l9, p10, l10, p11, l11, p12, l12, p13, l13, p14, l14, p15, l15, p16, l16, p17, l17 ; push all the objects features and locations for PopPoints
	call CreateBoard
	call PlayGame									; play the current puzzle
	n= y
	JumpNextInput %n
endm CreatePuzzle

macro ComingSoon CurrentP, y, label2
	mov bl, CurrentP								; put in bl the number of the current puzzle
	n= CurrentP								
	n= n+1											; put in n the number of the next puzzle
	add bl, '0'										; put in bl the ascii code of the current puzzle
	cmp al, bl										; check if the console pressed on the current puzzle
	jnz label2								; if he didn't, jump to the next puzzle
	Image cmngsn
	PressAnyKey
	n= y
	JumpNextInput %n
endm ComingSoon

macro JumpNextInput x
	jmp NextInput&x
endm JumpNextInput

macro ChangeFileName NewName, OldName, SLength		; ATTENTION: the new name mustn't be longer than the old one 
	local NextLetter
	doPush cx, ax, es, ds							; keep the following registers in the stack
	mov cx, SLength 
	mov ax, @data
	mov es, ax
	mov ds, ax
	mov si, offset NewName
	mov di, offset OldName							; prepare the movsb
	rep movsb										; replace the Slength first characters of OldName with the Slength first characters of NewName
	doPop ds, es, ax, cx							; restore the registers
endm ChangeFileName

macro PressAnyKey
	local KeepWaiting
	push ax
	xor al, al
	mov ah, 6
	mov dl, 0ffh
KeepWaiting:
	int 21h
	jz KeepWaiting
	pop ax
endm PressAnyKey
	
	
; receives: list of points and their location
; pushing the given points and their location	; ATTENTION: ax and sp are going to be changed!
macro CreateLevel p1, l1, p2, l2, p3, l3, p4, l4, p5, l5, p6, l6, p7, l7, p8, l8, p9, l9, p10, l10, p11, l11, p12, l12, p13, l13, p14, l14, p15, l15, p16, l16, p17, l17
	mov sp, 100h
	irp point,<l17, p17, l16, p16, l15, p15, l14, p14, l13, p13, l12, p12, l11, p11, l10, p10, l9, p9, l8, p8, l7, p7, l6, p6, l5, p5, l4, p4, l3, p3, l2, p2, l1, p1>
		ifnb <point>
			mov ax, point							
			push ax									; push all the points and their location to the stack
		endif
    endm
endm CreateLevel

macro KeepXAndY
	push ax
	mov ax, [x]
	mov [keepX], ax
	mov ax, [y]
	mov [keepY], ax
	pop ax
endm KeepXAndY

macro RestoreXAndY
	push ax
	mov ax, [keepX]
	mov [x], ax
	mov ax, [keepY]
	mov [y], ax
	pop ax
endm RestoreXAndY

macro PrepareObject	NewName, col, row				; receives the name of the object and it's lengths
	push di
	ChangeFileName NewName, filename, 6
	mov [columns], col
	mov [rows], row
	pop di
endm PrepareObject
	
macro MouseOn
	mov ax,0h										; initialize the mouse
	int 33h
	mov ax,1h										; show the mouse
	int 33h
endm MouseOn
	
macro MouseOff										
	mov ax, 2
	int 33h											; hide the mouse
endm MouseOff
	
macro PressedBoard row, column, InvalidInput		; ATTENTION: this macro jump to : "InvalidInput" which doesn't found in it
	cmp row, 0ah
	jna InvalidInput
	cmp row, 0beh
	jnb InvalidInput
	cmp column, 46h
	jna InvalidInput
	cmp column, 0fah
	jnb InvalidInput
endm PressedBoard

macro BasicCorrecting n								; put in di the location of the first correct point
	mov ah, [byte ptr di-1]
	mov al, [byte ptr di-2]
	mov [di], ax
	add di, 2
	add [byte ptr di-n], 30
endm BasicCorrecting

macro AdvancedCorrecting n							; put next to the object's point location the location of the next two correct points of the object
	BasicCorrecting n								; put in di the location of the first correct point
	BasicCorrecting n								; put in di the location of the second correct point
	jmp FinishCPOfObject
endm AdvancedCorrecting
	
macro FitLocation									; put in CorrectPoint it's object's point location
	inc di											; move to the location of the object's point
	mov ax, [word ptr di]							; put it in ax
	mov [CorrectPoint], ax							; put in CorrectPoint with ax
endm FitLocation

macro NextLoc operation								; add/sub the row/col of CorrectPoint by 30 and update the correct point and the point's location of the current object in PointsLoc 
	local FinishNextLoc
	local horiz
	cmp [status], 1									; check if the current object is vertical or horizontal 
	jz horiz										; if it horizontal, jump to horiz
	operation [byte ptr CorrectPoint+1], 30			; add/sub the row of CorrectPoint by 30		
	UpdatePoint operation, 1						; update the correct point and the point's location of the current object in PointsLoc
	jmp FinishNextLoc
horiz:
	operation [byte ptr CorrectPoint], 30			; add/sub the col of CorrectPoint by 30	
	UpdatePoint operation, 0						; update the correct point and the point's location of the current object in PointsLoc
FinishNextLoc:
endm NextLoc

macro RepairBoard sub1, sub2						; ATTENTION: this macro jump to : "FinishCurrentMoving" which doesn't found in it
	local repair
	mov al, [status]						
	mov [KeepStatus], al							; keep the current status in KeepStatus
	mov al, [byte ptr CorrectPoint]					; put in al the x coordinate of CorrectPoint
	xor ah, ah										; make sure ah is 0
	add [x], ax										; add the x coordinate of CorrectPoint to x
	mov al, [byte ptr CorrectPoint+1]				; put in al the y coordinate of CorrectPoint
	xor ah, ah										; make sure ah is 0
	add [y], ax										; add the y coordinate of CorrectPoint to y
	inc [y]
	call CheckTerritory 							; check if the object doesn't collide with the limits of the board or another object
	cmp [flag1], 1									
	jnz repair										; if it doesn't, jump to repair
	jmp FinishCurrentMoving							; if it does, jump to FinishCurrentMoving (this label is out of RepairBoard)
repair:
	mov ax, sub1									; put sub1 in ax
	add [x], ax										; add sub1 to x
	mov ax, sub2									; put sub2 in ax
	add [y], ax										; add sub1 to y
	mov [SLength], 29								
	MouseOff										; hide the mouse
	mov al, [BoardColor]							; put the BoardColor in al
	KeepXAndY
	call Square										; "erase" the "tail" of the object   
	RestoreXAndY
	dec [x]
	dec [y]											; set x and y to index on the under left pixel of the slot
	mov [LLength], 31								; update LLength for PrintLine
	mov al, 15										; put white in al 
	mov [status], 1									; update the status to indicate: horizontal
	KeepXAndY
	call PrintLine									; print the line
	RestoreXAndY
	mov [status], 0									; update the status to indicate: vertical
	KeepXAndY
	call PrintLine									; print the line
	RestoreXAndY
	add [x], 30										
	inc [y]											; set x and y to index on the right pixel of the bottom of the slot
	dec [LLength]									; update LLength for PrintLine
	KeepXAndY
	call PrintLine									; print the line
	RestoreXAndY
	add [y], 29
	sub [x], 30										; set x and y to index on the left pixel of the top of the slot
	mov [status], 1									; update the status to indicate: horizontal
	call PrintLine									; print the line
	mov al, [KeepStatus]
	mov [status], al								; restore the status of the current object
	mov ax,1h										
	int 33h											; show the mouse
endm RepairBoard

macro ResetXandY
	mov [x], 0
	mov [y], 0
endm ResetXandY
	
macro ResetPointsLoc								
	mov di, offset PointsLoc
	mov cx, 59
resetP:
	mov [word ptr di], 0
	add di, 2
	loop resetP	
endm ResetPointsLoc	
	
macro CheckMove reg, n, sub1, sub2					; check if the console moved the object 30 pixels (or above), if he did prepare to MoveObject 
	local Moveforward								; and print 29*29 square to repair the Screen
	local help1										; ATTENTION: this macro jump to : "moveinaccordance" and "moveobject" which don't found in it
	local Help2
	local Help3
	jb help1										; if the console moved the object back, jump to hejp1
	jmp Moveforward									; if he moved it forward, jump to Moveforward
help1:
	mov [direction], 0								; clear direction to indicate that the object is going to move back
	mov al, [byte ptr PressLoc+n]					; put in al the x/y coordinate of PressLoc 
	sub al, reg										; sub from al the x/y coordinate of the current press
	cmp al, 30										; compare al with 30 (the length of a single slot) to decide if it's necessary to move the object
	jnb Help2										; if it is, jump to Help2
	jmp MoveInAccordance							; if it's not, jump to MoveInAccordance
Help2:
	sub [byte ptr PressLoc+n], reg					; sub from PressLoc the x/y coordinate of the current press
	RepairBoard sub1, sub2							; check if the current object can move, if it does, repair the board
	NextLoc sub										; add/sub the row/col of CorrectPoint by 30
	jmp MoveObject
Moveforward:
	mov [direction], 1								; set direction to indicate that the object is going to move forward
	ResetXandY
	mov al, reg										; put the x/y coordinate of the current press in al		
	sub al, [byte ptr PressLoc+n]					; and sub the row/col of PressLoc
	cmp al, 30										; compare al with 30 (the length of a single slot) to decide if it's necessary to move the object
	jnb Help3										; if it is, jump to Help3
	jmp MoveInAccordance							; if it's not, jump to MoveInAccordance
Help3:
	add [byte ptr PressLoc+n], reg					; add to PressLoc the x/y coordinate of the current press
	RepairBoard 0, 0								; check if the current object can move, if it does, repair the board
	NextLoc add										; add/sub the row/col of CorrectPoint by 30
endm CheckMove

macro PrintLineLoop	Coor1, coor2, reg1, reg2
	local printLine
	push reg1
	mov ah, 0ch
	mov cx, [LLength]
printLine:
	push cx											; keep cx
	mov reg2, [Coor2]
	mov reg1, [coor1]
	int 10h
	pop cx											; restore cx
	inc [Coor2]										; move to the next pixel		
	loop printLine
endm PrintLineLoop

macro UpdatePoint operation, n
	local horiz
	local FinishUpdatePoint
	mov ax, [CorrectPoint]							; put CorrectPoint in ax
	mov di, [CurrentLoc]							; put in di CurrentLoc
	mov [di], ax									; replace CorrectPoint with the location of the current Object in PointsLoc 
	add di, 2										; set di to index on the offset of the first point's location  
	mov ah, [byte ptr CorrectPoint+n]				; put in ah the row/col of CorrectPoint
	mov [byte ptr di+n], ah							; put in the row/col of the first point's location the row/col of CorrectPoint 
	add [byte ptr di+n], 30							; and add 30	
	add di, 2										; set di to index on the offset of the second point's location
	cmp [byte ptr di], 0							; check if the current object has second point's location
	jz FinishUpdatePoint							; if not, jump to FinishUpdatePoint
	mov [byte ptr di+n], ah							; put in the row/col of the second point's location the row/col of CorrectPoint 
	add [byte ptr di+n], 60							; and add 60
FinishUpdatePoint:	
endm UpdatePoint

macro WaitForChar
	local KeepWaiting
	xor al, al
	mov ah, 6
	mov dl, 0ffh
KeepWaiting:
	int 21h
	jz KeepWaiting
endm WaitForChar

macro Image image									; print the received image, the image must be: 320x200 and it's location is (0,0)
	mov [CorrectTheImage], 0
	mov [rows], 200
	mov [columns], 320
	mov [Location], 0 
	ChangeFileName image, filename, 6
	call PrintBMP
endm Image
	
macro KeepClockStatus
	mov ax, 40h
	mov es, ax
	mov ax, [Clock]
	mov [ClockStatus], ax
endm KeepClockStatus

macro Delay sec
	local loopSec
	doPush ax, cx
	KeepClockStatus
	mov ax, 18
	mov cl, sec
	mul cl
	mov cx, ax										; put in cx the number of the seconds*18
	mov ax, 40h
	mov es, ax
loopSec:
	mov ax, [Clock]									; put the current clock status in ax
	cmp [ClockStatus], ax							; check if the clock status was changed
	jz loopSec
	mov [ClockStatus], ax
	loop loopSec
	doPop cx, ax
endm Delay  

DATASEG
; --------------------------
; Your variables here
; --------------------------

keepip				dw 	?							; keep the ip of CreateBoard
keepip2				dw 	?							; keep the ip of PopPoints
keepip3				dw	?							; keep the ip of StoryMode
keepip4				dw	?							; keep the ip of beginnerPuzzles, normalPuzzles and YouWillNotSurvive
keepip5				dw	?							; keep the ip of ChooseLevel
CheckIfError		db	0							; flag, indicate if there was an error while opening a file
ErrorMsg 			db 	'Error', 10, 13,'$'			; String: "Error" (enter)
FileHandle 			dw 	?							; keep the file handle of the current file
FileName 			db 	'Format.bmp',0 				; String, contains the name of the current file 
worker				db	'worker'					; String, contains the name of the image file: "worker"
menu 				db 	'menu12'					; String, contains the name of the image file: "menu12"
gamebg				db	'gamebg'					; String, contains the name of the image file: "gamebg"
cmngsn				db	'cmngsn'					; String, contains the name of the image file: "cmngsn"
levels				db	'levels'					; String, contains the name of the image file: "levels"
weldne				db	'weldne'					; String, contains the name of the image file: "weldne"
beginr				db	'beginr'					; String, contains the name of the image file: "beginr"
normal				db	'normal'					; String, contains the name of the image file: "normal"
uwlnsu				db 	'uwlnsu'					; String, contains the name of the image file: "uwlnsu"
verti2				db 	'verti2' 					; String, contains the name of the image file: "verti2"
verti3				db 	'verti3' 					; String, contains the name of the image file: "verti3"
horiz2				db 	'horiz2'					; String, contains the name of the image file: "horiz2"
horiz3				db 	'horiz3'					; String, contains the name of the image file: "horiz3"
redobj				db	'redobj'					; String, contains the name of the image file: "redobj"
Image1				db	'image1'					; String, contains the name of the image file: "image1"
Image2				db	'image2'					; String, contains the name of the image file: "image2"
Image3				db	'image3'					; String, contains the name of the image file: "image3"
Image4				db	'image4'					; String, contains the name of the image file: "image4"
Image5				db	'image5'					; String, contains the name of the image file: "image5"
puzle1				db	'puzle1'					; String, contains the name of the image file: "puzle1"
puzle2				db	'puzle2'					; String, contains the name of the image file: "puzle2"
puzle3				db	'puzle3'					; String, contains the name of the image file: "puzle3"
gameov				db	'gameov'					; String, contains the name of the image file: "gameov"
youwon				db	'youwon'					; String, contains the name of the image file: "youwon"
hwtply				db	'hwtply'					; String, contains the name of the image file: "hwtply"
Header     			db 	54 dup (0)					; the header of the current file
Palette     		db 	256*4 dup (0)				; the palette of the current file
ScrLine      		db 	320 dup (0)					; the current line
CorrectTheImage		db 	?							; As a result of saving the pictures with PhotoShop, every picture has it's own value that corrects it
PointsLoc			db 	17*7 dup (0)				; contains all the features of the objects, their correct points and their object points
rows				dw 	?							; the horizontal length of the current image
columns				dw 	?							; the vertical length of the current image
Location			dw  ?							; the location of the current image on the screen
OffsetPl			dw	?							; keep the offset of PointsLoc
keepdi				dw 	?							; how much adding to di, for setting the image to start from the required pixel
CorrectRow 			dw	?							; the current correct row of the object
CorrectColumn		dw	?							; the current correct column of the object
CorrectPoint		dw	?							; the current correct point of the object
status				db	?							; flag, horizontal or vertical?
PressLoc			dw 	?							; the original press location of the console					
flag				db 	0							; indicate if MatchObjectPoint matched the console input to a point in PointsLoc
flag1				db	0							; indicate if the current color in al is the color of the board
flag2				db 	?							; indicate if the console won
flag3				db	0							; indicate if the console pressed esc
flag4				db	0							; indicate that the current object moved at least once
flag5				db	?							; if flag5 is set, print: ":" in PrintDx
flag6				db	0							; indicate that the console lost the game
flag7				db	0							; indicate if PrintBMP is going to print an object
flag8				db	0							; indicate if in StoryMode
SLength				dw	?							; the length of the square 
BoardColor			db	?							; the color of the board
x					dw	?							; an x coordinate
y					dw	?							; an y coordinate
LLength				dw	?							; the length of the line
KeepX				dw	?							; keep the current value of x
KeepY				dw	?							; keep the current value of y
long				dw	?							; contains the length of the object-30
keepLong			dw	?							; keep the current value in long
CurrentLoc			dw	?							; keep the current point location
KeepStatus			db	?							; keep the current status
direction 			db	?							; flag, indicate if the object is going to move forward or back
KeepPressLoc		dw	?							; keep the current press location
CurrentObj			db 	?							; contains the features of the current object
Moves				db	'Moves:$'					; string: "moves:"
MovesCount			dw	0							; counting the moves of the console
time 				db	'time:$'					; string: "time:"
Clock 				equ	 es:6Ch						; index on es:6ch (the location of the clock)
ClockStatus			dw	?							; the last value in es:6ch
TimeCount			dw	0							; timer, is able to count 59:59
SecCounter			db	?							; count a clock change
youlose				db 	'game over, 1 hour passed$'	; string: "game over, 1 hour passed"
 
CODESEG

; receives: the features of the current object with al
; fit the value of al to the correct image, put it's name in FileName and treat rows and columns as needed
proc ImagePos										
	cmp al, 0ffh									  
	jnz IMG2
	PrepareObject horiz2, 59, 29
	mov [status], 1
	mov [long], 29
	jmp FinishImagePos
IMG2:
	cmp al, 0feh
	jnz IMG3
	PrepareObject horiz3, 89, 29
	mov [status], 1
	mov [long], 59
	jmp FinishImagePos
IMG3:
	cmp al, 0fdh
	jnz IMG4
	PrepareObject verti2, 29, 59
	mov [status], 0
	mov [long], 29
	jmp FinishImagePos
IMG4:
	cmp al, 0fch
	jnz IMG5
	PrepareObject verti3, 29, 89
	mov [status], 0
	mov [long], 59
	jmp FinishImagePos
IMG5:
	PrepareObject redobj, 59, 29
	mov [status], 1
	mov [long], 29
FinishImagePos:	
	ret
endp ImagePos

; receives: the color of the board with BoardColor
; the procedure prints the board with the color in BoardColor to the screen
proc Board
	mov [Slength], 179								; put in Slength 179 for the board square
	mov [y], 0ch									; update y coordinate
	mov [x], 47h									; update x coordinate
	mov al, [BoardColor]							; put in al the color of the board
	call Square										; print the board
	mov al, 15										; put in al the color in the 15th place in palette for the borders
	mov [x], 46h									; set the x coordinate to index on the top left pixel of the board
	mov [LLength], 179								; put in LLength the length of the vertical lines
	mov [status], 0									; update the status to indicate: vertical
	mov [y], 0ch									; prepare the y coordinate for the vertical lines
	mov cx, 7										; prepare cx for the next loop, the are 7 vertical lines
PrintBoardCol:
	push cx											; keep cx
	mov [y], 0ch									; update y coordinate for PrintLine
	call PrintLine									; print the line
	add [x], 30										; update the x coordinate to index on the next vertical line
	pop cx											; restore cx
	loop PrintBoardCol							
	mov [y], 0bh									; prepare the y coordinate for the horizontal lines						
	mov [LLength], 181								; put in LLength the length of the horizontal lines
	mov [status], 1									; update the status to indicate: horizontal
	mov cx, 7										; prepare cx for the next loop, the are 7 horizontal lines
PrintBoardRow:
	push cx											; keep cx
	mov [x], 46h									; update x coordinate for PrintLine
	call PrintLine									; print the line
	add [y], 30										; update the y coordinate to index on the next horizontal line
	pop cx											; restore cx
	loop PrintBoardRow
	ret
endp Board

; receives: the current location in the building process of PointsLoc with di, the correct column and row of the object with CorrectColumn and CorrectRow
; put in the next one/two bytes in PointsLoc the correct point/s of the object
proc CPOfObject
	mov al, [byte ptr di-3]
	cmp al, 0ffh
	jnz NextCheck1
	BasicCorrecting 2
	add di, 2
	jmp FinishCPOfObject
NextCheck1:
	cmp al, 0feh
	jnz NextCheck2
	AdvancedCorrecting 2
NextCheck2:
	cmp al, 0fdh
	jnz NextCheck3
	BasicCorrecting 1
	add di, 2
	jmp FinishCPOfObject
NextCheck3:
	cmp al, 0fch
	jnz NextCheck4
	AdvancedCorrecting 1
NextCheck4:
	BasicCorrecting 2
	add di, 2
FinishCPOfObject:
	mov al, [byte ptr CorrectColumn]
	mov [byte ptr CorrectPoint], al
	mov al, [byte ptr CorrectRow]
	mov [byte ptr CorrectPoint+1], al
	ret
endp CPOfObject

; receives: dx and flag5
; the procedure print the value in dx, if flag5 is set, prints colon between dl and dh
proc PrintDx										; print the numbers in dx to the screen
	mov bx, dx										; keep the number in bx
	shr dx, 12										; put in dl the first digit (left to right)
	add dl, '0'										; put in dl the ascii code of the digit
	mov ah, 2
	int 21h											; print the current digit in dl
	mov dx, bx 										; restore the number to dx
	shl dx, 4										; get rid of the first digit
	shr dx, 12										; put in dl the second digit
	add dl, '0'										; put in dl the ascii code of the digit
	mov ah, 2
	int 21h											; print the current digit in dl
	cmp [flag5], 1									; if flag5 is set, print: ":"
	jnz KeepPrinting
	mov dl, ':'
	mov ah, 2
	int 21h	
KeepPrinting:
	mov dx, bx 										; restore the number to dx
	shl dx, 8										; get rid of the first and second digits
	shr dx, 12										; put in dl the third digit
	add dl, '0'										; put in dl the ascii code of the digit
	mov ah, 2
	int 21h											; print the current digit in dl
	mov dx, bx 										; restore the number to dx
	shl dx, 12										; get rid of the first, second and third digit
	shr dx, 12										; put in dl the fourth digit
	add dl, '0'										; put in dl the ascii code of the digit
	mov ah, 2
	int 21h											; print the current digit in dl
	ret
endp PrintDx

; receives: the current time with TimeCount
; the procedure prints the time in TimeCount on the screen at (1,8)
proc PrintTimer
	mov dl, 1
	mov dh, 8
	mov ah, 2
	int 10h											; set the cursor to (1,8)
	mov bx, [TimeCount]
	cmp bx, 5959h									; check if TimeCount is 5959h
	jnz decimal1									; if it doesn't, jump to decimal
	mov ah, 9
	mov dx, offset youlose							
	int 21h											; if it does, print you lose to the screen
	Delay 3 										; wait 3 seconds
	mov [flag6], 1									; indicate that the console lost the game
	jmp FinishPrintTimer
decimal1:
	mov bx, [TimeCount]								; put in ax the number you want to convert
	cmp bl, 59h
	jnz decimal2
	mov bx, 0a7h									; cover the difference between 100 to 99 in hexadecimal and decimal	
	mov cx, [TimeCount]								; put in ax the number you want to convert
	shl cx, 4 
	shr cx, 12										; keep in bl just the tens digit
	cmp cl, 9
	jnz FinishIncTimer
	mov bx, 6a7h									; cover the difference between 1000 to 999 in hexadecimal and decimal
	jmp FinishIncTimer
decimal2:
	mov bx, [TimeCount]								; put in ax the number you want to convert
	shl bl, 4 
	shr bl, 4										; keep in bl just the unity digit
	cmp bl, 9
	jnz decimal3
	mov bx, 7										; cover the difference between 10 to 9 in hexadecimal and decimal
	jmp FinishIncTimer
decimal3:
	mov bx, 1
FinishIncTimer:
	add [TimeCount], bx
	mov ax, [TimeCount]
	mov dx, ax
	mov [flag5], 1
	call PrintDx
FinishPrintTimer:
	ret
endp PrintTimer

; receives: the object features with al
; the procedure fits the object to it's "CorrectTheImage" (As a result of saving the pictures with PhotoShop, every picture has it's own value that corrects it) value
proc CorrectTheObjectImage
	cmp al, 0ffh									; check if al is horiz2
	jnz NextCheck6
	mov [CorrectTheImage], 1						; the "CorrectTheImage" of the object horiz2 is 2
	jmp FinishCorrectTheObjectImage
NextCheck6:
	cmp al, 0fbh									; check if al is redobj
	jnz NextCheck7
	mov [CorrectTheImage], 1						; the "CorrectTheImage" of the object redobj is 2
	jmp FinishCorrectTheObjectImage
NextCheck7:
	mov [CorrectTheImage], 3						; the rest objects are 3
FinishCorrectTheObjectImage:
	ret
endp CorrectTheObjectImage

; receives: the color with al, the first pixel with x and y and the length with SLength
; print square to the screen (SLength*SLength) from the pixel according to x and y with the color in al
proc Square
	doPush ax, bx, cx, dx							; keep the following registers in the stack
	mov cx, [Slength]								; there are 125 lines
	xor bh, bh										; set to the first page
	mov ah, 0ch										; set ah for the interrupt 10h  
	mov dx, [x]										; put x in dx
	mov [KeepX], dx									; keep it in KeepX
printSquare:
	mov dx, [y]										; put in dx the beginning y coordinate of the line 										
	push cx											; keep cx of the first loop
	mov cx, [SLength]								; set cx for the next loop
printLine1:
	push cx											; keep cx
	mov cx, [x]										; move the next x coordinate		
	int 10h											; print the pixel to the screen
	pop cx											; restore cx
	inc [x]											; move to the next pixel		
	loop printLine1	
restoreCX:
	pop cx											; keep cx for printSquare
	mov dx, [KeepX]									; restore the beginning of X
	mov [x], dx										; move it to X
	inc [y]											; move to the next line
	loop printSquare	
	doPop dx, cx, bx, ax							; restore the registers
	ret 
endp Square

; receives: the color with al, the first pixel with x and y, the length with LLength and horizontal or vertical with status(1=horizontal, else vertical)
; print a line to the screen as required (at the first page) 
proc PrintLine
	doPush ax, bx, cx, dx							; keep the following registers in the stack
	mov cx, [LLength]								; put in cx the length of the line for the loop
	cmp [status], 1									; check if the line is vertical or horizontal 
	jz HorizLine									; if it horizontal jump to HorizLine 
	mov bx, [x]										; put x in bx 
	mov [KeepX], bx									; keep it in KeepX
	xor bx, bx										; set to the first page
	mov ah, 0ch										; prepare ah to the next interrupt
	mov cx, [LLength]								; put in cx the length of the line for the next loop
printLine2:
	push cx											; keep cx
	mov dx, [y]										; put the y coordinate in dx for the interrupt
	mov cx, [x]										; put the x coordinate in cx for the interrupt
	int 10h											; print the pixel to the screen
	pop cx											; restore cx
	inc [y]											; move to the next pixel		
	loop printLine2									
	mov bx, [KeepX]									; restore x with KeepX to bx
	mov [x], bx										; put it in x
	jmp FinishPrintLine
HorizLine:
	mov bx, [y]										; put y in bx
	mov [KeepY], bx									; keep it in KeepY
	xor bx, bx										; set to the first page
	mov ah, 0ch										; prepare ah to the next interrupt
	mov cx, [LLength]								; put in cx the length of the line for the next loop
printLine3:
	push cx											; keep cx
	mov dx, [y]										; put the y coordinate in dx for the interrupt
	mov cx, [x]										; put the x coordinate in cx for the interrupt
	int 10h											; print the pixel to the screen
	pop cx											; restore cx
	inc [x]											; move to the next pixel		
	loop printLine3
	mov bx, [KeepY]									; restore y with KeepY to bx
	mov [y], bx										; put it in y
	jmp FinishPrintLine 	
FinishPrintLine:
	doPop dx, cx, bx, ax							; restore the registers
	ret
endp PrintLine

; waiting for left clicked from the console, then checking if he pressed on the board, 
; if he did matching the pressed pixel to it's correct point
; returns the correct point with CorrectColumn and CorrectRow, if there isn't correct point put 0 in them
proc PressedCorrect
	mov [CorrectColumn], 0							; make sure CorrectColumn is 0
	mov [CorrectRow], 0								; make sure CorrectRow is 0
press:												; wait till left clicked
	mov ah, 1										; prepare for next interrupt
	int 16h											; check if the console pressed on the keyboard
	jz KeepCheck									; if he didn't jump to KeepCheck
	xor ah, ah										; if he did, put in al the ascii code of the pressed key
	int 16h
	cmp al, 27										; check if the console pressed on esc key
	jnz KeepCheck									; if he didn't jump to KeepCheck
	mov [flag3], 1									; set flag3 
	jmp FinishPressedCorrect						; Finish the current puzzle 
KeepCheck:
	call TimeCounter								; update the timer
	cmp [flag6], 1
	jnz KeepCheck1
	jmp FinishPressedCorrect
KeepCheck1:
	mov ax, 3h										; prepare for the next interrupt
	int 33h											; get data from the mouse
	sar bl, 1										; check if left clicked
	jnc press										; if not, jump to press
	shr cx, 1										; match cx to the dos column
	mov [byte ptr PressLoc], cl
	mov [byte ptr PressLoc+1], dl					; keep the original press in PressLoc
	PressedBoard dx, cx, FinishPressedCorrect		; check if the console pressed on the board
	; match the pressed pixel to it's correct point, save it in CorrectColumn and CorrectRow
	mov [CorrectRow], dx							; keep the current row in CorrectRow
	push ax											; keep ax
	mov ax, dx										; put in ax the current row
	sub ax, 0ah										; sub from ax the start row of the board (ah)
	mov dx, 30										; the length of a slot
	div dl											; put in ah current row mod 30
	shr ax, 8										; put ah in al, and in ah, 0
	sub [CorrectRow], ax							; sub from CorrectRow the rest			  
	inc [CorrectRow]								
	mov [CorrectColumn], cx							; keep the current column in CorrectColumn
	mov ax, cx										; put in ax the current column
	sub ax, 46h										; sub from ax the start column of the board (46h)
	mov cx, 30										; the length of a slot
	div cl											; put in ah current column mod 30
	shr ax, 8										; put ah in al, and in ah, 0
	sub [CorrectColumn], ax							; sub from CorrectColumn the rest
	inc [CorrectColumn]
	pop ax											; restore ax
FinishPressedCorrect:
	mov al, [byte ptr CorrectColumn]
	mov [byte ptr CorrectPoint], al					
	mov al, [byte ptr CorrectRow]
	mov [byte ptr CorrectPoint+1], al				; update CorrectPoint
	ret
endp PressedCorrect

; receives: the name of the image file with filename, the horizontal and vertical length of the image with rows and the columns,
; the location of the first pixel with Location and if it's going to print an object with flag7
; print the image to the screen from the given location (at the first page)
proc PrintBMP
	call OpenFile									; open the file
	cmp [CheckIfError], 1							; check if there was an error while opening the file
	jz FinishPrintBMP								; if there was, jump to FinishPrintBMP
	call ReadHeader					
	call ReadPalette								
	call CopyPal
	call CopyBitmap
	call CloseFile
FinishPrintBMP:
	ret
endp PrintBMP

; receives: a string of an error message with ErrorMsg and the name of the file with filename
; Opening the image, if there's an error, printing the error string in ErrorMsg and putting in CheckIfError 1
; updating filehandle and returning it
proc OpenFile
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	jmp FinishOpenFile
openerror:
	mov dx, offset ErrorMsg
	mov ah, 9h
	inc [CheckIfError]
	int 21h
FinishOpenFile:
	ret 
endp OpenFile

; receives: filehandle
; Read BMP file header, 54 bytes to Header
proc ReadHeader
	mov ah, 3fh
    mov bx, [filehandle]
    mov cx, 54
    mov dx, offset Header
    int 21h 
    ret
endp ReadHeader

; Read BMP file color palette, 256 
; colors * 4 bytes (400h)
proc ReadPalette
    mov ah, 3fh
    mov cx, 400h 
    mov dx, offset Palette
    int 21h 
    ret
endp ReadPalette


; receives: Palette
; Copy the colors palette to the video memory registers, The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
proc CopyPal
	mov si, offset Palette 
	mov cx, 256
	mov dx, 3C8h
	mov al, 0 
	out dx, al										; Copy starting color to port 3C8h
	inc dx 											; Copy palette itself to port 3C9h
PalLoop:											; Note: Colors in a BMP file are saved as BGR values rather than RGB
	mov al, [si+2] 									; Get red value
	shr al, 2 										; Max. is 255, but video palette maximal
	out dx, al										; Send it
	mov al,[si+1] 									; Get green value
	shr al, 2
	out dx, al 										; Send it
	mov al, [si] 									; Get blue value
	shr al, 2
	out dx, al 										; Send it
	add si, 4										; Point to next color
	loop PalLoop									; There is a null chr after every color
	ret
endp CopyPal

; receives: the location of the first pixel with Location, the horizontal and vertical length of the image with rows and columns, filehandle and flag7 
; BMP graphics are saved upside-down. Read the graphic line by line (200 lines in VGA format), displaying the lines from bottom to top.
proc CopyBitmap
	mov ax, 0A000h
	mov es, ax
	mov bl, [byte ptr location+1]					
	xor bh, bh
	mov di, bx
	shl bx, 6
	shl di, 8
	add di, bx										; put in di the row location of the image
	mov bl, [byte ptr location]
	xor bh, bh
	add di, bx										; add to di the column location of the image
	mov [keepdi], di								; put in keepdi how much you want to add to di, for setting the image to start from the required pixel
	mov cx, [rows] 
PrintBMPLoop:
	push cx
	mov di, cx 
	shl cx, 6 
	shl di, 8 
	add di, cx										; di= cx*320, point to the correct screen line
	add di, [keepdi]
	cmp [flag7], 1
	mov cx, [columns]
	jz printingOBJ
	sub di, 320
printingOBJ:
	mov al, [CorrectTheImage]
	xor ah, ah
	add cx, ax										; take care of a possible spreading
	mov ah, 3fh										; Read one line
bigBMP:
	mov dx, offset ScrLine
	mov bx, [filehandle]
	int 21h 
	cld 											; Clear direction flag, for movsb
	mov cx, [columns]								; Copy one line into video memory
	mov si, offset ScrLine
	mov bx, [filehandle]
	rep movsb 										; Copy line to the screen
	pop cx
	loop PrintBMPLoop
	Ret
endp CopyBitmap

; receives: filehandle
; closing the current file
proc CloseFile	
	mov ah, 3Eh	
	mov bx, [filehandle]							
	int 21h
	ret
endp CloseFile

; receives: all the points features and locations with the stack. Attention: ax, cx and di are going to be changed!
; move them from the stack to the PointsLoc array and attach them their correct points	
proc PopPoints										; put all the object's points: their features, locations and correct points in PointsLoc 
	pop [keepip2]									; keep ip
	mov di, offset PointsLoc										
NextPoint:
	cmp sp, 100h									; check if there are more points to pop
	jnz AnotherPoint								
	jmp FinishPopPoints								; if there aren't, end PopPoints
AnotherPoint:
	pop ax											; pop the features of an object's point 
	mov [di], al									; put it in PointsLoc
	pop ax											; pop the location of the object's point
	inc di											; move to the next byte in the array
	mov [di], al									; put the column of the object's point next to her features in PointsLoc
	inc di											; move to the next byte in the array
	mov [di], ah									; put the row of the object's point next to her column in PointsLoc
	inc di											; move to the next byte in the array	
	call CPOfObject										; put in the next one/two bytes in PointsLoc the correct point/s of the object
	jmp NextPoint									
FinishPopPoints:
	push [keepip2]									; restore ip for the ret
	ret												
endp PopPoints

; receives: PointsLoc and CorrectPoint
; matching the correct point in CorrectPoint to it's object's point from PointsLoc and saving it in CorrectPoint, updating filename, status and long.
; if couldn't match increase flag by 1 
proc MatchObjectPoint
	mov di, offset PointsLoc
	inc di											; move to the first location of a point in the array
ScanPoint:
	cmp [word ptr di], 0							; check if there is another point
	jnz CheckCurrentPoint							; if there is another point, check it
	mov [flag], 1									; if there isn't, set flag
	jmp FinishMatchObjectPoint						; else, finish MatchObjectPoint
CheckCurrentPoint:	
	mov ax, [word ptr di]							; put the location of the object's point in ax 
	cmp ax, [CorrectPoint]							; check if CorrectPoint and the object's point match
	jz help1										; if they do jump to help1
	jmp ScanSecondPoint								; else check the next point
help1:												; help to jump 
	mov [CurrentLoc], di							; keep the current point location in CurrentLoc
	dec di											; move to the byte that contain the features of the matched point
	mov al, [byte ptr di]							; put the features in al
	mov [CurrentObj], al							; keep the features in CurrentObj
	call ImagePos									; fit the value of al to the correct image, put it's name in FileName and treat rows and columns as needed	
	FitLocation										; put in CorrectPoint it's object's point location
	jmp FinishMatchObjectPoint						; after the object's point and the correct point that was pressed by the console matched, finish MatchObjectPoint
ScanSecondPoint:									; check the first correct point of the object
	add di, 2										; set di to the first correct point 
	mov ax, [word ptr di] 							; put the location of the point in ax
	cmp ax, [CorrectPoint]							; check if CorrectPoint and the first correct point of the object match
	jz help2										; if they do jump to help2
	jmp ScanThirdPoint								; else check the next point
help2:												; help to jump
	sub di, 2
	mov [CurrentLoc], di							; keep the current point location in CurrentLoc
	dec di											; move to the byte that contain the features of the matched point
	mov al, [byte ptr di]							; put the features in al
	mov [CurrentObj], al							; keep the features in CurrentObj
	call ImagePos										; fit the value of al to the correct image, put it's name in FileName and treat rows and columns as needed
	FitLocation										; put in CorrectPoint it's object's point location
	jmp FinishMatchObjectPoint						; after the object's point and the correct point that was pressed by the console matched, finish MatchObjectPoint
ScanThirdPoint:										; check the second correct point of the object
	add di, 2										; set di to the second correct point 
	mov ax, [word ptr di] 							; put the location of the point in ax
	cmp ax, [CorrectPoint]							; check if CorrectPoint and the second correct point of the object match
	jz help3										; if they do jump to help3
	add di, 3
	jmp ScanPoint									; else check the next point
help3:												; help to jump
	sub di, 4
	mov [CurrentLoc], di							; keep the current point location in CurrentLoc
	dec di											; move to the byte that contain the features of the matched point
	mov al, [byte ptr di]							; put the features in al
	mov [CurrentObj], al							; keep the features in CurrentObj
	call ImagePos									; fit the value of al to the correct image, put it's name in FileName and treat rows and columns as needed
	FitLocation										; put in CorrectPoint it's object's point location
FinishMatchObjectPoint:
	ret
endp MatchObjectPoint

; receives: long, forward/back with direction 
; the procedure checks if the object doesn't collide with the limits of the board or another object
proc CheckTerritory 
	mov [flag1], 0									; reset flag1
	doPush ax, bx, cx, dx							; keep the following registers in the stack							
	KeepXAndY										 
	cmp [status], 1									; check if the object is horizontal or vertical
	jz Horiz1										; if horizontal jmp to Horiz1
	cmp [direction], 1								; check if the object is going to move forward or back
	jz forward										; if forward jump to forword
	sub [y], 5	
	add [x], 5										; update the x and y coordinates to check if there is an object there
	jmp CheckColor									; check the territory 
forward:
	mov ax, [long]									 
	add [y], ax
	add [y], 30
	add [y], 5
	inc [x]											; update the x and y coordinates to check if there is an object there
	jmp CheckColor									; check the territory
Horiz1:
	cmp [direction], 0								; check if the object is going to move forward or back
	jz back1										; if back jump to back1
	mov ax, [long]
	add [x], ax
	add [x], 30
	add [x], 5
	add [y], 3										; update the x and y coordinates to check if there is an object there
	jmp CheckColor									; check the territory 
back1:
	sub [x], 5
	add [y], 5										; update the x and y coordinates to check if there is an object there
CheckColor:
	mov cx, [x]										; put in cx the x coordinate
	mov dx, [y]										; put in dx the y coordinate
	mov ah, 0dh										; prepare for the next interrupt
	xor bx, bx										; set to the first page
	int 10h											; put in al the color of the current pixel (by x and y coordinates)
	cmp al, [BoardColor]							; check if the color in al is the color of the board
	jz FinishCheckTerritory							; if it does, jump to FinishCheckTerritory
	mov [flag1], 1									; if it doesn't, set flag1
	mov ax, [KeepPressLoc]							
	mov [PressLoc], ax								; restore PressLoc
FinishCheckTerritory:
	RestoreXAndY
	doPop dx, cx, bx, ax							; restore the registers
	ret
endp CheckTerritory

; receives: the current count of the moves with MovesCount
; the procedure add 1 move to MovesCount in decimal and put in in dx
proc HexToDecMain
	mov bx, [MovesCount]							; put in ax the number you want to convert
	shr bx, 4 
	shl bx, 4										; keep in bx just the hundreds, tens and unity digits
	cmp bx, 999h
	jnz decimal
	mov bx, 667h									; cover the difference between 1000 to 999 in hexadecimal and decimal
	jmp FinishHexToDec
decimal:	
	mov bx, [MovesCount]							; put in ax the number you want to convert
	cmp bl, 99h
	jnz decimal4
	mov bx, 67h										; cover the difference between 100 to 99 in hexadecimal and decimal		
	jmp FinishHexToDec
decimal4:
	mov bx, [MovesCount]							; put in ax the number you want to convert
	shl bl, 4 
	shr bl, 4										; keep in bl just the unity digit
	cmp bl, 9
	jnz decimal5
	mov bx, 7										; cover the difference between 10 to 9 in hexadecimal and decimal
	jmp FinishHexToDec
decimal5:
	mov bx, 1
FinishHexToDec:
	add [MovesCount], bx							; add 1 move in decimal to MovesCount
	mov dl, 1								
	mov dh, 4
	xor bx, bx
	mov ah, 2
	int 10h 										; set the cursor to (1,3)
	mov dx, [MovesCount]							; put MovesCount in dx
	ret
endp HexToDecMain

; receives: status, long, filename, PressLoc, CorrectPoint and BoardColor
; moving the object in accordance with the input of the console
proc MovingObject
MoveInAccordance:
	mov ax, 3h										; prepare the next interrupt
	int 33h											; get information from the mouse 
	sar bl, 1										; check if left clicked
	jc CheckPress									; the console is still pressing the object
	jmp FinishMoveInAccordance						; if not the console finished moving the pressed object
CheckPress:
	call TimeCounter								; update the timer
	mov ax, [PressLoc]
	mov [KeepPressLoc], ax							; PressLoc is going to be changed, keep it in KeepPressLoc
	shr cx, 1										; match the received x coordinate from the mouse data to the real x coordinate 
	cmp [status], 1									; check if the pressed object is horizontal or vertical
	jnz verti										; if ir vertical, jump to verti
	jmp horiz										; if it horizontal, jump to horiz
verti:
	cmp dl, [byte ptr PressLoc+1]					; compare the current press location to the last press location that caused the object to move 									
	jz MoveInAccordance								; the console didn't try to move the object by the last check
	mov [y], 1										; prepare y for CheckMove
	mov [x], 0										; prepare x for CheckMove
	CheckMove dl, 1, 0, [long], y					; check if the console moved the object 30 pixels (or above), if he did prepare to MoveObject (also repair the board)
	jmp MoveObject									; jump to MoveObject
horiz:
	mov bl, [CurrentObj]							; put the features of the current object in bl
	cmp bl, 0fbh									; check if it's the red object
	jnz DidntWinYet									; if not, the console didn't win yet, jump to DidntWinYet
	cmp [byte ptr CorrectPoint], 0bfh				; check if the red object is at the winning location
	jnz DidntWinYet									; if not, the console didn't win yet, jump to DidntWinYet
	mov [flag2], 1									; the console won, set flag2
	jmp FinishMoveInAccordance						; don't prepare the object for another moving, jump to FinishMoveInAccordance
DidntWinYet:
	cmp cx, 0fah									; check if the console is trying to move the object out of the board
	jb InBoard										; if he isn't, jump to InBoard
	mov cl, 0feh									; if he is, put in cl a x coordinate out of the board
InBoard:
	cmp cl, [byte ptr PressLoc]						; compare the current press of the console with the last press location that caused the current object to move
	jnz CheckTheMove								; if the console moved the mouse since the last press location, jump to CheckTheMove
	jmp MoveInAccordance							; if he didn't, don't move the object and jump to CheckTheMove
CheckTheMove:
	mov [x], 1										; prepare y for CheckMove
	mov [y], 0										; prepare x for CheckMove
	CheckMove cl, 0, [long], 0, x					; check if the console moved the object 30 pixels (or above), if he did prepare to MoveObject (also repair the board)
MoveObject:
	shl dx, 8
	mov dl, cl										; the highest value of the row and the column of the board is two-digits hexadecimal number each, put them together in dx 
	mov [PressLoc], dx								; update PressLoc
	mov ax, [CorrectPoint]
	mov [location], ax								; put CorrectPoint in Location for PrintBMP
	MouseOff										; hide the mouse
	mov al, [CurrentObj]							; put the features of the current object in al 
	call CorrectTheObjectImage
	mov [flag7], 1									; tell to PrintBMP that it's going to print an object
	call PrintBMP									; print the current object at his new Location
	mov [flag7], 0
	mov [flag4], 1									; set flag4 to indicate that the current object moved at least once  
	mov ax,1h										
	int 33h											; show the mouse
FinishCurrentMoving:
	cmp [flag2], 1									; check if the console won
	jz FinishMoveInAccordance						; if he did, jump to FinishMoveInAccordance
	jmp MoveInAccordance							; if he didn't, jump to MoveInAccordance
FinishMoveInAccordance:
	cmp [flag4], 1									; check if the current object moved at least once
	jz PrintMoves									; if he did, jump to PrintMoves
	jmp FinishMovingObject							; if he didn't, jump to FinishMovingObject
PrintMoves:
	call HexToDecMain								; increase MovesCount by 1 and put it in dx (convert it to decimal)
	mov [flag5], 0
	call PrintDx									; print the numbers in dx to the screen							
FinishMovingObject:
	call TimeCounter								; update the timer
	mov [flag4], 0									; clear flag4
	ret
endp MovingObject

; receives: PointsLoc
; print the objects as they described in PointsLoc
proc PrintBoard
	doPush cx, ax									; keep the following registers in the stack							
	mov [OffsetPl], offset PointsLoc
PrintObject: 										; run on PointsLoc and print the correct object in his Location
	mov di, [OffsetPl]
	mov al, [byte ptr di]							; put in al the features of the object	
	cmp al, 0										; if al is 0 there are no more objects to print
	jnz NextCheck5
	jmp FinishPrintObject
NextCheck5:	
	call CorrectTheObjectImage
	call ImagePos										; put in filename the correct image name and the resolution in row and column 
	mov di, [OffsetPl]								; ImagePos doesn't keep registers
	mov al, [di+1]									; put in al the column location of the object
	mov [byte ptr Location], al
	mov al, [di+2]									; put in al the row location of the object
	mov [byte ptr Location+1], al
	add [OffsetPl], 7
	mov [flag7], 1									; tell to PrintBMP that it's going to print an object
	call PrintBMP									; print the object
	mov [flag7], 0
	jmp PrintObject
FinishPrintObject:
	mov ah, 5
	doPop ax, cx									; restore the registers
	ret
endp PrintBoard

; prints the board to the screen
proc CreateBoard
	ScreenMode 13h
	image gamebg
	call PrintBMP
	pop [keepip]									; the procedure is going to lose the ip for the ret
	mov [BoardColor], 8								; put in BoardColor dark grey 
	call Board										; print the board
	mov dl, 1									
	mov dh, 2
	xor bx, bx
	mov ah, 2
	int 10h 										; set the cursor to (1,2)
	mov ah, 9
	mov dx, offset Moves
	xor bx, bx
	int 21h											; print: "moves:"
	mov dl, 1									
	mov dh, 6
	xor bx, bx
	mov ah, 2
	int 10h 										; set the cursor to (1,2)
	mov ah, 9
	mov dx, offset time
	xor bx, bx
	int 21h
	call PopPoints									; build PointsLoc
	call PrintBoard									; print the objects as they described in PointsLoc
	push [keepip]									; restore the ip for the ret
	ret
endp CreateBoard

; receives: the status of es:6Ch since the last check with ClockStatus, SecCounter
; the procedure checks if a second passed, if it did, updates TimeCount and prints the new time to (1,8)
proc TimeCounter
	doPush ax, bx, dx
	mov ax, 40h
	mov es, ax
	mov ax, [Clock]									; put the current clock status in ax
	cmp [ClockStatus], ax							; check if the clock status was changed
	jnz TimeCounter1								; if it was, jump to TimeCounter1								
	jmp FinishTimeCounter							; if not, jump to FinishTimeCounter
TimeCounter1:
	mov [ClockStatus], ax							; update ClockStatus
	inc [SecCounter]								
	cmp [SecCounter], 18							; check if a second passed since the last second
	jz TimeCounter2									; if it was, jump to TimeCounter2								
	jmp FinishTimeCounter							; if not, jump to FinishTimeCounter
TimeCounter2:
	mov [SecCounter], 0								; reset SecCounter
	call PrintTimer									; prints the time in TimeCount on the screen at (1,8)
FinishTimeCounter:
	doPop dx, bx, ax
	ret
endp TimeCounter
	
; respond in accordance with the console input
proc PlayGame
	KeepClockStatus									; put the current clock status in ClockStatus
	MouseOn											; turn on the mouse
	mov [MovesCount], 0								; reset MovesCount
NextClick:
	mov [flag], 0									; clear flag 
	call PressedCorrect								; waiting for left clicked from the console, then checking if he pressed on the board, if he did matching the pressed pixel to it's correct point
	cmp [flag6], 1
	jnz KeepPlayGame
	jmp FinishPlayGame
KeepPlayGame:
	cmp [flag3], 1									; check if the console pressed esc
	jnz KeepPlayGame1								; if he didn't jump to KeepPlayGame
	jmp FinishPlayGame								; if he did jump to FinishPlayGame
KeepPlayGame1:
	cmp [CorrectColumn], 0							; check if the console pressed on the board
	jz NextClick									; if he didn't, jump to NextClick
	call MatchObjectPoint							; matching the correct point in CorrectPoint to it's object's point from PointsLoc and saving it in CorrectPoint, updating filename, status and long. if couldn't match increase flag by 1
 	cmp [flag], 1									; check if MatchObjectPoint matched the console input to a point in PointsLoc
	jz NextClick									; if it didn't, jump to NextClick
	call MovingObject								; moving the object in accordance with the input of the console						
	cmp [flag2], 1									; check if the console won
	jz PrintWellDone								; if he did, print Well Done, the moves and the time to the screen
	jmp KeepPlayGame2								; if he didn't, jump to KeepPlayGame2
PrintWellDone:
	MouseOff										; turn off the mouse
	Image weldne									; print Well Done to the screen
	mov dl, 23
	mov dh, 20
	xor bx, bx
	mov ah, 2
	int 10h											; set the cursor to (20,23)
	mov dx, [MovesCount]
	call PrintDx									; print the moves count
	mov dl, 22
	mov dh, 22
	xor bx, bx
	mov ah, 2
	int 10h											; set the cursor to (22,22)
	mov [flag5], 1									; print: ":" in PrintDx
	mov dx, [TimeCount]
	call PrintDx									; print the time
	mov [flag5], 0
	PressAnyKey										; wait for a key from the console
	jmp FinishPlayGame								; jump to FinishPlayGame
KeepPlayGame2:
	jmp NextClick	
FinishPlayGame:
	cmp [flag8], 1									; check if in the StoryMode
	jz DontResetflag3and6
	mov [flag3], 0									; reset flag3
	mov [flag6], 0									; reset flag6
DontResetflag3and6:
	mov [flag2], 0									; reset flag2
	mov [TimeCount], 0								; reset the timer
	MouseOff										; hide the mouse
	ResetPointsLoc									; reset PointsLoc for the next puzzle
	ret
endp PlayGame

; the procedure play the story mode. it finishes when the console loses the game or presses Esc either he won the game
proc StoryMode
	mov [flag8], 1									; indicate that in StoryMode
	pop [keepip3]
	Image Image1									; print the first image to the screen
	Delay 1											; wait 3 seconds
	Image Image2									; print the second image to the screen
	Delay 1 										; wait 5 seconds
	Image Image3									; print the third image to the screen
	Delay 1											; wait 3 seconds
	Image Image4									; print the fourth image to the screen
	Delay 1											; wait 5 seconds
	Image Image5									; print the fifth image to the screen
	Delay 1											; wait 5 seconds
	Image puzle1									; print the first puzzle title
	Delay 1											; wait 4 seconds
	CreateLevel 0fbh, 4747h, 0fdh, 0b47h, 0ffh, 0b83h, 0fch, 2983h, 0fdh, 29a1h, 0ffh, 29bfh, 0fch, 47ddh, 0fch, 6565h, 0feh, 8383h, 0ffh, 0a183h ; push all the objects features and locations for PopPoints
	call CreateBoard
	call PlayGame									; play puzzle 1
	cmp [flag3], 1									; check if the console pressed Esc
	jnz CheckStatus1
	mov [flag3], 0									; reset flag3
	Image Gameov									; print Game Over to the screen
	delay 1											; wait 4 seconds
	jmp FinishStoryMode								; if he did print the "game over" image and jump to FinishStoryMode
CheckStatus1:
	cmp [flag6], 1									; check if the console lost the game
	mov [flag6], 0									; prepare flag6 for the next game
	jnz KeepStoryMode1								; if he didn't, jump to the next puzzle
	Image Gameov									; print Game Over to the screen
	delay 1											; wait 4 seconds
	jmp FinishStoryMode								; if he did print the "game over" image and jump to FinishStoryMode
KeepStoryMode1:
	Image puzle2									; print the second puzzle title
	Delay 4											; wait 4 seconds
	CreateLevel 0fbh, 4783h, 0fch, 0b65h, 0ffh, 0b83h, 0ffh, 2983h, 0ffh, 0bbfh, 0fch, 29bfh, 0ffh, 6547h, 0fdh, 6583h, 0fdh, 65a1h, 0ffh, 83bfh, 0ffh, 0a165h, 0ffh, 0a1a1h ; push all the objects features and locations for PopPoints
	call CreateBoard
	call PlayGame									; play puzzle 2
	cmp [flag3], 1									; check if the console pressed Esc
	jnz CheckStatus2
	mov [flag3], 0									; reset flag3
	Image Gameov									; print Game Over to the screen
	delay 4											; wait 4 seconds
	jmp FinishStoryMode								; if he did print the "game over" image and jump to FinishStoryMode
CheckStatus2:
	cmp [flag6], 1									; check if the console lost the game
	mov [flag6], 0									; prepare flag6 for the next game
	jnz KeepStoryMode2								; if he didn't, jump to the next puzzle
	Image Gameov									; print Game Over to the screen
	delay 4											; wait 4 seconds
	jmp FinishStoryMode								; if he did print the "game over" image and jump to FinishStoryMode
KeepStoryMode2:
	Image puzle3									; print the third puzzle title
	Delay 4											; wait 4 seconds
	CreateLevel 0fbh, 4765h, 0feh, 0b47h, 0feh, 2947h, 0fdh, 0ba1h, 0fch, 0bbfh, 0fdh, 4747h, 0fdh, 47a1h, 0ffh, 65bfh, 0fdh, 6583h, 0ffh, 83a1h, 0fdh, 83ddh ; push all the objects features and locations for PopPoints
	call CreateBoard
	call PlayGame									; play puzzle 3
	cmp [flag3], 1									; check if the console pressed Esc
	jnz CheckStatus3
	mov [flag3], 0									; reset flag3
	Image Gameov									; print Game Over to the screen
	delay 4											; wait 4 seconds
	jmp FinishStoryMode								; if he did print the "game over" image and jump to FinishStoryMode
CheckStatus3:
	cmp [flag6], 1									; check if the console lost the game
	mov [flag6], 0									; prepare flag6 for the next game
	jnz KeepStoryMode3								; if he didn't, jump to the next puzzle
	Image Gameov									; print Game Over to the screen
	delay 4											; wait 4 seconds
	jmp FinishStoryMode								; if he did print the "game over" image and jump to FinishStoryMode
KeepStoryMode3:
	Image youwon									; print You Won to the screen
	delay 10										; wait 10 seconds
FinishStoryMode:
	mov [flag8], 0									; reset flag8
	push [keepip3]
	ret
endp StoryMode

; the procedure let the console choose one of the "beginner" puzzles and play it. the procedure finishes when the console press Esc
proc beginnerPuzzles
	pop [keepip4]
NextInput1:
	ScreenMode 13h
	Image beginr									; print the beginner puzzles menu
	WaitForChar										; wait for a char from the console
	CreatePuzzle 0, 1, puzzle1, 0fbh, 4747h, 0fdh, 0b47h, 0ffh, 0b83h, 0fch, 2983h, 0fdh, 29a1h, 0ffh, 29bfh, 0fch, 47ddh, 0fch, 6565h, 0feh, 8383h, 0ffh, 0a183h ; play the current puzzle
puzzle1:
	CreatePuzzle 1, 1, puzzle2, 0fbh, 4747h, 0fdh, 0b47h, 0fdh, 0b65h, 0fch, 0b83h, 0feh, 0ba1h, 0ffh, 29bfh, 0fdh, 47bfh, 0fdh, 47ddh, 0fdh, 6565h, 0feh, 8383h, 0feh, 0a147h, 0fdh, 83ddh
puzzle2:
	CreatePuzzle 2, 1, puzzle3, 0fbh, 4783h, 0ffh, 0b65h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0fch, 29bfh, 0ffh, 6547h, 0ffh, 6583h, 0fdh, 8383h, 0fdh, 83a1h, 0ffh, 0a1bfh ; play the current puzzle
puzzle3:
	CreatePuzzle 3, 1, puzzle4, 0fbh, 4765h, 0fdh, 0b65h, 0ffh, 2983h, 0fdh, 0bbfh, 0fch, 0bddh, 0fdh, 47a1h, 0ffh, 6565h, 0fdh, 8365h, 0fdh, 8383h, 0feh, 83a1h ; play the current puzzle
puzzle4:
	CreatePuzzle 4, 1, puzzle5, 0fbh, 4783h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0fch, 29bfh, 0feh, 6547h, 0fdh, 8365h, 0ffh, 8383h, 0ffh, 0a183h, 0ffh, 83bfh, 0ffh, 0a1bfh ; play the current puzzle
puzzle5:
	CreatePuzzle 5, 1, puzzle6, 0fbh, 4783h, 0ffh, 0b47h, 0fdh, 0b83h, 0fdh, 0ba1h, 0ffh, 29bfh, 0fdh, 2965h, 0fdh, 47bfh, 0ffh, 6547h, 0fdh, 65a1h, 0ffh, 83bfh, 0feh, 0a165h ; play the current puzzle
puzzle6:
	CreatePuzzle 6, 1, puzzle7, 0fbh, 4747h, 0feh, 0b47h, 0fch, 0bbfh, 0ffh, 2947h, 0fdh, 6547h, 0ffh, 6565h, 0ffh, 65a1h, 0ffh, 0a147h, 0fdh, 8383h, 0feh, 83a1h ; play the current puzzle
puzzle7:
	CreatePuzzle 7, 1, puzzle8, 0fbh, 4783h, 0fch, 0b65h, 0ffh, 0ba1h, 0fch, 29bfh, 0ffh, 6547h, 0fdh, 65a1h, 0ffh, 83bfh, 0feh, 0a165h	; play the current puzzle
puzzle8:
	CreatePuzzle 8, 1, puzzle9, 0fbh, 4765h, 0fch, 29a1h, 0fch, 29bfh, 0ffh, 6547h, 0fdh, 6583h, 0ffh, 83a1h, 0fdh, 8365h ; play the current puzzle
puzzle9:
	CreatePuzzle 9, 1, CheckEsc, 0fbh, 4747h, 0feh, 0b47h, 0fch, 0bddh, 0fch, 2983h, 0ffh, 65bfh, 0fdh, 83bfh, 0fdh, 6547h, 0feh, 0a147h ; play the current puzzle
CheckEsc:											
	cmp al, 27
	jz FinishbeginnersPuzzles
	jmp NextInput1
FinishbeginnersPuzzles:
	push [keepip4]
	ret
endp beginnerPuzzles

; the procedure let the console choose one of the "normal" puzzles and play it. the procedure finishes when the console press Esc
proc normalPuzzles
	pop [keepip4]
NextInput2:
	ScreenMode 13h
	Image normal									; print the normal puzzles menu
	WaitForChar										; wait for a char from the console
	CreatePuzzle 0, 2, puzzle01, 0fbh, 4783h, 0fch, 0b65h, 0ffh, 0b83h, 0ffh, 2983h, 0ffh, 0bbfh, 0fch, 29bfh, 0ffh, 6547h, 0fdh, 6583h, 0fdh, 65a1h, 0ffh, 83bfh, 0ffh, 0a165h, 0ffh, 0a1a1h ; play the current puzzle
puzzle01:	
	CreatePuzzle 1, 2, puzzle02, 0fbh, 4747h, 0fdh, 0b47h, 0ffh, 0b65h, 0ffh, 0ba1h, 0fch, 29bfh, 0fdh, 29ddh, 0ffh, 6547h, 0ffh, 6583h, 0ffh, 0a147h, 0fdh, 8383h, 0ffh, 83a1h ; play the current puzzle
puzzle02:
	CreatePuzzle 2, 2, puzzle03, 0fbh, 4765h, 0ffh, 0b47h, 0fdh, 6547h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0fdh, 2947h, 0fdh, 47a1h, 0ffh, 6565h, 0ffh, 65bfh, 0fdh, 8383h, 0ffh, 83a1h, 0fdh, 83ddh, 0ffh, 0a1a1h ; play the current puzzle
puzzle03:
	CreatePuzzle 3, 2, puzzle04, 0fbh, 4747h, 0feh, 0b47h, 0fdh, 0bddh, 0ffh, 2947h, 0fdh, 2983h, 0fdh, 47bfh, 0fdh, 47ddh, 0fdh, 6547h, 0ffh, 6565h, 0fdh, 8383h, 0ffh, 83bfh, 0ffh, 0a147h ; play the current puzzle
puzzle04:
	CreatePuzzle 4, 2, puzzle05, 0fbh, 4747h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0fdh, 2983h, 0ffh, 29bfh, 0fdh, 47a1h, 0fdh, 47bfh, 0fdh, 47ddh, 0fdh, 6547h, 0feh, 8365h, 0fdh, 83ddh ; play the current puzzle
puzzle05:
	CreatePuzzle 5, 2, puzzle06, 0fbh, 4783h, 0ffh, 0b47h, 0fdh, 0b83h, 0fch, 0bbfh, 0fdh, 0bddh, 0fch, 2947h, 0fdh, 2965h, 0fdh, 47ddh, 0fdh, 6583h, 0ffh, 65a1h, 0fdh, 83a1h, 0feh, 0a147h ; play the current puzzle
puzzle06:
	CreatePuzzle 6, 2, puzzle07, 0fbh, 4747h, 0fdh, 0b47h, 0feh, 0b65h, 0fdh, 0bbfh, 0fch, 0bddh, 0ffh, 2983h, 0fdh, 4783h, 0fch, 47a1h, 0fdh, 6547h, 0ffh, 65bfh, 0ffh, 8365h, 0feh, 0a147h ; play the current puzzle
puzzle07:
	CreatePuzzle 7, 2, puzzle08, 0fbh, 4783h, 0ffh, 0b47h, 0fdh, 0b83h, 0fch, 0bbfh, 0fdh, 0bddh, 0fch, 2947h, 0fdh, 2965h, 0fdh, 47ddh, 0fdh, 6583h, 0ffh, 65a1h, 0fdh, 83a1h, 0feh, 0a147h ; play the current puzzle
puzzle08:
	ComingSoon 8, 2, puzzle09
puzzle09:
	ComingSoon 9, 2, CheckEsc1
CheckEsc1:
	cmp al, 27
	jz FinishbeginnersPuzzles1
	jmp NextInput2
FinishbeginnersPuzzles1:
	push [keepip4]
	ret
endp normalPuzzles

; the procedure let the console choose one of the "YouWillNotSurvive" puzzles and play it. the procedure finishes when the console press Esc
proc YouWillNotSurvive
	pop [keepip4]
NextInput3:
	ScreenMode 13h
	Image uwlnsu									; print the YouWillNotSurvive puzzles menu
	WaitForChar										; wait for a char from the console
	CreatePuzzle 0, 3, puzzle001 0fbh, 47a1h, 0fch, 0b47h, 0ffh, 0b65h, 0fdh, 0bbfh, 0fdh, 2965h, 0fdh, 2983h, 0fch, 29ddh, 0feh, 6547h, 0fdh, 65a1h, 0fdh, 8383h, 0ffh, 83bfh, 0ffh, 0a147h, 0ffh, 0a1a1h ; play the current puzzle
puzzle001:	
	CreatePuzzle 1, 3, puzzle002 0fbh, 4765h, 0feh, 0b47h, 0feh, 2947h, 0fdh, 0ba1h, 0fch, 0bbfh, 0fdh, 4747h, 0fdh, 47a1h, 0ffh, 65bfh, 0fdh, 6583h, 0ffh, 83a1h, 0fdh, 83ddh ; play the current puzzle
puzzle002:
	CreatePuzzle 2, 3, puzzle003 0fbh, 4747h, 0fdh, 0b47h, 0ffh, 0b83h, 0fdh, 0bddh, 0feh, 2965h, 0fdh, 4783h, 0fdh, 47a1h, 0fdh, 47ddh, 0fdh, 83a1h, 0ffh, 6547h, 0fdh, 83a1h, 0ffh, 83bfh, 0ffh, 0a1bfh ; play the current puzzle
puzzle003:
	CreatePuzzle 3, 3, puzzle004 0fbh, 4747h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0fdh, 2983h, 0ffh, 29bfh, 0fdh, 47a1h, 0fdh, 47bfh, 0ffh, 6547h, 0fdh, 8347h, 0feh, 8365h, 0fdh, 83bfh, 0feh, 0a165h ; play the current puzzle
puzzle004:
	CreatePuzzle 4, 3, puzzle005 0fbh, 47a1h, 0feh, 0b47h, 0fch, 0bddh, 0fdh, 2983h, 0ffh, 6547h, 0fdh, 6583h, 0fdh, 65a1h, 0fdh, 8365h, 0ffh, 83bfh, 0feh, 0a183h ; play the current puzzle
puzzle005:
	CreatePuzzle 5, 3, puzzle006 0fbh, 4783h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0fch, 2947h, 0fdh, 2965h, 0fdh, 29bfh, 0fch, 29ddh, 0ffh, 6565h, 0ffh, 65a1h, 0fdh, 8383h, 0ffh, 83a1h, 0ffh, 0a147h, 0ffh, 0a1a1h ; play the current puzzle
puzzle006:
	CreatePuzzle 6, 3, puzzle007 0fbh, 4747h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0ffh, 2965h, 0fdh, 29bfh, 0fdh, 4783h, 0fdh, 47a1h, 0ffh, 6547h, 0ffh, 65bfh, 0fdh, 8347h, 0feh, 8365h, 0fdh, 83ddh, 0feh, 0a165h ; play the current puzzle
puzzle007:
	CreatePuzzle 7, 3, puzzle008 0fbh, 4765h, 0ffh, 0b47h, 0fdh, 0b83h, 0ffh, 0ba1h, 0ffh, 2947h, 0fch, 29bfh, 0fch, 4747h, 0fdh, 47ddh, 0feh, 6565h, 0fdh, 83a1h, 0ffh, 0a147h, 0ffh, 0a1bfh ; play the current puzzle
puzzle008:
	CreatePuzzle 8, 3, puzzle009 0fbh, 4747h, 0fdh, 0ba1h, 0ffh, 0bbfh, 0ffh, 2965h, 0fdh, 29bfh, 0fdh, 4783h, 0fdh, 47a1h, 0ffh, 6547h, 0ffh, 65bfh, 0fdh, 8347h, 0feh, 8365h, 0fdh, 83ddh, 0ffh, 0a183h ; play the current puzzle
puzzle009:
	CreatePuzzle 9, 3, CheckEsc2 0fbh, 4783h, 0feh, 0b47h, 0fdh, 0ba1h, 0fch, 0bbfh, 0fdh, 0bddh, 0fdh, 2947h, 0ffh, 2965h, 0ffh, 6547h, 0fdh, 6583h, 0fdh, 8365h, 0ffh, 83a1h, 0ffh, 0a183h, 0ffh, 0a1bfh ; play the current puzzle
CheckEsc2:
	cmp al, 27
	jz FinishbeginnersPuzzles2
	jmp NextInput3
FinishbeginnersPuzzles2:
	push [keepip4]
	ret
endp YouWillNotSurvive

; the procedure manages the levels panel, enables the console to choose level and puzzle and to solve it   
proc ChooseLevel
	pop [keepip5]
	ScreenMode 13h									; clear the screen
	Image levels									; print the levels image
	WaitForChar										; wait for a char from the console
MainLevels:
	cmp al, '1'										; check if the console pressed: 1
	jnz Check2										; if he didn't, jump to Check2
	call beginnerPuzzles							; if he did, call to beginnerPuzzles
	jmp FinishChooseLevel							
Check2:
	cmp al, '2'										; check if the console pressed: 2
	jnz Check3										; if he didn't, jump to Check3
	call normalPuzzles								; if he did, call to normalPuzzles
	jmp FinishChooseLevel
Check3:
	cmp al, '3'										; check if the console pressed: 2
	jnz Check4										; if he didn't, jump to Check3
	call YouWillNotSurvive							; if he did, call to normalPuzzles
	jmp FinishChooseLevel
Check4:
	cmp al, 27										; check if the console pressed: Esc
	jz FinishChooseLevel							; if he did, jump to FinishChooseLevel
	jmp MainLevels									; if he didn't, wait for another keyboard input from the console, jump to MainLevels
FinishChooseLevel:
	push [keepip5]
	ret
endp ChooseLevel

; The procedure displays the HowToPlay page and wait for any key
proc HowToPlay
	ScreenMode 13h									; clear the screen
	Image hwtply									; print the image: how to play
	PressAnyKey										; wait for any key input 
	ret
endp HowToPlay

; controls the game, lets the console choose from the following: story mode, choose level or how to play. The procedure finishes when the console press Esc 
proc MainMenu 
StartMenu:
	image menu										; print the menu image
	call PrintBMP
	WaitForChar										; wait for a char from the console and put it in al
	cmp al, 31h										; check if the console entered: 1
	jnz NextKey1									; if not, jump to the next check
	call StoryMode									; if he did, start the story mode
	jmp back										
NextKey1:
	cmp al, 32h										; check if the console entered: 2
	jnz NextKey2									; if not, jump to the next check
	call ChooseLevel								; if he did, open "Choose Level"
	jmp back
NextKey2:
	cmp al, 33h										; check if the console entered: 3
	jnz NextKey3									; if not, jump to the next check
	call HowToPlay									; if he did, open "How To Play"
	jmp back
NextKey3:
	cmp al, 27										; check if the console entered: Esc
	jnz StartMenu									; if not, jump to menu
	ScreenMode 2									; change the screen mode to text mode
	jmp exit										; if he did, finish Rush Hour
Back:
	jmp StartMenu
FinishMainMenu:
	ret
endp MainMenu

start:
	mov	ax,@data
	mov	ds, ax
; --------------------------
; Your code here
; --------------------------
	ScreenMode 13h
	Image worker
	PressAnyKey
	call MainMenu
exit:
	mov ax, 4c00h
	int 21h
END start