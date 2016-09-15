.globl main
.ent main
main:		

la $a0, Keyring
lw $a1, 8($a0)
addi $sp, $sp, -4
sw   $ra, 0($sp)
jalr $a1
lw   $ra, 0($sp)
addi $sp, $sp, 4

la $a0, Keyring
lw $a1, 16($a0)
addi $sp, $sp, -4
sw   $ra, 0($sp)
jalr $a1
lw   $ra, 0($sp)
addi $sp, $sp, 4

jr $ra

.end main

# Codice oggetto statico "Keyring" :

.data
	    # Stringhe costanti Input/Output:
	    String0: .asciiz "Per poter generare public-key e private-key è necessario inserire 4 numeri PIN \n"
	    String1: .asciiz "Inserisci PIN : "
	    String3: .asciiz "------------------------"
	    String4: .asciiz "\n"
	    String5: .asciiz "Hai creato un nuovo utente...\n"
	    String6: .asciiz "Private-key : "
	    String7: .asciiz "Public-key : "
	    String8: .asciiz " - "
	    String9: .asciiz "Nodo : "
		
	    # Array statici usati da "Random":
	    prime1: .word  61,  67,  71,  73,  79,  83,  89,  97, 101, 103
	    prime2: .word 107, 109, 113, 127, 131, 137, 139, 149, 151, 157
	    prime3: .word 163, 167, 173, 179, 181, 191, 193, 197, 199, 211
	   
            # Array di byte contenente la parola letta in input da criptare.
	    array:  .space 50
	    .align 2

Keyring:    
	    # Attributi:
	    # Entry Point List : 0-3 byte
	    # ID next Node     : 4-7 byte

	    # Funzioni : 
	    # Create-User      : 8-11
	    # Use_User	       : 12-15
	    # Show_List	       : 16-19

	    .space 4			# entry point lista: contiene indirizzo primo nodo.
	    .align 2
	    .space 4			# ID
	    
	    # Metodi:

	    .word Create_User
	    .word Use_User
	    .word Show_List

.text	    # Codice Metodi dell'oggetto

Create_User:
		li $v0, 4
		la $a0, String0
		syscall

		li $v0, 5
		syscall			# read del primo pin
		move $a0, $v0

		li $v0, 5
		syscall			# read del secondo pin
		move $a1, $v0

		li $v0, 5
		syscall			# read del terzo pin
		move $a2, $v0

		li $v0, 5
		syscall			# read del quarto pin
		move $a3, $v0

					# Devo chiamare funzione Random per ottenere il primo numero primo. LOL
					# Input : $a0, $a1, $a2, $a3
					# Output: $v0 = numero random
		addi $sp, $sp, -4
		sw   $ra, 0($sp)
		jal  random
		lw   $ra, 0($sp)
		addi $sp, $sp, 4
		
		move $t0, $v0		# salvo primo numero random
					# richiamo random per generare il secondo numero primo in questa maniera:
					# $a0 = $a0 xor $a1
					# $a1 = $a1 xor $a2
					# $a2 = $a2 xor $a3
					# $a3 = $a3 xor $a0
		xor $a0, $a0, $a1
		xor $a1, $a1, $a2
		xor $a2, $a2, $a3
		xor $a3, $a3, $a0

		addi $sp, $sp, -8
		sw   $t0, 4($sp)
		sw   $ra, 0($sp)
		jal random
		lw   $ra, 0($sp)
		lw   $t0, 4($sp)
		addi $sp, $sp, 8

		move $t1, $v0
					# $t0 = primo numero random
					# $t1 = secondo numero random
		
		addi $sp, $sp, -12      # salvo i due numeri primi nello stack
		sw   $t0, 8($sp)	# prima di chiamare la funzione "epsilon"
		sw   $t1, 4($sp)
		sw   $ra, 0($sp)

		addi $t0, $t0, -1	# p-1
		addi $t1, $t1, -1	# q-1
		mult $t0, $t1
		mflo $a1		# $a1 = (p-1)*(q-1)

		jal  epsilon		# $v0(e) $v1(x)

		lw   $ra, 0($sp)	# recupero valori precedenti
		lw   $t1, 4($sp)
		lw   $t0, 8($sp)
		addi $sp, $sp, 12	

		# Genero n = p*q
		
		mult $t0, $t1
		move $t8, $v0
		mflo $t2				# $t2 = $t0*$t1 = p*q
							# n = $t2
							# e = $t8
							# x = $v1
							# Li devo salvare in un nuovo nodo della lista

		la $t0, Keyring				# carico indirizzo entry point della lista = prima word
		
		while:	lw  $t1, 0($t0)
			bne $t1, $zero, end1		# se il campo "addr_nextNode" NON E' zero => non è l'ultimo nodo
			
			li $v0, 9
			li $a0, 20
			syscall				# sbrk del nuovo nodo

			sw $v0, 0($t0)			# salvo nel campo "addr_nextNode" del penultimo nodo l'indirizzo dell'ultimo nodo
			sw $zero, 0($v0)		# pongo il campo "addr_nextNode" dell'ultimo nodo a zero
							# ora devo salvare i campi del nuovo nodo con n,e,x ed ID

			# ID 4-7   byte
			# n  8-11  byte
			# e  12-15 byte
			# x  16-19 byte

			# ID progressivo del nodo
			# Ultimo valore inserito è salvato come attributo privato dell'oggetto Keyring
			
			la   $t0, Keyring		# uso $t0 tanto non mi servià più
			lw   $t1, 4($t0)		# salvo ID ultimo nodo in $t1 (che non mi serve più)
			addi $t1, $t1, 1		# incremento di 1
							
			sw   $t1, 4($t0)		# lo risalvo in memoria
							# salvo ID,n,e,x nel nodo nuovo

			sw   $t1, 4($v0)	        # ID => nodo	
			sw   $t2, 8($v0)		# n  => nodo
			sw   $t8, 12($v0)		# e  => nodo
			sw   $v1, 16($v0)		# x  => nodo

			j end2				# esco dal ciclo while

		end1:	move $t0, $t1
			j while
		end2:

			# Stampo i valori di ID,n,e,x dell'utente appena creato:
		
			li $v0, 4
			la $a0, String5
			syscall			# "Hai creato un nuovo utente..."

			la $a0, String6		# Private key
			syscall
			
			li $v0, 1
			move $a0, $t2
			syscall			# Print n

			li $v0, 4
			la $a0, String8
			syscall			# " - "
			
			li $v0, 1
			move $a0, $v1
			syscall			# print x


			li $v0, 4
			la $a0,String4
			syscall			# linea a capo			

			la  $a0, String7
			syscall			# "Public-key"

			li $v0, 1
			move $a0, $t2
			syscall			# Print n
	
			li $v0, 4
			la $a0, String8
			syscall			# " - "
			
			li $v0,1
			move $a0, $t8
			syscall			# Print 
	
			li $v0, 4
			la $a0,String4
			syscall			# linea a capo	

			jr $ra

Use_User:

Show_List:
			la $t0, Keyring				# carico indirizzo entry point della lista = prima word
			lw  $t1, 0($t0)
			beq $t1, $zero, end3B			# serve per controllare che l'entry point non sia zero
								# se lo è significa che la lista è vuota quindi esco subito
		while2:		
			li $v0, 4
			la $a0, String9
			syscall					# Nodo : 

			li $v0, 1
			lw $a0, 4($t1)
			syscall					# Print ID

			li $v0, 4
			la $a0, String8
			syscall					# " - "
		
			li $v0, 1
			lw $a0, 8($t1)
			syscall					# Print n

			li $v0, 4
			la $a0, String8
			syscall					# " - "
		
			li $v0, 1
			lw $a0, 12($t1)
			syscall					# Print e

			li $v0, 4
			la $a0, String8
			syscall					# " - "
		
			li $v0, 1
			lw $a0, 16($t1)
			syscall					# Print x

			li $v0, 4
			la $a0,String4
			syscall					# linea a capo	

			lw $t0, 0($t1)				# campo addr nodo successivo
			beq $t0, $zero, end3B			# se è zero dopo non ci sono più nodi
			
			move $t1,$t0
			j while2
		end3B:
			jr $ra

# --------------------------------------------
# Codice funzioni(private) usate dall'oggetto.
 
# =======================================
#####################
#       RANDOM      #
#####################

.globl random
.ent random
# INPUT
# $a0 = x
# $a1 = y
# $a2 = z
# $a3 = w
# RETURN1
# $v0 = numero primo random
random:
addi $sp, $sp, -16	  # alloco spazio stack
sw   $a0,  0($sp)         # salvo variabili x,y,z,w su stack
sw   $a1,  4($sp)
sw   $a2,  8($sp)
sw   $a3, 12($sp)     
addi $sp, $sp, -4
sw   $ra,  0($sp)         # salvo $ra per tornare al main
jal  xorshift             # chiamo la funzione xorshift
lw   $ra , 0($sp)         # ripristino $ra per il main
addi $sp, $sp, 4          # cancello $ra dallo stack
move $v0, $v1		  # $v0 <= return xorshift($v1) = K'
lw   $a0,  0($sp)
lw   $a1,  4($sp)
lw   $a2,  8($sp)
lw   $a3, 12($sp)         # ripristino i valori di x,y,z,w dallo stack
addi $sp, $sp, 16         # libero spazio dello stack

xor $a0, $a0, $v0         # x = x (xor) k'
xor $a1, $a1, $v0         # y = y (xor) k'
xor $a2, $a2, $v0         # z = z (xor) k'
xor $a3, $a3, $v0         # w = w (xor) k'

addi $sp, $sp, -4
sw   $ra,  0($sp)         # salvo $ra per tornare al main
jal xorshift              # chiamo xorshift con nuovi parametri x,y,z,w
                          # return xorshift è in $v1
                          # $v0 = riga | $v1 = colonna
lw   $ra , 0($sp)         # ripristino $ra per il main
addi $sp, $sp, 4          # cancello $ra dallo stack

move $a0, $v1
li   $a1, 10
addi $sp, $sp, -4
sw   $ra,  0($sp)         # salvo $ra per tornare al main
jal  mod                  # chiamo mod per calcolare $v1 mod 10 = colonna
                          # return in $v1
lw   $ra , 0($sp)         # ripristino $ra per il main
addi $sp, $sp, 4          # cancello $ra dallo stack

move $a0, $v0             # preparo parametro per prossima funzione modulo
move $v0, $v1             # salvo il precedente risultato in $v0 che non mi serve
li   $a1, 3

addi $sp, $sp, -4
sw   $ra,  0($sp)         # salvo $ra per tornare al main
jal  mod                  # return secondo modulo in $v1 = riga
                          # return primo   modulo in $v0 = colonna
lw   $ra , 0($sp)         # ripristino $ra per il main
addi $sp, $sp, 4          # cancello $ra dallo stack

# modifico funzione affinchè restituisca direttamente il numero primo
# seleziono prima la riga prime1|prime2|prime3

beq $v1,0,uno
beq $v1,1,due
beq $v1,2,tre

uno:
la  $t0,prime1
j col
due:
la  $t0,prime2
j col
tre:
la  $t0,prime3
col:
# seleziona colonna(numero) : $v0*4 indirizzo del numero primo scelto
sll  $t1, $v0, 2	      # moltiplicazione fatta con shift a sx
add  $t1, $t1, $t0            # sommo all'indirizzo base il suo offset
lw   $t0, 0($t1)	      # salvo numero in $t0

move $v0, $t0		      # $v0 = numero random
jr $ra                        # in $ra deve esserci il return per tornare al main

.end random
# =======================================
#####################
#     XORSHIFT      #
#####################

.globl xorshift
.ent xorshift
# INPUT
# $a0 = x
# $a1 = y
# $a2 = z
# $a3 = w
# RETURN : $v1
# $s0 = t
# $s1 = temp
xorshift:
move $s0, $a0		   # t=x
sll  $s1, $s0, 11          # t<<11
xor  $s0, $s0, $s1         # t = t ^ t<<11
srl  $s1, $s0, 8           # t>>8
xor  $s0, $s0, $s1         # t = t ^ t>>8
move $a0, $a1		   # x = y
move $a1, $a2		   # y = z
move $a2, $a3		   # z = w
srl  $s1, $a3, 19	   # w>>19
xor  $a3, $a3, $s1         # w = w ^ w>>19
xor  $a3, $a3, $s0	   # w = w ^ t
move $v1, $a3		   # return w

jr $ra
.end xorshift
# =======================================
#####################
#       MODULO      #
#####################

.globl mod
.ent mod
#$a0 = val
#$a1 = div
#v1  = val mod (div)
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
mfhi $v1
j endMod
gtz:
    # Greater than zero $a0 > 0
    slt $t0, $a0, $a1              # $t0 = 1 se $a0 < $a1
    beq $t0, $zero, greaterMod     # salto se $t0 = 0 => $a0 >= $a1
    # se arrivo qui è perchè $t0 = 1 => $a0 < $a1
    move $v1, $a0
    j endMod
greaterMod:
    # $a0 >= $a1
    div  $a0, $a1
    mfhi $v1    
    j endMod
zero:
    move $v1,$zero
    j endMod

endMod:
    jr $ra
.end mod

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
beq  $a1, $zero,endMcd
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
endMcd:
# return {lastx, lasty, a} a=mcd
# se lastx è < 0 => sommagli il modulo di b 

bgtz $t1, greaterMcd
#esegui codice qui se è < 0 (*)
lw   $t6, 0($sp)        # ricarico "b" originale in t6   
add  $t1, $t1, $t6      # lastx = lastx + b
greaterMcd:
addi $sp, $sp, 4	# stack lo aggiorno qui altrimenti mi da problemi quando non esegio (*)
addi $v0, $a0,0		# move $v0,$a0  mcd
addi $v1, $t1,0		# move $v1,$t1  lastx
jr $ra
.end mcd

