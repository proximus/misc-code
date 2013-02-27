#!/bin/bash -ex
#===============================================================================
#
#          FILE:  git-daily-sync.sh
#
#         USAGE:  ./git-daily-sync.sh -b <teambranch>
#
#   DESCRIPTION:  This program is meant to be a tool for the Integration Branch
#                 Owner (IBO). It will automatically sync the teambranch and the
#                 tracking branch with commits coming from clearcase git
#                 repository.
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
    echo "Usage: ${prog_name} -b <teambranch> [-h] [-d]

${prog_name} is a program to do daily integation and sync from a git repository

Options:
    -b <teambranch>     where <team-branch> is in the format <branch>-<type>-<team>. For example:
                        master-int-board, r48ya-int-board, master-int-tr or r48ya-int-tr.
    -h                  show this help text.
    -d                  show debug information.

Report bugs to samuel.gabrielsson@gmail.com
Integrator home page: <http://ki81fw4.rnd.ki.sw.ericsson.se/tiki/tiki-index.php?page=RA_Radio_Git_Integration>" >&2
}

#===============================================================================
# Function uses getopts to parse the command line options.
# Usage: parse_opts <options>
# Return: <args>
#===============================================================================
function parse_opts()
{
    local prog_name=$(basename "$0")

    # Use getopts to parse the arguments given in the console. Return the
    # argument using echo to the calling function.
    while getopts :b:dh arg; do
        case ${arg} in
        b)
            # Echo argument so calling calling function can store it
            echo ${OPTARG}
            ;;
        d)
            # TODO: Turn on debug mode
            set -x
            ;;
        h)
            # Print out help message
            print_usage
            # TODO: Should return 0 but exit doesnt work correct
            return 1
            ;;
        \?)
            # Exit if user has entered an invalid option in the console
            echo "${prog_name}: invalid option - '${OPTARG}'" >&2
            echo "Try \`${prog_name} -h' for more information." >&2
            return 1
            ;;
        :)
            # Exit if user has entered an invalid argument to the option
            echo "${prog_name}: option - '${OPTARG}' requires an argument" >&2
            echo "Try \`${prog_name} -h' for more information." >&2
            return 1
            ;;
        esac
    done
    shift $(( OPTIND - 1 ))
}

#===============================================================================
# Split the team branch array into three variables and do some sanity checks.
# Usage: get_name
# Return: branch_name, branch_type, branch_team
#===============================================================================
function get_name()
{
    local IFS=$'\n'
    local arr
    local line

    # Get the branch variables from options
    for line in $(echo $1); do
        IFS='-'
        arr=($line)
        branch_name=${arr[0]}
        branch_type=${arr[1]}
        branch_team=${arr[2]}
    done

    # Check if names are not empty
    if [ -z "${branch_name}" ] || [ -z "${branch_type}" ] || [ -z "${branch_team}" ]; then
        echo "Error: teambranch does not have the correct format. Should be <branch>-<type>-<team>"
        return 1
    fi

    # Check if branch name has the right format
    if ! [[ "${branch_name}" =~ ^(master|r[0-9]+[a-z]+)$ ]]; then
        echo "Error: Branch name is not a valid format"
        return 1
    fi

    # Check if branch type has the right format. Only dev or int is a valid name.
    if ! [[ "${branch_type}" =~ ^(dev|int)$ ]]; then
        echo "Error: Branch type is not a valid format"
        return 1
    fi

    # Check if team branch exists in remote branch
    if [ -z "$(git branch -r | grep "origin/${branch_name}-${branch_type}-${branch_team}" | tr -d ' ')" ]; then
        echo "Error: Local team branch $1 does not exist is remote origin branch"
        return 1
    fi

    return 0
}

function run_tests()
{
    local MAKE=$1

    ${MAKE} -C sw/make clean            || return 1
    ${MAKE} -C sw/make all              || return 1
    ${MAKE} -C test/unitTest clean      || return 1
    ${MAKE} -C test/unitTest run_all    || return 1
    return 0
}

#===============================================================================
# MAIN
#===============================================================================
# TODO: Fix this
if [ "$#" -eq 0 ]; then
    print_usage
    exit 1
fi

# Parse the options and save the arguments
team_branch=$(parse_opts "$@") || exit
get_name ${team_branch} || exit

# Set variables depending on master branch or other branches
MY_TEAM_BRANCH="${team_branch}"
MY_DELIVERY_BRANCH="${branch_name}"
if [ ${branch_name} == "master" ]; then
    GIT_CC_BRANCH="cc-main"
else
    GIT_CC_BRANCH="cc-${branch_name}"
fi
GIT_PRIMAL_BRANCH="${MY_DELIVERY_BRANCH}"
GIT_INTEGRATION_BRANCH="${MY_TEAM_BRANCH}"
GIT_BASELINE_BRANCH="${MY_DELIVERY_BRANCH}"
CLEARCASE_REFERENCE_VIEW="${USER}_${MY_DELIVERY_BRANCH}_reference"
CLEARCASE_DELIVERY_VIEW="${USER}_${MY_DELIVERY_BRANCH}_delivery"

# Checkout GIT_PRIMAL_BRANCH and get latest commits from remote repositories
git checkout ${GIT_PRIMAL_BRANCH}
git fetch

# Reset your GIT_PRIMAL_BRANCH in case it is in line with remotes/origin/GIT_PRIMAL_BRANCH
git reset --hard origin/${GIT_PRIMAL_BRANCH}

# Merge GIT_CC_BRANCH into GIT_PRIMAL_BRANCH
git merge origin/${GIT_CC_BRANCH}

# Get the latest baseline submodule
# TODO: Should be made generic for all submodules
pushd baseline
git checkout ${GIT_BASELINE_BRANCH}
git pull
popd

# Update baseline if it has new commits.
git_status=$(git status | grep --color=never 'modified:')
if [[ "${git_status}" =~ ' baseline (new commits)'$ ]]; then
    git add baseline
    git commit --amend -m "Merge 'origin/${GIT_CC_BRANCH}', update baseline"
fi

# If emake is not installed then fall back to regular make.
MAKE="emake"
which emake &>/dev/null || MAKE="make -j8"

# Make sure all xlfs builds and all unittests still pass.
run_tests ${MAKE} || exit

# Checkout GIT_INTEGRATION_BRANCH
git checkout ${GIT_INTEGRATION_BRANCH}

# Reset your GIT_INTEGRATION_BRANCH in case it is in line with remotes/origin/GIT_INTEGRATION_BRANCH
git reset --hard origin/${GIT_INTEGRATION_BRANCH}

# Merge GIT_PRIMAL_BRANCH into GIT_INTEGRATION_BRANCH
git merge ${GIT_PRIMAL_BRANCH}

# Make sure all xlfs builds and all unittests still pass.
run_tests ${MAKE} || exit

echo "!!!NOTE!!!"
git fetch

# Push to GIT_PRIMAL_BRANCH
echo git checkout ${GIT_PRIMAL_BRANCH}
echo git push origin ${GIT_PRIMAL_BRANCH}

# Push to GIT_INTEGRATION_BRANCH
echo git checkout ${GIT_INTEGRATION_BRANCH}
echo git push origin ${GIT_INTEGRATION_BRANCH}
