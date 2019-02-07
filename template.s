; Template: Patch SA through SK call (skGetId)
;
; Copyright (c) 2019 Jbop (https://github.com/jbop1626)
; Licensed under the MIT License:
; https://github.com/jbop1626/hackit_patcher/blob/master/LICENSE.md

.n64
.open "005d1870.sta",0x807C0000

start:
  li $v0, 0xF82ED0AE   ; Call fake SKC 0xF82ED0AE, which causes a jump within
                       ; secure mode to the address stored at 0x807C0068 (this
                       ; is the earliest address available).
                       ; See the eSKape template for more info.
  li $t0, 0xA4300014
  lw      $t1, 0($t0)  ; Trigger SK exception handler
  nop
  beq $zero, $zero, usermode_code
  nop
  
  

.org 0x807C0068

  .word 0x807C006C

  ; Patch skGetId
  li $t1, 0x9FC00D98   ; first jal in skGetId (a pointer bounds check)
  li $t0, 0x0FF005C7   ; "jal 0x9FC0171C"
  sw $t0, 0($t1)       ; patch instruction with the above jump, which causes
                       ;     skGetId to jump to the code cave soon to be created in skVerifyHash     
  
  ; Patch out the skVerifyHash signature check, creating code cave
  li $t1, 0x9FC01710   ; location right after function prologue in skVerifyHash
  li $t0, 0x0BF0063D   ; "j 0x9FC018F4"
  sw $t0, 0($t1)       ; patch instruction with the above jump, which causes
                       ;     skVerifyHash to immediately return 0 (success)
                       
  ; Copy code from patch_code (below) to the new code cave in skVerifyHash:
  li $t5, 0x9FC0171C
  la $t6, patch_code
  la $t7, end_code
code_cave_copy_loop:
  lw $t0, 0($t6)
  sw $t0, 0($t5)
  addiu $t5, $t5, 4
  addiu $t6, $t6, 4
  blt $t6, $t7, code_cave_copy_loop
  nop
  
  ; --- YOUR CODE HERE ---   
  ; Any other code to patch SK, which will persist across soft resets.  

  ; Leave secure mode
  jr $ra               ; jump back to SKC handler
  nop

usermode_code:
infinite_loop:
  beq $zero, $zero, infinite_loop
  nop

  
  
; CODE BELOW IS COPIED INTO MEMORY, NOT RUN
.org 0x807C3E00
patch_code:
  
  ; --- YOUR CODE HERE ---   
  ; Code to patch SA, which will occur every time SA calls skGetId.  
  ; Must fit into 114 (real) instructions; if using pseudoinstructions,
  ; ensure that the assembled output does not exceed this limit.
  ;
  ; Also make sure to stay compatible with the ABI; for example, don't
  ; use saved registers like s0, s1, etc. without first pushing them
  ; onto the stack (and then pop them before returning).

  ; Jump back
  ; Return 1 (success) because we hijacked a function call in skGetId to reach
  ; this code cave, and skGetId still checks the return value.
  addu $v0, $zero, $zero
  addiu $v0, $v0, 1
  jr $ra
  nop
end_code:



.org 0x807C7FFC
  .word 0
.close

