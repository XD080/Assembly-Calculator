bits 16        ; Tell the assembler that this is 16-bit code
global start   ; Make our "start" label public for the linker

start: ;     
    mov sp, 0x7c00      ; Pointing the stack pointer to a default address
    mov si,prompt_1     ; Load message
    mov ah, 0x00        ; Video Mode
    mov al, 0x03        ; Text Mode
    int 0x10            ; Interrupt
    mov al,0x00         
    jmp printone        ; jmp for printing the first prompt

printone:
    lodsb           	; load the first byte at si
    test al,al          ; test if al is empty
    jz get_inputone     ; if empty go ask for the first input
    mov ah,0x0e   	 	; print the character
    int 0x10
    jmp printone        ; loop until done

printtwo:               ; same logic as printone
    lodsb           	 
    test al,al
    jz get_inputtwo
    mov ah,0x0e   	 	
    int 0x10
    jmp printtwo

printthree:            ; same logic as printone
    lodsb           	 
    test al,al
    jz get_inputthree
    mov ah,0x0e   	 	
    int 0x10
    jmp printthree

get_inputone:
    mov al,0x00        ; reset al for next input
    mov ah,0x00
    mov cl,0           ; place to store val
    mov bl,10          ; default mutiplier, value of 10

    int 0x16            ; read mode
    mov ah,0x0e         ; print character
    int 0x10            

    cmp al,0x0d         ; enter key detection
    je check

    cmp al,'-'          ; negative sign detection
    je set_x

    mov [quit],al       ; store the current byte to quit, if q, end the program
    call convertX       ; see if the value stored needs to be negative
    jmp get_inputone

set_x:
    mov dl,-1    ; if "-" sign is given, indicate it in the buffer space
    jmp get_inputone

set_y: ; same logic as set_x
    mov dh,-1
    jmp get_inputtwo

get_inputtwo: ; same logic as get_inputtwo
    mov al,0x00
    mov ah,0x00
    mov cl,0
    mov bl,10

    int 0x16
    mov ah,0x0e
    int 0x10

    cmp al,0x0d
    je checktwo

    cmp al,'-'
    je set_y

    mov [quit],al
    call convertY
    jmp get_inputtwo

get_inputthree: ;same logic as getinputone
    mov al,0x00
    mov ah,0x00
    

    int 0x16
    mov ah,0x0e
    int 0x10

    cmp al,0x0d
    je checkthree

    mov [op],al

    jmp get_inputthree

convertX:
    sub al,'0' ; subtract character 0 from the input to get the numerical value
    xor ah,ah
    mov cl,al  ; load the character numerical value into cl
    mov al,[x]  ; load old value stored at x into al 
    imul bl     ; update the old value by mutipled by 10, val 10 was stored in bl register
    add al,cl   ; add the updated old value with the new entered input
    mov [x],al  ; store the final result into x
    ret

convertY:   ;same logic as convertX
    sub al,'0'
    xor ah,ah
    mov cl,al
    mov al,[y]
    imul bl
    add al,cl
    mov [y],al
    ret

check:
    cmp byte [quit],'q' ; if a single q is entered, end the program, keep jumping infinitely
    je done

  
    cmp dl ,-1    ; if a negative sign is entered, negate the value stored at X
    je negation_x
    jne negx_clean
    

negx_clean: 
    mov si,prompt_2 ; load the next prompt into si
    call new_line
    jmp printtwo

negy_clean:
    mov si,prompt_3 ; load the next prompt into si
    call new_line
    jmp printthree

negation_x:
    mov ax,[x] ; move the value stored at X into ax for negation
    neg ax ; negate the value
    mov [x],ax ; store it back to x
    jmp negx_clean 

negation_y: ; same logic as negation_y
    mov ax,[y]
    neg ax
    mov [y],ax
    jmp negy_clean
checktwo: ; same logic as checkone
    cmp byte [quit],'q'
    je done

    cmp dh ,-1
    je negation_y
    jmp negy_clean
    

checkthree: ; same logic as checkone
    cmp byte [op],"q"
    je done

    mov si,prompt_4
    
    mov al, 0x0d
    mov al, 0x0a
    int 0x10


    cmp byte [op],"+" ; if plus sign entered, do addition
    jz addition

    cmp byte [op],"*" ; if multiplication sign entered, do mutiplication
    jz mutiply

    cmp byte [op],"/" ; if division sign entered, do division
    jz divi

    cmp byte [op],"-" ; if minus sign entered, do subraction
    jz minus
  
addition:
    mov ax,[x] ; load the first input into ax(not al because we want the final to be 16 bit)
    mov bx,[y] ; load the first input into ax(not bl because we want the final to be 16 bit)
    add ax,bx   ; add them
    mov [z],ax  ; put the value into z
    xor ax,ax
    jmp print_result
    

minus:
    mov ax,[x]  
    mov bx,[y]
    sub ax,bx ; subtract them
    mov [z],ax
    jmp print_result
    ret

mutiply:
    mov ax,[x]
    mov bx,[y]
    imul bx ; val at ax mutiplied by val at bx
    mov [z],ax
    jmp print_result
    ret

divi:
    mov ax,[x]
    mov bx,[y]
    cwd
    idiv bx ; val at ax divided by val at bx
    mov [z],ax
    jmp print_result
    ret

print_result: ; print the "result: " prompt
    lodsb  
    test al,al
    jz set_up
    mov ah,0x0e   	 	
    int 0x10
    jmp print_result

set_up: 
    mov ax,[z] ; move the final result val to ax for final check
    test ax,ax ; see if the result is negative
    js set_neg  
    jmp itoa
    
set_neg:
    neg ax  ; make the negative value postive for easy printing
    mov [z],ax ; store it back to z
    mov al,"-" ; print the negative sign on the screen
    mov ah,0x0e
    int 0x10
    jmp itoa

itoa:
    mov ax,[z] ; put the final result into ax for operations
    mov bx,10 ; divisor for performing itoa
    mov cx,0 ; counter for performing loop
    jmp step1
step1:
    mov dx,0 ; clean dx
    cmp ax,10 ; if greater than 10, continue the loop
    idiv bx ; divide the val at ax by 10
    jl n1   ; if not, go to next step
    push dx ; reminder is at dx, push that to the stack 
    inc cx  ; increment cx, representing the number of characters inside the current number
    jmp step1
n1:
    push dx ; just one single digit, push it the stack and move one
    inc cx  ; increment cx
    jmp step2
step2: 
    pop ax  ; pop the first character to print into ax
    add al,'0' ; get its ascii value
    mov ah,0x0e ; print it
    int 0x10 ; interrupt
    loop step2 ; keep looping based on the val previously stored on cx


    call new_line   
    call clean
    mov si,prompt_1
    jmp printone

clean:
    push di     ;callee save data
    lea di,x    ; move the callee save data into buffer
    xor ax,ax   ; fill the buffer with 0
    mov cx,128  ; 512/4 = 128
    rep stosd   ; store string with 128 dwords = 512 bytes.
    pop di      ; point the di to the orignal address
    ret                  


new_line:
    mov al, 0x0d ; carrige return
    mov ah, 0x0e ; print it
    int 0x10 ; interrupt
    mov al, 0x0d ; carrige return again
    mov al, 0x0a ; a newline
    int 0x10    ; interrupt
    ret
done:
  jmp done     ; When we're done, loop indefinitely

prompt_1:
  db `First:\0`      ; "message" is the address at the start of the
                            ; character buffer
prompt_2:
  db `Second:\0`      ; "message" is the address at the start of the
                            ; character buffer
prompt_3:
  db `Op:\0`      ; "message" is the address at the start of the
                            ; character buffer

prompt_4:
  db `result:\0`      ; "message" is the address at the start of the
                            ; character buffer

x dw 0
y dw 0
z db 0

quit dw ''
op dw ''


