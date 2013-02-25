#!/bin/bash -e
#===============================================================================
#
#          FILE:  integration-daily-sync.sh
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
#===============================================================================
usage="usage: $(basename "$0") [-b team-branch] [-h] -- Program to do daily integation and sync

where:
    -b  branch name (master-int-board, r48ya-int-board, master-int-tr, r48ya-int-tr)
    -h  show this help text

Report bugs to samuel.gabrielsson@gmail.com
Integrator home page: <http://ki81fw4.rnd.ki.sw.ericsson.se/tiki/tiki-index.php?page=RA_Radio_Git_Integration>"

if [ "$#" -eq 0 ]; then
    echo "Now in 0"
    echo "$usage" >&2
    exit 1
fi

# Parse arguments
while getopts :b:h flag; do
  case $flag in
    b)
      echo "-b used: $OPTARG"
      team_branch=$OPTARG
      team_branch_array=$(echo $OPTARG | tr "-" "\n")
      ;;
    h)
      echo "$usage" >&2
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "$usage" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      echo "$usage" >&2
      exit 1
      ;;
  esac
done

shift $(( OPTIND - 1 ))

# Split the team branch array into three variables:
# Variable 1: branch
# Variable 2: integration or development
# Variable 3: team name
for i in $team_branch_array
do
    echo "> [$i]"
done
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
echo "Branch is: $branch"
