################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Nabiha Tariq, 1012251144
# Student 2: Dana Younes, 1012192084
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8 pixels
# - Unit height in pixels:      8 pixels
# - Display width in pixels:    256 pixels
# - Display height in pixels:   256 pixels
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data

##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# Grid - 7 coloumns and 14 rows (7*14*4 bytes = 392)
grid: .space 392

# Storing colours in memory

red: 	.word 0x00FF0000
green:	.word 0x0000FF00  
blue:	.word 0x000000FF 
black:	.word 0x00000000 
white: 	.word 0x00FFFFFF 
pink:	.word 0x00eda3b0


##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal draw_border
    
    lw $t3, ADDR_DSPL       # Reload bitmap base address
    la $t0, grid            # load address of current cell grid
    li $t1, 98              # load the total number of cells we have in 7 x 14 grid
    lw $t2, black           # load the empty/blank cell colour black
    lw $t3, ADDR_DSPL       # bitmap base address
    
initialize_grid:
    
    # creates grid
    
    sw $t2, 0($t0)              # stores 3 (black) in first cell
    addi $t0, $t0, 4            # increment the current cell to move on
    addi $t1, $t1, -1           # decrement the number of cells we still need to fill
    bgtz $t1, initialize_grid   # keep drawing until we have filled all cells
    la $t0, grid                # reset to first grid cell
    li $t1, 21                  # 3 rows * 7 columns = 21 bubbles that are coloured

# generates random colour bubbles 
random_bubbles:
    li $a0, 0                   # random generator
    li $a1, 4                   # upper bound on random int.
    li $v0, 42                  # random integer range syscall
    
    syscall
    
    # Choose a colour based on the random number
    beq $a0, $zero, choose_red      # if a0 is 0, bubble is red

    li $t4, 1                       # temp. store 1 in register
    beq $a0, $t4, choose_green      # if a0 if 1, bubble is green

    li $t4, 2                       # temp. store 2 in register
    beq $a0, $t4, choose_blue       # if a0 is 2, choose blue

    j choose_pink                   # else, choose pink
    
choose_red:
    lw $t2, red                     # store RGB of colour into register
    j store_bubble                 # make bubble

choose_green:
    lw $t2, green                   # store RGB of colour into register
    j store_bubble                  # make bubble

choose_blue:
    lw $t2, blue                    # store RGB of colour into register
    j store_bubble                  # make bubble
    
choose_pink:
    lw $t2, pink                    # store RGB of colour into register
    j store_bubble                  # make bubble
	
# stores bubble in address
store_bubble:
    sw $t2, 0($t0)                  # store colour in current cell
    addi $t0, $t0, 4                # increment the current cell to move on
    addi $t1, $t1, -1               # decrement the number of cells we still need to fill
    bgtz $t1, random_bubbles        # continue until we have filled all bubbles
    
la $t0, grid                         # reset to first grid cell before drawing
draw_grid:
    li $t1, 0                       # current row
    li $t2, 0                       # current column
    
draw_grid_loop:
    addi $t4, $t1, 4                # bitmap row
    addi $t5, $t2, 4                # bitmap column
    
    sll $t6, $t4, 5                 # Move to next row
    add $t6, $t6, $t5               # Find next unit
    sll $t6, $t6, 2                 # offsetting bytes
    add $t6, $t6, $t3               # add bitmap base address
    
    lw $t7, 0($t0)                  # current cell colour
    
    beq $t7, $zero, skip_draw       # Skip drawing if cell is black
    
    sw $t7, 0($t6)                  # draw cell
        
        
skip_draw:
    addi $t0, $t0, 4                # move to next cell
    addi $t2, $t2, 1                # move to next column
    
    blt $t2, 7, draw_grid_loop      # if column < 7, draw next bubble
    
    # Move to next row
    li $t2, 0
    addi $t1, $t1, 1

    blt $t1, 14, draw_grid_loop     # Check if we finished all 14 rows
    
    jal draw_player

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
    
draw_border:
    addi $sp, $sp, -4
    sw $ra, 0($sp)       # Save return address
    
    lw $t0, ADDR_DSPL   # address of bitmap
    lw $t5, white       # colour of border

    # Top border length is 9 since 7 from bubbles and 2 extra for sides
    li $t1, 3
    li $t2, 3
    li $t3, 9
    jal draw_horizontal_line

    # Bottom border length is 9 since 7 from bubbles and 2 extra for sides
    li $t1, 3
    li $t2, 18
    li $t3, 9
    jal draw_horizontal_line

    # Left border is 16 since 14 from bubbles and 2 extra for sides
    li $t1, 3
    li $t2, 3
    li $t3, 16
    jal draw_vertical_line

    # Right border is 16 since 14 from bubbles and 2 extra for sides
    li $t1, 11
    li $t2, 3
    li $t3, 16
    jal draw_vertical_line

    lw $ra, 0($sp)       # Restore saved return address
    addi $sp, $sp, 4
    jr $ra


# Draws a horizontal line
# $t0 = display base address
# $t1 = starting X coordinate
# $t2 = starting Y coordinate
# $t3 = line length
# $t5 = colour

draw_horizontal_line:
    sll $t1, $t1, 2
    sll $t2, $t2, 7
    add $t8, $t0, $t1
    add $t8, $t8, $t2

horizontal_loop:
    beq $t3, $zero, horizontal_done
    sw $t5, 0($t8)
    addi $t8, $t8, 4
    addi $t3, $t3, -1
    j horizontal_loop

horizontal_done:
    jr $ra


# Draws a vertical line
# $t0 = display base address
# $t1 = starting X coordinate
# $t2 = starting Y coordinate
# $t3 = line length
# $t5 = colour

draw_vertical_line:
    sll $t1, $t1, 2
    sll $t2, $t2, 7
    add $t8, $t0, $t1
    add $t8, $t8, $t2

vertical_loop:
    beq $t3, $zero, vertical_done       # keep drawing until length is 0
    sw $t5, 0($t8)
    addi $t8, $t8, 128                  
    addi $t3, $t3, -1                   # decrement length by 1
    j vertical_loop

vertical_done:
    jr $ra
    
    

draw_player:
    addi $sp, $sp, -4
    sw $ra, 0($sp)          # save address

    lw $t0, ADDR_DSPL
    lw $t5, pink

    li $t1, 7
    li $t2, 19
    li $t3, 2

    jal draw_vertical_line

    lw $ra, 0($sp)
    addi $sp, $sp, 4            # restore address
    jr $ra
