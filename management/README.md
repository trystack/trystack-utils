
trystack-utils management tools
===============================

**compare-rpm-qa.sh**
   - Compare two files that are output from rpm -qa
   - Useful to see how closely two hosts resemble one another,
     especially of you need to replicate an issue and want to
     match the installed RPMs on a host.

**cinder-purge.sh**
   - Purges Cinder volumes and snapshots every 48hours
 
**fip-query.sh**
   - Records floating IP allocations
   - Creates/manages floating IP database

**ospurge-driver.sh**
   - Run ospurge against a limited set of tenants
   - Tenants that have not had an instance for 2 days get purged
     (tenant is not deleted, just resources released)
   - ospurge: https://github.com/openstack/ospurge

**router-query.sh**
   - Queries tenant gateways/routers
   - Uses router-query-json.py

**router-query-json.py**
   - Extracts fields from JSON for router-query.sh

**router-purge.sh**
   - References data from router-query.sh
   - Removes tenant gateways/routers

**track-fip-history.sh**
   - Query/track history of a floating IP to tenant records
   - Utilizes exiting floating IP database from fip-query.sh
