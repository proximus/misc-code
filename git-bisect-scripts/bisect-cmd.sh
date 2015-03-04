#!/bin/sh
#===============================================================================
#
#          FILE:  bisect-cmd.sh
#
#         USAGE:  git bisect run bisect-cmd.sh
#
#   DESCRIPTION:  Include file for the Radio Software Application.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  Dependent on wmru
#          BUGS:  ---
#         NOTES:  For Yocto Project Documentation see:
#                 https://www.yoctoproject.org/documentation
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@ericsson.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-02-12 09:00:00 CET
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
# Function will print out help and usage
#
# Usage: print_usage
#===============================================================================
function print_usage()
{
    echo "Usage: ${prog_name} [-d] [-g <gateway>] [-h] -p <position> [-t <testsuite>] testcase

${prog_name} is a program used with git bisect to automate testing

Options:
    -d                  Show debug information.
    -g <gateway>        OSE gateway. Default is tcp://sekic1339:50001
    -h                  Show this help text.
    -p <position>       Terminal position.
    -t <testsuite>      Run mira testsuite

Report bugs to samuel.gabrielsson@gmail.com
Home page: https://github.com/proximus/misc-code" >&2
}

#===============================================================================
# MAIN
#===============================================================================
# Global variables

# Initialize our global array of return status
return_code=()

# Initialize our global array of commands
commands=()

# Program name
prog_name=$(basename "$0")

# Use getopts to parse the arguments given in the console. Return the
# argument using echo to the calling function.
while getopts dg:hp:t: arg; do
    case ${arg} in
    d)
        # Turn on bash debug mode
        set -x
        ;;
    g)
        OSE_GW="--osegw ${OPTARG}"
        ;;
    h)
        # Print out help message
        print_usage
        exit 0
        ;;
    p)
        WM_POSITION="${OPTARG}"
        ;;
    t)
        TEST_SUITE="${OPTARG}"
        ;;
    \?)
        # Exit if user has entered an invalid option in the console
        echo "${prog_name}: invalid option - '${OPTARG}'" >&2
        echo "Try \`${prog_name} -h' for more information." >&2
        exit 1
        ;;
    :)
        # Exit if user has entered an invalid argument to the option
        echo "${prog_name}: option - '${OPTARG}' requires an argument" >&2
        echo "Try \`${prog_name} -h' for more information." >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

# Run wmru, parse the output and save some important data
load_lmc_cmd="$(wmru ${WM_POSITION} | sed -n -e 's/[\ \t]\+\(bundle exec mira_lmc_load.rb .* --lmcfile \/.*.xlf\)/\1/p')"

# Set default gateway if it has not been set in getopts
if [ -z "$OSE_GW" ]; then
    OSE_GW="$(echo ${load_lmc_cmd} | sed -n -e 's/^bundle exec mira_lmc_load.rb .* \(--osegw .*\) --lnhpath.*.xlf$/\1/p')"
fi

# Get Linkhandler path to the RU
lnhpath="$(echo ${load_lmc_cmd} | sed -n -e 's/^bundle exec mira_lmc_load.rb .* --osegw .* \(--lnhpath .*\) --lmcfile .*.xlf$/\1/p')"

# Path to the lmc file to be loaded
lmcfile="$(echo ${load_lmc_cmd} | sed -n -e 's/^bundle exec mira_lmc_load.rb .* --lmcfile \(\/.*.xlf$\)/\1/p')"
xlf_name="$(basename ${lmcfile})"
xlf_target="${xlf_name%.*}"

# Clean everything. If cleaning breaks, then exit with failure.
echo ""
echo "#==============================================================================="
echo "# Cleaning up"
echo "#==============================================================================="
run_cmd "make clean"

# Update submodule
echo ""
echo "#==============================================================================="
echo "# Updating submodules"
echo "#==============================================================================="
run_cmd "git submodule update --recursive --init"

# Build target. If building breaks, then exit with a failure.
echo ""
echo "#==============================================================================="
echo "# Building Target: ${xlf_target}"
echo "#==============================================================================="
run_cmd "qemake -C sw/make ${xlf_target}"

# Get CXP number and sha id from target file after building
cxp_and_sha_id=$(strings ${lmcfile} | sed -n -e 's/^\(CXP.*\)[ \t]\+/\1/p')
cxp=$(echo ${cxp_and_sha_id} | awk '{print $1}')
sha_id=$(echo ${cxp_and_sha_id} | awk '{print $2}')

# Delete all possible (non protected) LMCs before loading.
#echo ""
#echo "#==============================================================================="
#echo "# Deleting all (non protected) LMCs"
#echo "#==============================================================================="
#run_cmd "bundle exec mira_lmc_load.rb -a ${OSE_GW} ${lnhpath} --lmcfile ${lmcfile}"

# Run mira load command. After a successful load, restart board with loaded LMC.
echo ""
echo "#==============================================================================="
echo "# Loading LMC"
echo "#==============================================================================="
run_cmd "bundle exec mira_lmc_load.rb -r ${OSE_GW} ${lnhpath} --lmcfile ${lmcfile}"

# Run mira exec command
echo ""
echo "#==============================================================================="
echo "# Running MIRA"
echo "#==============================================================================="
# Strangely, mira requires us to run testsuites from MIRA_ROOT, but individual
# TCs can be run from anywhere.
if [ ! -z "${TEST_SUITE}" ]; then
    pushd "${MIRA_ROOT}"
    run_cmd "bundle exec mira.rb --terminal_pos ${WM_POSITION} --sw_pid ${cxp}_${sha_id} ${OSE_GW} --options_file ${TEST_SUITE} $@"
    popd
else
    run_cmd "bundle exec mira.rb --terminal_pos ${WM_POSITION} --sw_pid ${cxp}_${sha_id} ${OSE_GW} $@"
fi

# Print a nice summary and return with appropriate exit status
handle_exit
