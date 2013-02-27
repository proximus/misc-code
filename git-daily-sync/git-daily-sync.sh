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
    echo "Usage: $prog_name -b <teambranch> [-h] [-d]

$prog_name is a program to do daily integation and sync from a git repository

Options:
    -b <teambranch>     where <team-branch> is in the format <branch>-<type>-<team>. For example:
                        master-int-board, r48ya-int-board, master-int-tr or r48ya-int-tr.
    -h                  show this help text.
    -d                  show debug information.

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
    local prog_name=$(basename "$0")

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
            return 1 # TODO: Should return 0 but exit doesnt work correct
            ;;
        \?)
            echo "$prog_name: invalid option - '$OPTARG'" >&2
            echo "Try \`$prog_name -h' for more information." >&2
            return 1
            ;;
        :)
            echo "$prog_name: option - '$OPTARG' requires an argument" >&2
            echo "Try \`$prog_name -h' for more information." >&2
            return 1
            ;;
        esac
    done
    shift $(( OPTIND - 1 ))
}

#===============================================================================
# Split the team branch array into three variables
# Usage: get_name
# Return: branch_name, branch_type, branch_team
#===============================================================================
function get_name()
{
    local IFS=$'\n'
    local arr
    local line
    local remote_team_branch

    for line in $(echo $1); do
        IFS='-'
        arr=($line)
        branch_name=${arr[0]}
        branch_type=${arr[1]}
        branch_team=${arr[2]}
    done

    # Check if names are not empty
    if [ -z "$branch_name" ] || [ -z "$branch_type" ] || [ -z "$branch_team" ]; then
        echo "Error: teambranch does not have the correct format. Should be <branch>-<type>-<team>"
        return 1
    fi

    # Check if team branch exists in remote
    remote_team_branch=$(git branch --no-color -r | grep "^[ ]+origin/$branch_name-$branch_type-$branch_team" | tr -d ' ')
    if [ -z "$remote_team_branch" ]; then
        echo "Error: Remote branch origin/$1 does not exist"
        return 1
    fi

    # Check if branch has right format

    # Check if type has right format
    return 0
}

# TODO: Fix this
if [ "$#" -eq 0 ]; then
    print_usage
    exit 1
fi

options=$(parse_opts "$@") || exit
get_name "$options" || exit
#get_name $(parse_opts "$@")
echo "branch_name: $branch_name"
echo "branch_type: $branch_type"
echo "branch_team: $branch_team"

exit 0
# Set variables
if [ "${branch_name}" == "master" ]; then
    set MY_TEAM_BRANCH="master-int-board"

    set MY_DELIVERY_BRANCH="master"
    set MY_BASELINE_BRANCH="master"
    set GIT_CC_BRANCH="cc-main"

else
    set MY_TEAM_BRANCH="r48ya-int-board"

    set MY_DELIVERY_BRANCH="r48ya"
    set MY_BASELINE_BRANCH="v10.6.0-r48ya"
    set GIT_CC_BRANCH="cc-${MY_DELIVERY_BRANCH}"
fi
set GIT_PRIMAL_BRANCH="${MY_DELIVERY_BRANCH}"
set GIT_INTEGRATION_BRANCH="${MY_TEAM_BRANCH}"
set GIT_BASELINE_BRANCH="${MY_BASELINE_BRANCH}"
set CLEARCASE_REFERENCE_VIEW="${USER}_${MY_DELIVERY_BRANCH}_reference"
set CLEARCASE_DELIVERY_VIEW="${USER}_${MY_DELIVERY_BRANCH}_delivery"
