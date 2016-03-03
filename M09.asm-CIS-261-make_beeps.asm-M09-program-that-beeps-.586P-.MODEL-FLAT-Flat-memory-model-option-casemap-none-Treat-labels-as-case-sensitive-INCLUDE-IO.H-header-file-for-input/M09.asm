; CIS-261
; make_beeps.asm
; M09: program that beeps


.586P
.MODEL FLAT         ; Flat memory model
option casemap:none ; Treat labels as case-sensitive

INCLUDE IO.H        ; header file for input/output

EXTERN _Beep@8:NEAR
EXTERN _GetLastError@0:NEAR
EXTERN _Sleep@4:NEAR

.CONST              ; Constant data segment
WHITE_SPACE        BYTE ' ', 0
PROMPT_FREQ        BYTE "Enter an array of frequencies:", 0
PROMPT_DURATION    BYTE "Enter an array of durations:", 0
NEWLINE            BYTE 13, 10, 0

.STACK 100h         ; (default is 1-kilobyte stack)

.DATA               ; Begin initialized data segment
    buffer      BYTE    12 DUP (?), 0   ; input buffer for user interaction
    dtoa_buffer BYTE    11 DUP (?), 0

    frequency   DWORD   16 DUP (?)      ; array of frequencies in Hertz
    frequency_end EQU   OFFSET frequency + SIZEOF frequency
                DWORD   0               ; zero marks freq end

    duration    DWORD   16 DUP (50)     ; array sound duration in ms
    duration_end    EQU        OFFSET duration + SIZEOF duration

.CODE           ; Begin code segment
_main PROC      ; Beginning of code
repeat_freq_input:
    xor     edi, edi       ; set EDI = 0, to be used as array index
    output  NEWLINE
    output  PROMPT_FREQ
    output  NEWLINE
get_next_freq:
    input   buffer, 12
    szlen   buffer                  ; check the length of input
    or      eax, eax                ; if input is empty (EAX == 0)
    jz      repeat_duration_input   ; done with the input
    atod    buffer                  ; convert user input, result in EAX
    jno     @F                      ; Check the overflow flag
    ; Handle input error:
    ;...
    jmp        repeat_freq_input
@@:
    ; store freq or zero at the end of the array
    mov     frequency[ edi * 4 ], eax
    inc     edi                         ; increment array index
    lea     eax, frequency[ edi * 4 ]   ; set EAX equal address of the array element
    cmp     eax, frequency_end          ; out of bounds ?
    je      @F                          ; if yes, terminate the input loop
    jmp     get_next_freq
@@:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; input duration array
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
repeat_duration_input:
    xor     edi, edi            ; set EDI = 0, to be used as array index
    output  PROMPT_DURATION
    output  NEWLINE
get_next_duration:
    input   buffer, 12
    szlen   buffer              ; check the length of input
    or      eax, eax            ; if input is empty (EAX == 0)
    jz      produce_sounds      ; done with the input
    atod    buffer              ; convert user input, result in EAX
    jno     @F                  ; Check the overflow flag
    ; Handle input error:
    ;...
    jmp        repeat_duration_input
@@:
    ; store freq or zero at the end of the array
    mov     duration[ edi * 4 ], eax
    inc     edi                      ; increment array index
    lea     eax, duration[ edi * 4 ] ; set EAX equal address of the array element
    cmp     eax, duration_end        ; out of bounds ?
    je      @F                       ; if yes, terminate the input loop
    jmp     get_next_duration
@@:
produce_sounds:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; loop to produce sounds with Beep
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cl, LENGTHOF frequency       ; loop counter
    mov esi, 0                       ; frequency array index

repeat_beep:
    mov eax, DWORD PTR frequency[esi*TYPE DWORD]
    or  eax, eax    ; if freq iz zero, stop
    jnz @F
    jmp repeat_freq_input
@@:
    mov ebx, DWORD PTR [duration]
    call make_beep
    or eax, eax
    jz @F           ; everything is okay
    ; report an error...
@@:
    inc esi         ; increment array index
    dec cl          ; decrement loop counter
    jnz repeat_beep ; repeat
    ret             ; Exit the program
    
_main ENDP

; POSTCONDITION: modifies ebx
; input params: eax freq
;               ebx duration
; returns: eax == 0 if no error, otherwise GetLastError result
make_beep PROC         ; sample procedure
    dtoa    dtoa_buffer, eax        ; convert 32-bit signed integer to string
    output  dtoa_buffer             ; print frequency
    output  WHITE_SPACE             ; print space

    ; preserve all gp registers
    pushad

    push ebx                        ; duration param
    push eax                        ; freq param
    call _Beep@8                    ; make sound

    ; EAX != 0 indicates succeess, error otherwise
    or eax, eax
    jnz @F                          ; success

    popad
    call _GetLastError@0
    ; EAX contains the error code to report
    ret
@@:
    pushd 300                       ; duration of sleep in MS
    call _Sleep@4

    ; restore all registers
    popad
    xor eax, eax    ; set EAX = 0
    ret             ; return from procedure
make_beep ENDP

END _main           ; Marks the end of the module and sets the program entry point label
