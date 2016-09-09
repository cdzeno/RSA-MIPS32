.data

string1: .asciiz "Il numero Epsilon e' : "
string2: .asciiz "Il suo inverso e' : "
newline: .asciiz "\n"

.text
main:
.globl main
.ent main

li   $t0, 33811			# p
addi $t0, $t0, -1		# p-1
li   $t1, 26251			# q
addi $t1, $t1, -1		# q-1
mult $t0, $t1
mflo $a1			# (p-1)*(q-1)

addi $sp, $sp, -4
sw   $ra, 0($sp)
jal  epsilon
lw   $ra, 0($sp)
addi $sp, $sp, 4

# $v0(e) $v1(x)
# li stampo
move $t8, $v0

li $v0,4
la $a0, string1
syscall

li $v0,1
move $a0,$t8
syscall

li $v0,4
la $a0, newline
syscall

li $v0,4
la $a0, string2
syscall
 
li $v0,1
move $a0,$v1
syscall


jr $ra
.end main

# =======================================
#####################
#       EPSILON     #
#####################

# INPUT : $a1 = (p-1)*(q-1)
# OUTPUT: $v0(e) $v1(x)  epsilon e x=inverso di e

.globl epsilon
.ent epsilon
epsilon:

li   $t0, 2              # i=2
			 # $a1 = max = (p-1)*(q-1) 
li   $t2, 1		 # $t2 = costante "1" = mi serve nel ciclo
# for (i=2; i<max; i++)
for:
slt  $t1, $t0, $a1	 # $t1 = 1 se $t0<$a1
beq  $t1, $zero, fine	 # se è 0 => $t0>=$a1 => fine
# i<max
# eseguo mcd
move $a0, $t0		 # carico "i" per chiamare mcd(i,max)

# salvo tutti i registri che andrà ad usare MCD nello stack !!
# $a0,$a1, $t0,$t1,$t2,$t3,$t4,$t5,$t6,$ra

addi $sp, $sp, -40
sw   $a0, 0($sp)
sw   $a1, 4($sp)
sw   $t0, 8($sp)
sw   $t1, 12($sp)
sw   $t2, 16($sp)
sw   $t3, 20($sp)
sw   $t4, 24($sp)
sw   $t5, 28($sp)
sw   $t6, 32($sp)
sw   $ra, 36($sp)
jal  mcd		 # chiamo mcd
lw   $a0, 0($sp)
lw   $a1, 4($sp)
lw   $t0, 8($sp)
lw   $t1, 12($sp)
lw   $t2, 16($sp)
lw   $t3, 20($sp)
lw   $t4, 24($sp)
lw   $t5, 28($sp)
lw   $t6, 32($sp)
lw   $ra, 36($sp)
addi $sp, $sp, 40
# se mcd=1 => $v0=1 (return di "mcd") 
beq  $v0, $t2, found
# else
addi $t0, $t0, 1
j for

found:
# ho trovato (e=$t0="i") e (x=$v1) 
move  $v0, $t0
fine:
jr $ra

.end epsilon
# =======================================
#####################
#        MCD        #
#####################

.globl mcd
.ent mcd
# INPUT  : $a0(a), $a1(b)
# OUTPUT : $v0(m), $v1(x)
# Temp reg : $t0,$t1,$t2,$t3,$t4,$t5,$t6
# $t0 = x
# $t1 = lastx
# $t2 = y
# $t3 = lasty
# $t4 = temp
# $t5 = quotient
# $t6 = temporaneo per conti parziali
# m=mcd(a,b)
# a*x+b*y = m
# mcd(e,(p-1)(q-1))=1
# x*e+y(p-1)(q-1)=1
# x*e = -y(p-1)(q-1)+1
# x*e~1 mod(p-1)(q-1)
# NB: y non viene restituito poiche' devo solo trovare
#     inverso di "e"   
# NB: se x<0 => x'=x+b | prova : a*x'mod b=m
mcd:
addi $t0, $zero,0       # x = 0;
addi $t1, $zero,1	# lastx = 1;
addi $t2, $zero,1	# y = 1;
addi $t3, $zero,0	# lasty = 0;
addi $sp, $sp, -4
sw   $a1, 0($sp)	# salvo il valore di "b" nello stack per (*)

loop:
beq  $a1, $zero,end
#while(b!=0)
addi $t4, $a1,0         # temp = b;
div  $a0, $a1		# a div b;
mflo $t5  		# quotient = a div b;
mfhi $a1		# b = a mod b;
addi $a0, $t4,0		# a = temp;
addi $t4, $t0,0		# temp = x;
mult $t5, $t0 		# quotient*x;
mflo $t6
sub  $t0, $t1, $t6	# lastx-quotient*x;
addi $t1, $t4,0		# lastx = temp;
addi $t4, $t2,0		# temp = y;
mult $t5, $t2		# quotient*y;
mflo $t6
sub  $t2, $t3, $t6	# y = lasty-quotient*y;
addi $t3, $t4,0		# lasty = temp;
j loop
end:
# return {lastx, lasty, a} a=mcd
# se lastx è < 0 => sommagli il modulo di b 

bgtz $t1, greater
#esegui codice qui se è < 0 (*)
lw   $t6, 0($sp)        # ricarico "b" originale in t6   
add  $t1, $t1, $t6      # lastx = lastx + b
greater:
addi $sp, $sp, 4	# stack lo aggiorno qui altrimenti mi da problemi quando non esegio (*)
addi $v0, $a0,0		# move $v0,$a0  mcd
addi $v1, $t1,0		# move $v1,$t1  lastx
jr $ra
.end mcd
