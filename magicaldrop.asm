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
# - Display height in pixels:   512 pixels
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data


bubble_grid: .space 392
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
black:	.word 0x00FFFFFF
white: 	.word 0x00000000 
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
	

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
