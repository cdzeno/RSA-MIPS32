# p=199
# q=211
# n=41989
# epsilon = 13
# inverso(x) = 6397
# (n,e) = chiave pubblica
# (n,x) = chiave privata 
.data
StringInsert: .asciiz "Inserisci una parola : "
StringReply:  .asciiz "Hai inserito la parola : "
StringEscape: .asciiz "\n"
StringSpace:  .asciiz " - "
.align 2
StringInput:  .space 50
# stringecrypt = (stringinput-1)*4 byte
.align 2
StringEcrypt: .space 196
.align 2

.text


.globl main
.ent main
# 1.Lettura in input di una stringa
# 2.Encrypt della strina
# 3.Decrypt e relativa stampa a video della stringa di partenza
main:
li $v0, 4
la $a0, StringInsert
syscall

# Read string
li $v0, 8
la $a0, StringInput
li $a1, 49
syscall
li $v0, 4
#Print string
la $a0, StringEscape
syscall
la $a0, StringReply
syscall
la $a0, StringInput
syscall
la $a0, StringEscape
syscall
# Ecrypt della frase:
# $t0 : base address Array stringa in chiaro = pointer
# $t1 : index della stringa
# $t2 : BASE POINTER StringEcrypt
# $t3 : INDEX StringEcrypt
# $a0 : base = carattere da criptare
# $a1 : eponent = e = fisso
# $a2 : m = n = fisso
la $t0, StringInput
li $t1, 0
la $t2, StringEcrypt
li $t3, 0
# li $a1, 13 => lo sposto nel while perchè così dopo aver decriptato posso criptare nel ciclo
li $a2, 41989

# while(carattere letto!=null)
startWhile:
li   $a1, 13
add  $t0, $t0, $t1   # pointer = pointer+index
lb   $a0, 0($t0)     # carico carattere da criptare
sub  $t0, $t0, $t1   # riporto il base pointer al suo valore originale!!
beq  $a0, $zero, endCrypt
# cripta
addi $sp, $sp, -32
sw   $t0, 28($sp)
sw   $t1, 24($sp)
sw   $t2, 20($sp)
sw   $t3, 16($sp)
sw   $a0, 12($sp)
sw   $a1,  8($sp)
sw   $a2,  4($sp)
sw   $ra,  0($sp)
jal  mod_exponent
lw   $ra,  0($sp)
lw   $a2,  4($sp)
lw   $a1,  8($sp)
lw   $a0, 12($sp)
lw   $t3, 16($sp)
lw   $t2, 20($sp)
lw   $t1, 24($sp)
lw   $t0, 28($sp)
addi $sp, $sp, 32
# metto nell'array StringEcrypt il carattere cryptato
# add  $t2, $t2, $t3
# sw   $v0, 0($t2)
# sub  $t2, $t2, $t3   
# aggiorno index delle due stringhe
addi $t1, $t1, 1
#addi $t3, $t3, 4
   
# $v0 è il carattere criptato => stampo 
move $a0, $v0
move $v1, $v0   # lo copio anche qui perchè mi serve per il decript
li   $v0, 1
syscall
# stampo "-"
li   $v0, 4
la   $a0, StringSpace
syscall
# decripto il carattere appena criptato : inserire chiave privata => n,x
# devo mettere x al posto di epsilon in $a1
li $a1, 6397
# chiamo mod_exponent con nuovi parametri
move $a0, $v1 #carico il carattere criptato che avevo salvato prima
# $a2 non viene mai modificato
# DECRYPT:
addi $sp, $sp, -32
sw   $t0, 28($sp)
sw   $t1, 24($sp)
sw   $t2, 20($sp)
sw   $t3, 16($sp)
sw   $a0, 12($sp)
sw   $a1,  8($sp)
sw   $a2,  4($sp)
sw   $ra,  0($sp)
jal  mod_exponent
lw   $ra,  0($sp)
lw   $a2,  4($sp)
lw   $a1,  8($sp)
lw   $a0, 12($sp)
lw   $t3, 16($sp)
lw   $t2, 20($sp)
lw   $t1, 24($sp)
lw   $t0, 28($sp)
addi $sp, $sp, 32
# $v0 = codice ASCII char decryptato
# stampo carattere
move $a0,$v0
li $v0, 11
syscall
li $v0, 4
la $a0, StringEscape
syscall
j    startWhile
endCrypt:
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
