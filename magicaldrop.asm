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
orange: .word 0x00FFA500
bubble_colours: .word 0x00FF0000, 0x0000FF00, 0x000000FF, 0x00eda3b0   # red, green, blue, pink
game_over: .word 0  # this will be 1 when the game is over
key_count: .word 0  # tracks number of keystrokes so we can implement a row advance after every 10


##############################################################################
# Mutable Data
##############################################################################

player_col: .word 7
player_row: .word 19

hand_colour: .word 0x00000000
hand_count:  .word 0

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
    
# $t0 - current grid cell
# $t1 - total number of cells we have in 7 x 14 grid
# $t2 - black colour
# $t3 - bitmap base address
# $t4 - keyboard address base
main:
    # Initialize the game
    jal draw_border
    la $t0, grid            # load address of current cell grid
    li $t1, 98              # load the total number of cells we have in 7 x 14 grid
    lw $t2, black           # load the empty/blank cell colour black
    lw $t3, ADDR_DSPL       # bitmap base address
    
    
# $t0 - current grid cell
# $t1 - total number of cells needed to fill
# $t2 - black colour
# $t3 - bitmap base address
initialize_grid:
    
    # creates grid
    
    sw $t2, 0($t0)              # stores 3 (black) in first cell
    addi $t0, $t0, 4            # increment the current cell to move on
    addi $t1, $t1, -1           # decrement the number of cells we still need to fill
    bgtz $t1, initialize_grid   # keep drawing until we have filled all cells
    la $t0, grid                # reset to first grid cell
    li $t1, 28                  # 3 rows * 7 columns = 21 bubbles that are coloured

# generates random colour bubbles 
# $a0 - random integer
# $t4 - stores integer from 1 0 to 2
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
    
# $t2 - stores colour
choose_red:
    lw $t2, red                     # store RGB of colour into register
    j store_bubble                  # make bubble

# $t2 - stores colour
choose_green:
    lw $t2, green                   # store RGB of colour into register
    j store_bubble                  # make bubble

# $t2 - stores colour
choose_blue:
    lw $t2, blue                    # store RGB of colour into register
    j store_bubble                  # make bubble

# $t2 - stores colour
choose_pink:
    lw $t2, pink                    # store RGB of colour into register
    j store_bubble                  # make bubble
	
# stores bubble in address
# $t2 - stores colour
# $t0 - current grid cell
# $t1 - total number of cells needed to fill
store_bubble:
    sw $t2, 0($t0)                  # store colour in current cell
    addi $t0, $t0, 4                # increment the current cell to move on
    addi $t1, $t1, -1               # decrement the number of cells we still need to fill
    bgtz $t1, random_bubbles        # continue until we have filled all bubbles

la $t0, grid                         # reset to first grid cell before drawing

# draws grid 
# $t1 - row
# $t2 - coloumn
draw_grid:
    li $t1, 0                       # current row
    li $t2, 0                       # current column
    
# draws grid
# $t4 - bitmap row (we draw on 4 x 4)
# $t5 - bitmap column
# t6 - address of pixel
# t7 - cell colour
# t3 - bitmap base address
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
    lw   $t0, game_over         # check if game is over
    bne  $t0, $zero, quit_game  # if yes, end the game
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
   
    lw $t4, ADDR_KBRD       # load keyboard base address
    lw $t9, 0($t4)                      # load first value of keyboard
    andi $t9, $t9, 1                    # Check whether a key is available
    beq $t9, $zero, game_loop           # If no key, keep checking
    lw $t5, key_count                   
    addi $t5, $t5, 1                    # another keystroke happened so increase key count!
    blt $t5, 10, save_count             # less than 10 keystrokes have passed since last row advance

    # we have reached 10 keystrokes 
    sw $zero, key_count
    jal advance_rows  # advance rows every 10 key strokes
    jal redraw_grid
    j read_key        # read which key is pressed

    
    save_count: 
      sw $t5, key_count             # write key count to memory            
      
    read_key:
      lw $t4, ADDR_KBRD             # reading a key pressed
    
    lw $a0, 4($t4)                  # load second word of keyboard input
    
    li $t8, 0x61                    # load A
    beq $a0, $t8, respond_to_A     # 0X61 is A in ASCII, and we respond when done
    
    li $t8, 0x64                    # load D
    beq $a0, $t8, respond_to_D     # 0X64 is A in ASCII, and we respond when done
    
    li $t8, 0x73                    # load S
    beq $a0, $t8, respond_to_S    # 0X61 is A in ASCII, and we respond when done
                                    
    li $t8, 0x77                    # load W
    beq $a0, $t8, respond_to_W      # 0X77 is W in ASCII
    
    li $t8, 0x71                    # for q
    beq $a0, $t8, quit_game
    
    j frame_done
    
frame_done:
    li $v0, 32
    li $a0, 17                  # sleep for 17 ms
    syscall

    j game_loop
    

quit_game:
    li $v0, 10
    syscall


respond_to_A:
    lw $s1, player_col              # load player col
    li $t8, 4                       # max col in left dir.
    beq $s1, $t8, game_loop           # if it's reached max. movement in left direction, don't do anything and go back to game loop

    # erase the bubbles by calculating bitmap position and putting black
    lw $t0, ADDR_DSPL               # Load the bitmap display base address
    sll $t1, $s1, 2                 # Multiply the player's column by 4 (bytes per pixel)
    add $t0, $t0, $t1               # Calculate the address of the bottom held bubble
    li $t1, 17                      # Set the starting bitmap row to 17
    sll $t1, $t1, 7                 # Multiply row 17 by 128 (bytes per bitmap row)
    add $t0, $t0, $t1
    lw $t2, hand_count              # Load the number of bubbles being held
    lw $t3, black                   # Load the black colour
    
erase_hand_A:
    beq $t2, $zero, move_A          # if no more bubbles, erase player 
    sw $t3, 0($t0)                  # Erase the current held bubble by drawing black
    addi $t0, $t0, -128             # Move up one row
    addi $t2, $t2, -1               # Decrement the number of bubbles held
    j erase_hand_A                  # keep going until all erased
    
move_A:
    jal erase_player
    addi $s1, $s1, -1               # Decrease the player's column by 1
    sw $s1, player_col              # save player column
    jal draw_player                 # draw player 
    
    lw $t0, ADDR_DSPL               # Load the bitmap address
    sll $t1, $s1, 2                 # Multiply the column by 4
    add $t0, $t0, $t1               # Add the column offset to address
    li $t1, 17                      # Set the starting bitmap row to 17
    sll $t1, $t1, 7                 # Multiply row 17 by 128
    add $t0, $t0, $t1               # address of the bottom held bubble
    lw $t2, hand_count              # Load the bubbles being held
    lw $t3, hand_colour             # Load the colour 
    
draw_hand_A:
    beq $t2, $zero, frame_done      # if none left, done
    sw $t3, 0($t0)                  # Draw a collected bubble at new pos.
    addi $t0, $t0, -128             # Move up one row
    addi $t2, $t2, -1               # decrement bubble
    j draw_hand_A               

respond_to_D:
    lw $s1, player_col              # load player col
    li $t8, 10                      # max col in right dir.
    beq $s1, $t8, game_loop         # if it's reached max. movement in left direction, don't do anything and go back to game loop

    # erase the bubbles by calculating bitmap position and putting black
    lw $t0, ADDR_DSPL               # Load the bitmap display base address
    sll $t1, $s1, 2                 # Multiply the player's column by 4 (bytes per pixel)
    add $t0, $t0, $t1               # Calculate the address of the bottom held bubble
    li $t1, 17                      # Set the starting bitmap row to 17
    sll $t1, $t1, 7                 # Multiply row 17 by 128 (bytes per bitmap row)
    add $t0, $t0, $t1
    lw $t2, hand_count              # Load the number of bubbles being held
    lw $t3, black                   # Load the black colour
    
erase_hand_D:
    beq $t2, $zero, move_D          # if no more bubbles, erase player 
    sw $t3, 0($t0)                  # Erase the current held bubble by drawing black
    addi $t0, $t0, -128             # Move up one row
    addi $t2, $t2, -1               # Decrement the number of bubbles held
    j erase_hand_D                  # keep going until all erased
    
move_D:
    jal erase_player
    addi $s1, $s1, +1               # increase the player's column by 1
    sw $s1, player_col              # save player column
    jal draw_player                 # draw player 
    
    lw $t0, ADDR_DSPL               # Load the bitmap address
    sll $t1, $s1, 2                 # Multiply the column by 4
    add $t0, $t0, $t1               # Add the column offset to address
    li $t1, 17                      # Set the starting bitmap row to 17
    sll $t1, $t1, 7                 # Multiply row 17 by 128
    add $t0, $t0, $t1               # address of the bottom held bubble
    lw $t2, hand_count              # Load the bubbles being held
    lw $t3, hand_colour             # Load the colour 
    
draw_hand_D:
    beq $t2, $zero, frame_done      # if none left, done
    sw $t3, 0($t0)                  # Draw a collected bubble at new pos.
    addi $t0, $t0, -128             # Move up one row
    addi $t2, $t2, -1   
    j draw_hand_D
    
  # throw when the W key is pressed
  respond_to_W:
    jal throw
    jal redraw_grid
    j frame_done
    
# s1 - player column in bitmap display 
# t0 - player column in grid display 
# t1 - bottom most rown in grid display 
# t2 - current cell index in grid display 
# t3 - current cell offsetted by 4 
# t4 - current cell address in grid display
respond_to_S:
    lw $s1, player_col              # load player col
    addi $t0, $s1, -4               # convert to grid column from bitmap since player_col is the bitmap "location"
    li $t1, 13                      # bottom most row which account for if bubbles occupy spaces past the third row
    
    mul $t2, $t1, 7                 # we need to convert from grid location to bitmap location using formula (row x total columns + current column)
    add $t2, $t2, $t0               # calculates the cell we want
    
    sll $t3, $t2, 2                 # byte offset since each cell is 4 bytes
    
    la $t4, grid                    # load start of grid
    
    add $t4, $t4, $t3               # add grid starting point to get the memory address
    lw $t6, black

    # Search upward for first non-empty cell
    lw $t5, 0($t4)                  # colour of cell
    beq $t5, $t6, check_row         # if black, keep searching

    sw $t5, hand_colour 
    jal grab_bubble
    j frame_done

check_row:
    beq $t1, $zero, game_loop

    addi $t1, $t1, -1               # move up one row
    addi $t4, $t4, -28              # move cell above in memory address (28 bytes per row)

    lw $t5, 0($t4)                  # get colour
    beq $t5, $t6, check_row         # if cell empty, check next row in same column

    lw $t7, hand_count
    beq $t7, $zero, first_bubble

    lw $t8, hand_colour
    bne $t5, $t8, draw_bubbles      # if different colour, don't collect

    j grab_bubble

first_bubble:
    sw $t5, hand_colour             # save colour of first bubble
    j grab_bubble
    
# $t5 - colour of bubble(s)
# $t4 - address of current cell
# $t1 - current row
grab_bubble:
    lw $t6, black
    sw $t6, 0($t4)                  # replaces current cell colour with black in memory 

    # Erase bubble from bitmap display
    lw $t7, ADDR_DSPL
    addi $t8, $t1, 4                # calculate bitmap display address
    sll $t8, $t8, 7                 # grid to bitmap
    add $t7, $t7, $t8               # multiply by 128 since 128 bytes per row

    lw $t8, player_col              # load player column
    sll $t8, $t8, 2                 # multiply by 4 since each cell is 4 bytes
    add $t7, $t7, $t8               # the actual bitmap address

    sw $t6, 0($t7)                  # store black in the address to showup on display

    lw $t8, hand_count              # increment number of bubbles player has collected 
    addi $t8, $t8, 1
    sw $t8, hand_count

    beq $t1, $zero, grab_done       # stop if we reached the top row

    addi $t1, $t1, -1               # move up
    addi $t4, $t4, -28              # move cell

    lw $t6, 0($t4)                  # check if next one has same colour 
    beq $t6, $t5, grab_bubble

    j grab_done
    
    
# t0 - bitmap address
# t3 - hand count of bubbles collected
# t4 - colour of bubbles
draw_bubbles:
    lw $t0, ADDR_DSPL               # starting bitmap display address

    lw $t1, player_col              # load player column
    sll $t1, $t1, 2                 # multiply by 4 to offset bytes
    add $t0, $t0, $t1               # add to starting address

    li $t1, 17                      # put bubbles in row 18 starting (right above player)
    sll $t2, $t1, 7                 # multiply by 128 since 128 bytes per row
    add $t0, $t0, $t2               # get the bitmap address

    lw $t3, hand_count              # load number of bubbles collected
    lw $t4, hand_colour             # load colour of bubbles

draw_bubbles_loop:
    beq $t3, $zero, game_loop       # when count is 0, done drawing

    sw $t4, 0($t0)                  # draw bubble
    addi $t0, $t0, -128             # decrement address to get next row right on top
    addi $t3, $t3, -1               # decrement hand count

    j draw_bubbles_loop

grab_done:
    j draw_bubbles
    
# draws border
# s0 - RA to main address
# t1 - start column
# t2 - start row
# t3 - length of line
draw_border:
    add $s0, $ra, $zero      # Save return address because we have nested calls
    
    lw $t0, ADDR_DSPL   # address of bitmap
    lw $t5, white       # colour of border

    # Top border length is 9 since 7 from bubbles and 2 extra for sides
    li $t1, 3
    li $t2, 3
    li $t3, 9
    jal draw_horizontal_line        # Note: new RA value stored in ra

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

    add $ra, $s0, $zero      # Restore saved return address so that we return to proper instruction    
    jr $ra


# Draws a horizontal line
# $t0 - display base address
# $t1 - starting X coordinate
# $t2 - starting Y coordinate
# $t3 - line length
# $t5 - colour
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
    jr $ra              # jump back to address in RA


# Draws a vertical line
# $t0 - display base address
# $t1 - starting X coordinate
# $t2 - starting Y coordinate
# $t3 - line length
# $t5 - colour

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
    
# t1- start column
# t2 - start row
# t3 - length of player line
draw_player:
    add $s0, $ra, $zero         # save address

    lw $t0, ADDR_DSPL
    lw $t5, orange

    lw $t1, player_col
    lw $t2, player_row
    li $t3, 2

    jal draw_vertical_line

    add $ra, $s0, $zero          # restore address
    jr $ra
    
     
# t1- start column
# t2 - start row
# t3 - length of player line   
erase_player:
    add $s0, $ra, $zero         # save address

    lw $t0, ADDR_DSPL
    lw $t5, black

    lw $t1, player_col
    lw $t2, player_row
    li $t3, 2

    jal draw_vertical_line

    add $ra, $s0, $zero          # restore address
    jr $ra

# returns $v0 = 1 if any cell in row 13 (the last row) is filled, else 0
# $t0 - address of current cell, $t1 - stop address, $t2 - cell colour (to check for bubbles)
check_game_over:
    la   $t0, grid
    addi $t0, $t0, 364 # first cell of row 13
    la   $t1, grid
    addi $t1, $t1, 392 # one past the last cell
    
cgo_loop:
    bge  $t0, $t1, cgo_safe # checked all 7 cells, safe
    lw   $t2, 0($t0)        # load current cell
    bne  $t2, $zero, cgo_over # there is a bubble, so game over!
    addi $t0, $t0, 4
    j    cgo_loop

# the game is over here (as $v0 = 1)
cgo_over:
    li   $v0, 1
    jr   $ra

# the game continues (as $v0 = 0)    
cgo_safe:
    li   $v0, 0
    jr   $ra

# fills row 0 with 7 random bubble colours
# $t0 - address of current cell, $t1 - cells left, $t2 - colour, $t3 - colour address
gen_row:
    la   $t0, grid # starting cell
    li   $t1, 7    # 7 cells per row
gen_loop:
    li   $v0, 42 # ask for random number
    li   $a0, 0 # random generator 0
    li   $a1, 4 # max is 4
    syscall     # so $a0 = random number from 0 to 3
    sll  $a0, $a0, 2    # turn the number into an offset into the colour list
    la   $t3, bubble_colours 
    add  $t3, $t3, $a0   # point at chosen colour
    lw   $t2, 0($t3)     # load the colour
    sw   $t2, 0($t0)     # put the colour in the grid
    addi $t0, $t0, 4     # go to next cell
    addi $t1, $t1, -1    # one fewer cell left
    bgtz $t1, gen_loop   
    jr   $ra

# pushes every row down one and adds a new random row 0
# sets game_over = 1 instead if the last row is already filled
# $t0 - address of current cell, $t1 - cell colour, $t2 - start of grid
advance_rows:
    addi $sp, $sp, -4 # make room in stack
    sw   $ra, 0($sp) # save return address (since we are calling other functions)

    jal  check_game_over   # check if bottom row is full
    beq  $v0, $zero, do_shift # if not, push rows down 
    li   $t0, 1  
    sw   $t0, game_over # game over!
    j    advance_end   # skip the shifting

# push each row down one
do_shift:
    la   $t2, grid  # stop point
    addi $t0, $t2, 360 # last cell of row 12 

shift_loop:
    blt  $t0, $t2, shift_done # (stop once every row has moved down)
    lw   $t1, 0($t0)   # read the cell
    sw   $t1, 28($t0)  # write it one row lower
    addi $t0, $t0, -4  # go back one cell
    j    shift_loop

shift_done:
    jal  gen_row # fill top row with new random bubbles

# end of row advance
advance_end:
    lw   $ra, 0($sp)  
    addi $sp, $sp, 4
    jr   $ra

# $t0 - current cell, $t1 - cell colour, $t2 - held colour, $t3 - held count (how many bubbles are held), $t4 will be grid, then finish line
throw:
  addi $sp, $sp, -4
  sw   $ra, 0($sp) # save return address again
  
  lw $t3, hand_count
  beq $t3, $0, throw_end
  lw $t0, player_col  # read the player's column
  addi $t0, $t0, -4   # player_col is the bitmap column, so -4 gives the grid column
  sll $t0,$t0, 2      # column offset (player column x 4)
  la $t4, grid 
  add $t0, $t0, $t4 
  addi $t4, $t4, 392 # the finish line 


  find_empty:
    bge $t0, $t4, throw_end # reached the end
    lw $t1, 0($t0)          # read current cell
    beq $t1, $zero, place_bubbles # found the empty spot
    addi $t0, $t0, 28
    j find_empty

place_bubbles:
  lw $t2, hand_colour

place_loop:
  beq $t3, $zero, reset_hands # no bubbles
  bge $t0, $t4, reset_hands   # reached finish line
  sw $t2, 0($t0)              # update cell colour
  addi $t0, $t0, 28
  addi $t3, $t3, -1
  j place_loop

# resets hand_count and hand_colour
reset_hands: 
  sw $zero, hand_count
  sw $zero, hand_colour

jal matches # check for 3+ in this column
  
# end
throw_end:
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra

# check for 3 in a row or more
# $t0 - walker address, $t1 - run start, $t2 - run colour, $t3 - run length, $t4 - current cell colour, $t5 - finish line 
# (a run being the number of same-coloured cells in a row!)
matches:
  lw $t0, player_col  # read the player's column
  addi $t0, $t0, -4   # player_col is the bitmap column, so -4 gives the grid column
  sll $t0,$t0, 2      # column offset (player column x 4)
  la $t5, grid 
  add $t0, $t0, $t5 
  addi $t5, $t5, 392 # the finish line
  lw $t4, 0($t0)  # read first cell's colour
  beq $t4, $zero, matches_end # it's empty
  add $t1, $t0, $zero # start counting the first run
  add $t2, $t4, $zero
  li $t3, 1

matches_loop:
  addi $t0, $t0, 28
  bge $t0, $t5, run_end
  lw $t4, 0($t0) # load the current cell colour
  beq $t4, $0, run_end  # empty cell, end run
  bne $t4, $t2, run_end # different colour, end run
  addi $t3, $t3, 1 # another cell of the same colour, so increase run by 1
  j matches_loop

run_end:
    blt $t3, 3, new_run # restart run when length < 3
    j clear_loop # clear run otherwise
  
clear_loop:
    beq $t3, $zero, new_run # run restarts (a new one)
    sw $zero, 0($t1) # clear this bubble
    addi $t1, $t1, 28 # move down one row
    addi $t3, $t3, -1 # decrease run length by 1
    j clear_loop
      
new_run:
  bge $t0, $t5, matches_end # reached finish line, end run
  beq $t4, $zero, matches_end # empty cell, end run_end
  add $t1, $t0, $zero # update run start to where walker is
  add $t2, $t4, $zero # update run colour to current cell's colour
  li $t3, 1 # reset run length to 1
  j matches_loop 

# done     
matches_end:
  jr $ra

# redraws the whole grid on the screen, painting empty cells black
# $t0 - current grid cell, $t1 - row, $t2 - column, $t3 - bitmap address
# $t4, $t5 - bitmap row/col, $t6 - pixel address, $t7 - cell colour
redraw_grid:                             
    la   $t0, grid  # setup (start at first cell of grid)                     
    lw   $t3, ADDR_DSPL # get screen's starting address
    li   $t1, 0 # start at row 0
    li   $t2, 0 # start at column 0

redraw_loop:                               
    addi $t4, $t1, 4  # board starts 4 squres down                   
    addi $t5, $t2, 4 # 4 squares in
    sll  $t6, $t4, 5 # x32 for 32 squares per screen row
    add  $t6, $t6, $t5 # screen column = which squre on the screen
    sll  $t6, $t6, 2 # x4 for number of bytes
    add  $t6, $t6, $t3 # screen start is the exact address to paint!

    lw   $t7, 0($t0) # read cell's colour from grid
                                          
    sw   $t7, 0($t6) # paint it on screen (black if empty)
                                          
    addi $t0, $t0, 4 # next grid cell
    addi $t2, $t2, 1 # next column
    blt  $t2, 7, redraw_loop # in same row? keep going

    li   $t2, 0 # back to first column
    addi $t1, $t1, 1 # next row
    blt  $t1, 14, redraw_loop # rows left? keep going

    jr   $ra

  

