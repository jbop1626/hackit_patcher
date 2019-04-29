; HackIt Patcher, v1.0
; For SKSA versions 1095 and 1106
;
; Copyright (c) 2019 Jbop (https://github.com/jbop1626)
; Licensed under the MIT License:
; https://github.com/jbop1626/hackit_patcher/blob/master/LICENSE.md
;
; This first patches skGetId to jump to a location in skVerifyHash.
; This location is at the start of a code cave that will be
; created by patching skVerifyHash to immediately return 0.
;
; When SA calls skGetId during its boot-up, which it does several
; times, it will trigger the jump. The code cave will contain the
; instructions starting at the "patch_code" label below. This code
; reaches back into SA and patches it, so that:
;    1. It checks what SKSA version is running
;    2. SA is made to read tickets from "hackit.sys" (instead of ticket.sys)
;    3. Signature verification is disabled
;
; In addition, SK is patched to disable all signature verification,
; hash checks, and console ID checks.
;
; This same idea can be used for any other patches you might want
; to apply to SA, as long as the code needed to do it fits in the
; code cave in skVerifyHash (and/or in other caves you create).


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
  
  ; Disable the ticket BBID check
  li $t1, 0x9FC00C10   ; BBID check in sub_9FC00BAC
  li $t0, 0x00000000   ; "nop"
  sw $t0, 0($t1)
  
  ; Disable the content hash check
  li $t1, 0x9FC01620   ; memcmp in skRecryptEnd
  li $t0, 0x00001021   ; "move $v0, $zero"
  sw $t0, 0($t1)       ; patch the call to memcmp to essentially "return 0"
  
  ; Disable the hash check in skLaunch
  li $t1, 0x9FC00FF0   ; memcmp
  li $t0, 0x00001021   ; "move $v0, $zero"
  sw $t0, 0($t1)
  
  ; Patch a separate call to the RSA signature verification function in SK
  li $t1, 0x9FC033E8   ; memcmp in sub_9FC03388
  li $t0, 0x00001021   ; "move $v0, $zero"
  sw $t0, 0($t1)       

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
  ; Load constants into registers
  lui $t7, 0x7469      ; "ti"
  ori $t7, $t7, 0x636B ; "ck"
  lui $t6, 0x6861      ; "ha"
  ori $t6, $t6, 0x636B ; "ck"
  lui $t5, 0x6974      ; "it"
  ori $t5, $t5, 0x2E73 ; ".s"
  
  ; Determine what SKSA version we're on by checking for
  ; the (start of the) "ticket.sys" string 
  lui $t0, 0x804E          ; address of the first occurrence
  ori $t0, $t0, 0x94BC     ;    of the string in 1106
  lw $t1, 0($t0)           ; If it matches, set 1106 addresses,
  beq $t1, $t7, sksa_1106  ;    otherwise continue to check for 1101
  nop 
  
  lui $t0, 0x804E          ; address of the first occurrence
  ori $t0, $t0, 0x98BC     ;    of the string in 1101
  lw $t1, 0($t0)           ; If it matches, set 1101 addresses,
  beq $t1, $t7, sksa_1101  ;    otherwise continue to check for 1095
  nop 
  
  lui $t0, 0x804E          ; address of the first occurrence
  ori $t0, $t0, 0xB54C     ;    of the string in 1095
  lw $t1, 0($t0)           ; If it matches, set 1095 addresses,
  bne $t1, $t7, jump_back  ;    otherwise jump to end and do nothing
  nop 
  
  ; Set addresses
  ; t6 = address of 1st occurrence of "ticket.sys"
  ; t7 = address of 2nd occurrence of "ticket.sys"
  ; t1 = location of memcmp just after sig check
sksa_1095:
  lui $t4, 0x804E      
  ori $t4, $t4, 0xB54C 
  lui $t3, 0x804E      
  ori $t3, $t3, 0xBB6C 
  lui $t2, 0x8043        
  ori $t2, $t2, 0x1ECC
  beq $zero, $zero, patch_sa
  nop
  
sksa_1101:
  lui $t4, 0x804E      
  ori $t4, $t4, 0x98BC 
  lui $t3, 0x804E      
  ori $t3, $t3, 0x9EDC 
  lui $t2, 0x8043        
  ori $t2, $t2, 0x241C
  beq $zero, $zero, patch_sa
  nop
  
sksa_1106:
  lui $t4, 0x804E      
  ori $t4, $t4, 0x94BC 
  lui $t3, 0x804E      
  ori $t3, $t3, 0x9ADC 
  lui $t2, 0x8043        
  ori $t2, $t2, 0x241C

patch_sa:  
  ; Change both occurrences of "ticket.sys" to "hackit.sys"
  sw $t6, 0($t4)       ; patch first occurrence
  sw $t5, 4($t4)       ; "
  sw $t6, 0($t3)       ; patch second
  sw $t5, 4($t3)       ; "
  
  ; SA2 has code to verify ticket signatures itself, without calling
  ; skVerifyHash, so patch it out.
  addiu $t1, $zero, 0x1021 ; "move $v0, $zero" (i.e. 0x00001021)
  sw $t1, 0($t2)           

  ; Jump back
  ; Return 1 (success) because we hijacked a function call in skGetId to reach
  ; this code cave, and skGetId still checks the return value.
jump_back:
  addu $v0, $zero, $zero
  addiu $v0, $v0, 1
  jr $ra
  nop
end_code:



.org 0x807C7FFC
  .word 0
.close

