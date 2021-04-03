# Victor Ko
# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512 
# - Base Address for Display: 0x10008000 ($gp)
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. score and display also highscore
# 2. ability to shoot objects
# 3. no flickering obstacles and ship, by redrawing rectangle edges only

# link to video
# https://play.library.utoronto.ca/71d476c9efa535ce5440ca3f9324f12e
# ok with sharing?

.eqv	BASE_ADDRESS 0x10008000

.eqv	SLEEP 0x12
.eqv	spawn_frequency 50
.eqv	max_obstacles 5
.eqv	obstacle_speed 8
.eqv	max_missiles 3
.data

# pixel value to fill to generate letters
one: 	.word 	0,256,256,256,256,-16
two: 	.word 	0,4,4,256,256,-4,-4,256,256,4,4,-16
three: 	.word 	0,4,4,256,256,-4,-4,512,4,4,-256,-16
four: 	.word 	0,256,256,4,4,-256,-256,768,256,-16
five: 	.word 	0,4,4,248,256,4,4,256,256,-4,-4,-16
six: 	.word 	0,4,4,248,256,256,256,4,4,-256,-256,-4,-16
seven: 	.word 	0,4,4,256,256,256,256,-16
eight: 	.word 	0,4,4,256,-8,256,4,4,256,-8,256,4,4,-16
nine: 	.word 	0,4,4,256,-8,256,4,4,256,256,-16
zero: 	.word 	0,4,4,256,256,256,256,-4,-4,-256,-256,-256,-16
printh: .word 	0,8,256,-8,256,4,4,256,-8,256,8,-16
prints: .word 	0,4,252,256,4,256,256,-4,-16
printp: .word 	0,4,4,256,-8,256,4,4,248,256,-16
print_game_overx: .word 0,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,-5376,252,252,252,252,252,252,252,252,252,252,252,252,252,252,252,252,252,252,252,252,252,-16
print_game_over: .word 0,4,4,248,256,256,256,4,4,-256,8,-256,512,-508,512,-508,256,256,4,8,-252,260,-252,260,8,4,4,-264,-256,4,4,-264,4,4,1212,4,4,256,-8,256,8,256,-4,-4,-240,260,-252,264,4,4,-264,-256,4,4,-264,4,4, 776, -256,-256, 4,4 -16
printblock: .word 0,4,4,256,-4,-4,256,4,4,256,-4,-4,256,4,4,-16

# score
score: .word 0,0,0,0,0 # stores the score in reverse order ie big endian
hiscore: .word 0,0,0,0,0 # stores the highscore in reverse order ie big endian

scorecounter: .word 0 # This is a counter that resets to 0 to increment the score

spaceshiphit: .word 0 # Counter to draw spaceship as red

# spaceship
spaceship: .word 0:40 # allocate space for spaceship obj
# stores top left x,y and bottom right x,y each as a byte
# then stores hp field
# it should be 3x5 units
ship_colour: .word 0xE7E7E7

# stores obstacle objects
obstacles: .word 0:604 
# first index stores current number of obstacles
# allot 60 to store obstacle and 10 max obstacles in the game 
# each obstacle: 
# is active 0 1
# stores top left x,y and bottom right x,y  


# stores missile objects
missiles: .word 0:404 
# first one stores the num of missiles
# allot 20 to store missile and 20 max missiles in the game 

# missile obj:
# single pixel x, y stored




.text
.globl main

main:	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	j startgame
	# game ready state
	# wait for input p to start game
readytostart:
	li $t9, 0xffff0000	# get keyboard press event
	lw $t8, 0($t9)		# get keyboard press value
	beq $t8, 1, start_or_quit
	j readytostart

# check if input starts the game or quits it
start_or_quit:
	lw $t2, 4($t9)			# get value from keyboard
	beq $t2, 0x70, startgame	# start game if keypress is p
	beq $t2, 0x71, quit		# quit game if keypress is q
	j readytostart

quit:
	li $v0, 10 # terminate the program gracefully
	syscall 	

startgame:
	# initialize the game by setting up
	jal clearbitmap2
	jal setup_val
	jal draw_hud
	jal update_hs
	jal update_s
	jal draw_spaceship
	j gamephase	# starts the gamephase
# sets spaceship hp, starting point, scores, obstacles , missiles states
setup_val:

	la $t1, spaceship 	# spaceship object  
	li $t2, 3		# set hp to 3
	sw $t2, 16($t1)		# store hp
	
	# set starting (x,y) = rect (2,20) , (5,25)
	li $t2, 2
	sw $t2, 0($t1)		# left x = 2
	li $t2, 20	
	sw $t2, 4($t1)		# top y = 20
	li $t2, 5
	sw $t2, 8($t1)		# right x = 8
	li $t2, 25
	sw $t2, 12($t1)		# bot y = 25
	
	# set current score 0
	# set each num in the array to 0
	la $t1, score
	sw $0, ($t1) 
	sw $0, 4($t1)
	sw $0, 8($t1)
	sw $0, 12($t1)
	sw $0, 16($t1)

	
	# set obstacles values
	la $t1, obstacles
	sw $0, 0($t1)		# num obstacles = 0
	sw $0, 4($t1)		# obs1 = inactive
	sw $0, 64($t1)		# obs2 = inactive
	sw $0, 124($t1)		# obs3 = inactive
	sw $0, 184($t1)		# obs4 = inactive
	sw $0, 244($t1)		# obs5 = inactive
	sw $0, 304($t1)		# obs6 = inactive
	sw $0, 364($t1)		# obs7 = inactive
	# set missiles
	la $t1, missiles	
	sw $0, 0($t1)		# num missiles = 0
	sw $0, 4($t1)		# missile1 = inactive
	sw $0, 24($t1)		# missile2 = inactive
	sw $0, 44($t1)		# missile3 = inactive
	sw $0, 64($t1)		# missile4 = inactive
	sw $0, 84($t1)		# missile5 = inactive
	jr $ra

# wipes the entire bitmap display by writing black bg 
clearbitmap2:
	li $t1, 4096 		# number of times to loop
	li $t0, BASE_ADDRESS	# t0 address of bitmap
	li $t2, 0 		# index
	li $t3, 0 		# black bg
cbm2main:
	beq $t1, $t2, cbm2done	# if index = numberof of times to loop -> done
	sw $t3, 0($t0)		# draw bg colour at t0
	addi $t0, $t0, 4	# t0 increment byte
	addi $t2, $t2, 1	# increment index
	j cbm2main		# loop again
cbm2done: 
	jr $ra

# draws the general information display of the game info
draw_hud:
	

	
	# store ra
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	# draw top boundary line
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 12544 	# 256 *49 is the offset for the start 
	li $a1, 64		# width
	li $a2, 1		# height
	li $a3, 0xffffff	# colour white
	jal draw_rect		# draw line
	# draw hp letters
 	li $a2, 0xffffff	# set text colour to white
	li $t1, BASE_ADDRESS
	addi $a1, $t1, 12544 	# 256 *49	y offset
	addi $a1, $a1, 516 	# 512 +4	x offset
	li $a0, 10		
	jal get_numaddress	# get data to draw H
	move $a0, $v0		
	jal draw_letter		# draw H
	addi $a1, $a1, 16 	# shift right 4
	li $a0, 12		
	jal get_numaddress	# get letter P
	move $a0, $v0
	jal draw_letter		# draw p
	
	# draw num of hp
	addi $a1, $a1, 20 	# shift right 5
	li $a0, 3		
	jal get_numaddress	# get drawable 3 
	move $a0, $v0
	jal draw_letter		# draw 3
	
	# draw s for score
	li $a0, 11
	jal get_numaddress	# get drawable s
	move $a0, $v0
	addi $a1, $a1, 36 	# set offset 4* (6*4 + 1) 
	jal draw_letter
	
	# draw hs
	li $t1, BASE_ADDRESS	
	addi $a1, $t1, 14848 	# get y offset  256 *56
	
	addi $a1, $a1, 60 	# 15 units right
	li $a0, 10
	jal get_numaddress	# get drawable h
	move $a0, $v0
	jal draw_letter		# draw h
	addi $a1, $a1, 16	#shift right 4 4*4
	li $a0, 11
	jal get_numaddress	# get drawable s
	move $a0, $v0
	jal draw_letter		# draw s

	# get ra from stack
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	jr $ra

update_hs:
	li $a2, 0xffffff	# set colour of text
	# store saved registers
	addi $sp, $sp, -4
	sw $s0, ($sp)
	addi $sp, $sp, -4
	sw $s1, ($sp)
	addi $sp, $sp, -4
	sw $s2, ($sp)
	addi $sp, $sp, -4
	sw $s3, ($sp)
	addi $sp, $sp, -4
	sw $s4, ($sp)
	addi $sp, $sp, -4
	sw $s5, ($sp)	
	addi $sp, $sp, -4
	sw $s6, ($sp)		
	addi $sp, $sp, -4
	sw $s7, ($sp)	
	move $s0, $ra


	
	li $t1, BASE_ADDRESS
	addi $a1, $t1, 14848 	# set y offset 256 *56
	addi $a1, $a1, 96 	# set x offset 23 units right

	# remove previously drawn letters
	li $a2, 0		# set colour to black
	li $a0, 14		
	jal get_numaddress	# get a drawable block to overwrite
	move $a0, $v0
	jal draw_letter		# draw bg over number position
	# repeat 4 more times
	addi $a1, $a1,16 	# move 4 right
	jal draw_letter
	addi $a1, $a1,16 	# move 4 right
	jal draw_letter
	addi $a1, $a1,16	# move 4 right
	jal draw_letter
	addi $a1, $a1,16	# move 4 right
	jal draw_letter

	# get values of hiscore and draw
	li $a2, 0xffffff	# set white colour
	li $t1, BASE_ADDRESS
	addi $a1, $t1, 14848 	#y offset 256 *56
	addi $a1, $a1, 96 	#x offset 23 units right
	
	# display highscore number by number
	la $t8, hiscore
	lw $a0, 0($t8)		# get num at highscore[0]  
	jal get_numaddress
	move $a0, $v0
	jal draw_letter		# draw the num
	# repeat 4 more times
	addi $a1, $a1,16 # move 4 right
	lw $a0, 4($t8)		# get num at highscore[1]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter		# draw the num
	addi $a1, $a1,16 # move 4 right
	lw $a0, 8($t8)		# get num at highscore[2]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter		# draw the num
	addi $a1, $a1,16 # move 4 right
	lw $a0, 12($t8)		# get num at highscore[3]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter		# draw the num
	addi $a1, $a1,16 # move 4 right
	lw $a0, 16($t8)		# get num at highscore[4]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter		# draw the num
	# restore registers
	move $ra, $s0
	lw $s7, ($sp)
	addi $sp, $sp, 4
	lw $s6, ($sp)
	addi $sp, $sp, 4
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	lw $s3, ($sp)
	addi $sp, $sp, 4
	lw $s2, ($sp)
	addi $sp, $sp, 4
	lw $s1, ($sp)	
	addi $sp, $sp, 4
	lw $s0, ($sp)	
	addi $sp, $sp, 4
	
	jr $ra

# draw the score
update_s:
	# store ra
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	li $a2, 0xffffff	# set colour
	li $t1, BASE_ADDRESS
	addi $a1, $t1, 12544 	# y offset 256 *49
	addi $a1, $a1, 512 	# 2 down
	addi $a1, $a1, 96 	# 23 units right
	
	# get values of hiscore and store
	li $a2, 0xffffff	# set white colour
	la $t8, score		 
	lw $a0, 0($t8)		# get num of score[0]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter		# draw the num
	# repeat 4 more times
	addi $a1, $a1,16 	# move 4 right
	lw $a0, 4($t8)		# get num of score[1]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter
	addi $a1, $a1,16 	# move 4 right
	lw $a0, 8($t8)		# get num of score[2]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter
	addi $a1, $a1,16 	# move 4 right
	lw $a0, 12($t8)		# get num of score[3]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter
	addi $a1, $a1,16 	# move 4 right
	lw $a0, 16($t8)		# get num of score[4]
	jal get_numaddress
	move $a0, $v0
	jal draw_letter	
	
	# pop ra from sp
	lw $ra, ($sp)
	addi $sp, $sp ,4
	
	jr $ra


# takes in a0 the array that draws the letter, and the coord in a1, colour in a2
draw_letter:
	move $t1, $a1	# index
	move $t4, $a0	# address of array
	li $t2, -16 	# end condition
	move $t5, $a2	# set t5 = colour
	lw $t3, 0($t4)	

dlmain: 
	beq $t2, $t3, dldone	#if end of the array done
	add $t1, $t1, $t3	# move to the next pixel in the array to draw
	addi $t4,$t4,4		# increment the address
	sw $t5, 0($t1)		# colour at pixel t1 
	lw $t3, 0($t4)		# get next value
	j dlmain		# loop back

dldone:	
	jr $ra

# takes in a value in a0 and returns the array that will draw it
get_numaddress:
	# a long switch case
	li $t1, 0
	beq $a0, $t1, get0
	li $t1, 1
	beq $a0, $t1, get1
	li $t1, 2
	beq $a0, $t1, get2	
	li $t1, 3
	beq $a0, $t1, get3
	li $t1, 4
	beq $a0, $t1, get4
	li $t1, 5
	beq $a0, $t1, get5
	li $t1, 6
	beq $a0, $t1, get6	
	li $t1, 7
	beq $a0, $t1, get7	
	li $t1, 8
	beq $a0, $t1, get8
	li $t1, 9
	beq $a0, $t1, get9
	li $t1, 10
	beq $a0, $t1, get10
	li $t1, 11
	beq $a0, $t1, get11
	li $t1, 12
	beq $a0, $t1, get12
	li $t1, 13
	beq $a0, $t1, get13
	li $t1, 14
	beq $a0, $t1, get14
# labels that handle specific numbers to draw
get0: la $v0, zero
	j retnumaddress
get1: 	la $v0, one
	j retnumaddress
get2: 	la $v0, two
	j retnumaddress
get3: 	la $v0, three
	j retnumaddress
get4:	la $v0, four
	j retnumaddress
get5: 	la $v0, five
	j retnumaddress
get6: 	la $v0, six
	j retnumaddress
get7: 	la $v0, seven
	j retnumaddress
get8: 	la $v0, eight
	j retnumaddress
get9: 	la $v0, nine
	j retnumaddress
get10: 	la $v0, printh
	j retnumaddress
get11: 	la $v0, prints
	j retnumaddress
get12: 	la $v0, printp
	j retnumaddress
get13: 	la $v0, print_game_over
	j retnumaddress
get14: 	la $v0, printblock
	j retnumaddress
retnumaddress:
	jr $ra


draw_spaceship:

	li $t0, BASE_ADDRESS
	la $t1, spaceship
	
	lw $t2, 0($t1) 		# get left x
	lw $t3, 4($t1) 		# get top  y
	lw $t4, ship_colour	
	sll $t3, $t3, 8		# compute y offset
	sll $t2, $t2, 2		# x offsetr
	add $t2, $t2, $t3	
	add $t2, $t2, $t0 	# get start pixel index 
	
	# draw spaceship
	sw $t4, 0($t2)
	sw $t4, 256($t2)
	sw $t4, 512($t2)
	sw $t4, 768($t2)
	sw $t4, 1024($t2)
	sw $t4, 260($t2)
	sw $t4, 516($t2)
	sw $t4, 772($t2)
	sw $t4, 520($t2)
	
	jr $ra
	
# top left bound (x+y*512) width,height as a0,a1,a2 add $a3 as colour... 
# uses t registers
# who should do the checking?
draw_rect: 
	move $t1, $a0 	# left position
	li $t2, 0 	# height counter
	li $t3, 0 	# width counter
	move $t4, $t1 	# current index

drouter:
	# while height counter < a2
	bge $t2, $a2, drdone 
drinner:
	# while width counter < a1
	bge $t3, $a1,drinnerdone 
	
	sw $a3, 0($t4)		# colour the pixel
	addi $t4,$t4,4		# move right
	addi $t3, $t3,1		# increment width counter
	j drinner
drinnerdone:
	addi $t2,$t2, 1		# increment height counter
	addi $t1,$t1, 256	# set left most position lower by 1
	li $t3, 0		# reset inner counter 
	move $t4, $t1 
	j drouter
drdone:
	jr $ra


gamephase:
	# update states
	li $a0, 1
	jal time_increase
	# move missiles
	jal move_missiles
	#checkspaceship movement
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened
keypress_done:
	
	jal recolour_spaceship
	jal spawn_obstacle
	jal move_obstacles

	# check collision
	jal check_missile_collision
	jal check_spaceship_collision
	
	#sleep
	li $v0, 32
	li $a0, SLEEP # Wait one second (1000 milliseconds)
	syscall


	j gamephase

keypress_happened:
	lw $t2, 4($t9)
	la $t3, spaceship
	lw $t4, 0($t3)  	# top left x
	lw $t5, 4($t3)  	# top left y
	lw $t6, 8($t3)  	# bot right x
	lw $t7, 12($t3)  	# bot right y
	li $t0, BASE_ADDRESS
	beq $t2, 0x61, respond_to_a
	beq $t2, 0x77, respond_to_w
	beq $t2, 0x64, respond_to_d
	beq $t2, 0x73, respond_to_s
	beq $t2, 0x20, respond_to_space
	beq $t2, 0x70, respond_to_p
	beq $t2, 0x71, respond_to_q
	
# move down
respond_to_s:
	li $t8, 49 # lower bound
	beq $t7 $t8, sp_moveinvalid
	# redraw
		# setting the top left pixel index
	sll $t8, $t5, 8
	sll $t9, $t4, 2
	add $t8, $t8, $t9
	add $t8, $t8, $t0
	# erase only the sides
	sw $0, 0($t8) 
	sw $0, 260($t8)
	sw $0, 520($t8)
	# draw movement
	lw $t9, ship_colour
	sw $t9, 1280($t8)
	sw $t9, 1028($t8)
	sw $t9, 776($t8)
	# move object coord
	addi $t5, $t5,1
	addi $t7, $t7,1
	sw $t5, 4($t3)
	sw $t7, 12($t3)
	
	j keypress_done
# move up
respond_to_w:
	li $t8, 0 # lower bound
	beq $t5 $t8, sp_moveinvalid
	# redraw
	# setting the top left pixel index at t8
	sll $t8, $t5, 8
	sll $t9, $t4, 2
	add $t8, $t8, $t9
	add $t8, $t8, $t0
	# erase only the sides
	sw $0, 1024($t8) 
	sw $0, 772($t8)
	sw $0, 520($t8)
	# draw movement
	lw $t9, ship_colour
	sw $t9, -256($t8)
	sw $t9, 4($t8)
	sw $t9, 264($t8)
	# move object coord
	addi $t5, $t5,-1
	addi $t7, $t7,-1
	sw $t5, 4($t3)
	sw $t7, 12($t3)
	j keypress_done
# move left
respond_to_a:
	li $t8, 0 # upper bound
	beq $t4 $t8, sp_moveinvalid
	# redraw
	# setting the top left pixel index
	sll $t8, $t5, 8
	sll $t9, $t4, 2
	add $t8, $t8, $t9
	add $t8, $t8, $t0
	# erase only the sides
	sw $0, 0($t8) 
	sw $0, 260($t8)
	sw $0, 520($t8)
	sw $0, 772($t8)
	sw $0, 1024($t8)
	# draw movement
	lw $t9, ship_colour
	sw $t9, -4($t8)
	sw $t9, 252($t8)
	sw $t9, 508($t8)
	sw $t9, 764($t8)
	sw $t9, 1020($t8)
	# move object coord
	addi $t4, $t4,-1
	addi $t6, $t6,-1
	sw $t4, 0($t3)
	sw $t6, 8($t3)
	j keypress_done
# move right
respond_to_d:
	li $t8, 63 # upper bound
	beq $t6 $t8, sp_moveinvalid
	# redraw
	# setting the top left pixel index
	sll $t8, $t5, 8
	sll $t9, $t4, 2
	add $t8, $t8, $t9
	add $t8, $t8, $t0
	# erase only the sides
	sw $0, 0($t8) 
	sw $0, 256($t8)
	sw $0, 512($t8)
	sw $0, 768($t8)
	sw $0, 1024($t8)
	# draw movement
	lw $t9, ship_colour
	sw $t9, 4($t8)
	sw $t9, 264($t8)
	sw $t9, 524($t8)
	sw $t9, 776($t8)
	sw $t9, 1028($t8)
	# move object coord
	addi $t4, $t4,1
	addi $t6, $t6,1
	sw $t4, 0($t3)
	sw $t6, 8($t3)
	
	j keypress_done
# shoot missile
respond_to_space:
	la $t1, spaceship
	la $t2, missiles
	lw $t3, ($t2)
	li $t4, max_missiles
	beq $t3, $t4 , keypress_done
	addi $t3, $t3, 1
	sw $t3, ($t2)
	# find unusedmissile
	addi $t2, $t2, -16
while_space:
	addi $t2, $t2, 20	# find next missile 
	lw $t3, ($t2)
	bnez $t3, while_space	# if index contains unused missile
	lw $t4, 0($t1)	
	lw $t5, 4($t1)	
	addi $t4, $t4, 3	# set x
	addi $t5, $t5, 2	# set y
	li $t6, 1		# set missile active
	sw $t6, ($t2)		# store active, x,y 
	sw $t4, 4($t2)
	sw $t5, 8($t2)
	j keypress_done
# restart/ start
respond_to_p:
	j startgame
# quit
respond_to_q:
	j quit
# cannot move spaceship
sp_moveinvalid:
	j keypress_done


# scoring system

# increments the score depending on counter state
time_increase:
	lw $t1, scorecounter
	li $a0, 1	
	beqz $t1, increase_score	# if counter state is zero then increase
	subi $t1, $t1, 1		# otherwise decrease counter
	sw $t1, scorecounter
	jr $ra
increase_score:	
	li $t1, 60			# reset counter
	sw $t1, scorecounter		# and store
# takes in a value in a0 and adds it to the scores
increase_score2:
	# store saved registers
	addi $sp, $sp, -4
	sw $s0, ($sp)
	addi $sp, $sp, -4
	sw $s1, ($sp)
	addi $sp, $sp, -4
	sw $s2, ($sp)
	addi $sp, $sp, -4
	sw $s3, ($sp)
	addi $sp, $sp, -4
	sw $s4, ($sp)
	addi $sp, $sp, -4
	sw $s5, ($sp)	
	addi $sp, $sp, -4
	sw $s6, ($sp)		
	addi $sp, $sp, -4
	sw $s7, ($sp)	
		
	move $s0, $ra
	la $s1, score 		# s1 = score addr
	
	addi $s1,$s1, 16

	li $s3, 10		# s3 = threshold
	li $s4, 16 		# index
	# set current pixel to draw
	li $s5, BASE_ADDRESS
	addi $s5, $s5, 12544 	# 256 *49
	addi $s5, $s5, 512 	# 2 down
	addi $s5, $s5, 96 	# 23 units right
	addi $s5, $s5, 64 	# start at the end
	move $a1, $s5 		# set current pixel to draw
	
	lw $s2, 0($s1)		# s2 = value of current score
	add $s6, $a0, $s2 	# current value updated
	
increase_score_main:
	bge $s6, $s3, update_score2
				# remove prev number
	li $a2, 0 		# set colour black
	move $a0, $s2
	jal get_numaddress	# draw previous number in black
	move $a0, $v0
	jal draw_letter		
	# draw new number
	li $a2, 0xffffff 	# set colour white
	move $a0, $s6
	jal get_numaddress	# draw new num
	move $a0, $v0
	jal draw_letter	
	
	# set s6 to be the value stored in the score array
	sw $s6, 0($s1)
	
	# restore registers
	move $ra, $s0
	lw $s7, ($sp)
	addi $sp, $sp, 4
	lw $s6, ($sp)
	addi $sp, $sp, 4
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	lw $s3, ($sp)
	addi $sp, $sp, 4
	lw $s2, ($sp)
	addi $sp, $sp, 4
	lw $s1, ($sp)	
	addi $sp, $sp, 4
	lw $s0, ($sp)	
	addi $sp, $sp, 4
	jr $ra
	
update_score2:
	# t1 = t1-10
	subi $s6, $s6, 10
	
	li $a2, 0 # set colour black
	move $a0, $s2
	jal get_numaddress
	move $a0, $v0
	jal draw_letter
	# draw new number
	li $a2, 0xffffff # set colour white
	move $a0, $s6
	jal get_numaddress
	move $a0, $v0
	jal draw_letter	
	
	sw $s6, 0($s1)
	# add 1 to the next index
	subi $a1, $a1, 16 # set current pixel to draw
	subi $s4,$s4, 4
	subi $s1, $s1, 4
	subi $s5, $s5, 16	# start at the end
	move $a1, $s5 		# set current pixel to draw

	lw $s2, 0($s1)
	addi $s6, $s2, 1
	bgtz $s4, increase_score_main
	
	# restore registers
	move $ra, $s0
	lw $s7, ($sp)
	addi $sp, $sp, 4
	lw $s6, ($sp)
	addi $sp, $sp, 4
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	lw $s3, ($sp)
	addi $sp, $sp, 4
	lw $s2, ($sp)
	addi $sp, $sp, 4
	lw $s1, ($sp)	
	addi $sp, $sp, 4
	lw $s0, ($sp)		
	addi $sp, $sp, 4
	
	jr $ra

spawn_obstacle:
	la $t0, obstacles 
	lw $t1, ($t0) # num obstacles
	move $s0, $ra
	li $t2, max_obstacles
	beq $t1, $t2, spawn_obstacle_done
	# call random number generator 
	li $v0, 42
	li $a0, 0
	li $a1, spawn_frequency
	syscall
	li $t2, 1
	bne $a0, $t2, spawn_obstacle_done
	# spawning conditions met
	
	addi $t1, $t1, 1
	sw $t1, ($t0)

	# find unused address in obstacle array
	addi $t1, $t0, -56
	
find_unused_obstacle:
	addi $t1, $t1, 60
	lw $t2, ($t1)
	bnez $t2, find_unused_obstacle
	# t1 stores unused obstacle address
	li $t2, 1
	sw $t2, ($t1)
	# randomize y
	li $v0, 42
	li $a0, 0
	li $t0, 47
	move $a1, $t0
	syscall
	sw $a0, 8($t1)	# store top y
	move $t4, $a0
	li $t2, 64
	sw $t2, 4($t1)	# store left x
	# randomize size
	li $v0, 42
	li $a0, 0
	li $t3, 7
	move $a1, $t3
	syscall
	addi $a0, $a0 ,2
	add $t3, $a0, $t2 # bottom right x
	sw $t3,	12($t1)
	add $t3, $a0, $t4 # bottom right y
	li $t4, 47
	bgt $t3, $t4 fix_y
	
set_spawn:
	sw $t3,	16($t1)	
	# randomize movement func
	li $v0, 42	
	li $a0, 0	
	li $t3, 1
	move $a1, $t3
	syscall
	sw $a0,	20($t1)
	# randomize move vector x
	li $v0, 42
	li $a0, 0
	li $t3, 10
	move $a1, $t3
	syscall
	addi $a0, $a0, 4 # prevent weird behaviour
	sw $a0, 24($t1)
	# randomize move vector y
	li $v0, 42
	li $a0, 0
	li $t3, 2
	move $a1, $t3
	syscall
	sw $a0, 28($t1)
	# randomize speed
	li $v0, 42
	li $a0, 0
	li $t3, obstacle_speed
	move $a1, $t3
	syscall
	addi $a0, $a0, 2 # prevent weird behaviour 
	sw $a0, 32($t1)
	# initialize state
	sw $0, 36($t1)	# vector state
	sw $0, 40($t1)	# speed state

spawn_obstacle_done:
	jr $s0
fix_y: 
	li $t3, 48	# shrink y of obstacle so that it doesnt go past the hud
	b set_spawn

move_obstacles:
	# store saved registers
	addi $sp, $sp, -4
	sw $s0, ($sp)
	addi $sp, $sp, -4
	sw $s1, ($sp)
	addi $sp, $sp, -4
	sw $s2, ($sp)
	addi $sp, $sp, -4
	sw $s3, ($sp)
	addi $sp, $sp, -4
	sw $s4, ($sp)
	addi $sp, $sp, -4
	sw $s5, ($sp)	
	addi $sp, $sp, -4
	sw $s6, ($sp)		
	addi $sp, $sp, -4
	sw $s7, ($sp)	
	move $s0, $ra

	li $s1, 0 		# declare counter 
	la $s2, obstacles 	# store address
	lw $s3, ($s2) 		# store num obstacles
	addi $s2, $s2, -56

move_obstacles_main:
	# get first available object
	beq $s1, $s3, move_obstacles_done
	addi $s2, $s2, 60
	lw $t1, ($s2)	# check if valid
	beqz $t1, move_obstacles_main
	lw $s4, 40($s2) #speed state
	addi $s4, $s4, 1
	sw $s4, 40($s2)
	lw $s5, 32($s2) # speed
	
	bne $s4, $s5, found_obstacle
	# reset speed state
	sw $0, 40($s2)
	
	lw $s4, 20($s2)
	
	bnez $s4, found_obstacle # temporary in case want to add more movement funcs
	
	lw $s4, 24($s2) # vec x
	lw $s5, 28($s2)	# vec y
	lw $s6, 36($s2) # vec state
	addi $s6, $s6, 1
	sw $s6, 36($s2)
	li $t0, BASE_ADDRESS

	
	beq $s4, $s6, move_rect_vert
	j move_rect_left

move_rect_vert:
	
	sw $0, 36($s2) # reset state
	beqz $s5, move_rect_down
	b move_rect_up

move_rect_down:
	lw $s4, 4($s2)	# top left x
	lw $s5, 8($s2)	# top left y
	lw $s6, 12($s2)	# bot right x
	lw $s7, 16($s2)	# bot right y
	# check if edges are in the left right frame
	li $t1, 64
	bgt $s6, $t1, move_rect_left
	bltz $s4, move_rect_left
	# clear the top row
	li $a3, 0
	li $a2, 1 # height
	sub $a1, $s6, $s4 # width
	addi $a1, $a1, 1
	sll $t2, $s4, 2
	sll $t3, $s5, 8
	li $a0, BASE_ADDRESS
	add $a0, $a0, $t3
	add $a0, $a0, $t2

	jal draw_rect
	# perform move down coords


	addi $t1, $s5, 1
	sw $t1, 8($s2)
	addi $t1, $s7, 1

	li $t3, 48
	# check if can be deleted
	bge $s5, $t3, delete_obstacles_move
	# if bot goes past frame do nothing
	ble $s7, $t3, move_rect_down2
	# set the bottom to be exactly 47
	addi $t3, $t3, 1
	sw $t3, 16($s2)
	b found_obstacle

move_rect_down2: # bot is good to draw
	sw $t1, 16($s2)
	addi $s5, $s5, 1	# move down coord
	li $a3, 0xBB9440	# set colour
	sub $a1, $s6, $s4	# compute offsets 
	sub $a2, $t1, $s5
	sll $t2, $s4, 2		
	sll $t3, $s5, 8	
	li $a0, BASE_ADDRESS
	add $a0, $a0, $t3	# still compute offsets
	add $a0, $a0, $t2
	jal draw_rect
	b found_obstacle

move_rect_up:	
	lw $s4, 4($s2)	# top left x
	lw $s5, 8($s2)	# top left y
	lw $s6, 12($s2)	# bot right x
	lw $s7, 16($s2)	# bot right y
	# check if edges are in the frame
	li $t1, 64
	bgt $s6, $t1, move_rect_left
	bltz $s4, move_rect_left
	# clear the bottom row
	li $a3, 0
	li $a2, 1 # height
	sub $a1, $s6, $s4 # width
	addi $a1, $a1, 1
	sll $t2, $s4, 2
	sll $t3, $s7, 8
	li $a0, BASE_ADDRESS
	add $a0, $a0, $t3
	add $a0, $a0, $t2
	addi $a0, $a0, -256
	jal draw_rect
	# perform move up coords

	addi $t1, $s7, -1
	sw $t1, 16($s2)
	
	# check if can be deleted
	bltz $s1, delete_obstacles_move
	# if top goes past frame do nothing
	addi $t1, $s5, -1
	bgez $t1, move_rect_up2
	sw $0, 8($s2)
	b found_obstacle

move_rect_up2: # top is good to draw full rectangle
	sw $t1, 8($s2)		
	subi $s5, $s5, 1	# set position
	li $a3, 0xBB9440	# set colour
	sub $a1, $s6, $s4	# compute offsets
	sub $a2, $t1, $s5
	sll $t2, $s4, 2
	sll $t3, $s5, 8	
	li $a0, BASE_ADDRESS
	add $a0, $a0, $t3	# compute offsets
	add $a0, $a0, $t2
	jal draw_rect
	b found_obstacle

move_rect_left:
	lw $s4, 4($s2)	# top left x
	lw $s5, 8($s2)	# top left y
	lw $s6, 12($s2)	# bot right x
	lw $s7, 16($s2)	# bot right y
	
	# perform move left coords
	addi $t1, $s4, -1
	sw $t1, 4($s2)
	addi $t1, $s6, -1
	sw $t1, 12($s2)	
	
	# setup values to erase right edge
	li $t1, 64
	bgt $s6, $t1, move_rl_1 # draw left edge if right edge out of frame
	li $a3, 0		# set colour
	li $a1, 1		# set width
	sub $a2, $s7, $s5
	sll $t2, $s6, 2		# x offset
	sll $t3, $s5, 8		# y offset
	li $a0, BASE_ADDRESS
	add $a0, $a0, $t3	
	add $a0, $a0, $t2	# pixel index
	jal draw_rect
	
# move rect left and redraw entire rect 
move_rl_2:
	beqz $s6, delete_obstacles_move # the obstacle is completely out of frame, delete
	
	addi $s4, $s4, -1
	bltz $s4, found_obstacle # dont draw left edge if out of frame	
	li $a3, 0xBB9440
	sub $a1, $s6, $s4	# width
	sub $a2, $s7, $s5	# height
	sll $t2, $s4, 2		# x offset
	sll $t3, $s5, 8		# y offset
	li $a0, BASE_ADDRESS
	add $a0, $a0, $t3	# y offset
	add $a0, $a0, $t2	# x offset
	jal draw_rect

	j found_obstacle
	
# draw only the left edge of rect
move_rl_1:
	beqz $s6, delete_obstacles_move # delete obstacle if right is out of frame
	addi $s4, $s4, -1
	bltz $s4, found_obstacle 	# dont draw left edge if out of frame
	li $a3, 0xBB9440		# set colour
	li $a1, 1			# height 1
	sub $a2, $s7, $s5		
	sll $t2, $s4, 2			# x offset
	sll $t3, $s5, 8			# y offset
	li $a0, BASE_ADDRESS
	add $a0, $a0, $t3		# y offset
	add $a0, $a0, $t2		# x offset
	jal draw_rect
	j found_obstacle	

# delete obstacle when it has gone out of frame
delete_obstacles_move:
	sw $0, ($s2)		# set to inactive
	lw $t2, obstacles	
	subi $t2, $t2, 1
	sw $t2, obstacles	# subtract num obstacles by 1
 	j found_obstacle

found_obstacle:
	
	addi $s1, $s1, 1	# increment obstacle counter
	j move_obstacles_main

move_obstacles_done:
	# restore registers
	move $ra, $s0

	lw $s7, ($sp)
	addi $sp, $sp, 4
	lw $s6, ($sp)
	addi $sp, $sp, 4
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	lw $s3, ($sp)
	addi $sp, $sp, 4
	lw $s2, ($sp)
	addi $sp, $sp, 4
	lw $s1, ($sp)	
	addi $sp, $sp, 4
	lw $s0, ($sp)	
	addi $sp, $sp, 4

	jr $ra
move_missiles:
	# store saved registers
	addi $sp, $sp, -4
	sw $s0, ($sp)
	addi $sp, $sp, -4
	sw $s1, ($sp)
	addi $sp, $sp, -4
	sw $s2, ($sp)
	addi $sp, $sp, -4
	sw $s3, ($sp)
	addi $sp, $sp, -4
	sw $s4, ($sp)
	addi $sp, $sp, -4
	sw $s5, ($sp)	
	addi $sp, $sp, -4
	sw $s6, ($sp)		
	addi $sp, $sp, -4
	sw $s7, ($sp)	
	move $s0, $ra
	li $s1, 0 		# declare counter 
	la $s2, missiles 	# store address
	lw $s3, ($s2) 		# store num obstacles
	addi $s2, $s2, -16

move_missiles_main:
	# get first available object
	beq $s1, $s3, move_missiles_done
	addi $s2, $s2, 20
	lw $t1, ($s2)	# check if valid
	beqz $t1, move_missiles_main
	
	
	# update pixel
	li $t0, BASE_ADDRESS
	lw $t2, 4($s2)
	lw $t3, 8($s2)
	addi $t2, $t2, 1
	sw $t2, 4($s2)
	# erase previous pixel
	sll $t2, $t2, 2
	sll $t3, $t3, 8
	add $t3, $t2, $t3
	add $t3, $t0, $t3
	
	sw $0, -4($t3)
	# check if out of bounds
	li $t5, 256
	bge $t2,$t5, delete_missile
	# draw pixel
	li $t1, 0xD7DD75
	sw $t1, ($t3)

found_missile:
	addi $s1, $s1, 1
	
	j move_missiles_main

move_missiles_done:	
	jr $ra
	
delete_missile:
	lw $t1, missiles
	subi $t1, $t1, 1
	sw $t1, missiles
	sw $0, ($s2)
	j found_missile

#   =====================================================
check_missile_collision:
	move $s0, $ra
	li $s1, 0 		# declare counter 
	la $s2, missiles 	# store address
	lw $s3, ($s2) 		# store num obstacles
	addi $s2, $s2, -16

check_missile_collision_main:
	# get first available object
	beq $s1, $s3, check_missile_collision_done
	addi $s2, $s2, 20
	lw $t1, ($s2)	# check if valid
	beqz $t1, check_missile_collision_main
	# =========================================
	
	# for each obstacle, check for collision
	li $s5, 0 	# declare counter 
	la $s6, obstacles 	# store address
	lw $s7, ($s6) 	# store num obstacles
	addi $s6, $s6, -56

check_missile_obstacles_main:
	# get first available object
	beq $s5, $s7, check_missile_obstacles_done
	addi $s6, $s6, 60
	lw $t1, ($s6)	# check if valid
	beqz $t1, check_missile_obstacles_main
	
	#=== conditions for missile collistion 
	# s2 is missile, s5 is obstacle
	# use t reg only
	lw $t1, 4($s2) # x
	lw $t2, 8($s2) # y
	lw $t4, 4($s6)	# rectx
	lw $t5, 8($s6)	# recty
	lw $t6, 12($s6)	# rectx
	lw $t7, 16($s6)	# recty
	sub $t6, $t6, $t4 # width
	sub $t7, $t7, $t5 # height
	
	# check collision
	blt $t1, $t4, found_obstacle_missile
	add $t9, $t4, $t6
	bge $t1, $t9, found_obstacle_missile
	blt $t2, $t5, found_obstacle_missile
	add $t9, $t5, $t7
	bge $t2, $t9, found_obstacle_missile
	# resolve collision
	# remove missile
	lw $t9, missiles
	subi $t9, $t9, 1
	sw $t9, missiles
	sw $0, ($s2)
	#subi $s3, $s3, 1
	# remove object
	lw $t9, obstacles
	subi $t9, $t9, 1
	sw $t9, obstacles
	sw $0, ($s6)
	#subi $s5, $s5, 1
	# set rect address
	li $t0, BASE_ADDRESS
	sll $t8, $t4, 2
	sll $t9, $t5, 8
	add $t8, $t9, $t8
	add $t8, $t0, $t8
	
	sw $0, ($t8)
	# erase obstacle
	li $a3, 0
	addi $a1, $t6,1
	addi $a2, $t7,0
	addi $a0, $t8,0
	jal draw_rect
	li $a0, 5
	# increase score
	# store in stack pointer 
	# save necessary values

	jal increase_score2

	#=== 
	j found_missile2
	# top left bound (x+y*256) width,height as a0,a1,a2 add $a3 as colour... 
	#uses t registers
found_obstacle_missile:
	addi $s5, $s5, 1
	
	j check_missile_obstacles_main

check_missile_obstacles_done:
	j found_missile2

found_missile2:
	addi $s1, $s1, 1
	
	j check_missile_collision_main

check_missile_collision_done:
	move $ra, $s0
	# restore registers
	move $s0, $ra
	lw $s7, ($sp)
	addi $sp, $sp, 4
	lw $s6, ($sp)
	addi $sp, $sp, 4
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	lw $s3, ($sp)
	addi $sp, $sp, 4
	lw $s2, ($sp)
	addi $sp, $sp, 4
	lw $s1, ($sp)	
	addi $sp, $sp, 4
	lw $s0, ($sp)	
	addi $sp, $sp, 4
	


	jr $ra
# ==========================================================
check_spaceship_collision:
	# store saved registers
	addi $sp, $sp, -4
	sw $s0, ($sp)
	addi $sp, $sp, -4
	sw $s1, ($sp)
	addi $sp, $sp, -4
	sw $s2, ($sp)
	addi $sp, $sp, -4
	sw $s3, ($sp)
	addi $sp, $sp, -4
	sw $s4, ($sp)
	addi $sp, $sp, -4
	sw $s5, ($sp)	
	addi $sp, $sp, -4
	sw $s6, ($sp)		
	addi $sp, $sp, -4
	sw $s7, ($sp)
	move $s0, $ra

	
	# for each obstacle, check for collision
	li $s5, 0 			# declare counter 
	la $s6, obstacles 		# store address
	lw $s7, ($s6) 			# store num obstacles
	addi $s6, $s6, -56
	la $s4, spaceship
	lw $s1, ($s4) 			# left x spaceship
	lw $s2, 4($s4) 			# top y spaceship
	lw $s3, 8($s4)			# right x spacehsip
	lw $s4, 12($s4) 		# bot y	spaceship

check_spaceship_collision_main:		# main loop to get obstacle
	# get first available obstacle
	beq $s5, $s7, check_spaceship_collision_done
	addi $s6, $s6, 60		# go to next obstacle
	lw $t1, ($s6)			# check if active obstacle
	beqz $t1, check_spaceship_collision_main
	# load obstacle values
	lw $t5, 4($s6) 			# left x obstacle
	lw $t6, 8($s6)			# top y obstacle
	lw $t7, 12($s6)			# right x obstacle
	lw $t8, 16($s6)			# bot y obstacle
	# check for collision
	ble $s3, $t5, found_spaceship_obstacle
	bge $s1, $t7, found_spaceship_obstacle
	ble $s4, $t6, found_spaceship_obstacle
	bge $s2, $t8, found_spaceship_obstacle
	# collision detected
	# delete obstacle
	lw $t9, obstacles
	subi $t9, $t9, 1
	sw $t9, obstacles		# decrement total active
	sw $0, ($s6)	
	# erase obstacle by only redrawing the background in its space
	li $t0, BASE_ADDRESS
	sll $t1, $t5, 2			# x offset
	sll $t2, $t6, 8			# y offset
	add $t1, $t1, $t2	
	add $a0, $t0, $t1		# starting coordinate of obstacle

	sub $a1,$t7,$t5 		# get width
	addi $a1, $a1, 1 		# off by 1 width calculation
	sub $a2,$t8, $t6 		# get height
	li $a3, 0			# set colour
	jal draw_rect
	# operations to decrease hp
	la $t1, spaceship
	li $t0, BASE_ADDRESS
	addi $a1, $t0, 13096	# get address to redraw
	lw $t2, 16($t1) 	# get hp value
	# first erase hp num
	li $a2, 0
	move $a0, $t2
	jal get_numaddress
	move $a0, $v0
	jal draw_letter	
	# decrement hp
	la $t1, spaceship
	lw $t2, 16($t1)
	subi $t2, $t2, 1		# store changes
	sw $t2, 16($t1)
	# redraw
	li $a2, 0xffffff
	li $t0, BASE_ADDRESS
	addi $a1, $t0, 13096	# get address to redraw
	move $a0, $t2
	jal get_numaddress
	move $a0, $v0
	jal draw_letter
	# check gameover condition
	la $t1, spaceship
	lw $t2, 16($t1)
	blez $t2, game_over
	# redraw spaceship red
 	li $t0, BASE_ADDRESS
	la $t1, spaceship	
	lw $t2, 0($t1) # get top left x spaceship
	lw $t3, 4($t1) # get top left y spaceship
	sll $t3, $t3, 8
	sll $t2, $t2, 2
	add $t2, $t2, $t3
	add $t2, $t2, $t0 # get start pixel index 
	li $t4, 0xBE2525
	sw $t4, ship_colour
	sw $t4, 0($t2)
	sw $t4, 256($t2)
	sw $t4, 512($t2)
	sw $t4, 768($t2)
	sw $t4, 1024($t2)
	sw $t4, 260($t2)
	sw $t4, 516($t2)
	sw $t4, 772($t2)
	sw $t4, 520($t2)	

	li $t4, 15
	sw $t4, spaceshiphit
	
 
 

found_spaceship_obstacle:
	addi $s5, $s5, 1
	j check_spaceship_collision_main

check_spaceship_collision_done:

	# restore registers
	move $ra, $s0
	
	lw $s7, ($sp)
	addi $sp, $sp, 4
	lw $s6, ($sp)
	addi $sp, $sp, 4
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	lw $s3, ($sp)
	addi $sp, $sp, 4
	lw $s2, ($sp)
	addi $sp, $sp, 4
	lw $s1, ($sp)	
	addi $sp, $sp, 4
	lw $s0, ($sp)	
	addi $sp, $sp, 4

	jr $ra
	

game_over:
	# restore registers
	move $s0, $ra
	lw $s7, ($sp)
	addi $sp, $sp, 4
	lw $s6, ($sp)
	addi $sp, $sp, 4
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	lw $s3, ($sp)
	addi $sp, $sp, 4
	lw $s2, ($sp)
	addi $sp, $sp, 4
	lw $s1, ($sp)	
	addi $sp, $sp, 4
	lw $s0, ($sp)	
	addi $sp, $sp, 4

	la $t0, score
	la $t1, hiscore

	# check highscore
	# compare each digit, if the first one is bigger then set higscore
	lw $t2, ($t0)
	lw $t3, ($t1)
	bne $t2, $t3, compare_score
	lw $t2, 4($t0)
	lw $t3, 4($t1)
	bne $t2, $t3, compare_score
	lw $t2, 8($t0)
	lw $t3, 8($t1)
	bne $t2, $t3, compare_score
	lw $t2, 12($t0)
	lw $t3, 12($t1)
	bne $t2, $t3, compare_score
	lw $t2, 16($t0)
	lw $t3, 16($t1)
	bne $t2, $t3, compare_score
game_over_x:
	# draw giant gameover on screen in red
	li $a2, 0xff0000
	li $t0, BASE_ADDRESS
	li $t3, 22
	li $t4, 14
	sll $t5, $t3, 2
	sll $t6, $t4, 8
	add $t5, $t5, $t6
	add $a1, $t0, $t5	# get address to redraw
	li $t8, 13
	move $a0, $t8
	jal get_numaddress
	move $a0, $v0
	jal draw_letter
	j readytostart	
compare_score:
	bgt $t2, $t3, change_highscore
	j game_over_x
change_highscore:
	# compare each value in array and update
	lw $t2, ($t0)
	sw $t2, ($t1)
	lw $t2, 4($t0)
	sw $t2, 4($t1)
	lw $t2, 8($t0)
	sw $t2, 8($t1)
	lw $t2, 12($t0)
	sw $t2, 12($t1)
	lw $t2, 16($t0)
	sw $t2, 16($t1)
	jal update_hs
	j game_over_x

# recolour spaceship whenever hit
recolour_spaceship:
	lw $t1, spaceshiphit
	bnez $t1, recolour_spaceship2	# check if spaceship has been recently hit
	jr $ra
recolour_spaceship2:		# the spaceship has been recently hit
	addi $t1, $t1, -1	# decrease timer 
	sw $t1, spaceshiphit

	beqz $t1, recolour_operation	# recolour spacehip
	jr $ra
recolour_operation:			# change spaceship colour back to white
	li $t2, 0xE7E7E7
	sw $t2, ship_colour
	
	j draw_spaceship

# stack implementation of while caller pop
while:
	# store ra
	subi $sp, $sp, 4
	sw $ra, 0($sp)
	li $t2, 0
repeat:	
	lw $t3, 8($sp) # load terminating val
	beq $t2, $t3, endwhile #terminating condition
	lw $t1, 4($sp) # load address of content function 

	subi $sp, $sp, 4 # send current index as arg before calling
	sw $t2, 0($sp) 
	
	jalr $t1  # jump to the function 
	
	# get current index value
	lw $t2, 0($sp)
	addi $sp, $sp, 4 
	addi $t2, $t2, 1
	j repeat

endwhile:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


test:
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 13824
	li $t1, 0xff0000 # $t1 stores the red colour code
	li $t2, 0x00ff00 # $t2 stores the green colour code
	li $t3, 0x0000ff # $t3 stores the blue colour code
	sw $t1, 0($a0) # paint the first (top-left) unit red.
	sw $t2, 8($t0) # paint the second unit on the first row green. Why $t0+4?
	sw $t3, 256($t0) # paint the first unit on the second row blue. Why +128?
	
	la $t3, one
	lw $t3, 4($t3)
	j game_over_x
	jr $ra



# check for keyboard input	
# li $t9, 0xffff0000
# lw $t8, 0($t9)
# beq $t8, 1, keypress_happened

# if keypress happened check type of key being pressed
# lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
# beq $t2, 0x61, respond_to_a # ASCII code of 'a' is 0x61 or 97 in decimal

#func display text given index
