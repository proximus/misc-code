#!/bin/bash -e
#===============================================================================
#
#          FILE:  git-daily-sync.sh
#
#         USAGE:  ---
#
#   DESCRIPTION:  ---
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@gmail.com)
#       COMPANY:
#       VERSION:  1.0
#       CREATED:  2013-02-25 09:00:00 IST
#      REVISION:  ---
#       CHANGES:  ---
#
#===============================================================================

#===============================================================================
# Function will print out help and usage
# Usage: print_usage
#===============================================================================
function print_usage()
{
    local prog_name=$(basename "$0")
    echo "$prog_name is a program to do daily integation and sync from a git repository"
    echo "Usage: $prog_name -b <teambranch> [-h]

Options:
    -b <teambranch>     where <team-branch> is in the format <branch>-<type>-<team>. For example:
                        master-int-board, r48ya-int-board, master-int-tr, r48ya-int-tr.
    -h                  show this help text.

Report bugs to samuel.gabrielsson@gmail.com
Integrator home page: <http://ki81fw4.rnd.ki.sw.ericsson.se/tiki/tiki-index.php?page=RA_Radio_Git_Integration>" >&2
}

#===============================================================================
# Function uses getopts to parse the command line options
# Usage: parse_opts <options>
# Return: <args>
#===============================================================================
function parse_opts()
{
    while getopts :b:dh arg; do
        case $arg in
        b)
            # Return value for function
            echo $OPTARG
            ;;
        d)
            # Turn on debug mode
            set -x
            ;;
        h)
            print_usage
            exit
            ;;
        \?)
            echo "Error: Invalid option: -$OPTARG" >&2
            print_usage
            exit 1
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument." >&2
            print_usage
            exit 1
            ;;
        esac
    done
    shift $(( OPTIND - 1 ))
}

#===============================================================================
# Split the team branch array into three variables
# Usage: get_name
# TODO
#===============================================================================
function get_name()
{
    local IFS=$'\n'
    local arr
    local line

    for line in `echo $1`; do
        IFS='-'
        arr=($line)
        branch_name=${arr[0]}
        branch_type=${arr[1]}
        branch_team=${arr[2]}
    done
    # Check if names are not empty
    if [ -z "$branch_name" ] || [ -z "$branch_type" ] || [ -z "$branch_team" ]; then
        echo "Error: teambranch does not have the correct format. Should be <branch>-<type>-<team>"
        print_usage
        exit 1
    fi
}

if [ "$#" -eq 0 ]; then
    print_usage
    exit 1
fi

get_name $(parse_opts "$@")
echo $branch_name
echo $branch_type
echo $branch_team

exit 1
# Set variables
if [ "$branch" == "master" ]; then
    MY_TEAM_BRANCH="master-int-board"

    MY_DELIVERY_BRANCH="master"
    MY_BASELINE_BRANCH="master"
    GIT_CC_BRANCH="cc-main"
else
    echo "hej"
fi
