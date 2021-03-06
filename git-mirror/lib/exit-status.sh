#!/bin/bash
#===============================================================================
#
#          FILE:  exit-status.sh
#
#         USAGE:  . exit-status.sh
#
#   DESCRIPTION:  Include this library in any script to execute commands and
#                 handle exit status in a controlled way.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@ericsson.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-06-01 09:00:00 CET
#      REVISION:  ---
#       CHANGES:  ---
#
#      EXAMPLES:  run_cmd
#                 run_cmd "ls -l" -c
#                 run_cmd
#                 run_cmd "your_momma sux" -c
#                 run_cmd "fdisk" -c
#                 run_cmd "ls -lh"
#                 run_cmd
#                 handle_exit
#
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

    # Get array length of return code status.
    local rc_length=${#return_code[@]}
    # Get array length of commands.
    local commands_length=${#commands[@]}

    # If an argument -k is given to the command then the program should
    # continue to run, else the command is given without an argument and
    # should exit the program if the command fails.
    if [ $# -eq 1 ]; then
        if [ ${return_code[${rc_length}-1]} -ne 0 ]; then
            print_summary
            printf "ERROR: Failed to execute command #%d: %s\n" $index "${commands[${commands_length}-1]}"
            exit "${return_code[${rc_length}-1]}";
        fi
    fi
    if [ $# -ge 2 ]; then
        case "$2" in
        -c) echo "Will not exit program if command fails..."
            ;;
        *)  echo "Invalid argument to command!"; exit 1
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
#
# Usage: print_summary          # Print summary of exit status and commands
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
#
# Usage: handle_exit
#===============================================================================
function handle_exit()
{
    local return_status=0
    print_summary
    for index in ${!return_code[*]}; do
        if [ ${return_code[$index]} -ne 0 ]; then
            printf "ERROR: Failed to execute command #%d: %s\n" $index "${commands[$index]}"
            return_status=1
        fi
    done
    exit ${return_status}
}

# Initialize our global array of return status
return_code=()

# Initialize our global array of commands
commands=()
