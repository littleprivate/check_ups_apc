# check_ups_apc
Monitors APC SmartUPS via SNMP.

Based on check_ups_apc.pl from altinity.com (Opsview) with modifications by Blueeye and M. Fuchs.

    Summary:
    perfdata for Battery Capacity
    Frequency-Monitoring (with perfdata)
    Voltage-Monitoring (Input/Output and perfdata)
    Battery Replacement notification
    UPS Serialnumber
	Temperature 

Usage:

 $script -H  -C  [...]

Options:

-H .....  Hostname or IP address
-C .....  Community (default is public)
