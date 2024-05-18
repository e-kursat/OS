     name "kernel"
; this is a very basic example
; of a tiny operating system.
;
; this is kernel module!
;
; it is assumed that this machine
; code is loaded by 'micro-os_loader.asm'
; from floppy drive from:
;   cylinder: 0
;   sector: 2
;   head: 0


;=================================================
; how to test micro-operating system:
;   1. compile micro-os_loader.asm
;   2. compile micro-os_kernel.asm
;   3. compile writebin.asm
;   4. insert empty floppy disk to drive a:
;   5. from command prompt type:
;        writebin loader.bin
;        writebin kernel.bin /k
;=================================================

; directive to create bin file:
#make_bin#

; where to load? (for emulator. all these values are saved into .binf file)
#load_segment=0800#
#load_offset=0000#

; these values are set to registers on load, actually only ds, es, cs, ip, ss, sp are
; important. these values are used for the emulator to emulate real microprocessor state 
; after micro-os_loader transfers control to this kernel (as expected).
#al=0b#
#ah=00#
#bh=00#
#bl=00#
#ch=00#
#cl=02#
#dh=00#
#dl=00#
#ds=0800#
#es=0800#
#si=7c02#
#di=0000#
#bp=0000#
#cs=0800#
#ip=0000#
#ss=07c0#
#sp=03fe#



; this macro prints a char in al and advances
; the current cursor position:
putc    macro   char
        push    ax
        mov     al, char
        mov     ah, 0eh
        int     10h     
        pop     ax
endm


; sets current cursor position:
gotoxy  macro   col, row
        push    ax
        push    bx
        push    dx
        mov     ah, 02h
        mov     dh, row
        mov     dl, col
        mov     bh, 0
        int     10h
        pop     dx
        pop     bx
        pop     ax
endm


print macro x, y, attrib, sdat
LOCAL   s_dcl, skip_dcl, s_dcl_end
    pusha
    mov dx, cs
    mov es, dx
    mov ah, 13h
    mov al, 1
    mov bh, 0
    mov bl, attrib
    mov cx, offset s_dcl_end - offset s_dcl
    mov dl, x
    mov dh, y
    mov bp, offset s_dcl
    int 10h
    popa
    jmp skip_dcl
    s_dcl DB sdat
    s_dcl_end DB 0
    skip_dcl:    
endm



; kernel is loaded at 0800:0000 by micro-os_loader
org 0000h

; skip the data and function delaration section:
jmp start 
; The first byte of this jump instruction is 0E9h
; It is used by to determine if we had a sucessful launch or not.
; The loader prints out an error message if kernel not found.
; The kernel prints out "F" if it is written to sector 1 instead of sector 2.
           



;==== data section =====================

; welcome message:
msg  db "Micro-os'a ho",9Fh," geldiniz!", 0 

cmd_size        equ 10    ; size of command_buffer
command_buffer  db cmd_size dup("b")
clean_str       db cmd_size dup(" "), 0
prompt          db ">", 0

HOUR     DW 1 DUP (?)
MINUTE   DW 1 DUP (?)

; commands:
chelp    db "help", 0
chelp_tail:
ccls     db "cls", 0
ccls_tail:          

ctime   db "time", 0
ctime_tail:

cinitcap   db "initcap", 0
cinitcap_tail:

cstar db "star", 0
cstar_tail:

cauthors   db "authors", 0
cauthors_tail:

cquit    db "quit", 0
cquit_tail:
cexit    db "exit", 0
cexit_tail:
creboot  db "reboot", 0
creboot_tail:    

help_msg db "Micro-os'u se",87h,"ti",0A7h,"iniz i",87h,"in te",9Fh,"ekk",9Ah,"rler!", 0Dh, 0Ah
         db "Komutlar",8Dh,"n k",8Dh,"sa listesi:", 0Dh, 0Ah     
         db "help      - bu listeyi ekrana yazd",8Dh,"r",8Dh,"r.", 0Dh, 0Ah         
         
         db "time      - saati ekrana yazd",8Dh,"r",8Dh,"r.", 0Dh, 0Ah
         db "initcap   - girilen c",9Ah,"mlenin ba",9Fh," harflerini b",9Ah,"y",9Ah,"t",9Ah,"r.", 0Dh, 0Ah
         db "star      - ekrana y",8Dh,"ld",8Dh,"z ",87h,"izdirir.", 0Dh, 0Ah
         db "authors   - sistemi olu",9Fh,"turanlar",8Dh," ekrana yazd",8Dh,"r",8Dh,"r.", 0Dh, 0Ah         
                  
         db "cls       - ekran",8Dh," temizler.", 0Dh, 0Ah
         db "reboot    - makineyi yeniden ba",9Fh,"lat",8Dh,"r.", 0Dh, 0Ah         
         db "quit      - reboot komutuyla ayn",8Dh,".", 0Dh, 0Ah
         db "exit      - quit komutuyla ayn",8Dh,".", 0Dh, 0Ah, 0

         
time_msg db "Saat: ", 0

input_msg          db  "C",9Ah,"mleyi giriniz: ", 0 

user_input         db  50 (?)
tr_cmd_size        equ 50    ; size of command_buffer
tr_command_buffer  db tr_cmd_size dup("b")

initcap_result_msg db  "Sonu",87h,": ", 0 
 
author_name db "K",81h,"r",9Fh,"at Emre ",99h,"zkara"," taraf",8Dh,"ndan tasarland",8Dh,".", 0Dh, 0Ah, 0
authorname_end:

unknown  db "bilinmeyen komut: " , 0

;======================================

start:

; set data segment:
push    cs
pop     ds

; set default video mode 80x25:
mov     ah, 00h
mov     al, 03h
int     10h

; blinking disabled for compatibility with dos/bios,
; emulator and windows prompt never blink.
mov     ax, 1003h
mov     bx, 0      ; disable blinking.
int     10h


; *** the integrity check  ***
cmp [0000], 0E9h
jz integrity_check_ok
integrity_failed:  
mov     al, 'F'
mov     ah, 0eh
int     10h  
; wait for any key...
mov     ax, 0
int     16h
; reboot...
mov     ax, 0040h
mov     ds, ax
mov     w.[0072h], 0000h
jmp	0ffffh:0000h	 
integrity_check_ok:
nop
; *** ok ***
              


; clear screen:
call    clear_screen
                     
                       
; print out the message:
lea     si, msg
call    print_string


eternal_loop:
call    get_command

call    process_cmd

; make eternal loop:
jmp eternal_loop


;===========================================
get_command proc near

; set cursor position to bottom
; of the screen:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]

gotoxy  0, al

; clear command line:
lea     si, clean_str
call    print_string

gotoxy  0, al

; show prompt:
lea     si, prompt 
call    print_string


; wait for a command:
mov     dx, cmd_size    ; buffer size.
lea     di, command_buffer
call    get_string


ret
get_command endp
;===========================================

process_cmd proc    near

;//// check commands here ///
; set es to ds
push    ds
pop     es

cld     ; forward compare.

; compare command buffer with 'help'
lea     si, command_buffer
mov     cx, chelp_tail - offset chelp   ; size of ['help',0] string.
lea     di, chelp
repe    cmpsb
je      help_command

; compare command buffer with 'cls'
lea     si, command_buffer
mov     cx, ccls_tail - offset ccls  ; size of ['cls',0] string.
lea     di, ccls                     
repe    cmpsb
jne     not_cls
jmp     cls_command
not_cls:

   
; compare command buffer with 'time'
lea     si, command_buffer
mov     cx, ctime_tail - offset ctime   ; size of ['time',0] string.
lea     di, ctime
repe    cmpsb
je      time_command

; compare command buffer with 'initcap'
lea     si, command_buffer
mov     cx, cinitcap_tail - offset cinitcap   ; size of ['initcap',0] string.
lea     di, cinitcap
repe    cmpsb
je      initcap_command 

; compare command buffer with 'star'
lea     si, command_buffer
mov     cx, cstar_tail - offset cstar   ; size of ['star',0] string.
lea     di, cstar
repe    cmpsb
je      star_command

; compare command buffer with 'authors'
lea     si, command_buffer
mov     cx, cauthors_tail - offset cauthors   ; size of ['authors',0] string.
lea     di, cauthors
repe    cmpsb
je      authors_command

 
; compare command buffer with 'quit'
lea     si, command_buffer
mov     cx, cquit_tail - offset cquit ; size of ['quit',0] string.
lea     di, cquit
repe    cmpsb
je      reboot_command

; compare command buffer with 'exit'
lea     si, command_buffer
mov     cx, cexit_tail - offset cexit ; size of ['exit',0] string.
lea     di, cexit
repe    cmpsb
je      reboot_command

; compare command buffer with 'reboot'
lea     si, command_buffer
mov     cx, creboot_tail - offset creboot  ; size of ['reboot',0] string.
lea     di, creboot
repe    cmpsb
je      reboot_command

; ignore empty lines
cmp     command_buffer, 0
jz      processed


;////////////////////////////

; if gets here, then command is
; unknown...

mov     al, 1
call    scroll_t_area

; set cursor position just
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
dec     al
gotoxy  0, al

lea     si, unknown
call    print_string

lea     si, command_buffer
call    print_string

mov     al, 1
call    scroll_t_area

jmp     processed

; +++++ 'help' command ++++++
help_command:

; scroll text area 9 lines up:
mov     al, 14
call    scroll_t_area

; set cursor position 9 lines
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
sub     al, 14
gotoxy  0, al

lea     si, help_msg
call    print_string

mov     al, 1
call    scroll_t_area

jmp     processed



; +++++ 'cls' command ++++++
cls_command:
call    clear_screen
jmp     processed 



; +++++ 'time' command ++++++
time_command:

; scroll text area 2 lines up:
mov     al, 2
call    scroll_t_area

; set cursor position 2 lines
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
sub     al, 2
gotoxy  0, al

lea     si, time_msg
call    print_string

call    get_time

mov     al, 1
call    scroll_t_area

jmp     processed


; +++++ 'initcap' command ++++++
initcap_command:

; scroll text area 2 lines up:
mov     al, 2
call    scroll_t_area

; set cursor position 2 lines
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
sub     al, 2
gotoxy  0, al

lea     si, input_msg
call    print_string

call    initcap_upper

mov     al, 1
call    scroll_t_area

jmp     processed


; +++++ 'star' command ++++++
star_command:

call    draw_star
                  
jmp     start


; +++++ 'authors' command ++++++
authors_command:

; scroll text area 2 lines up:
mov     al, 2
call    scroll_t_area

; set cursor position 2 lines
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
sub     al, 2
gotoxy  0, al

lea     si, author_name
call    print_string

mov     al, 1
call    scroll_t_area

jmp     processed


; +++ 'quit', 'exit', 'reboot' +++
reboot_command:
call    clear_screen

print 5,2,0011_1111b," l"
print 7,2,0011_1111b,9Ah 
print 8,2,0011_1111b,"tfen t"
print 14,2,0011_1111b,9Ah
print 15,2,0011_1111b,"m disketleri "
print 28,2,0011_1111b,87h
print 29,2,0011_1111b,8Dh
print 30,2,0011_1111b,"kar"
print 33,2,0011_1111b,8Dh
print 34,2,0011_1111b,"n "

print 5,3,0011_1111b," ve yeniden ba"
print 19,3,0011_1111b,9Fh
print 20,3,0011_1111b,"latmak i"
print 28,3,0011_1111b,87h
print 29,3,0011_1111b,"in herhangi bir tu"
print 47,3,0011_1111b,9Fh
print 48,3,0011_1111b,"a bas"
print 53,3,0011_1111b,8Dh
print 54,3,0011_1111b,"n... "

mov ax, 0  ; wait for any key....
int 16h

; store magic value at 0040h:0072h:
;   0000h - cold boot.
;   1234h - warm boot.
mov     ax, 0040h
mov     ds, ax
mov     w.[0072h], 0000h ; cold boot.
jmp	0ffffh:0000h	 ; reboot!

; ++++++++++++++++++++++++++

processed:
ret
process_cmd endp

;===========================================

; scroll all screen except last row
; up by value specified in al

scroll_t_area   proc    near

mov dx, 40h
mov es, dx  ; for getting screen parameters.
mov ah, 06h ; scroll up function id.
mov bh, 07  ; attribute for new lines.
mov ch, 0   ; upper row.
mov cl, 0   ; upper col.
mov di, 84h ; rows on screen -1,
mov dh, es:[di] ; lower row (byte).
dec dh  ; don't scroll bottom line.
mov di, 4ah ; columns on screen,
mov dl, es:[di]
dec dl  ; lower col.
int 10h

ret
scroll_t_area   endp

;===========================================



; get characters from keyboard and write a null terminated string 
; to buffer at DS:DI, maximum buffer size is in DX.
; 'enter' stops the input.
get_string      proc    near
push    ax
push    cx
push    di
push    dx

mov     cx, 0                   ; char counter.

cmp     dx, 1                   ; buffer too small?
jbe     empty_buffer            ;

dec     dx                      ; reserve space for last zero.


;============================
; eternal loop to get
; and processes key presses:

wait_for_key:

mov     ah, 0                   ; get pressed key.
int     16h

cmp     al, 0Dh                 ; 'return' pressed?
jz      exit


cmp     al, 8                   ; 'backspace' pressed?
jne     add_to_buffer
jcxz    wait_for_key            ; nothing to remove!
dec     cx
dec     di
putc    8                       ; backspace.
putc    ' '                     ; clear position.
putc    8                       ; backspace again.
jmp     wait_for_key

add_to_buffer:

        cmp     cx, dx          ; buffer is full?
        jae     wait_for_key    ; if so wait for 'backspace' or 'return'...

        mov     [di], al
        inc     di
        inc     cx
        
        ; print the key:
        mov     ah, 0eh
        int     10h

jmp     wait_for_key
;============================

exit:

; terminate by null:
mov     [di], 0

empty_buffer:

pop     dx
pop     di
pop     cx
pop     ax
ret
get_string      end



; print a null terminated string at current cursor position, 
; string address: ds:si
print_string proc near
push    ax      ; store registers...
push    si      ;

next_char:      
        mov     al, [si]
        cmp     al, 0
        jz      printed
        inc     si
        mov     ah, 0eh ; teletype function.
        int     10h
        jmp     next_char
printed:

pop     si      ; re-store registers...
pop     ax      ;

ret
print_string endp



; clear the screen by scrolling entire screen window,
; and set cursor position on top.
; default attribute is set to white on blue.
clear_screen proc near
        push    ax      ; store registers...
        push    ds      ;
        push    bx      ;
        push    cx      ;
        push    di      ;

        mov     ax, 40h
        mov     ds, ax  ; for getting screen parameters.
        mov     ah, 06h ; scroll up function id.
        mov     al, 0   ; scroll all lines!
        mov     bh, 0000_1111b  ; attribute for new lines.
        ;mov     bh, 1001_1111b  ; attribute for new lines.
        mov     ch, 0   ; upper row.
        mov     cl, 0   ; upper col.
        mov     di, 84h ; rows on screen -1,
        mov     dh, [di] ; lower row (byte).
        mov     di, 4ah ; columns on screen,
        mov     dl, [di]
        dec     dl      ; lower col.
        int     10h

        ; set cursor position to top
        ; of the screen:
        mov     bh, 0   ; current page.
        mov     dl, 0   ; col.
        mov     dh, 0   ; row.
        mov     ah, 02
        int     10h

        pop     di      ; re-store registers...
        pop     cx      ;
        pop     bx      ;
        pop     ds      ;
        pop     ax      ;

        ret
clear_screen endp
            


get_time proc near
        push    ax
        push    bx
        push    cx
        push    dx
    
        mov     ah, 00h
        
        int     1Ah     ; time interrupt
        
        mov     [HOUR], cx  ; set HOUR in memory    
                           

                           
        mov     ax, dx  ; total clock ticks per second
                        
        xor     dx, dx
        mov     bx, 12h ; divisor: 18 
        div     bx      ; find second, (total ticks / 18)
        sub     ax, 0Ah ; second lag fixed                   
                           
        xor     dx, dx                    
        mov     bx, 3Ch ; divisor: 60
        div     bx      ; find minute (second / 60)  
        
        mov     [MINUTE], ax  ; set MINUTE in memory
        
        
        
        mov     ax, [HOUR]
        
        xor     dx, dx  ; quick reset dx
        mov     bx, 0Ah ; splits the HOUR
        div     bx      ; HOUR / 10
        
        add     al, '0' ; ascii convertor, current al ascii + 30h ('0')
        
        mov     ah, 0Eh
        int     10h     ; print HOUR[0]
        
        
        mov     ax, dx  ; move remainder (HOUR[0]) to ax
        add     al, '0' ; convertor ascii, current al ascii + 30h ('0')
        
        mov     ah, 0Eh
        int     10h     ; print HOUR[1]
        
        
        mov     al, ':'
        mov     ah, 0Eh
        int     10h
        
        
        mov     ax, [MINUTE]
        
        xor     dx, dx  ; quick reset dx
        mov     bx, 0Ah ; splits the MINUTE
        div     bx      ; MINUTE / 10
        
        add     al, '0' ; ascii convertor, current al ascii + 30h ('0')
        
        mov     ah, 0Eh
        int     10h     ; print MINUTE[0]
                                                          
                                                         
        mov     ax, dx  ; move remainder (MINUTE[1]) to ax
        add     al, '0' ; convertor ascii, current al ascii + 30h ('0') 
             
        mov     ah, 0Eh
        int     10h     ; print MINUTE[1]
        
        pop     dx
        pop     cx
        pop     bx
        pop     ax
                                                           
        ret
get_time endp



tr_get_string   proc    near
        push    ax
        push    cx
        push    di
        push    dx
                
        mov     cx, 0                   ; char counter.
                
        cmp     dx, 1                   ; buffer too small?
        jbe     tr_empty_buffer         ;
                
        dec     dx                      ; reserve space for last zero.                


        tr_wait_for_key:
        
                mov     ah, 0                   ; get pressed key.
                int     16h
                
                cmp     al, 0Dh                 ; 'return' pressed?
                jz      tr_exit
                
                
                call    tr_word_convertor          ; check turkish char 
                
                
                cmp     al, 8                   ; 'backspace' pressed?
                jne     tr_add_to_buffer
                jcxz    tr_wait_for_key         ; nothing to remove!
                dec     cx
                dec     di
                putc    8                       ; backspace.
                putc    ' '                     ; clear position.
                putc    8                       ; backspace again.
                jmp     tr_wait_for_key
                
        tr_add_to_buffer:
        
                cmp     cx, dx          ; buffer is full?
                jae     tr_wait_for_key ; if so wait for 'backspace' or 'return'...
                
                mov     [di], al
                inc     di
                inc     cx
                
                ; print the key:
                mov     ah, 0eh
                int     10h
        
                jmp     tr_wait_for_key
                
        tr_word_convertor:
                cmp al, 0E7h
                je  in_turkish_c 
                
                cmp al, 0F0h
                je  in_turkish_g
                
                cmp al, 0FCh
                je  in_turkish_u
                
                cmp al, 0FEh
                je  in_turkish_s
                
                cmp al, 0F6h
                je  in_turkish_o   
                   
                ret
                
                                
        in_turkish_c:
                mov al, 87h
                
                ret
                
        in_turkish_g:
                mov al, 0A7h
                
                ret
                
        in_turkish_u:
                mov al, 81h
                
                ret      
            
        in_turkish_s:
                mov al, 9Fh
                
                ret 
            
        in_turkish_o:
                mov al, 94h
                
                ret
                                
        tr_exit:
        
                ; terminate by null:
                mov     [di], 0
        
        tr_empty_buffer:
        
                pop     dx
                pop     di
                pop     cx
                pop     ax
                ret
                
tr_get_string endp 



initcap_upper proc near       
        
        mov     dx, tr_cmd_size      ; buffer size.
        lea     di, tr_command_buffer
        
        lea     di, user_input
        call    tr_get_string
        
        
        ; scroll text area 2 lines up:
        mov     al, 2
        call    scroll_t_area
        
        ; set cursor position 2 lines
        ; above prompt line:
        mov     ax, 40h
        mov     es, ax
        mov     al, es:[84h]
        sub     al, 2
        gotoxy  0, al
        
        
        lea     si, initcap_result_msg
        call    print_string
        
                
        lea     si, user_input
        mov     al, [si]
        
        call    word_convertor
            
        mov     ah, 0Eh
        int     10h
        
        inc si

        
        main_loop:
            mov al, [si]
            
            cmp al, 20h     ; is span
            je  span
            
            mov ah, 0Eh
            int 10h
            
            inc si
        
            cmp al, 0       ; is word end
            je  main_loop_end
            
            jmp main_loop
        
        main_loop_end:
            ret
        
        
        init_char:          ; initial word
            mov al, [si]
            
            cmp al, 0       ; is word end
            je  main_loop_end
            
            call word_convertor
            
            mov ah, 0Eh
            int 10h
            
            inc si
            
            jmp main_loop        
        
        
        span:
            mov al,[si]
            
            mov ah, 0Eh
            int 10h
            
            inc si
            
            jmp init_char 
            
            
        word_convertor:
            cmp al, 40h
            jbe special_char
            
            cmp al, 41h
            jae check_upper_char
            
            
            not_special_char:
                cmp al, 87h
                je  turkish_c 
                
                cmp al, 0A7h
                je  turkish_g
                
                cmp al, 81h
                je  turkish_u
                
                cmp al, 9Fh
                je  turkish_s
                
                cmp al, 94h
                je  turkish_o
                   
                call is_ascii   
               
            ret
        
        is_ascii:        
            sub al, 20h
            
            ret
            
        special_char:
            ret
            
            
        check_upper_char:
            cmp al, 5Ah
            jbe upper_char
            
            jmp not_special_char
        
            
        upper_char:
            ret
                       
                       
        turkish_c:
            mov al, 80h
            
            ret 
            
        turkish_g:
            mov al, 0A6h
            
            ret 
            
        turkish_u:
            mov al, 9Ah
            
            ret      
            
        turkish_s:
            mov al, 9Eh
            
            ret 
            
        turkish_o:
            mov al, 99h
            
            ret                                      
initcap_upper endp



draw_star proc near
    
    mov     ah, 0
    mov     al, 13h
    int     10h         ; graphic mode
    
    
    mov     ah, 0Ch
    mov     al, 01
    mov     cx, 100      ; column (x)
    mov     dx, 150      ; row    (y)
    int     10h
               
               
               
    mov     bl, 45      ; lenght
    a1:
    int     10h
    inc     cx          ; column (x)
    sub     dx, 3       ; row    (y)
    dec     bl          
    jnz     a1
    
    
    mov     bl, 45      ; lenght
    a2:
    int     10h
    inc     cx          ; column (x)
    add     dx, 3       ; row    (y)
    dec     bl          
    jnz     a2
    
    
    mov     bl, 100     ; lenght
    a3:
    int     10h
    dec     cx          ; column (x)
    dec     dx          ; row    (y)
    dec     bl          
    jnz     a3     
    
              
    mov     bl, 110     ; lenght
    a4:
    int     10h
    inc     cx          ; column (x)
    dec     bl          
    jnz     a4
    
    
    mov     bl, 100     ; lenght
    a5:
    int     10h
    dec     cx          ; column (x)
    inc     dx          ; row    (y)
    dec     bl          
    jnz     a5

    
    ret    
draw_star endp
