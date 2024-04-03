TITLE String Primitives and Macros      (Proj6_Sperlijo.asm)

; Author: Joseph Sperling
; Last Modified: 6/11/23
; OSU email address: sperlijo@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:        6        Due Date: 6/11/23
; Description: This program asks the user for 10 signed intergers that fit within a 32-bit register and then will display those
;				those intergers as well as the sum and average of them.

INCLUDE Irvine32.inc

;-------------------------------------------------------------
; Name: mGetString
;
; Takes a string entered by the user and adds it into memory
; at the address given by numHolder
;
; Preconditions: Uses EAX, EDX, and ECX
;
; Receives: introPromptAddress = string address offset
;			numHolder = string address offset
;
; Returns: numHolder with string entered by user
;			EAX = number of characters entered
;-------------------------------------------------------------

mGetString MACRO introPromptAddress, numHolder
	MOV			EDX, introPromptAddress
	CALL		WriteString
	MOV			EDX, numHolder
	MOV			ECX, 12
	CALL		ReadString
ENDM

;-------------------------------------------------------------
; Name: mDisplayString
;
; Takes the string at convertedString and prints each 
; each character to the console.
;
; Preconditions: Do not use ECX as argument
;
; Receives: convertedString: memory offset of a string to read 
;							 from
;			loopNum: value for number characters in 
;					 converted string.
;
; Returns: None
;-------------------------------------------------------------

mDisplayString MACRO convertedString, loopNum
	MOV		ECX, loopNum
_displayLoop:
	LODSB
	CALL	WriteChar
	LOOP	_displayLoop
ENDM


HI = 2147483647
LO = 2147483648
MAXSIZE = 10

.data
intro			BYTE "Project 6: String Primitives and Macros				By Joseph Sperling", 13, 10, 13, 10, 
					 "Please enter 10 signed numbers, each of which will need to fit in a 32 bit register", 13, 10,
					 "When you have done so, I will display a list of the inputted numbers, their sum, and the truncated average.", 13, 10, 0
prompt			BYTE "Please enter your signed integer: ", 0
errorPrompt		BYTE "ERROR: Please re-enter your number and make sure it is a signed integer within the specified range", 13, 10, 0
listDisplay		BYTE "You entered the following numbers:", 0
sumDisplay		BYTE "The sum of the above numbers is: ",0
averageDisplay	BYTE "The truncated average is: ",0
closing			BYTE "Thanks for playing! Come back anytime.", 13, 10, 13, 10, 0
space			BYTE ", ", 0
numList			SDWORD MAXSIZE DUP(?)
userNum			BYTE ?
convertBack		BYTE ?
sum				SDWORD ?
average			SDWORD ?



.code
main PROC
;Introduce the program
	PUSH	OFFSET intro
	CALL	Message
	CALL	CRLF

;Get the 10 numbers from the user
	MOV		EDX, OFFSET numList
	MOV		ECX, MAXSIZE
_getUserNumLoop:
	PUSHAD
	PUSH	OFFSET errorPrompt
	PUSH	EDX
	PUSH	OFFSET userNum
	PUSH	OFFSET prompt
	CALL	ReadVal
	POPAD
	ADD		EDX, 4
	LOOP	_getUserNumLoop
	CALL	CRLF


;Display the list of user numbers
	PUSH	EDX
	PUSH	OFFSET listDisplay
	CALL	Message
	POP		EDX
	CALL	CRLF
	MOV		ECX, MAXSIZE
	MOV		ESI, OFFSET numList
_writeLoop:
	PUSHAD
	PUSH	ESI 
	PUSH	OFFSET convertBack
	CALL	WriteVal
	POPAD
	ADD		ESI, 4
	CMP		ECX, 1
	JE		_nextOperation
	PUSH	EDX
	PUSH	OFFSET space
	CALL	AddSpace
	POP		EDX
	LOOP	_writeLoop

;Calculate  sum and average
_nextOperation:
	CALL	CrLf
	PUSHAD
	PUSH	OFFSET sum
	PUSH	OFFSET average
	PUSH	OFFSET numList
	CALL	SumAndAverage
	POPAD

;Display sum
	PUSH	EDX
	PUSH	OFFSET sumDisplay
	CALL	Message
	POP		EDX
	PUSHAD
	PUSH	OFFSET sum
	PUSH	OFFSET convertBack
	CALL	WriteVal
	POPAD
	CALL	CrLf
;Display average
	PUSH	EDX
	PUSH	OFFSET averageDisplay
	CALL	Message
	POP		EDX 
	PUSHAD
	PUSH	OFFSET average
	PUSH	OFFSET convertBack
	CALL	WriteVal
	POPAD
	CALL	CRLF

;Exit message
	PUSH	OFFSET closing
	CALL	Message


	Invoke ExitProcess,0	; exit to operating system
main ENDP

;-------------------------------------------------------------
; Name: ReadVal
; 
; Reads an input from the user and converts it from a string
; to a signed integer SDWORD. Checks the string to make sure 
; that it is valid before conversion. If it is not, it will
; produce and error statement and jump back to the top of the 
; procedure
;
; Preconditions: The array type is SDWORD
;
; Postconditions: EDX, ECX, ESI, EDI, and EBX are changed
;
; Receives: [EBP + 8] = Prompt (reference, input, string)
;			[EBP + 12] = userNum (reference, input, string) 
;			[EBP + 16] = numList (reference, input, output, SDWORD 
;								array)
;			[EBP + 20] = error (reference, input, string)
;
; Returns: numList with new SDWORD added in 
;-------------------------------------------------------------

ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP
_getVal:
	MOV		EDX, [EBP + 8]
	MOV		EBX, [EBP + 12]
	PUSH	EDX
	PUSH	ECX
	mGetString	EDX, EBX					;Call the macro that actually gets the string from the user
	POP		ECX
	POP		EDX
	MOV		ECX, EAX						;Move string characters entered into ECX
	MOV		ESI, [EBP + 12]
	MOV		EDI, [EBP + 16]
	MOV		EBX, 0							;EBX will hold total for the string to num conversion
	CLD						
	LODSB
	CMP		AL, 43							;Check for + sign
	JE		_posDec
	CMP		AL, 45							;Check for - sign
	JE		_negDec
	CMP		AL, 48
	JL		_error
	CMP		AL, 57
	JG		_error
	JMP		_makeNum

_posDec:
	DEC		ECX
_posValLoop:								;Loop to be used if number is positive
	LODSB
	CMP		AL, 48
	JL		_error
	CMP		AL, 57
	JG		_error
_makeNum:
	SUB		AL, 48
	PUSH	EAX
	MOV		EAX, EBX
	MOV		EBX, 10
	MUL		EBX
	POP		EDX
	ADD		EAX, EDX
	MOV		EBX, EAX
	XOR		EAX, EAX						;Needed to clear EAX otherwise the algorithm stopped working for strings greater than 4
	LOOP	_posValLoop
	CMP		EBX, HI
	JA		_error
	MOV		SDWORD PTR [EDI], EBX
	JMP		_readValEnd

_negDec:
	DEC		ECX
_negValLoop:								;Loop to be used if number is negative 
	LODSB
	CMP		AL, 48
	JL		_error
	CMP		AL, 57
	JG		_error
_makeNegNum:
	SUB		AL, 48
	PUSH	EAX
	MOV		EAX, EBX
	MOV		EBX, 10
	MUL		EBX
	POP		EDX
	ADD		EAX, EDX
	MOV		EBX, EAX
	XOR		EAX, EAX
	LOOP	_negValLoop
	CMP		EBX, HI
	JA		_error
	NEG		EBX								;Turn number negative before storing it
	MOV		SDWORD PTR [EDI], EBX
	JMP		_readValEnd

_error:
	MOV		EDX, [EBP + 20]
	CALL	WriteString
	JMP		_getVal

_readValEnd:
	POP		EBP
	RET		16
ReadVal ENDP

;-------------------------------------------------------------
; Name: WriteVal
;
; Takes a interger, signed or unsigned, and converts it from
; a number into ASCII characters before printing those to the 
; console. Contains two loops to go through based on whether
; the number is positive or negative.
;
; Preconditions: Needs some sort of stored integer signed or
;				unsigned.
;
; Postconditions: ESI, EDI, EAX, ECX, and EBX are changed 
;
; Receives: [EBP + 12] = numList (reference, input, integer)
;			[EBP + 8] = convertBack (reference, input, string)
;
; Returns: None
;-------------------------------------------------------------

WriteVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	MOV		ESI, [EBP + 12]
	MOV		EDI, [EBP + 8]
	MOV		EAX, [ESI]
	MOV		ECX, 0
	CMP		EAX, 0
	JS		_negVal

_writeValStart:					;Loop to follow if the value is positive, deals with endianess by pushing onto the stack and popping off in reverse order
	XOR		EDX, EDX
	CDQ
	MOV		EBX, 10
	DIV		EBX
	INC		ECX
	CMP		EAX, 0
	JE		_store
	ADD		DL, 48
	PUSH	EDX
	JMP		_writeValStart
	
_store:
	MOV		EBX, 0
	ADD		DL, 48
	PUSH	EDX
_storeLoop:
	POP		EAX
	STOSB
	INC		EBX
	LOOP	_storeLOOP
	JMP		_endWriteVal

_negVal:					;Loop to follow if the value is negative, deals with endianess by pushing onto the stack and popping off in reverse order
	NEG		EAX
_negValStart:
	XOR		EDX, EDX
	CDQ
	MOV		EBX, 10
	DIV		EBX
	INC		ECX
	CMP		EAX, 0
	JE		_negStore
	ADD		DL, 48
	PUSH	EDX
	JMP		_negValStart
	
_negStore:
	MOV		EBX, 0
	ADD		DL, 48
	PUSH	EDX
	MOV		DL, 45
	PUSH	EDX
	INC		ECX
_negStoreLoop:
	POP		EAX
	STOSB
	INC		EBX
	LOOP _negStoreLOOP


_endWriteVal:
	MOV		ESI, [EBP + 8]
	mDisplayString ESI, EBX
	POP		EBP
	RET		8
WriteVal ENDP

;-------------------------------------------------------------
; Name: Message
;
; Writes a message of choice to the console using Irvine's
; WriteString.
;
; Receives: [EBP + 8] = Address offset of a string 
;			(reference, input)
;
;-------------------------------------------------------------

Message PROC 
	PUSH	EBP
	MOV		EBP, ESP
	MOV		EDX, [EBP + 8]
	CALL	WriteString
	POP		EBP
	RET		4
Message ENDP


;-------------------------------------------------------------
; Name: AddSpace
;
; Writes a comma and space to the console using Irvine's 
; WriteString. 
;
; Receives: [EBP + 8] = Address offset of a comma + space 
;			string (reference, input)
;-------------------------------------------------------------

AddSpace PROC
	PUSH	EBP
	MOV		EBP, ESP
	MOV		EDX, [EBP + 8]
	CALL	WriteString
	POP		EBP
	RET		4
AddSpace ENDP

;-------------------------------------------------------------
; Name: SumAndAverage
;
; Takes an SDWORD array and calculates the sum and truncated 
; average of the array.
;
; Preconditions: Needs two empty SDWORDS and a filled SDWORD
;				array. Also need a constant named MAXSIZE 
;				defining the size of the array.
;
; Postconditions: ESI, EDI, EBX, ECX, and EAX are changed 
;
; Receives: [EBP + 8] = numlist [reference, input]
;			[EBP + 12] = average [reference, output]
;			[EBP + 16] = sum [reference, output]
;
; Returns: average and sum SDWORDS filled with their respective
;			values 
;-------------------------------------------------------------

SumAndAverage PROC
	PUSH	EBP
	MOV		EBP, ESP
	MOV		ESI, [EBP + 8]			
	MOV		EDI, [EBP + 16]
	MOV		EBX, 0
	MOV		ECX, MAXSIZE 
_sumLoop:
	MOV		EAX, [ESI]
	ADD		EBX, EAX
	ADD		ESI, 4
	LOOP	_sumLoop
	MOV		[EDI], EBX
	MOV		EDI, [EBP + 12]
	MOV		EAX, EBX
	XOR		EDX, EDX
	MOV		EBX, MAXSIZE
	CDQ
	IDIV	EBX
	MOV		[EDI], EAX
	POP		EBP
	RET		12

SumAndAverage ENDP



END main
