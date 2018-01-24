#
# FILE:		$File$
# AUTHOR:	Daniel Slapelis
# CONTRIBUTORS:
#		Me, Myself, and I-
#
# DESCRIPTION:
#	This program is an implementation of dijkstra's algorithm in
#	MIPS assembly.
#
# ARGUMENTS:
#	None
#
# INPUT:
#	Takes in a list of directed nodes from STDIN.
#	See https://www.cs.rit.edu/~csci250/project/171/proj171.html
#	for details on the input.
#
# OUTPUT:
#	A matrix of the dijkstra's algorithm path, as well as a chart showing
#	the path for each node.
#
# REVISION HISTORY:
#	November 2017	- Initial implementation
#

#----------------------------

#
# NUMERIC CONSTANTS
#

PRINT_STRING = 4
READ_INT = 5
PRINT_INT = 1
INFINITY = 2147483646

#
# DATA AREAS
#

	.data 
	.align	2		# word data must be on word boundries

#
# DATA ARRAYS
#

edges:
	.space	4800	# for edges
grid:
	.space	4800	# for 400 (20x20) positions of data
dist:
	.space	100	# for 20 distances
sptSet:
	.space	100	# for 20 true/false (1/0)
path:
	.space	100	# path for dijkstra's
nmsrc:
	.space	80	# for n, m, and src

#
# BOARD STRINGS
#

board_dash:
	.asciiz "-"
board_space_1:
	.asciiz " "
board_space_2:
	.asciiz "  "
board_space_3:
	.asciiz "   "
board_space_4:
	.asciiz "    "
board_space_6:
	.asciiz "      "
board_space_7:
	.asciiz "       "
board_dijkstra_top:
	.asciiz "Node    Path : Distance\n"


#
# ERROR STRINGS
#

error1:
	.asciiz	"Invalid number of nodes. Must be between 1 and 20.\n"
error2:
	.asciiz "Invalid number of edges. Must be between 0 and 400.\n"
error3: 
	.asciiz	"Invalid source for edge.\n"
error4:
	.asciiz	"Invalid destination for edge.\n"
error5:
	.asciiz	"Invalid weight for edge.\n"
error6:
	.asciiz	"Invalid starting node.\n"

#
# MISC. STRINGS
#
prompt1:
	.asciiz "Your input is..."
newline:
	.asciiz "\n"
comma:
	.asciiz ", "
colon:
	.asciiz ":"
unreachable:
	.asciiz "unreachable\n"
#
# CODE AREAS
#

	.text
	.align	2
#
# EXECUTION BEGINS HERE
#
main:
	jal	read_nodes
	la	$s3, nmsrc		# array containing n, m, and src
	lw	$s1, 0($s3)		# n
	lw	$s2, 4($s3)		# m
	lw	$s3, 8($s3)		# src

	move	$a0, $s1
	move	$a1, $s2
	jal	setup_grid		# adds data to grid array
	
	move	$a0, $s1
	jal	print_grid		# prints grid array data
	
	move	$a0, $s1
	move	$a1, $s3
	jal	dijkstra		# performs dijkstra's alg functions
	
	move	$a0, $s1
	move	$a1, $s3
	jal	print_nodes

	li	$v0, 10
	syscall

#
# Name:         read_nodes
# Description:  reads integers from STDIN, and populates the edges array with
#			node edge data. also populates nmsrc with n, m, and src
# Arguments:    none
# Returns:      none
# Destroys:     none
#
read_nodes:
	addi	$sp, $sp, -36	# $sp = $sp + 36
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)

	la	$s0, edges		# edges array pointer		 
	
	li	$v0, READ_INT
	syscall
	
	addi	$t0, $zero, 20
	bgt	$v0, $t0, num_node_err
	ble	$v0, $zero, num_node_err

	move 	$s7, $v0		# total number of nodes

	li	$v0, READ_INT
	syscall
	
	addi	$t0, 400
	bgt	$v0, $t0, num_edge_err
	ble	$v0, $zero, num_edge_err

	move	$s6, $v0		# total number of edges
	add	$t0, $zero, $zero
read_data:
	beq	$t0, $s6, done_read_data	
	
	li	$v0, READ_INT		# read in integer from STDIN
	syscall

	bge	$v0, $s7, invl_src_err
	blt	$v0, $zero, invl_src_err
	
	sw	$v0, 0($s0)		# store int in array

	li	$v0, READ_INT
	syscall

	bge	$v0, $s7, invl_dst_err
	blt	$v0, $zero, invl_dst_err

	sw	$v0, 4($s0)

	li	$v0, READ_INT
	syscall

	addi	$t1, $zero, 1000
	bgt	$v0, $t1, invl_weight_err
	ble	$v0, $zero, invl_weight_err

	sw	$v0, 8($s0)

	addi	$s0, $s0, 12
	addi	$t0, $t0, 1

	j	read_data		# jump to read_data
done_read_data:
	la	$s4, nmsrc
	
	sw	$s7, 0($s4)
	sw	$s6, 4($s4)

	li	$v0, READ_INT
	syscall
	
	bge	$v0, $s7, invl_strt_err
	blt	$v0, $zero, invl_strt_err

	sw	$v0, 8($s4)

	lw	$s7, 32($sp)
	lw	$s6, 28($sp)
	lw	$s5, 24($sp)
	lw	$s4, 20($sp)
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 36
	jr	$ra					# jump to $ra
	

#
# Name:         setup_grid
# Description:  sets up grid as 1D array with node data
# Arguments:    a0:     total number of nodes, n
#               a1:     total number of edges, m
# Returns:      none
# Destroys:     a lot of t registers
#
setup_grid:
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)
 
	move	$s0, $a0		# number of nodes, n
	la	$s2, grid

	addi	$t7, $t7, 99
	sw	$t7, 0($s2)

	add	$t1, $zero, $zero
setup_grid_loop_y:
	beq	$t1, $s0, setup_grid_loop_y_done
	add	$t2, $zero, $zero
setup_grid_loop_x:
	beq	$t2, $s0, setup_grid_loop_x_done
	
	add	$t3, $zero, $zero
	la	$s1, edges		# load edges array
search_edges:
	beq	$t3, $a1, search_done

	lw	$t4, 0($s1)		# check y
	bne	$t1, $t4, edge_ne

	lw	$t4, 4($s1)		# check x
	bne	$t2, $t4, edge_ne

	lw	$t4, 8($s1)		# store weight
	sw	$t4, 0($s2)

	addi	$s2, $s2, 4
	addi	$t2, $t2, 1
	j	setup_grid_loop_x
edge_ne:
	addi	$s1, $s1, 12
	addi	$t3, $t3, 1
	j	search_edges
search_done:
	sw	$zero, 0($s2)
	addi	$s2, $s2, 4
	addi	$t2, $t2, 1
	j	setup_grid_loop_x

setup_grid_loop_x_done:
	addi	$t1, $t1, 1		# increment y counter
	j	setup_grid_loop_y

setup_grid_loop_y_done:
        lw      $s7, 32($sp)
        lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
        jr      $ra	# jump to $ra

#
# Name:         print_grid
# Description:  prints the matrix of nodes in grid array
# Arguments:    a0:     total number of nodes, n
# Returns:      none
# Destroys:     a lot of t registers
#
print_grid:
	addi    $sp, $sp, -36   # $sp = $sp + 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)
	
	move	$s0, $a0			# move x/y length
	move	$s2, $a0			# store the x/y length

	la	$s3, grid

	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall

	move	$a0, $s0
	jal	print_top_row

	add	$t0, $zero, $zero
print_grid_data:
	beq	$t0, $s2, print_grid_data_done

	li	$v0, PRINT_STRING
	la	$a0, board_space_1
	syscall

	slti	$t1, $t0, 10
	beq	$t1, $zero, y_gt_ten

	li	$v0, PRINT_STRING		# print another space and then
	la	$a0, board_space_1		# print our integer
	syscall

	li	$v0, PRINT_INT
	move	$a0, $t0
	syscall

	j	grid_data_cont
y_gt_ten:
	li	$v0, PRINT_INT
	move	$a0, $t0
	syscall
grid_data_cont:
	add	$t1, $zero, $zero
print_grid_data_loop:				# prints row of nodes
	beq	$t1, $s2, print_grid_data_loop_done	        
	lw	$t2, 0($s3)
	slti	$t3, $t2, 10
	bne	$t3, $zero, data_lt_ten
	slti	$t3, $t2, 100
	bne	$t3, $zero, data_lt_hund
						# if we are here, data is
						# 100 < x < 1000

	li	$v0, PRINT_STRING		# we will only print 1 space
						# before our data here
	la	$a0, board_space_1
	syscall

	li	$v0, PRINT_INT
	move	$a0, $t2
	syscall
	
	addi	$s3, $s3, 4
	addi	$t1, $t1, 1
	j	print_grid_data_loop
data_lt_ten:					# 3 spaces before data if
						# it is < 10
	li	$v0, PRINT_STRING
	la	$a0, board_space_3
	syscall
	
	beq	$t2, $zero, data_is_zero

	li	$v0, PRINT_INT
	move	$a0, $t2
	syscall
	j	data_isnt_zero
data_is_zero:					# all zeros in grid ar printed
						# as a dash
	li	$v0, PRINT_STRING
	la	$a0, board_dash
	syscall
data_isnt_zero:					# increment and repeat
	addi	$s3, $s3, 4
	addi	$t1, $t1, 1
	j	print_grid_data_loop
data_lt_hund:					# if node weight is 10 < x < 100
	li	$v0, PRINT_STRING		# print 2 spaces before it
	la	$a0, board_space_2
	syscall

	li	$v0, PRINT_INT
	move	$a0, $t2
	syscall

	addi	$s3, $s3, 4
	addi	$t1, $t1, 1
	j	print_grid_data_loop
print_grid_data_loop_done:
	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall

	addi	$t0, $t0, 1		# increment
	j	print_grid_data
print_grid_data_done:
	lw      $s7, 32($sp)
        lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
        jr      $ra                     # jump to $ra

#
# Name:         print_top_row
# Description:  prints top row of nodes matrix
# Arguments:    a0:     number of nodes, n
# Returns:      none
# Destroys:     none
#
print_top_row:
	addi    $sp, $sp, -36   # $sp = $sp + 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)

	move	$s0, $a0
	
	li	$v0, PRINT_STRING
	la	$a0, board_space_3
	syscall

	add	$t0, $zero, $zero
print_top_columns:
	beq	$t0, $s0, print_top_columns_done

	slti	$t1, $t0, 10
	beq	$t1, $zero, gt_ten

	li	$v0, PRINT_STRING
	la	$a0, board_space_3
	syscall

	li	$v0, PRINT_INT		# print column integer
	move	$a0, $t0
	syscall
	j	print_top_col_cont
gt_ten:
	li	$v0, PRINT_STRING
	la	$a0, board_space_2
	syscall
	
	li	$v0, PRINT_INT
	move	$a0, $t0
	syscall
print_top_col_cont:
	addi	$t0, $t0, 1
	j	print_top_columns
print_top_columns_done:
	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall
        
	lw      $s7, 32($sp)
        lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
	jr	$ra

#
# Name:         dijkstra
# Description:  main function which calls all the functions that complete
#			dijkstra's algorithm
# Arguments:    a0:     total number of nodes, n
#               a1:     source node S
# Returns:      none
# Destroys:     $t0 - $t7
#
dijkstra:
        addi    $sp, $sp, -36   # $sp = $sp + 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)

	move	$s0, $a0		# number of node n, V
	move	$s1, $a1		# source node S

	move	$a0, $s0
	jal	populate_dijkstra_arrays
	
	addi	$t0, $zero, 4		# 4 bytes
	mul	$t0, $t0, $s1		# 4 bytes * source index
	la	$t1, dist	
	add	$t1, $t1, $t0	
	sw	$zero, 0($t1)		# store 0 at dist[S]

	add	$s2, $zero, $zero	# v
	
for_find_short_path:
	beq	$s2, $s0, find_short_path_done

	move	$a0, $s0
	jal	min_distance
	move	$s4, $v0		# u in s4

	la	$t0, sptSet
	addi	$t1, $zero, 4
	mul	$t1, $t1, $s4		# bytes past sptSet for u
	addi	$t2, $zero, 1
	add	$t0, $t0, $t1
	sw	$t2, 0($t0)		# put 1 in sptSet[u]

	move	$a0, $s0		# give V
	move	$a1, $s4		# give u
	jal	adjacent_verticies

	addi	$s2, $s2, 1
	j	for_find_short_path
find_short_path_done:
	addi	$t0, $zero, 5

	lw	$s7, 32($sp)
        lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
        jr      $ra

#
# Name:         adjacent_verticies
# Description:  populates the dist and path grids from dijkstra's algorithm
# Arguments:    a0:     total number of nodes, V
#               a1:     current minimun index, u
# Returns:      none
# Destroys:     $t0 - $t7
#
adjacent_verticies:
        addi    $sp, $sp, -36   # $sp = $sp + 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)

	move	$s0, $a0		# store V 
	move	$s1, $a1		# store u
	la	$s2, sptSet
	la	$s7, path

	add	$t0, $zero, $zero
adj_V_loop:
	beq	$t0, $s0, adj_V_done

	lw	$t1, 0($s2)		# sptSet[v]
	bne	$t1, $zero, break_adj_V # sptSet[v] == 0

	mul	$t1, $s1, $s0		# u * m
	add	$t1, $t1, $t0		# u * m + v <-- this is our pos in grid

	la	$s3, grid		# load grid	
	addi	$t2, $zero, 4
	mul	$t1, $t1, $t2		# byte position for grid [u][v]
				
	add	$s3, $s3, $t1
	lw	$t1, 0($s3)		# get element at grid[u][v]
	beq	$t1, $zero, break_adj_V	# if grid[u][v] != 0
	
	addi	$t2, $zero, 4
	mul	$t2, $t2, $s1		# byte position for dist[u]
	la	$t3, dist
	add	$t3, $t3, $t2
	lw	$t2, 0($t3)		# dist[u] value

	addi	$t3, $zero, INFINITY	# infinity value
	beq	$t2, $t3, break_adj_V	# dist[u] != infinity
	
	addi	$t3, $zero, 4
	mul	$t3, $t3, $t0		# byte position for dist[v]
	la	$t4, dist
	add	$t4, $t4, $t3		
	lw	$t4, 0($t4)		# dist[v]

	add	$t5, $t2, $t1		# dist[u] + grid[u][v]
	
	slt	$t6, $t5, $t4		# dist[u] + grid[u][v] < dist[v]
	beq	$t6, $zero, break_adj_V

	addi	$t2, $zero, 4
	mul	$t2, $t2, $t0		# dist[v] bytes
	la	$t3, dist
	add	$t3, $t3, $t2		# dist[v] position
	sw	$t5, 0($t3)

	addi	$t2, $zero, 4
	mul	$t2, $t2, $t0		# path[v] bytes
	la	$t5, path
	add	$t5, $t5, $t2		# path[v]
	sw	$s1, 0($t5)		# store path[v]

break_adj_V:
	addi	$t0, $t0, 1
	addi	$s2, $s2, 4
	j	adj_V_loop
adj_V_done:
        lw      $s7, 32($sp)
        lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
        jr      $ra
#
# Name:         print_nodes
# Description:  prints the second half of STDOUT with each node, its path,
#			and its weight
# Arguments:    a0:     total number of nodes, n
#               a1:     source node, S
# Returns:      none
# Destroys:     $t0 - $t7
#
print_nodes:
        addi    $sp, $sp, -36   # $sp = $sp + 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)
      	
	move	$s0, $a0		# store n
	move	$s1, $a1		# store origin

	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall	

	li	$v0, PRINT_STRING	# print top of nodes board
	la	$a0, board_dijkstra_top
	syscall
	        
	add	$s2, $zero, $zero
pn_loop:
	beq	$s2, $s0, pn_loop_done

	li	$v0, PRINT_INT
	move	$a0, $s2
	syscall

	slti	$s3, $s2, 10
	beq	$s3, $zero, node_ge_ten

	li	$v0, PRINT_STRING
	la	$a0, board_space_7
	syscall
	j	pn_loop_cont
node_ge_ten:				# for if node is >= 10
	li	$v0, PRINT_STRING
	la	$a0, board_space_6
	syscall
pn_loop_cont:
	
	add	$v0, $zero, $zero
	move	$a0, $s2
	move	$a1, $s1
	jal	print_path

	addi	$t0, $zero, -1
	beq	$t0, $v0, pn_unreachable	# if v0 is -1 the path is
						# unreachable.

	li	$v0, PRINT_STRING
	la	$a0, colon
	syscall

	li	$v0, PRINT_STRING
	la	$a0, board_space_1
	syscall
	
	la	$t0, dist
	addi	$t1, $zero, 4
	mul	$t1, $t1, $s2
	add	$t0, $t0, $t1
	lw	$t0, 0($t0)

	li	$v0, PRINT_INT			# prints the weight to this node
	move	$a0, $t0
	syscall
	
	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall

	j	reachable
pn_unreachable:					# unreachable case
	li	$v0, PRINT_STRING
	la	$a0, unreachable
	syscall

reachable:					# continue
	addi	$s2, $s2, 1
	j	pn_loop
pn_loop_done:					# newline for bottom of screen
	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall

	lw	$s7, 32($sp)
	lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
        jr      $ra

#
# Name:         print_path
# Description:  recursive function to print the path from our destination to
#			our source node.
# Arguments:    a0:     destination node, j
#               a1:     source node, S
# Returns:      $v0:	will contain -1 if the path is unreachable
# Destroys:     $t0 - $t7
#
print_path:
        addi    $sp, $sp, -36   # $sp = $sp + 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)

	move	$s0, $a0
	move	$s1, $a1

	beq	$s0, $s1, dst_is_src

	la	$s2, path
	addi	$s3, $zero, 4
	mul	$s3, $s3, $s0		# path[j] bytes

	add	$s2, $s2, $s3
	lw	$s3, 0($s2)		# path[j]

	addi	$t0, $zero, -1
	beq	$s3, $t0, pp_unreachable

	li	$v0, PRINT_INT
	move	$a0, $s3
	syscall

	li	$v0, PRINT_STRING
	la	$a0, board_space_1
	syscall

	move	$a0, $s3
	move	$a1, $s1
	addi	$v0, $v0, 1
	jal	print_path
dst_is_src:
	j	pp_cont
pp_unreachable:
	addi	$v0, $zero, -1
pp_cont:
        lw      $s7, 32($sp)
        lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
        jr      $ra

#
# Name:         populate_dijkstra_arrays
# Description:  populates sptSet with 0's, dist with INFINITY, and path with -1
# Arguments:    a0:     total number of nodes, V
# Returns:      none
# Destroys:     $t0 - $t7
#
populate_dijkstra_arrays:
	addi	$sp, $sp, -20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)

	move	$s0, $a0
	la	$s1, dist
	la	$s2, sptSet
	la	$s3, path	

	add	$t0, $zero, $zero
populate:
	beq	$t0, $s0, populate_done

	addi	$t1, $zero, INFINITY
	sw	$t1, 0($s1)
	sw	$zero, 0($s2)
	addi	$t1, $zero, -1
	sw	$t1, 0($s3)		# path[0] == -1

	addi	$t0, $t0, 1
	addi	$s1, $s1, 4
	addi	$s2, $s2, 4
	addi	$s3, $s3, 4
	j	populate
populate_done:
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra

#
# Name:         min_distance
# Description:  finds the current minimum distance index
# Arguments:    a0:     total number of nodes, V
# Returns:      none
# Destroys:     $t0 - $t7
#
min_distance:
        addi    $sp, $sp, -36   # $sp = $sp + 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)

	move	$s0, $a0		# store V

	addi	$t0, $zero, INFINITY	# curr distance
	addi	$t1, $zero, -1		# curr index

	la	$s1, sptSet
	la	$s2, dist

	add	$t2, $zero, $zero	# counter v
for_min_dist:
	beq	$t2, $s0, for_min_dist_done	# when v == V stop

	lw	$t3, 0($s1)			# sptSet[v]
	bne	$t3, $zero, break_min		# sptSet[V] == 0
	lw	$t3, 0($s2)			# dist[v]
	bge	$t3, $t0, break_min		# branch if dist[v]  >= curr dist

	add	$t0, $zero, $t3			# min_dist = dist[v]
	add	$t1, $zero, $t2			# min index = v
break_min:
	addi	$s1, $s1, 4
	addi	$s2, $s2, 4
	addi	$t2, $t2, 1
	j	for_min_dist
for_min_dist_done:
	move	$v0, $t1

        lw      $s7, 32($sp)
        lw      $s6, 28($sp)
        lw      $s5, 24($sp)
        lw      $s4, 20($sp)
        lw      $s3, 16($sp)
        lw      $s2, 12($sp)
        lw      $s1, 8($sp)
        lw      $s0, 4($sp)
        lw      $ra, 0($sp)
        addi    $sp, $sp, 36
        jr      $ra


# ERROR PRINTING

#
# Name:         num_node_err
# Description:  prints an error stating there is an invalid number of nodes
#			and quits.
# Arguments:    none
# Returns:      none
# Destroys:     none
#
num_node_err:
	li	$v0, PRINT_STRING
	la	$a0, error1
	syscall

	li	$v0, 10
	syscall

#
# Name:         num_edge_err
# Description:  prints an error stating there is an invalid number of edges
#                       and quits.
# Arguments:    none
# Returns:      none
# Destroys:     none
#
num_edge_err:
	li	$v0, PRINT_STRING
	la	$a0, error2
	syscall

	li	$v0, 10
	syscall

#
# Name:         invl_src_err
# Description:  prints an error stating the source is invalid
# Arguments:    none
# Returns:      none
# Destroys:     none
#
invl_src_err:
	li	$v0, PRINT_STRING
	la	$a0, error3
	syscall

	li	$v0, 10
	syscall

#
# Name:         invl_dst_err
# Description:  prints an error stating the destination is invalid
# Arguments:    none
# Returns:      none
# Destroys:     none
#
invl_dst_err:
	li	$v0, PRINT_STRING
	la	$a0, error4
	syscall
	
	li	$v0, 10
	syscall

#
# Name:         invl_weight_err
# Description:  prints an error stating the weight is invalid
# Arguments:    none
# Returns:      none
# Destroys:     none
#
invl_weight_err:
	li	$v0, PRINT_STRING
	la	$a0, error5
	syscall
	
	li	$v0, 10
	syscall

#
# Name:         invl_strt_err
# Description:  prints an error stating the starting node is invalid
# Arguments:    none
# Returns:      none
# Destroys:     none
#
invl_strt_err:
	li	$v0, PRINT_STRING
	la	$a0, error6
	syscall

	li	$v0, 10
	syscall
