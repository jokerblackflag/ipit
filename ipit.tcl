#!/usr/bin/env tclsh

proc error {} {
    puts "  \nUsage:"
    puts "  ipit <IP> <minusIP> <plusIP>"
    puts "\n  Example:"
    puts "  ipit 192.168.0.1 10 10"
    puts "  ipit 2001:db8::1 10 10"
    puts "\n  ipit 192.168.0.1/24"
    puts "  ipit 2001:db8:1234:5678::/126"
    puts "\n  ipit 192.168.0.1/28"
    puts "  ipit 2001:db8:1234:5678::/126\n"
    exit 1
}

proc help {} {
    puts "\n"
    puts "  █████████████████████████████████"
    puts "  ██                             ██"
    puts "  ██   ██ ████████ ██ ████████   ██"
    puts "  ██   ██ ██    ██ ██    ██      ██"
    puts "  ██   ██ ████████ ██    ██      ██"
    puts "  ██   ██ ██       ██    ██      ██"
    puts "  ██   ██ ██       ██    ██      ██"
    puts "  ██                             ██"
    puts "  █████████████████████████████████"
    puts "\n"
    puts "  I P  I T E R A T O R (ipit)"
    puts "  Developed by: joker (joker@blackflagcrew.net)"
    puts "  A simple tool to iterate through IPv4 and IPv6 ranges."
    puts "\n  Usage:"
    puts "  ipit <IP> <minusIP> <plusIP>"
    puts "\n  Example:"
    puts "  ipit 192.168.0.1 10 10"
    puts "  ipit 2001:db8::1 10 10"
    puts "\n  ipit 192.168.0.1/28"
    puts "  ipit 2001:db8:1234:5678::/126\n\n"
    exit 0
}

proc ipv6_to_int {ip} {
    set expanded_ip [expand_ipv6 $ip]
    set groups [split $expanded_ip :]
    set int_val 0

    foreach group $groups {
        scan $group "%x" hex_value
        set int_val [expr {($int_val << 16) + $hex_value}]
    }

    return $int_val
}

proc int_to_ipv6 {num} {
    set groups {}

    for {set i 0} {$i < 8} {incr i} {
        set groups [linsert $groups 0 [format "%x" [expr {($num >> (16 * $i)) & 0xFFFF}]]]
    }

    return [compress_ipv6 [join $groups ":"]]
}

proc expand_ipv6 {ip} {
    set parts [split $ip :]
    set expanded {}

    foreach part $parts {
        if {$part eq ""} {
            set zeros [lrepeat [expr {9 - [llength $parts]}] "0000"]
            set expanded [concat $expanded $zeros]
        } else {
            set expanded [concat $expanded [format "%04x" 0x$part]]
        }
    }

    return [join $expanded ":"]
}

proc compress_ipv6 {ip} {
    regsub -all {(^|:)0+(:|$)} $ip {\1} ip
    regsub -all {:{2,}} $ip {::} ip
    return $ip
}

proc iterate_ipv6 {ip minusIP plusIP} {
    set ip_num [ipv6_to_int $ip]
    set start_num [expr {$ip_num - $minusIP}]
    set end_num [expr {$ip_num + $plusIP}]

    for {set num $start_num} {$num <= $end_num} {incr num} {
        puts [int_to_ipv6 $num]
    }
}

proc ipv4_to_int {ip} {
    set octets [split $ip .]
    return [expr {[lindex $octets 0] * 256**3 + [lindex $octets 1] * 256**2 + [lindex $octets 2] * 256 + [lindex $octets 3]}]
}

proc int_to_ipv4 {num} {
    return [format "%d.%d.%d.%d" \
        [expr {($num >> 24) & 255}] \
        [expr {($num >> 16) & 255}] \
        [expr {($num >> 8) & 255}] \
        [expr {$num & 255}]
    ]
}

proc iterate_ipv4 {ip minusIP plusIP} {
    set ip_num [ipv4_to_int $ip]
    set start_num [expr {$ip_num - $minusIP}]
    set end_num [expr {$ip_num + $plusIP}]

    for {set num $start_num} {$num <= $end_num} {incr num} {
        puts [int_to_ipv4 $num]
    }
}

proc iterate_ipv4_cidr {cidr_ip} {
    set parts [split $cidr_ip /]
    set base_ip [lindex $parts 0]
    set cidr [lindex $parts 1]

    if {$cidr eq ""} {
        error "Invalid IPv4 CIDR format: $cidr_ip"
    }

    set ip_num [ipv4_to_int $base_ip]
    set netmask [expr {~((1 << (32 - $cidr)) - 1) & 0xFFFFFFFF}]
    set network [expr {$ip_num & $netmask}]
    set broadcast [expr {$network | (~$netmask & 0xFFFFFFFF)}]

    for {set num $network} {$num <= $broadcast} {incr num} {
        puts [int_to_ipv4 $num]
    }
}

proc iterate_ipv6_cidr {cidr_ip} {
    set parts [split $cidr_ip /]
    set base_ip [lindex $parts 0]
    set cidr [lindex $parts 1]

    if {$cidr eq ""} {
        error "Invalid IPv6 CIDR format: $cidr_ip"
    }

    lassign [ipv6_cidr_to_range $base_ip $cidr] start_ip end_ip

    for {set num $start_ip} {$num <= $end_ip} {incr num} {
        puts [int_to_ipv6 $num]
    }
}

proc ipv6_cidr_to_range {ip cidr} {
    set ip_num [ipv6_to_int $ip]
    set netmask [expr {~((1 << (128 - $cidr)) - 1) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}]
    set network [expr {$ip_num & $netmask}]
    set broadcast [expr {$network | (~$netmask & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)}]

    return [list $network $broadcast]
}

proc iterate_ipv6_cidr {cidr_ip} {
    set parts [split $cidr_ip /]
    set base_ip [lindex $parts 0]
    set cidr [lindex $parts 1]

    if {$cidr eq ""} {
        error "Invalid IPv6 CIDR format: $cidr_ip"
    }

    lassign [ipv6_cidr_to_range $base_ip $cidr] start_ip end_ip

    for {set num $start_ip} {$num <= $end_ip} {incr num} {
        puts [int_to_ipv6 $num]
    }
}

proc validate_ip {ip} {
    if {[regexp {^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}$} $ip]} { return "ipv4cidr"
    } elseif {[regexp {^[0-9a-fA-F:]+/\d{1,3}$} $ip]} { return "ipv6cidr"
    } elseif {[regexp {^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$} $ip]} { return "ipv4"
    } elseif {[regexp {^[0-9a-fA-F:]+$} $ip]} { return "ipv6"
    } else { return "na" }
}

proc manage_cmd {cmd ip {mip ""} {pip ""}} {
    if {$cmd eq "ipv4cidr"} {
        iterate_ipv4_cidr $ip
    } elseif {$cmd eq "ipv6cidr"} {
        iterate_ipv6_cidr $ip
    } elseif {$cmd eq "ipv4"} {
        iterate_ipv4 $ip $mip $pip
    } elseif {$cmd eq "ipv6"} {
        iterate_ipv6 $ip $mip $pip
    } else {
        error
    }
}

proc init {} {
    global argv

    if {[llength $argv] == 1 && [lindex $argv 0] eq "--help"} { help }

    set ip [lindex $argv 0]
    set mip [lindex $argv 1]
    set pip [lindex $argv 2]

    set cmd [validate_ip $ip]
    manage_cmd $cmd $ip $mip $pip
}

init
