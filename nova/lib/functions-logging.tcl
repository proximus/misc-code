#===============================================================================
#
#          FILE:  functions-logging.tcl
#
#         USAGE:  Sourced by main program
#
#   DESCRIPTION:  Logging functions
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@gmail.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-06-10 11:00:00 CET
#      REVISION:  ---
#       CHANGES:  ---
#
#===============================================================================
# Include this library only once (Simulate an ifdef)
if {[ info exists _functions_logging_tcl ]} return
set _functions_logging_tcl 1

#===============================================================================
# Expect internal diagnostic information consists of:
#   - every character received
#   - every attempt made to match the current output against the patterns
#
# exp_internal [-f file] value
#
# exp_internal 0                    - Disable diagnostic information to stderr.
# exp_internal 1                    - Enable diagnostic information to stderr.
# exp_internal -f file              - Write all output to file (ignoring value).
#
#===============================================================================
exp_internal 0

#===============================================================================
# User logging of:
#   - send/expect dialogue to stdout
#   - send/expect dialogue to a logfile if open
#
# log_user 0|1
#
# log_user 0                        - Disable logging to stdout.
# log_user 1                        - Enabled logging to stdout. Logging to
#                                     logfile is unchanged.
# Default                           - Send/Expect dialogue is logged to stdout
#                                     and logfile.
#
#===============================================================================
log_user 0

#===============================================================================
# Record a transcript of the session to file
#
# log_file [args] [[-a] file]
#
# log_file                          - Disable logging to file.
# log_file file                     - Enable logging to file.
# log_file -a file                  - Enable logging to file and force
#                                     previously supressed logging by log_user.
# log_file -noappend -a file        - Enable logging to truncated file and force
#                                     previously supressed logging by log_user.
#
#===============================================================================
log_file
