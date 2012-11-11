#!/bin/bash
#===============================================================================
# The point of this program is to execute commands in a controlled way and
# return an exit status to jenkins so that the gerrit_trigger can verify the
# patchset in a proper way.
#===============================================================================

#===============================================================================
# Function will run any command and save its exit status. If the argument -m has
# been given and the command returns an error exit status, then print out the
# command summary and exit the program immediately.
#
# Usage: run_cmd <command>      # Run command but exit program if command fails
#        run_cmd <command> -c   # Continue running program even if command fails
#===============================================================================
function run_cmd()
{
	# Execute the command and save the exit status.
	eval ${1}
	add_status

	# Append the command to list of commands. Basically just save a history
	# of commands that has been executed.
	commands+=("${1}")

	# If an argument -k is given to the command then the program should
        # continue to run, else the command is given without an argument and
        # should exit the program if the command fails.
	if [ $# -eq 1 ]; then
		if [ ${return_code[-1]} -ne 0 ]; then
			print_summary
			printf "ERROR: Failed to execute command #%d: %s\n" $index "${commands[-1]}"
			exit "${return_code[-1]}";
		fi
	fi
	if [ $# -ge 2 ]; then
		case "$2" in
		-c)	echo "Will not exit program if command fails..."
			;;
		*)	echo "Invalid argument to command!"; exit 1
			;;
		esac
	fi
}

#===============================================================================
# Function appends the exit status of an evaluated command to an array.
# Usage: <execute command>
#        add_status
#===============================================================================
function add_status()
{
	local status=$(echo $?)
	return_code+=($status)
}

#===============================================================================
# Function prints a summary of the currently executed commands.
#===============================================================================
function print_summary()
{
	echo "#==============================================================================="
	echo "# SUMMARY:"
	for index in ${!return_code[*]}; do
		printf "#%4d: Exit status [%3d], Command = %s\n" $index ${return_code[$index]} "${commands[$index]}"
	done
	echo "#==============================================================================="
}

#===============================================================================
# If a command in the list failed to execute and returned an error exit status,
# then exit the whole program with an unsuccessful exit code.
#===============================================================================
function handle_exit()
{
	print_summary
	for index in ${!return_code[*]}; do
		if [ ${return_code[$index]} -ne 0 ]; then
			printf "ERROR: Failed to execute command #%d: %s\n" $index "${commands[$index]}"
			exit "${return_code[$index]}";
		fi
	done
}

# Initialize our global array of return status
return_code=()
# Initialize our global array of commands
commands=()

run_cmd
run_cmd "ls -l" -c
run_cmd
run_cmd "your_momma sux" -c
run_cmd "fdisk" -c
run_cmd "ls -lh"
run_cmd

# Print a nice summary and return exit status.
handle_exit
