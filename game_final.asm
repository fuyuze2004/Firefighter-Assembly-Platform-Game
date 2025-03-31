#####################################################################
#
# CSCB58 Winter 2025 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Yuze Fu, 1009918467, fuyuze, lucas.fu@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - All 4 milestones
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Double jump (1 mark)
# 2. Moving objects (2 marks): moving enemies (red fire)
# 3. Moving platforms (2 marks): the brown upper platform 
# 
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# 1. The player can jump through the platform and stand onto it. This is the game design instead of collision errors. If you think it is not 
# reasonable, you could search some videos about Terraria. There are similar platfors design especially for building fields for beating boss
# 2. Press q will go to the game over page directly.
#
#####################################################################


.data
    displayAddress: .word 0x10008000	# Base address of bitmap display
    width:         .word 64          	# Game width in units
    height:        .word 64          	# Game height in units
    
    # Colors
    bg:           .word 0x87CEEB     	# Sky blue background
    platform:     .word 0x8B4513     	# Brick brown platforms
    player:       .word 0x00FF0080     	# Purple player
    save:       .word 0x2E8B57     		# Green Scores
    coin:		  .word 0xFFD700		# Golden objects
    black:      .word 0x00000000    	# Black goal
    gray:       .word 0x00808080    	# Gray goal
    red:        .word 0x00FF0000    	# Red fire
    
    
    # Memory-mapped I/O addresses for keyboard
    keyboard_control: .word 0xFFFF0000
    keyboard_data:    .word 0xFFFF0004
    
    # Player info
    playerX: .word 6
    playerY: .word 59
    playerW: .word 4
    playerH: .word 4
    playerV: .word 4
    jumpLimit: .word 0
    
    # Game info
    time:			.word 0
    invincableTime:	.word 0
    score:       	.word 0
    lives:       	.word 3
    
    # Array of platforms
	platforms:                
        # Platform 0 (floor)
        .word 0   # x
        .word 63  # y (bottom)
        .word 64  # width
        # Platform 1
        .word 10  # x
        .word 40  # y
        .word 20  # width
        # Platform 2
        .word 10  # x
        .word 20  # y
        .word 20  # width
        
    people:				# Arrary of coins
    	# Person 0
        .word 50   	# x
        .word 59  	# y (bottom)
        .word 0		# saved or not
        # Person 1
        .word 14  	# x
        .word 36  	# y
        .word 0		# saved or not
        
   	fire:
   		# fire 1
   		.word 31	# x
   		.word 1		# y
   		.word 2		# fall down speed
     
	# Goal position
   	doorX:	.word 42	# x
    doorY:	.word 16	# y
    

.text
.globl main

main:
    # Clear screen with background color
    jal clear_screen
    # Reset all fields
    jal reset_platform
    li $t0, 6
    li $t1, 59
    sw $t0, playerX
    sw $t1, playerY
    li $t0, 0
    sw $t0, score
    sw $t0, time
    la $t0, people
    li $t1, 0
    sw $t1, 8($t0)
    sw $t1, 20($t0)
    # Draw the frame
    jal draw_frame
    
    # Draw first object (4x4 square)
    la $t0, people
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    lw $a3, coin             # color
    jal draw_object
    
    # Draw second object (4x4 square)
    la $t0, people
    lw $a0, 12($t0)
    lw $a1, 16($t0)
    jal draw_object
    
    jal game_loop
    
    # Exit program
    li $v0, 10
    syscall

# Draw the frame
draw_frame:
	addi $sp, $sp, -4
    sw $ra, 0($sp)
    
	# Draw floor (platform at bottom)
    la $t0, platforms
    lw $a0, 0($t0)          # x = 0
    lw $a1, 4($t0)         	# y = 63 (bottom row)
    lw $a2, 8($t0)         	# width = full width
    lw $a3, platform   		# color
    jal draw_horizontal_line
    
    # Draw first platform
    la $t0, platforms
    lw $a0, 12($t0)          	# x = 10
    lw $a1, 16($t0)         	# y = 40 (bottom row)
    lw $a2, 20($t0)         	# width = 20
    jal draw_horizontal_line
    
    # Clear second platform before moving
    la $t0, platforms
    lw $a0, 24($t0)   
    lw $a1, 28($t0)         
    lw $a2, 32($t0)         
    lw $a3, bg
    jal draw_horizontal_line
    # Draw second platform after moving
    la $t0, platforms
    jal move_platform			# moving platform
    lw $a0, 24($t0)
    lw $a1, 28($t0)         
    lw $a2, 32($t0) 
    lw $a3, platform
    jal draw_horizontal_line
    
    # Draw player (3 * 3 square)
    lw $a0, playerX          	# x = 6
    lw $a1, playerY         	# y = 59 (on floor)
    jal draw_player
    
    # Draw the goal (4 * 4 square)
    lw $a0, doorX
    lw $a1, doorY
    jal draw_door
    
    # Draw the enemy
    lw $a3, bg
    jal draw_fire
    jal move_fire
    lw $a3, red
    jal draw_fire
    
    # Draw the health
    lw $a3, bg
    li $t8, 3
    jal draw_life
    lw $a3, player
    lw $t8, lives
    jal draw_life
    
	# Draw Score
	li $a0, 2
	li $a1, 2
	lw $a3, save		# color
	jal draw_object
	li $a0, 6
	li $a1, 4
	lw $a2, score
	lw $a3, save		# color
	jal draw_score
	
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Draw the life on the top-right corner
draw_life:
	move $t9, $ra
	li $a0, 59
	li $a1, 2
	
draw_heart_loop:
	beqz $t8, draw_life_back
	# draw a heart
	li $a2, 1
	jal draw_horizontal_line
	addi $a0, $a0, 2
	jal draw_horizontal_line
	addi $a0, $a0, -2
	addi $a1, $a1, 1
	li $a2, 3
	jal draw_horizontal_line
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	li $a2, 1
	jal draw_horizontal_line
	# change back the cursor
	addi $a0, $a0, -1
	addi $a1, $a1, -2
	# move the cursor to next spot
	addi $a0, $a0, -4
	addi $t8, $t8, -1
	
	j draw_heart_loop
	
draw_life_back:
	lw $t8, lives
	beqz $t8, game_over
	move $ra, $t9
	jr $ra

# Moving fire
move_fire:
	la $t0, fire
	lw $t2, 4($t0)
	li $t1, 60
	beq $t1, $t2, reset_fire
	addi $t2, $t2, 1
	sw $t2, 4($t0)
	jr $ra
	
reset_fire:
	li $t2, 1
	sw $t2, 4($t0)
	jr $ra

# Draw the fire
draw_fire:
	move $t9, $ra
	la $t0, fire
	lw $a0, 0($t0)
	lw $a1, 4($t0)
	# first row
	addi $a0, $a0, 1
	li $a2, 1
	jal draw_horizontal_line
	# second row
	addi $a0, $a0, -1
	addi $a1, $a1, 1
	li $a2, 3
	jal draw_horizontal_line
	# third row
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	li $a2, 1
	jal draw_horizontal_line
	
	move $ra, $t9
	jr $ra

# Moving platform
move_platform:
	# Test the time is a multiple of 16 or not
	lw $t1, time
	andi $t1, $t1, 15
	bnez $t1, move_platform_back
	lw $t1, 24($t0)
	li $t2, 40
	beq $t1, $t2, reset_platform
	addi $t1, $t1, 2
	sw $t1, 24($t0)
	jr $ra

reset_platform:
	li $t1, 10
	sw $t1, 24($t0)
	jr $ra
	
move_platform_back:
	jr $ra
	

# Clear screen with background color
clear_screen:
    lw $t0, displayAddress
    li $t1, 0                   # counter
    li $t2, 4096               # total pixels (64x64)
    lw $t3, bg
    
clear_loop:
    sw $t3, 0($t0)             # store color
    addi $t0, $t0, 4           # next pixel
    addi $t1, $t1, 1
    blt $t1, $t2, clear_loop
    jr $ra

# Draw horizontal line (platform)
# a0 = x, a1 = y, a2 = length, a3 = color
draw_horizontal_line:
    lw $t0, displayAddress     # base address
    lw $t1, width              # width of display
    mul $t2, $a1, $t1          # y * width
    add $t2, $t2, $a0          # + x
    sll $t2, $t2, 2            # multiply by 4 (bytes per pixel)
    add $t0, $t0, $t2          # final address
    
    li $t3, 0                  # counter
    
draw_line_loop:
    sw $a3, 0($t0)             # draw pixel
    addi $t0, $t0, 4           # next pixel
    addi $t3, $t3, 1
    blt $t3, $a2, draw_line_loop
    jr $ra
    

# Draw the score on the top-left corner
draw_score:
	beq $a2 $zero, draw_score_end
	lw $t4, bg
	lw $t0, displayAddress     # base address
    lw $t1, width              # width of display
    mul $t2, $a1, $t1          # y * width
    add $t2, $t2, $a0          # + x
    sll $t2, $t2, 2            # multiply by 4 (bytes per pixel)
    add $t0, $t0, $t2          # final address
    
    li $t3, 0                  # counter
    
draw_score_loop:
    sw $t4, 0($t0)             # draw pixel
    addi $t0, $t0, 4           # next pixel
    sw $a3, 0($t0)
    addi $t0, $t0, 4
    addi $t3, $t3, 1
    blt $t3, $a2, draw_score_loop
    jr $ra
    
draw_score_end:
	jr $ra

# Draw player (4x4 square)
# a0 = x, a1 = y
draw_player:
    # Save return address
    move $t9, $ra
    
    # Draw 3 horizontal lines
    lw $a3, player             # color
    lw $a2, playerW				# width
    jal draw_horizontal_line    # 1
    
    addi $a1, $a1, 1           # 2
    jal draw_horizontal_line
    
    addi $a1, $a1, 1           # 3
    jal draw_horizontal_line
    
    addi $a1, $a1, 1           # 4
    jal draw_horizontal_line
    
    # Restore return address
    move $ra, $t9
    jr $ra
    
clear_player:
	# Save return address
    move $t9, $ra
    
    # Draw 3 horizontal lines
    lw $a3, bg             # color
    lw $a2, playerW				# width
    jal draw_horizontal_line    # 1
    
    addi $a1, $a1, 1           # 2
    jal draw_horizontal_line
    
    addi $a1, $a1, 1           # 3
    jal draw_horizontal_line
    
    addi $a1, $a1, 1           # 4
    jal draw_horizontal_line
    
    # Restore return address
    move $ra, $t9
    jr $ra

# Draw the goal
draw_door:
	move $t9, $ra
	# first row
	addi $a0, $a0, 1
	li $a2, 2
	lw $a3, gray
	jal draw_horizontal_line
	# second row
	addi $a0, $a0, -1
	addi $a1, $a1, 1
	li $a2, 1
	lw $a3, gray
	jal draw_horizontal_line
	addi $a0, $a0, 1
	li $a2, 2
	lw $a3, black
	jal draw_horizontal_line
	addi $a0, $a0, 2
	li $a2, 1
	lw $a3, gray
	jal draw_horizontal_line
	# third row
	addi $a0, $a0, -3
	addi $a1, $a1, 1
	li $a2, 1
	lw $a3, gray
	jal draw_horizontal_line
	addi $a0, $a0, 1
	li $a2, 2
	lw $a3, black
	jal draw_horizontal_line
	addi $a0, $a0, 2
	li $a2, 1
	lw $a3, gray
	jal draw_horizontal_line
	# fourth row
	addi $a0, $a0, -2
	addi $a1, $a1, 1
	li $a2, 2
	lw $a3, gray
	jal draw_horizontal_line
	
	move $ra, $t9
	jr $ra
	
	
# Draw object (3x3 square)
# a0 = x, a1 = y
draw_object:
    # Save return address
    move $t9, $ra
    
    # Draw 3 horizontal lines
    li $a2, 2
    addi $a0, $a0, 1                  
    jal draw_horizontal_line    # top row
    
    addi $a1, $a1, 1           # middle row
    li $a2, 4
    subi $a0, $a0, 1
    jal draw_horizontal_line
    
    addi $a1, $a1, 1           # bottom row
    li $a2, 2
    addi $a0, $a0, 1
    jal draw_horizontal_line
    
    addi $a1, $a1, 1           # bottom row
    li $a2, 2
    jal draw_horizontal_line
    
    # Restore return address
    move $ra, $t9
    jr $ra

# Game logic loop
game_loop:
	# update the time
	lw $t0, time
	addi $t0, $t0, 1
	sw $t0, time
	lw $t0, invincableTime
	addi $t0, $t0, -1
	sw $t0, invincableTime
	# update the graphics
	jal draw_frame
	# check the collision
	jal check_goal
	jal check_coin
	jal check_fall
	jal check_fire
    # Check keyboard
    lw $t0, keyboard_control
    lw $t0, 0($t0)
    andi $t0, $t0, 1
    beqz $t0, no_key
    
    # r: restart
    lw $t1, keyboard_data
    lw $t1, 0($t1)
    li $t2, 114
    beq $t1, $t2, main
    # Key pressed - check if it's 'q'
    lw $t1, keyboard_data
    lw $t1, 0($t1)
    li $t2, 113
    beq $t1, $t2, game_over
    # a
    li $t2, 97
    beq $t1, $t2, move_left
    # d
    li $t2, 100
    beq $t1, $t2, move_right
    # space
    li $t2, 32
    beq $t1, $t2, jump
        
no_key:
    # Small delay to prevent CPU overuse (50ms)
    li $v0, 32
    li $a0, 40
    syscall
        
    j game_loop

# Check the collision for fire
check_fire:
	# check the invincable time
	lw $t0, invincableTime
	bgtz $t0, check_fire_back
	lw $t0, playerX
	lw $t1, playerY
	la $t2, fire
	lw $t3, 0($t2)		# fire x
	lw $t4, 4($t2)		# fire y
	
check_fire_x:
	addi $t0, $t0, -1
	beq $t0, $t3, check_fire_y
	addi $t0, $t0, 1
	beq $t0, $t3, check_fire_y
	addi $t0, $t0, 1
	beq $t0, $t3, check_fire_y
	addi $t0, $t0, 1
	beq $t0, $t3, check_fire_y
	jr $ra

check_fire_y:
	addi $t1, $t1, -1
	beq $t1, $t4, decrease_health
	addi $t1, $t1, 1
	beq $t1, $t4, decrease_health
	addi $t1, $t1, 1
	beq $t1, $t4, decrease_health
	addi $t1, $t1, 1
	beq $t1, $t4, decrease_health
	jr $ra
	
# Decrease the health after touching the fire
decrease_health:
	lw $t0, lives
	addi $t0, $t0, -1
	# beqz $t0, game_over
	sw $t0, lives
	# reset the invincable time
	li $t0, 16
	sw $t0, invincableTime
	jr $ra
	
check_fire_back:
	jr $ra

# Check the collision with the coins
check_coin:
	addi $sp, $sp, -4
    sw $ra, 0($sp)

	la $t0, people
	
	lw $a0, playerX
	lw $a1, playerY
	
	lw $t1, 0($t0)
	lw $t2, 4($t0)
	lw $t3, 8($t0)
	jal check_coin_eaten
	
	addi $t0, $t0, 12
	lw $t1, 0($t0)
	lw $t2, 4($t0)
	lw $t3, 8($t0)
	jal check_coin_eaten
	
	lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Check the collision of the goal
check_goal:
	lw $t0, playerX
	lw $t1, playerY
	lw $t2, doorX
	lw $t3, doorY
	beq $t0, $t2, check_goal_y
	jr $ra
	
check_goal_y:
	beq $t1, $t3, game_win
	jr $ra

check_coin_eaten:
	beq $t3, $zero, check_coin_x
	jr $ra
	
check_coin_x:
	beq $t1, $a0, check_coin_y
	jr $ra

check_coin_y:
	beq $t2, $a1, add_score
	jr $ra

# Add score
add_score:
	lw $t4, score
	addi $t4, $t4, 1
	sw $t4, score
	addi $t3, $t3, 1
	sw $t3 8($t0)
	jr $ra

# Check the left boundary
check_left:
	
	blez $a0, game_loop
	jr $ra

# Check the right boundary
check_right:
	lw $t0, width
	lw $t1, playerW
	sub $t0, $t0, $t1			# the head is on the left-top
	beq $a0, $t0, game_loop
	jr $ra

# Move left action
move_left:
	lw $a0, playerX
    lw $a1, playerY
    jal check_left
    jal clear_player
    lw $a0, playerX
    lw $a1, playerY
    lw $a3, playerV
	sub $a0, $a0, $a3
	sw $a0, playerX
	# Draw player (3x3 square)
    jal draw_player
	
	j game_loop

# Move right action
move_right:
	lw $a0, playerX
    lw $a1, playerY
    jal check_right
    jal clear_player
    lw $a0, playerX
    lw $a1, playerY		# Reload after clear_player
    lw $a3, playerV
	add $a0, $a0, $a3
	sw $a0, playerX
	# Draw player (3x3 square)
    jal draw_player
	
	j game_loop

# Jump action
jump:
	# Check the time to jump
	lw $t8, jumpLimit
	beqz $t8, jump_back
	addi $t8, $t8, -1
	sw $t8, jumpLimit
	# Erase the old player
	lw $a0, playerX
    lw $a1, playerY
    jal clear_player
	subi $a1, $a1, 20
	sw $a1, playerY
	# Draw player (3x3 square)
    jal draw_player
	
	j game_loop

jump_back:
	j game_loop

# Check the collision of falling
check_fall:
	addi $sp, $sp, -4
    sw $ra, 0($sp)
	
	lw $t0, playerW
	lw $t1, playerX
	lw $t2, playerY
	la $a0, platforms
	
	jal ground_or_not	# check first platform
	jal ground_or_not	# check second platform
	jal ground_or_not	# check third platform
	
	jal fall
	
	lw $ra, 0($sp)
    addi $sp, $sp, 4
	jr $ra

# Check the player is on the ground or not
ground_or_not:
	lw $t3, 0($a0)
	lw $t4, 4($a0)
	lw $t5, 8($a0)
	addi $a0, $a0, 12
	
	add $t6, $t2, $t0
	beq $t6, $t4, check_left_edge	# floor
	
	jr $ra

# Check the left edge of the platform
check_left_edge:
	bge $t1, $t3, check_right_edge	# left
	jr $ra

# Check the right edge of the platform
check_right_edge:
	add $t7, $t3, $t5
	sub $t7, $t7, $t0
	ble $t1, $t7, check_fall_back
	jr $ra

check_fall_back:
	lw $ra, 0($sp)
    addi $sp, $sp, 4
    # Reset the time to jump
    li $t8, 2
    sw $t8, jumpLimit
	jr $ra
    
# Falling action
fall:
    # Save return address on stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a0, playerX
    lw $a1, playerY
    jal clear_player
    
    lw $a0, playerX
    lw $a1, playerY
    addi $a1, $a1, 1
    sw $a1, playerY
    
    jal draw_player
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
# Emergent exit
exit_program:
    # Exit the program
    li $v0, 10
    syscall

# Game over page
game_over:
	jal clear_screen
	jal draw_over
	li $v0, 10
    syscall

# Win page
game_win: 
	jal clear_screen
	# draw the health
    lw $a3, bg
    li $t8, 3
    jal draw_life
    lw $a3, player
    lw $t8, lives
    jal draw_life
	# Draw Score
	li $a0, 2
	li $a1, 2
	lw $a3, save		# color
	jal draw_object
	li $a0, 6
	li $a1, 4
	lw $a2, score
	lw $a3, save		# color
	jal draw_score
	
	jal draw_win
	
	li $v0, 10
    syscall
    
# Draw veritcal line
# a0 = x, a1 = y, a2 = length, a3 = color
draw_vertical_line:
    lw $t0, displayAddress     # base address
    lw $t1, width              # width of display
    mul $t2, $a1, $t1          # y * width
    add $t2, $t2, $a0          # + x
    sll $t2, $t2, 2            # multiply by 4 (bytes per pixel)
    add $t0, $t0, $t2          # final address
    
    li $t3, 0                  # counter
    
draw_vertical_line_loop:
    sw $a3, 0($t0)             # draw pixel
    addi $t0, $t0, 256           # next pixel
    addi $t3, $t3, 1
    blt $t3, $a2, draw_vertical_line_loop
    jr $ra
	
# Draw the word of game over page
draw_over:
	move $t9, $ra
	li $a0, 26
	li $a1, 30
	lw $a3, red
	# D
	li $a2, 2
	jal draw_horizontal_line
	li $a2, 5
	jal draw_vertical_line
	addi $a0, $a0, 2
	addi $a1, $a1, 1
	li $a2, 3
	jal draw_vertical_line
	addi $a0, $a0, -2
	addi $a1, $a1, 3
	li $a2, 2
	jal draw_horizontal_line
	# I
	addi $a1, $a1, -4
	addi $a0, $a0, 4
	li $a2, 3
	jal draw_horizontal_line
	addi $a0, $a0, 1
	li $a2, 5
	jal draw_vertical_line
	addi $a0, $a0, -1
	addi $a1, $a1, 4
	li $a2, 3
	jal draw_horizontal_line
	# E
	addi $a1, $a1, -4
	addi $a0, $a0, 4
	li $a2, 3
	jal draw_horizontal_line
	li $a2, 5
	jal draw_vertical_line
	addi $a1, $a1, 2
	li $a2, 3
	jal draw_horizontal_line
	addi $a1, $a1, 2
	jal draw_horizontal_line
	
	move $ra, $t9
	jr $ra

# Draw the word for winning page
draw_win:
	move $t9, $ra
	li $a0, 24
	li $a1, 30
	lw $a3, save
	# W
	li $a2, 4
	jal draw_vertical_line
	addi $a0, $a0, 2
	jal draw_vertical_line
	addi $a0, $a0, 2
	jal draw_vertical_line
	addi $a0, $a0, -3
	addi $a1, $a1, 4
	li $a2, 1
	jal draw_horizontal_line
	addi $a0, $a0, 2
	jal draw_horizontal_line
	# I
	addi $a0, $a0, 3
	addi $a1, $a1, -4
	li $a2, 3
	jal draw_horizontal_line
	addi $a0, $a0, 1
	li $a2, 5
	jal draw_vertical_line
	addi $a0, $a0, -1
	addi $a1, $a1, 4
	li $a2, 3
	jal draw_horizontal_line
	# N
	addi $a0, $a0, 4
	addi $a1, $a1, -4
	li $a2, 5
	jal draw_vertical_line
	li $a2, 1
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	jal draw_horizontal_line
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	jal draw_horizontal_line
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	jal draw_horizontal_line
	addi $a0, $a0, 1
	addi $a1, $a1, -3
	li $a2, 5
	jal draw_vertical_line
	
	move $ra, $t9
	jr $ra
