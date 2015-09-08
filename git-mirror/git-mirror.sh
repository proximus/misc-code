#!/bin/bash
#===============================================================================
#
#          FILE:  git-mirror.sh
#
#         USAGE:  ./git-mirror.sh -h
#
#   DESCRIPTION:  Mirror repositories by initializing (cloning) them locally and
#                 syncronizing (fetch and push) them from source to destination.
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
# Get the directory of this script
DIR="${BASH_SOURCE%/*}"; if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Source library and configuration files
. "$DIR/lib/exit-status.sh"
. "$DIR/cfg/repositories.cfg"

#===============================================================================
# Function will print out help and usage
#
# Usage: print_usage
#===============================================================================
function print_usage()
{
    echo "
${prog_name} is a program used to mirror repositories

Usage:
    ${prog_name} [options]
    ${prog_name}        Syncronize repositories to mirror
    ${prog_name} -i     Initialize and syncronize repositories to mirror

Options:
    -h, --help          Show this help text
    -d, --debug         Show debug information
    -i, --init          Initialize all repositories locally

Report bugs to samuel.gabrielsson@gmail.com" >&2
}

# Program name
prog_name=$(basename "$0")

# Initialize variables
do_init=false
do_debug=false

#===============================================================================
# Parse arguments from commandline using bash builtin getopts
#===============================================================================
#while getopts dhi arg; do
#    case ${arg} in
#    d)
#        # Turn on bash debug mode
#        set -x
#        do_debug=true
#        ;;
#    h)
#        # Print out help message
#        print_usage
#        exit 0
#        ;;
#    i)
#        do_init=true
#        ;;
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
SHORTOPTS="hdi"
LONGOPTS="help,debug,init"
OPTS=$(getopt --name "$0" \
              --options ${SHORTOPTS} \
              --longoptions ${LONGOPTS} \
              -- "$@")
# Print help and quit if exit status of getopt returns an error
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "${OPTS}"
while true; do
    case "$1" in
    -h|--help)
        # Print out help message
        print_usage
        exit 0
        ;;
    -d|--debug)
        # Turn on bash debug mode
        set -x
        do_debug=true
        shift
        ;;
    -i|--init)
        # Set initialization to true
        do_init=true
        shift
        ;;
    --)
        # Shift opts and break the while loop
        shift
        break
        ;;
    *)
        # For everything else just break the while loop
        break
        ;;
    esac
done

#===============================================================================
# MAIN
#===============================================================================
# A place to locally store all the mirrored repositories
local_repo_base="/tmp/git-mirror-${USER}"

# Create the mirror base directory if it does not exist
mkdir -p "${local_repo_base}"

# Initialize (clone) all repositories
if [ "${do_init}" = true ]; then
    echo "#==============================================================================="
    echo "# Initializing all repositories to ${local_repo_base}:"
    echo "#==============================================================================="
    # Loop through all keys in an associative array
    for repo in "${!repos[@]}"; do

        # Set the full path and name to the local mirror repository
        local_repo="${local_repo_base}/${repo##*/}.git"

        # Make a bare clone of remote repository if it does not exist locally
        if [ ! -d "${local_repo}" ]; then
            run_cmd "git clone --bare ${repo} ${local_repo}"
        else
            echo "Repository ${local_repo} already initializated"
        fi

    done
fi

echo "#==============================================================================="
echo "# Syncronizing all repositories in ${local_repo_base}:"
echo "#==============================================================================="
for repo in "${!repos[@]}"; do

    # Set the full path and name to the local mirror repository
    local_repo="${local_repo_base}/${repo##*/}.git"

    # If the local repo does not exists, then something went wrong.
    if [ ! -d "${local_repo}" ]; then
        echo "Error: Repository ${local_repo} does not exists"
        exit 1
    fi

    # Go to the local repository
    pushd "${local_repo}" > /dev/null

    # Set the push location to your mirror
    run_cmd "git remote set-url --push origin ${repos[$repo]}"

    # Fetch from origin
    # - Copy all branches from the remote refs/heads/ namespace and store them
    #   to the local refs/remotes/origin/ namespace, unless the
    #   branch.<name>.fetch option is used to specify a non-default refspec.
    # - Remove any remote tracking branches which no longer exists on the remote
    # - Fetch all tags
    run_cmd "git fetch --prune origin"
    run_cmd "git fetch --tags origin"

    # Push to origin
    # - Push all refs under refs/heads
    # - Push all refs under refs/tags
    run_cmd "git push --all"
    run_cmd "git push --tags"

    popd > /dev/null
done

# Print a nice summary and return with appropriate exit status
if [ "${do_debug}" = true ]; then
    handle_exit
fi
