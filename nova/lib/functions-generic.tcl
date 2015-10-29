#===============================================================================
#
#          FILE:  functions-generic.tcl
#
#         USAGE:  Sourced by main program
#
#   DESCRIPTION:  Generic functions
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
if { [info exists _functions_generic_tcl] } return
set _functions_generic_tcl 1

#===============================================================================
# Function will execute commands when this program is about to exit
#
# exit -onexit                      - Exit function
#
#===============================================================================
exit -onexit {
    if { [info exists ::shell_id] } {
        send -i $::shell_id "exit\n"
    }
    send_user "Goodbye!\n"
}

#===============================================================================
# Function will check if a file exists in a given path. Print message if it does
# not exist and exit.
#
# check <path>                      - Check if path exists
#
#===============================================================================
proc check { path } {
    # Check if file exists and return its path if it does.
    if { [file exists $path] } {
        return $path
    } else {
        # Print a message and exit if file does not exist.
        send_user "Error: File does not exist: $path\n"; exit 1
    }
}

#===============================================================================
# Function will set a default variable if it has not been set previously
#
# set_default <variable> <value>    - Set default variable with value
#
#===============================================================================
proc set_default { variable value } {
    # Let the local variable refer to the global variable
    upvar 1 $variable var

    # Check if the varible has been set in the past
    if { ! [info exists var]} {
        # Set the default value if it has not been set before
        set var $value
    }
}

#===============================================================================
# Function will expect a prompt
#
# expect_prompt <prompt>            - Expect prompt
#
#===============================================================================
proc expect_prompt { prompt } {
    # Expect the prompt to show up withing the timeout
    set timeout 30
    expect {
        -re "(Error: .*)\r\n" {
            send_user "$expect_out(1,string)\n"; exit 1
        }
        -re "$prompt" { }
        default { send_user "Error: Failed to expect prompt: $prompt\n"; exit 1 }
    }
}

#===============================================================================
# Function will search for the latest version of a file in directory
#
# latest_file <dir>                 - Return latest version of file in directory
#
#===============================================================================
proc latest_file { dir } {
    return [lindex [lsort -dictionary -decreasing -nocase [glob -dir $dir svp-*]] 0]
}

#===============================================================================
# Function removes the first element of a list and returns it. The list must be
# passed by name.
#
# lshift <inputlist>                - List to be left shifted
#
#===============================================================================
proc lshift { inputlist } {

    # Upvar will create a link to a variable in a different stack frame, i.e. we
    # let the local variable refer to a global variable.
    upvar 1 $inputlist argv

    # Save the first element in the list
    set arg [lindex $argv 0]

    # Replace an element of a list with another
    set argv [lreplace $argv[set argv {}] 0 0]

    # Return the left shifted element
    return $arg
}

#===============================================================================
# A function to print nice to screen.
#
# print <message>                   - Print string message as default
# print -ok                         - Print OK in green color
# print -warn                       - Print WARN in yellow color
# print -fail                       - Print FAIL in red color and exit
# print -result <expr>              - Print OK or FAIL depending on expression
#
#===============================================================================
proc print { msg {my_expr ""} } {

    # Define colors
    set green "\033\[01;32m"
    set yellow "\033\[01;33m"
    set red "\033\[01;31m"
    set normal "\033\[0m"

    # Print with color
    switch -exact -- $msg {
        -ok {
            send_user "\[$green  OK  $normal\]\n"
        }
        -warn {
            send_user "\[$yellow WARN $normal\]\n"
        }
        -fail {
            send_user "\[$red FAIL $normal\]\n$my_expr"
            exit 1
        }
        -result {
            if {$my_expr} {print -ok} else {print -fail}
        }
        default {
            # Maximum amount of chars to print
            set columns_max [lindex [exec stty size] 1]

            # Horizontal progress bar style
            set hpbar_style " "

            # Prompt style
            set tab         ""
            set date_time   [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
            set prog_name   [file tail $::argv0]
            set prompt      "\[$green$date_time$normal\] $yellow$prog_name$normal: "

            # Get the length of all constant and variable strings so that we can
            # calculate the amount of filling we need to print on screen.
            set prompt_size [ string length $prompt ]
            set tab_size    [ string length $tab ]
            set msg_size    [ string length $msg ]
            set green_size  [ string length $green]
            set yellow_size [ string length $yellow]
            set red_size    [ string length $red]
            set normal_size [ string length $normal]
            set print_status_size 8

            # Calculate the total size of the horizontal progress bar.
            set hpbar_size  [ expr $columns_max - $prompt_size - $tab_size - $msg_size - $print_status_size + 2*$green_size + $yellow_size + 2*$normal_size - 8]
            #if { [ expr $hpbar_size <= 0 ] } {
            #    send_user "\033\[01;33mPlease shorten below message to fit into max $columns_max columns!\033\[0m\n"
            #}

            # Print the prompt, message and horizontal progress bar
            send_user "$prompt$msg"
            for { set i 0 } { $i < $hpbar_size } { incr i } {
                send_user $hpbar_style
            }
            flush stdout
        }
    }
}

#===============================================================================
# Function will check if a file exists in the given path and try to source it
#
# source_file <filename>            - Source filename
#
#===============================================================================
proc source_file { filename } {
    # File to source
    set filename [file normalize $filename]

    print "Sourcing $filename"

    # Source the file if it exists
    if { [file exists $filename] } {
        # Evaluate all variables to the global namespace
        namespace inscope :: eval source $filename
        print -ok
    } else {
        print -fail
    }
}
