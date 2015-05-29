#!/bin/bash
#===============================================================================
#
#          FILE:  git-mirror.sh
#
#         USAGE:  ./git-mirror.sh
#
#   DESCRIPTION:  Mirror and syncronize repos from one target server to
#                 destination server.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@ericsson.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-05-21 09:00:00 CET
#      REVISION:  ---
#       CHANGES:  ---
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
    echo ""
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

#===============================================================================
# Check if a variable is set
# Usage: is_set my_var          # Check if my_var exists
#===============================================================================
function is_set()
{
    [[ -n "${1}" ]] && test -n "$(eval "echo "\${${1}+x}"")"
}

#===============================================================================
# Function will print out help and usage
#
# Usage: print_usage
#===============================================================================
function print_usage()
{
    echo "Usage: ${prog_name} [--help] [--debug] [--clone]

${prog_name} is a program used with git bisect to automate testing

Options:
    -h or --help        Show this help text
    -d or --debug       Show debug information
    -c or --clone       Clone bare repositories

Report bugs to samuel.gabrielsson@gmail.com" >&2
}

# Initialize our global array of return status
return_code=()

# Initialize our global array of commands
commands=()

# Program name
prog_name=$(basename "$0")

#===============================================================================
# Parse arguments from commandline using bash builtin getopts
#===============================================================================
#do_clone=false

#while getopts dha:c arg; do
#    case ${arg} in
#    d)
#        # Turn on bash debug mode
#        set -x
#        ;;
#    h)
#        # Print out help message
#        print_usage
#        exit 0
#        ;;
#    a)
#        my_arg=0
#        ;;
#    c)
#        do_clone=true
#        ;;
#
#    \?)
#        # Exit if user has entered an invalid option in the console
#        echo "${prog_name}: invalid option - '${OPTARG}'" >&2
#        echo "Try \`${prog_name} -h' for more information." >&2
#        exit 1
#        ;;
#    :)
#        # Exit if user has entered an invalid argument to the option
#        echo "${prog_name}: option - '${OPTARG}' requires an argument" >&2
#        echo "Try \`${prog_name} -h' for more information." >&2
#        exit 1
#        ;;
#    esac
#done
#shift $((OPTIND - 1))

#===============================================================================
# Parse arguments from commandline using getopt
#===============================================================================
do_clone=false

OPTS=`getopt -o hdc -l help,debug,clone -- "$@"`
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$OPTS"
while true; do
    case "$1" in
    -h | --help)
        # Print out help message
        print_usage
        exit 0
        shift;;

    -d | --debug)
        # Turn on bash debug mode
        set -x
        shift;;

    -c | --clone)
        # Set cloning to true
        do_clone=true
        shift;;

    --)
        shift
        break;;
    esac
done

#===============================================================================
# MAIN
#===============================================================================
repo_addr="gerritforge.lmera.ericsson.se:29418"

# CRL Repositories that needs to be synced
#repos=( crl-coli.git \
#        crl-errman-pmd.git \
#        crl-hwlog.git \
#        crl-itc.git \
#        crl-itclnh.git \
#        crl-lhsh_shelld.git \
#        crl-liblits.git \
#        crl-libsds.git \
#        crl-libuio_helper.git \
#        crl-lmc_parser.git \
#        crl-xte.git \
#        )
repos=( crl-coli )

# Check if the users want us to clone
if [ "$do_clone" = true ] ; then
    # Clone all repos
    for repo_name in "${repos[@]}"; do
        # Clone to bare repos
        run_cmd "git --bare clone ssh://${USER}@${repo_addr}/${repo_name}"
    done
    exit 1
fi

# Print a nice summary and return with appropriate exit status
handle_exit
