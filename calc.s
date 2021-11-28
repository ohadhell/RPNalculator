section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string
    fmtInt: db "%d", 0
    promptMsg: db "calc: ", 0
    err_overflow: db "Error: Operand Stack Overflow",0
    err_insufficient: db "Error: Insufficient Number of Arguments on Stack",0
    line_format: db 10,0

section .bss
    isDebug: resb 1
    isFirstLink: resb 1
    isCustomStackSize: resb 1
    reset_var: resb 5
    STKCTR: resd 1
    STKSIZE: resd 1     ;need to try double word
    opStk: resd 1
    buffer: resb 81     ;max is 80 + null char
    linkPassedNum: resd 1     
    strLen: resb 1
    opCounter: resd 1   ;counter for num of op that was done
    prevLink: resb 5    ;for plus op
    


section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern gets 
  extern getchar 
  extern fgets 
  extern stdout
  extern stdin
  extern stderr

main:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]            ;eax = argc
    mov ecx, [ebp + 12]         ; ecx = argv
    mov byte[isDebug], 0        ;initialize isDebug with 0
    mov byte[isCustomStackSize],0 ;initialize iisCustomStackSize with 0
    mov byte[STKSIZE],5
    mov byte[STKCTR],0
    mov byte[opCounter],0
    mov dword[reset_var],0
    cmp eax, 1                  ; check if we got one argument
    je createStack              ; we didn't got args
    mov edi, 1                  ;edi = i
argvLoop:
    cmp edi,eax                 ;comparing i and argc
    je createStack              ;if so need to continue
    mov esi, dword[ecx + 4*edi] ;esi = argv[i]
    cmp byte[esi], '-'
    je activeDebug              ;checking for '-d' otherwise a number max 77
    inc byte[isCustomStackSize]
    ; now need to get the number from octal to dec and malloc for our stack
    inc edi
    mov ebx,0
    mov edx,0
convertDig:                 ; esi has the argv[i]
        cmp byte[esi], 0	;check for null byte
        je argvLoop         ;need to continue go over argv
        sub byte[esi], 48	;converting the number to it's decimal value
    .OctToDecimal:
        or byte[esi],0      ; converting to binary represantation
        mov dl, byte[esi]
        shl ebx,3           ;saving space for the 3 bits
        add ebx,edx         ;adding the bits we got
        inc esi             ; moving to the next digit
        jmp convertDig      ;continute to next digit
        
createStack:                ;ebx = custom stack size in decimal
    cmp byte[isCustomStackSize],1
    je .createCustomStack
    push 20                 ;default is 4*5 = 20 bytes
    call malloc
    add esp, 4
    mov edi,eax             ; edi points to our stack
    mov [opStk], eax        ;for free purposes
    add edi, 20             ; edi points to the end of the stack
    jmp calc                ; need to start getting number
    .createCustomStack:     
        mov eax,ebx                 ;moving the number to eax for mul
        mov dword[STKSIZE],eax      ;stksize = custom stack size
        mov ebx,4                   ; mul by 4 because each linklist will need 4 bytes
        mul ebx
        mov ebx,eax
        push eax
        call malloc
        add esp, 4
        mov edi,eax                 ; edi points to our stack
        mov [opStk], eax            ;for free purposes
        add edi, ebx                ;edi points to the end of the stack

calc:           ;edi is the pointer for the opstack
    push promptMsg
    call printf
    add esp, 4
    mov byte[isFirstLink],0
    mov eax,buffer
    push eax
    call gets                      ;the returned string will be inside of eax
    ;-------------
    ;checking for special input 
    cmp byte[eax],'q'
    je freeOpStack
    cmp byte[eax],'+'
    je opPlus
    cmp byte[eax],'p'
    je print_OP
    cmp byte[eax],'d'
    je duplicate_Op
    cmp byte[eax],'&'
    je and_Op
    cmp byte[eax],'n'
    je numberByte_Op
    ;-------------
    ;no special input, so ocatl number is inserted
    ;---input is a number---
    mov edx,[STKSIZE]
    cmp edx, dword[STKCTR]
    je Error_OverFlow           ;need to jmp to print to many numbers and come back to calc
    inc dword[STKCTR]
    cmp byte[isDebug],1
    je printDebug               ;printing the number that was entered
    
contCalc:
    mov ebx,eax                 ;moving the string to ebx
    mov byte[strLen], 0
getStrLen:
    inc byte[strLen]
    inc eax
    cmp byte[eax], 0            ;check for end of the string
    jne getStrLen
    and byte[strLen], 1         ;check if length is even or odd
    cmp byte[strLen], 1
    jne convertor               ;if odd we want to put the msb to contain only one digit
    mov esi, 1
    mov edx, 0
    jmp convertDig2
convertor:                      ;edi is the pointer for the opstack
    mov esi,2
    mov edx,0                   ;edx will hold the value
    mov eax,0                   ;tmp for help calc
convertDig2:                    ; esi has the argv[i]
        cmp esi,0
        je  putInLink
        cmp byte[ebx], 0	    ;check for null byte
        je  putInLink           ;finished going over all of the number
        sub byte[ebx], 48	    ;converting the number to it's decimal value
    .OctToDecimal:              ; binary rep
        or byte[ebx],0          ; converting to binary represantation
        mov al, byte[ebx]
        shl edx,3               ;saving space for the 3 bits
        add edx,eax             ;adding the bits we got
        dec esi                 ; moving to the next digit
        inc ebx
        jmp convertDig2         ;continute to next digit


;this implemnts push to the stack
putInLink: ;edx holds the number we want to put in the first link (msb) we will use just al
    cmp esi,2
    je calc                 ;if we got to the null char at the end
    push edx
    push ebx
    push ecx
    mov eax, 5
    push eax
    call malloc             ;malloc 5 bytes first for number next for next link
    add esp,4
    pop ecx
    pop ebx
    pop edx                 ; edx = input number
    cmp byte[isFirstLink],0
    jne .skip
    sub edi, 4
    mov [edi], eax          ;put the pointer for 5 bytes in the right place in edi, [edi] will point to the adress of the link list
    mov byte[eax], dl       ; suppused to put the bits in the first byte
    mov dword[eax + 1], 0   ; put null char in the first link
    mov ecx,eax             ; save the address of the first link
    inc byte[isFirstLink]
    jmp convertor
    .skip:
        mov [edi], eax
        mov byte[eax], dl       ; suppused to put the bits in the first byte
        mov dword[eax + 1], ecx
        mov ecx, eax            ; save the address of the curr 
jmp convertor

opPlus:
    inc dword[opCounter]    ;
    cmp byte[STKCTR],1      ;checking if we got enough numbers in stack
    jle Error_Insufficient  ;need to print not enough numbers   
    call popOp
    push eax                ;to free it later
    mov esi, eax            ;esi points to the last number entered
    call popOp              
    push eax                ;to free it later
    mov ebx, eax            ;ebx points to the second number now
    sub edi,4               ;we removed two from the stack need to put the result in the currect place
    mov edx,0               ;for the carry
    inc byte[STKCTR]
    
    .loop:
        cmp esi, ebx
        je .check_carry
        mov ecx, 0
        mov cl, byte[ebx]     ;moving the number in the first link to al
        add cl, byte[esi]       ;sum off the two numbers
        add cl,dl               ;add the carry
        jmp .nextLinks
        .retNextLinks:       
        cmp cl, 64              ;if we got 64 or more in the sum we need to add to the carry
        jge .tooBig
        mov edx, 0
        jmp .enter_to_link       
    .tooBig:
        mov edx,1               ;edx holds the carry
        and ecx,63              ;now ecx holds 6 bits of sum
    .enter_to_link: 
        push ecx
        push ebx
        push edx
        push 5
        call malloc
        add esp, 4
        pop edx
        pop ebx
        pop ecx
    .labl:
        cmp byte[isFirstLink],0
        jne .skip
        mov [edi], eax                  ;put the pointer for 5 bytes in the right place in edi, [edi] will point to the adress of the link list
        mov byte[eax], cl               ; suppused to put the bits in the first byte
        mov dword[eax + 1], 0           ; put null char in the first link 
        mov dword[prevLink], eax        ;save current link
        inc byte[isFirstLink]           ;indicates that we inserted the first link
        jmp .loop
        .skip:
            push edx
            mov edx,dword[prevLink]
            mov dword[edx + 1], eax         ;prev link to point to the curr we created
            mov dword[eax + 1], 0           ; put null char in the last link created
            mov byte[eax], cl               ; put the numer in the link data section
            mov dword[prevLink], eax        ;save current link 
            pop edx                         ;get the carry back
            jmp .loop  

    .nextLinks:
        cmp dword[ebx+1] , 0            ;check if next link is null
        je .stayPut_ebx                 ;if null point it to reset_var
        mov ebx,dword[ebx+1]            ;if not, point to next link
        .ret1:
        cmp dword[esi+1] , 0            ;check if next link is null
        je .stayPut_esi                 ;if null point it to reset_var
        mov esi,dword[esi+1]            ;if not, point to next link
        jmp .retNextLinks               ;return to continue the op  
        .stayPut_ebx:
            mov ebx,reset_var
            jmp .ret1
        .stayPut_esi:
            mov esi,reset_var
            jmp .retNextLinks
            
    .check_carry:
        mov ebx, edx            ;moving edx because it will change in the free process
        pop eax                 ;we pushed the pointer for the lists in the start to free them
        call freeLinkList        
        pop eax
        call freeLinkList
        cmp ebx, 0
        je calc                 ;we need to create a new link for the carry
        push 5
        call malloc
        add esp, 4
        mov ebx,dword[prevLink]
        mov dword[ebx + 1], eax        ;prev link to point to the curr we created
        mov dword[eax + 1], 0   ;put null char in the last link created 
        mov byte[eax], 1        ;put the carry in the last link
        jmp calc
numberByte_Op:
    inc dword[opCounter] 
    cmp byte[STKCTR],0      ;checking if we got enough numbers in stack
    je Error_Insufficient  ;need to print not enough numbers
    mov ebx, [STKSIZE]
    cmp bl,byte[STKCTR] 
    inc byte[STKCTR]
    je Error_OverFlow
    call popOp
    push eax        ;to free it later
    mov esi,eax     ;esi = last number entered
    sub edi, 4      ;pointing edi so we insert the link in the correct place
    mov ebx,0       ;counter for links
    .loop:
        mov esi,dword[esi + 1]  ; esi now point to the next link
        cmp esi,0
        je .finishLoop
        inc ebx
        jmp .loop
    .finishLoop:
        mov eax,6
        mul ebx             ;counting the bits
        shr eax,3           ;counting the bytes
    ;     jnc .ret_addOne
    ;     inc eax
    ; .ret_addOne:
        inc eax             ;adding one because the last link can contain one digit or two
        mov esi, eax        ;copying to esi the number of bytes
        push esi
        push fmtInt
        call printf
        add esp, 8
        push line_format
        call printf
        add esp, 4
        mov ebx,0

    .put_in_link:
        inc ebx             ;number of curr link
        mov ecx,esi         ;copying the number of bytes 
        and ecx, 63         ;reveling the first 6 bytes        
        push ecx
        push edx
        push 5
        call malloc
        add esp, 4
        pop edx
        pop ecx
        cmp ebx, 1
        jne .skip
        mov dword[edi],eax      ;put the new link in the operand stack 
        mov byte[eax],cl        ;putting the data to the link
        mov dword[eax+1],0      ;null char if last
        mov edx,eax             ;saving the previous link address
        shr esi, 6
        jmp .put_in_link
        .skip:
            cmp esi, 0
            je .finish
            mov dword[edx+1],eax    ;pointing the prev link to the new one
            mov byte[eax],cl    ;inserting the byte data
            mov dword[eax+1],0  ;next link null
            mov edx,eax         ;save the curr link
            shr esi,6           ;removing the 6 first bytes
            jmp .put_in_link
    .finish:
        pop eax
        call freeLinkList
        jmp calc


duplicate_Op:
    inc dword[opCounter] 
    cmp byte[STKCTR],0      ;checking if we got enough numbers in stack
    je Error_Insufficient  ;need to print not enough numbers
    mov ebx, [STKSIZE]
    cmp bl,byte[STKCTR] 
    je Error_OverFlow
    inc byte[STKCTR]
    mov esi,dword[edi]      ;esi = last number entered
    sub edi, 4
    push 5
    call malloc
    add esp,4
    mov dword[edi],eax      ;put the new link in the operand stack
    mov ebx,[esi]
    mov byte[eax],bl
    mov esi,dword[esi + 1]  ; esi now point to the next link
    mov dword[eax+1],0      ;null char if last
    mov ecx,eax             ; ecx points to the dup list
    .loop:
        cmp esi, 0          ;esi = address of next link
        je calc
        push ecx
        push 5
        call malloc
        add esp,4
        pop ecx
        mov dword[ecx+1],eax        ;setting the prev link to point to the new link   
        mov ecx,eax                 ;ecx points to the new link           
        mov ebx,[esi]               ;mov the curr link data to ebx
        mov byte[eax],bl            ; mov the data to the dup link data
        mov esi,dword[esi + 1]      ; esi now point to the next link
        mov dword[eax+1],0          ;null char if last
        jmp .loop

and_Op:
    inc dword[opCounter]    ;
    cmp byte[STKCTR],1      ;checking if we got enough numbers in stack
    jle Error_Insufficient  ;need to print not enough numbers  
    push 5 
    call malloc
    add esp, 4
    mov edx,eax             ;edx will point to the new list
    call popOp
    push eax                ;to free it later
    mov esi, eax            ;esi points to the last number entered
    call popOp              
    push eax                ;to free it later
    mov ebx, eax            ;ebx points to the second number now
    sub edi, 4              ;we removed two from the stack need to put the result in the currect place
    inc byte[STKCTR]
    mov dword[edi],edx      ;putting the list in the stack
    mov ecx, 0
    mov cl, byte[ebx]       ;moving the number in the first link to cl
    and cl, byte[esi]       ;& off the two numbers
    mov byte[edx],cl        ;insert the add result to the link
    mov dword[edx+1],0      ;next link = null for now
    .loop:
        mov esi, dword[esi+1]       ;pointing to next link
        mov ebx, dword[ebx+1]       ;pointing to next link
        cmp esi,0
        je .finish
        cmp ebx,0
        je .finish
        mov ecx, 0
        mov cl, byte[ebx]     ;moving the number in the first link to al
        and cl, byte[esi]       ;sum off the two numbers
    .put_in_link:
        push edx
        push ecx
        push ebx
        push 5
        call malloc
        add esp,4
        pop ebx
        pop ecx
        pop edx
        mov dword[edx+1], eax   ;telling the prev link to point to the next(curr)
        mov edx, eax            ;edx now points to the new link
        mov byte[edx],cl        ;inserting data to the link
        mov dword[edx+1],0      ;pointing to null
        jmp .loop

    .finish:
    pop eax
    call freeLinkList
    pop eax 
    call freeLinkList
    jmp calc

print_OP:
    inc dword[opCounter]
    cmp byte[STKCTR],0
    je Error_Insufficient       ;need to print not enough arguments
    mov byte[linkPassedNum], 0
    call popOp                  ;putting the list pointer in eax
    push eax                    ;saving the pointer for the first link in the stack for the free
    .loop:
    inc byte[linkPassedNum]
    mov ebx, 0
    mov bl, byte[eax]           ;ebx will hold the number that in the curr link
    push ebx                    ;push for the print
    mov ecx, dword[eax + 1]     ;pointing to the next link
    mov eax, ecx                ;eax points to the next link
    cmp ecx, 0                  ;check for last link
    jne .loop
    pop esi                     ;getting the msb
    mov ebx, esi                ;copying it to ebx
    cmp ebx, 7                  ;checking if we got one dig in the last link(msb) to remove leading zero
    jle  .skip                  ;will remove leading zeros
    jmp .return_checkNumDig
    .contLoop:
    pop esi                     ;putting the number in esi
    mov ebx, esi                ;copying it to ebx  
    .return_checkNumDig:
    and ebx,56                  ; revealing the 3 left most bits
    shr ebx, 3                  ;divide by 8 for octal
    push ebx
    push fmtInt         
    call printf
    add esp,8   
    .skip:        
    and esi,7                   ;revealing the 3 right bits to esi
    push esi
    push fmtInt
    call printf
    add esp,8          
    dec byte[linkPassedNum]
    cmp byte[linkPassedNum], 0
    jne .contLoop
    push line_format
    call printf
    add esp,4                   
    pop eax                     ;getting the list we pushed in the start 
    call freeLinkList
    jmp calc                    

popOp: ;mov into eax the curr linklist that the stack (edi) points to
    mov eax,dword[edi]
    mov dword[edi], 0
    add edi, 4
    dec byte[STKCTR]
    ret

printDebug: ;need to print to stderr
    push eax
    push format_string
    push dword[stderr]
    call fprintf
    add esp,8
    pop eax
    jmp contCalc

Error_Insufficient:
    push err_insufficient
    push format_string
    call printf
    add esp,8
    jmp calc
Error_OverFlow:
    push err_overflow
    push format_string
    call printf
    add esp,8
    jmp calc
activeDebug:
    inc byte[isDebug]   ;isDebug =1
    inc edi             ;i++
    jmp argvLoop

freeLinkList:           ;we assume the list is now in eax
    mov esi, dword[eax + 1]     ;pointing to the next link
    push eax
    call free
    add esp, 4
    mov eax, esi        ;eax will point again to the link we need to free
    cmp eax, 0
    jne freeLinkList
    ret

freeOpStack:            ;edi points to the stack
    cmp byte[STKCTR], 0 ;check if empty
    je  done
    mov eax,dword[edi]  ;moving the first list to eax
    add edi, 4          
    call freeLinkList
    dec byte[STKCTR]
    jmp freeOpStack

done:                   ;edi points to our implemented stack
    push dword[opStk]
    call free
    add esp, 4
    mov ebx,0           ;for print op counter

print_OP_Counter:           ;printing the number of opertions preformed
    inc ebx
    mov eax, dword[opCounter]   ;copying for calc
    and eax, 7
    push eax                ;for printing later in .loop
    shr dword[opCounter],3
    cmp dword[opCounter], 0
    jne print_OP_Counter
    .loop:
        dec ebx
        push fmtInt
        call printf
        add esp, 8
        cmp ebx,0
        jne .loop 
    push line_format
    call printf
    add esp,4 
exit:
    mov esp, ebp
    pop ebp 
    ret
