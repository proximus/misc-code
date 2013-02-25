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
# Function will print out help
# usage: print_usage
# TODO
#===============================================================================
function print_usage()
{
    local prog_name=$(basename "$0")
    echo "$prog_name is a program to do daily integation and sync from a git repository"
    echo "Usage: $prog_name -b <teambranch> [-h]

Options:
    -b  team-branch argument can be one of master-int-board, r48ya-int-board, master-int-tr, r48ya-int-tr.
    -h  show this help text.

Report bugs to samuel.gabrielsson@gmail.com
Integrator home page: <http://ki81fw4.rnd.ki.sw.ericsson.se/tiki/tiki-index.php?page=RA_Radio_Git_Integration>" >&2
}

# TODO
# Parse input arguments from console
if [ "$#" -eq 0 ]; then
    print_usage
    exit 1
fi

while getopts :b:h flag; do
  case $flag in
    b)
      echo "-b used: $OPTARG"
      teambranch=$OPTARG
      ;;
    h)
      print_usage
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      print_usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      print_usage
      exit 1
      ;;
  esac
done
shift $(( OPTIND - 1 ))

#===============================================================================
# Split the team branch array into three variables
# usage: get_name
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
        echo branch_name=${arr[0]}
        echo branch_type=${arr[1]}
        echo branch_team=${arr[2]}
    done
}

get_name $teambranch

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
