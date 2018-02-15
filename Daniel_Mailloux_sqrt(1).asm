.data
pairs:		.space 400
answer:		.space 400
prompt:		.asciiz "Enter a floating-point number: "
answer_prompt:	.asciiz "The square root of "
is_str:		.asciiz " is "
dec_str:	.asciiz "."
.text
add $v0, $zero, 4
la $a0, prompt
syscall
addi $a1, $zero, 20
addi $v0, $zero, 8
syscall
addi $s1, $a0, 0	#saves user's string into $s1

addi $v0, $zero, 4
la $a0, answer_prompt
syscall
addi $a0, $s1, 0
syscall


jal _findDecimal
addi $s2, $v0, 0	#$s2 contains spot of decimal
jal _strLength
addi $s3, $v1, 0	#$s3 contains string length
bne $s2, $s3, hasDecimal
addi $s7, $zero, 1	#if $s7=1, there is no decimal
addi $s2, $s2, 1	#this is for numbers without a decimal
hasDecimal:
la $a0, pairs		#loads pairs array into $a0
jal _convertNum		#$v0=left side of decimal $v1=right side of decimal
addi $s4, $v0, 0	#s4=left side
addi $s5, $v1, 0	#s5=right side
addi $a3, $zero, 0	#counts number of pairs
addi $s6, $s2, -1	#gets number of digits on left
andi $t0, $s6, 1	#is first half an odd amount?
beq $t0, 1, odd
bnez $s6, skipOdd	#keep going if only 1 digit
beq $s4, 0, pairRight	#if right side has no digits
sw $s4, 0($a0)
addi $a3, $a3, 1	#number of pairs++
addi $a0, $a0, 4
j pairRight
odd:	#get greatest digit
	addi $s6, $s6, -1	#$s6=number of digits-1 (makes it even)
	addi $t1, $zero, 10	#t1=10
	addi $t3, $zero, 10
	addi $t2, $s6, -1	#get number of digits-2 of first half
	slti $t4, $t2, 0
	beq $t4, 0, power	#if only one digit, add it and skip
	sw $s4, 0($a0)
	addi $a3, $a3, 1	#number of pairs++
	j pairRight
	power:	#multiple 10 by number of digits-2
		beqz $t2, endPower	#if $t2=0
		addi $t2, $t2, -1	#$t2--
		multu $t1, $t3 	#t1x10
		mflo $t1
		j power
	endPower:
	divu $s4, $t1	#divide left side by $t1 to get greatest digit
	addi $t7, $t7, 1
	mflo $t1
	sw  $t1,0($a0)	#stores first digit into array
	addi $a3, $a3, 1	#number of pairs++
	addi $a0, $a0, 4	#index++
skipOdd:
addi $t0, $zero, 2
divu $s6, $t0
mflo $t2	
addi $t2, $t2, -1	#$t2=number of indexes going to be used
addi $t4, $zero, 4
multu $t2, $t4	#t2x4
mflo $t2	#t2=t2x4
add $a0, $a0, $t2	#$a0=$a0+$t2
addi $t0, $zero, 100
add $a1, $a0, $zero
pairLeft:
	divu $s4, $t0	#divide left side by 100 to get next 2 numbers
	mfhi $t1	#get remainder
	mflo $s4
	sw $t1, 0($a1)	#store remainder in array
	addi $a3, $a3, 1	#number of pairs++
	addi $a1, $a1, -4	#index++
	
	slti $t3, $s4, 10	#if quotient is less than 10, you are done
	beq $t3, 1, pairRight
	
	j pairLeft
pairRight:
beq $s7, 1, doneRight	#if no decimal, skip right
subu $t0, $s3, $s2	#t0(number of digit on right)=strlength-decimalposition
seq $t7, $t0, 1		#SPECIAL CASE: if only 1 digit on left skip second part
andi $t1, $t0, 1	#if $t1=1, its odd
add $t2, $zero, $s5	#t2=s5
beq $t1, 0, exitOR
oddRight:
	addi $t2, $zero, 10
	divu $s5, $t2	#divide right side by 10 to get smallest digit
	mfhi $t3	#t2=smallest digit
	mflo $t2	#t2= rest of number
	addi $t0, $t0, 1	#add 1 to number of digits on right
exitOR:
bne $s2, 1, hasRight	#dont adjust array pointer if no right side
addi $t0, $t0, -1
hasRight:
addi $t4, $zero, 2
divu $t0, $t4	#number of digits/2
mflo $t4
addi $t5, $zero, 4	
multu $t4, $t5	#$t4x4
mflo $t6
add $a0, $a0, $t6	#points array to the correct amount of slots needed to fit right side
beq $t1, 0 ,skipOR
#only do this if there is odd number of digits
beqz $t7, moreThan1Digit
#only does this if there is only 1 digit on right
moreThan1Digit:
addi $s6, $zero, 10	#just a place holder for 10
multu $t3, $s6
mflo $t3	#multiples the smallest digit by 10 if its the only digit

sw $t3, 0($a0)	#stores smallest number
addi $a3, $a3, 1	#number of pairs++
addi $a0, $a0, -4	#index--
beq $t7, 1, doneRight
skipOR:
rightLoop:
	addi $t1, $zero, 100
	divu $t2, $t1	#divides number/100
	mflo $t2	#t2=new number
	mfhi $t1	#t1=remainder
	sw $t1, 0($a0)	#$stores $t1 in array
	addi $a3, $a3, 1	#number of pairs++
	addi $a0, $a0, -4
	beqz $t2, doneRight
	j rightLoop
doneRight:
jal _math
j exit

#-------------------------------Functions-------------------------------#
#$v0 = result
_math:
	addi $s0, $zero, 0	#counter
	addi $v0, $zero, 0
	la $s1, pairs		#array
	addi $s3, $zero, 0	#$s3=reference
	addi $s4, $zero, 0	#$s4=remainder
	addi $sp, $sp, -24
	addi $s0, $zero, 0	#counter
	addi $s6, $zero, 0	#counts number of digits in answer
	sw $s2, 4($sp)		#decimal spot
	sw $a3, 20($sp)		#number of pairs
	addi $t0, $s1, 0	#loads array into $t0
	la $a1, answer		#loads answer array into $a1
	mathLoop:
		lb $t1, 0($t0)		#loads first pair (n)
		addi $t2, $zero, 100	#t2=100
		addi $t5, $zero, 2
		multu $s4, $t2
		mfhi $t4
		bnez $t4, tooBig	#branch if over 32 bits
		mflo $t3		#$t3=remainderx100
		add $s4, $t3, $t1	#remainder = (remainder x 100) + n
		
		bnez $s4, keepGoing	#if remainder is 0, done.
		beq $a3, 0, tooBig	#if you have gone through all the pairs and the remainder is 0
		keepGoing:
		multu $v0, $t5
		mflo $s3	#ref = 2 x result
		addi $t6, $zero, 1	#$t6 = x
		addi $t7, $zero, 0	#$t7 = y
		maxXLoop:
			addi $t4, $zero, 10
			multu $t4, $s3		#reference x 10
			mflo $t4	#$t4=reference x 10
			add $t4, $t4, $t6	#(refernce x 10) + x
			multu $t4, $t6		#((refernce x 10) + X) x X
			mflo $t7	#y = ((refernce x 10) + X) x X
			mfhi $t4
			bnez $t4, tooBig	#branch if over 32 bits
			sgtu $t4, $t7, $s4	#if y is bigger than remainder
			beq $t4, 1, exitMaxLoop
			addi $t6, $t6, 1	#x++
			j maxXLoop
		exitMaxLoop:
		addi $a3, $a3, -1	#number of pairs--
		addi $t6, $t6, -1	#x = x - 1 (to make up for going to high)
		addi $t4, $zero, 10
		multu $v0, $t4		# result x 10
		mflo $v0
		add $v0, $v0, $t6	#result= (result x 10) + x
		divu $v0, $t4	#get the last digit added to result
		mfhi $t1
		sb $t1, 0($a1)	#stores digit into answer
		addi $s6, $s6, 1	#adds 1 to counter
		addi $a1, $a1, 4
		multu $t4, $s3		#reference x 10
		mflo $t4		#$t4=reference x 10
		add $t4, $t4, $t6	#(refernce x 10) + x
		multu $t4, $t6		#((refernce x 10) + X) x X
		mflo $t7		#y = ((refernce x 10) + X) x X
		
		subu $s4, $s4, $t7	#remainer= remainder - y
		addi $t0, $t0, 4	#n++
		j mathLoop
	tooBig:
	lw $s0, 0($sp)		#counter
	lw $s2, 4($sp)		#decimal spot
	lw $s3, 8($sp)		#reference
	lw $s4, 12($sp)		#remainder
	lw $s1, 16($sp)		#array of pairs
	lw $a3, 20($sp)		#number of pairs
	addi $sp, $sp, 24
	jr $ra
		
#converts the string into 2 numbers
#v0=half to the left of decimal
#v1=half to the right of decimal
_convertNum:
	addi $sp, $sp, -20
	sw $a0, 0($sp)	#stores array
	sw $s1, 4($sp)	#stores user string
	sw $s2, 8($sp)	#stores decimal spot
	sw $s3, 12($sp)	#stores string length
	sw $s7, 16($sp)
	addi $t1, $s1, 0	#t1=string address
	addi $t2, $s2, 0	#t2=index of decimal
	addi $t5, $zero, 10 
	addi $t4, $zero, 0
	beq $t2, 1, half2	#if no right
	half1Loop:
		addi $t2, $t2 , -1	#index--;
		beqz $t2, half2
		oneDigitL:
		multu $t4, $t5		#number*10(to make room for next digit)
		mflo $t4
		lb $t3, 0($t1)		#loads first ascii bit
		addi $t3, $t3, -48	#turns into number
		add $t4, $t4, $t3	#number($t4)=$t4+$t3
		addi $t1, $t1, 1
		j half1Loop
	half2:
		addi $v0, $t4, 0	#$v0=first half
		addi $t2, $s2, 0	#resets decimal
		addi $t1, $s1, 0	#reloads string
		add $t1, $t1, $t2	#t1=1+address of decimal
		add $t1, $t1, -1	#t1=address of decimal
		addi $t4, $zero, 0	#resets $t4
	half2Loop:
		add $t1, $t1, 1
		lb $t3, 0($t1)		#loads first ascii bit
		beq $t3, 10, exitCN	#if bit is line feed character
		beq $t3, 0, exitCN	#if bit is null character
		multu $t4, $t5		#number*10(to make room for next digit)
		mflo $t4
		addi $t3, $t3, -48	#turns into number
		add $t4, $t4, $t3	#number($t4)=$t4+$t3
		j half2Loop
	
	exitCN:
	addi $v1, $t4, 0	#v1=second half
	lw $a0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)	
	lw $s3, 12($sp)	
	lw $s7, 16($sp)	
	addi $sp, $sp, 20
	jr $ra
	
	
#finds the decimal in the string
#returns $v0=spot in string of decimal
#if there is no decimal, it returns the length of the string
_findDecimal:
	addi $sp, $sp, -4
	sw $s1, 0($sp)	#stores user string
	
	addi $t0, $zero, 0	#counter
	add $t1, $zero, $s1	#user string
	lb $t2, dec_str		#loads string with decimal
	findLoop:
		addi $t0, $t0, 1
		lb $t3($t1)	#loads first byte
		beq $t3, 10, endOfStr	#if the byte is 10, you are at the end of the string
		seq $t4, $t3, $t2	#if byte= "."
		beq $t4, 1 , match
		addi $t1, $t1, 1	#next bit
		j findLoop
	endOfStr:
		addi $t0, $t0, -1	#subtracts 1 so that counter=length of the string
	match:
		add $v0, $zero, $t0
		lw $s1, 0($sp)
		addi $sp, $sp, 4
		jr $ra

#this function is taken from lab4 modified for this program, returns $v1 as size of string
_strLength:
	addi $sp, $sp, -8
	sw $s1, 0($sp)	#stores user string
	sw $s2, 4($sp)	#stores user string
	addi $v1, $zero, 0	#counter
	addi $t0, $zero, 0	#offset
	add $t2, $zero, $s1	#string to be counted
	sl_loop:
		lbu $t1, 0($t2)
		beq $t1, 10, exit_loop	#when bit=line feed
		addi $t2, $t2, 1	#next bit
		addi $v1, $v1, 1	#$v1++
		j sl_loop
	exit_loop:
	lw $s1, 0($sp)
	lw $s2, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	
	
exit:
la $a1, answer
addi $v0, $zero, 4
la $a0, is_str
syscall
addi $v0, $zero, 1
addi $t0, $zero, 2
bne $s2, 1, hasRightFin		#if doesnt have right side, just output decimal
addi $v0, $zero, 4
la $a0, dec_str
syscall
hasRightFin:
divu $s2, $t0
mflo $s2	#divide decimal place by 2 to get correct spot
addi $v0, $zero, 1
beq $s2, 0, skipDecimal
addi $s2, $s2, 1

finishLoop:
	beqz $s6, doneFinish
	addi $s6, $s6, -1
	addi $s2, $s2, -1	#decimal--
	bnez $s2, skipDecimal	#skip next part which outputs decimal	
	addi $v0, $zero, 4
	la $a0, dec_str
	syscall
	addi $v0, $zero, 1
	skipDecimal:
	lb $a0, 0($a1)
	syscall
	addi $a1, $a1, 4	#index++
	j finishLoop
doneFinish:
addi $v0, $zero, 10
syscall
