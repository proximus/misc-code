#===============================================================================
#
#          FILE:  nova.tcl
#
#         USAGE:  Sourced by main program
#
#   DESCRIPTION:  Program specific functions
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@gmail.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-10-28 11:00:00 CET
#      REVISION:  ---
#       CHANGES:  ---
#
#===============================================================================
# Include this library only once (Simulate an ifdef)
if {[ info exists _nova_tcl ]} return
set _nova_tcl 1

#===============================================================================
# Function will print out the program name in ASCII
#
# Usage:
# print_prog_name                   - Print ascii art to screen
#===============================================================================
proc print_prog_name { } {
    set ascii_art {
  _   _
 | \ | |
 |  \| | _____   ____ _
 | . ` |/ _ \ \ / / _` |
 | |\  | (_) \ V / (_| |
 \_| \_/\___/ \_/ \__,_|

By Samuel Gabrielsson (samuel.gabrielsson@gmail.com)}

    send_user "$ascii_art\n\n"
}

#===============================================================================
# Function will print usage and information on how to run the script
#
# usage                             - Print usage information
#
#===============================================================================
proc usage { } {
    # Get basename of prog
    set prog [file tail $::argv0]

    set usage_message "
Usage: $prog \[--help] \[--log <file>] \[--verbose] \[--debug]
            \[--port <port number>] \[--list-config] \[--config <file>]
            \[--cli-dir <dir>]  \[--enable-cli] \[--images <dir>]
            \[--kernel <img>] \[--device-tree <file>] \[--rootfs <img>]

$prog is a program used to start up SVP simulation

Options:
    --port <number>             Ethernet host base port (default is 50000)
    --list-config               Lists all configuration files in the cfg directory
    --config <file>             Configuration file
    --enable-cli                Start SVP CLI and bootup (to u-boot) in a separate xterm
    --cli-dir <dir>             CLI directory
    --images <dir>              Images directory (kernel, device tree, rootfs)
    --kernel <img>              Linux Kernel image
    --device-tree <file>        Device Tree Blob (dtb) file
    --rootfs <img>              Root Filesystem image
    --log <file>                Save output log to file
    --verbose                   Output more log message data to the terminal
    --debug                     Enable Debug mode
    --help                      Show this help text

Report bugs to samuel.gabrielsson@gmail.com"

    send_user "$usage_message\n"
    exit 1
}

#===============================================================================
# Function will set a value in the cli and check for faults
#
# cli_set <cmd>                     - Run a command on the cli
#
#===============================================================================
proc cli_set { cmd } {
    send "$cmd\r"
    expect {
        -re "\r\n(\[S|s]et .* to .*)\r\n" {
        }
        -re "\r\n(\[U|u]nable to set .* to .*)\r\n" {
            print -fail "$expect_out(1,string)\n"
        }
        "(Error: syntax error)" {
            print -fail "$expect_out(1,string)\n"
        }
        default {
            print -fail "Error: Failed to run command: $cmd\n"
        }
    }
}

#===============================================================================
# Function will load binary data file to memory
#
# loadmem <memory> <file> <address> - Load image to memory and specific address
#
#===============================================================================
proc loadmem { memory file address } {
    # Skip loading to memory if file is set to /dev/null
    if [ string match "$file" "/dev/null" ] {
        return 0
    } else {
        set cmd "loadmem $memory $file $address"

        send "$cmd\r"
        expect {
            -re "\r\n(invalid input: .*)\r\n" {
                print -fail "$expect_out(1,string)\n"
            }
            -re "\r\n(\[E|e]rror .*)\r\n" {
                print -fail "$expect_out(1,string)\n"
            }
            "\r\n(syntax error)\r\n" {
                print -fail "$expect_out(1,string)\n"
            }
            "\r\nok\r\n" { }
            default {
                print -fail "Error: Failed to run command: $cmd\n"
            }
        }
    }
}
