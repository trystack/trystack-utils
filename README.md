
trystack-utils
==============

Post-deployment ops tools for managing the Trystack public cloud
   - http://trystack.org

**cinder-purge.sh**
   - Purges Cinder volumes and snapshots every 48hours
 
**fip-query.sh**
   - Records floating IP allocations
   - Creates/manages floating IP database

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
