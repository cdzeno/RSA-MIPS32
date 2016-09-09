.data


.text

.globl main
.ent main

main:
#carica input
li $a0, 255
li $a1, 798
li $a2, 45612

#chiamata "mod_exponent"
addi $sp, $sp, -16
sw   $a0, 12($sp)
sw   $a1, 8($sp)
sw   $a2, 4($sp)
sw   $ra, 0($sp)
jal  mod_exponent
# $v0 = ($a0^$a1) mod $a2
lw   $ra, 0($sp)
lw   $a2, 4($sp)
lw   $a1, 8($sp)
lw   $a0, 12($sp)
addi $sp, $sp, -16 
# sposto risultato in $t8
move $t8, $v0
#stampa risultato
jr $ra

.end main

# =======================================
#####################
#    MOD_EXPONENT   #
#####################
# c=(b^e)mod m
# INPUT: b($a0), e($a1), m($a2)
# OUTPUT: c($v0)
# variabile locale : y ($t0)
.globl mod_exponent
.ent mod_exponent

mod_exponent:
#PROLOGO
addi $sp, $sp, -4
sw $fp, 0($sp)
move $fp, $sp
#RECUPERO PARAMETRI **
lw $a2, 8($fp)
lw $a1, 12($fp)
lw $a0, 16($fp)
#ALGORITMO **
beq $a1, $zero, end1
# else if n%2==0
# n%2 :
addi $sp, $sp, -16
sw   $a0, 12($sp)
sw   $a1, 8($sp)
sw   $a2, 4($sp)
sw   $ra, 0($sp)
# mod:
#$a0 = val
#$a1 = div
#v0  = val mod (div)
move $a0, $a1
li   $a1, 2
jal  mod
#$v0 = n%2
lw   $ra, 0($sp) 
lw   $a2, 4($sp)
lw   $a1, 8($sp)
lw   $a0, 12($sp)
addi $sp, $sp, 16
# **
beq $v0, $zero, even
# odd:
# return {(b%m)*mod_exponent(b,e-1,m)}%m 
# $t0 = b%m
# $t1 = mod_exponent(b,e-1,m)
# $t2 = {(b%m)*mod_exponent(b,e-1,m)}%m 

addi $sp, $sp, -16
sw   $a0, 12($sp)
sw   $a1, 8($sp)
sw   $a2, 4($sp)
sw   $ra, 0($sp)
# b in a0 ok
# m in a1 
move $a1, $a2
jal  mod
#$v0 = b%m
lw   $ra, 0($sp) 
lw   $a2, 4($sp)
lw   $a1, 8($sp)
lw   $a0, 12($sp)
addi $sp, $sp, 16
move $t0, $v0		# sposto $v0 perchè devo chiamare mod_exponent
addi $a1, $a1, -1       # e = e-1
addi $sp, $sp, -20
sw   $t0, 16($sp)
sw   $a0, 12($sp)
sw   $a1, 8($sp)
sw   $a2, 4($sp)
sw   $ra, 0($sp)
jal  mod_exponent
# $v0 = mod_exponent(b,e-1,m)
lw   $ra, 0($sp) 	# FORSE DOVREI FARE $fp per recuperare parametri
lw   $a2, 4($sp)
lw   $a1, 8($sp)
lw   $a0, 12($sp)
lw   $t0, 16($sp)
addi $sp, $sp, 20
move $t1, $v0            # $t1 = mod_exponent(b,e-1,m)
mult $t0, $t1		 # (b%m)*mod_exponent(b,e-1,m)
mflo $a0		 # $a0 = (b%m)*mod_exponent(b,e-1,m)
move $a1, $a2		 # carico $a0 e $a1 per chiamare mod => non devo salvare niente tranne $ra
addi $sp, $sp, -4
sw   $ra, 0($sp)
jal  mod
# $v0 = {(b%m)*mod_exponent(b,e-1,m)}%m
lw   $ra, 0($sp)
addi $sp, $sp, 4
# a questo punto $sp punta a fp di mod_expont superiore che è caricato nello stack.
# devo restaurare $fp della funzione chiamante prima di saltare ad essa. !!
lw   $fp, 0($sp) # $fp contiene il valore del frame pointer della funzione chiamante
addi $sp, $sp, 4
jr   $ra

even:
# y=mod_exponent(b,e/2,m)
srl  $a1, $a1, 1 # divisione per 2 => e= e/2 $a1
addi $sp, $sp, -16
sw   $a0, 12($sp)
sw   $a1, 8($sp)
sw   $a2, 4($sp)
sw   $ra, 0($sp)	# $ra = mod_exp verso main/mod_exp superiore
jal  mod_exponent
lw   $ra, 0($sp) 
lw   $a2, 4($sp)
lw   $a1, 8($sp)
lw   $a0, 12($sp)
addi $sp, $sp, 16
# ATTENZIONE : ora $sp punta a 
# y=$v0
mult $v0, $v0
mflo $v0	# $v0 = $v0*$v0
# return (y*y)%m
addi $sp, $sp, -16
sw   $a0, 12($sp)
sw   $a1, 8($sp)
sw   $a2, 4($sp)
sw   $ra, 0($sp)
move $a0, $v0      # parametri mod function
move $a1, $a2
jal  mod
# $v0 = (y*y)%m
lw   $ra, 0($sp) 
lw   $a2, 4($sp)
lw   $a1, 8($sp)
lw   $a0, 12($sp)
addi $sp, $sp, 16
# ATTENZIONE : ora $sp punta a $fp di mod_exponent superiore e prima di saltare ad esso deve essere restaurato !!
lw   $fp, 0($sp)
addi $sp, $sp, 4
jr $ra   	# return

end1:
#return 1
lw   $fp, 0($sp)
addi $sp, $sp, 4
li   $v0, 1
jr   $ra	# return

.end mod_exponent

# =======================================
#####################
#       MODULO      #
#####################

.globl mod
.ent mod
#$a0 = val
#$a1 = div
#v0  = val mod (div)
mod:
  
beq  $a0, $zero, zero
bgtz $a0, gtz
# Se sono qui $a0 < 0
li   $s0, -1           # $s0 = 111111111
xor  $a0, $a0, $s0     # xor mi produce una not 
addi $a0, $a0, 1       # complemento a due
div  $a0, $a1
mfhi $s0
addi $s1, $a1, -1
mult  $s1, $s0
mflo $s0
div  $s0, $a1
mfhi $v0
j end
gtz:
    # Greater than zero $a0 > 0
    slt $t0, $a0, $a1              # $t0 = 1 se $a0 < $a1
    beq $t0, $zero, greater        # salto se $t0 = 0 => $a0 >= $a1
    # se arrivo qui è perchè $t0 = 1 => $a0 < $a1
    move $v0, $a0
    j end
greater:
    # $a0 >= $a1
    div  $a0, $a1
    mfhi $v0    
    j end
zero:
    move $v0,$zero
    j end

end:
    jr $ra
.end mod
