     name "loader"
; this is a very basic example of a tiny operating system.

; directive to create boot file:
   #make_boot#

; this is an os loader only!
;
; it can be loaded at the first sector of a floppy disk:

;   cylinder: 0
;   sector: 1
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


;
; The code in this file is supposed to load
; the kernel (micro-os_kernel.asm) and to pass control over it.
; The kernel code should be on floppy at:

;   cylinder: 0
;   sector: 2
;   head: 0

; memory table (hex):
; -------------------------------
; 07c0:0000 |   boot sector
; 07c0:01ff |   (512 bytes)
; -------------------------------
; 07c0:0200 |    stack
; 07c0:03ff |   (255 words)
; -------------------------------
; 0800:0000 |    kernel
; 0800:1400 | 
;           |   (currently 5 kb,
;           |    10 sectors are
;           |    loaded from
;           |    floppy)
; -------------------------------


; To test this program in real envirinment write it to floppy
; disk using compiled writebin.asm
; After sucessfully compilation of both files,
; type this from command prompt:   writebin loader.bin   

; Note: floppy disk boot record will be overwritten.
;       the floppy will not be useable under windows/dos until
;       you reformat it, data on floppy disk may be lost.
;       use empty floppy disks only.


; micro-os_loader.asm file produced by this code should be less or
; equal to 512 bytes, since this is the size of the boot sector.



; boot record is loaded at 0000:7c00
org 7c00h

; initialize the stack:
mov     ax, 07c0h
mov     ss, ax
mov     sp, 03feh ; top of the stack.


; set data segment:
xor     ax, ax
mov     ds, ax

; set default video mode 80x25:
mov     ah, 00h
mov     al, 03h
int     10h

; print welcome message:
lea     si, msg
call    print_string

;===================================
; load the kernel at 0800h:0000h
; 10 sectors starting at:
;   cylinder: 0
;   sector: 2
;   head: 0

; BIOS passes drive number in dl,
; so it's not changed:

mov     ah, 02h ; read function.
mov     al, 10  ; sectors to read.
mov     ch, 0   ; cylinder.
mov     cl, 2   ; sector.
mov     dh, 0   ; head.
; dl not changed! - drive number.

; es:bx points to receiving
;  data buffer:
mov     bx, 0800h   
mov     es, bx
mov     bx, 0

; read!
int     13h
;===================================

; integrity check:
cmp     es:[0000],0E9h  ; first byte of kernel must be 0E9 (jmp).
je     integrity_check_ok

; integrity check error
lea     si, err
call    print_string

;call    draw_star

; wait for any key...
mov     ah, 0
int     16h

; store magic value at 0040h:0072h:
;   0000h - cold boot.
;   1234h - warm boot.
mov     ax, 0040h
mov     ds, ax
mov     w.[0072h], 0000h ; cold boot.
jmp	0ffffh:0000h	     ; reboot!

;===================================

integrity_check_ok:

call    draw_star

; pass control to kernel:
jmp     0800h:0000h

;===========================================



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
                       
                       
                              
;==== data section =====================

msg  db "Y", 81h, "kleniyor..." ,0Dh,0Ah, 0 
     
err  db "Sekt",94h,"r 2'de ge",87h,"ersiz veri,"," silindir: 0,"," ba",9Fh," : 0"," - b",81h,"t",81h,"nl",81h,"k kontrol",81h," ba",9Fh,"ar",8Dh,"s",8Dh,"z oldu.", 0Dh, 0Ah
     db "Sistem yeniden ba",9Fh,"lat",8Dh,"lacak."," Herhangi bir tu",9Fh,"a bas",8Dh,"n",8Dh,"z...", 0
         
;======================================

