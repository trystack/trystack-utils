
trystack-utils monitoring tools
===============================

**openstack-neutron-network-check.sh**
   - Enhanced Nagios check for Neutron and related instance creation
   - This check does the following, testing each component of instance creation:
      * Boots a new instance
      * Sets gateway to external network
      * Attaches floating IP address
      * Pings floating IP address
      * SSH into instance
      * Records status (pass/fail)
         * updates flat file for Nagios check
      * Tears down everything
 
**openstack-neutron-network-check-wrapper.sh**
   - Simple wrapper to launch openstack-neutron-network-check.sh

**nagios-generate-dashboard.sh**
   - Scrapes an internal Nagios instance, re-creating the HTML/CSS
   - Generates a static page suitable for exposing externally
   - Example:
      * https://x86.trystack.org/dashboard/static/dashboard/nagios/
