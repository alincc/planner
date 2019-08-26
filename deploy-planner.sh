#!/bin/bash

set -e

function log() {
  echo "==> $1"
}

# Authenticate to DigitalOcean
log "Authenticating with DigitalOcean"
doctl auth init -t $DO_TOKEN

# Initialize variables
log "Initializing variables"
OLD_DROPLET=$(doctl compute droplet list 'planner*' --format Name | sed -n 2p)
log "Old Droplet: $OLD_DROPLET"

NEW_DROPLET=$([ $OLD_DROPLET = 'planner-g' ] && echo 'planner-b' || echo 'planner-g')
log "New Droplet: $NEW_DROPLET"

log "Downloading user data script"
curl -L -o planner-user-data.sh \
https://$GIT_USERNAME:$GIT_PASSWORD@raw.githubusercontent.com/jim-brighter/ops-secrets/master/planner/planner-user-data.sh

# # Launch new Planner droplet
log "Launching the new droplet"
doctl compute droplet create $NEW_DROPLET \
--region nyc3 \
--size s-1vcpu-1gb \
--image 50944795 \
--ssh-keys 22134471,23526912,24637185 \
--enable-monitoring \
--tag-names $NEW_DROPLET \
--user-data-file planner-user-data.sh \
--wait

# Get ID of new droplet
log "Getting info about the droplet"
NEW_DROPLET_ID=$(doctl compute droplet list $NEW_DROPLET --format ID | sed -n 2p)
NEW_DROPLET_IP=$(doctl compute droplet list $NEW_DROPLET --format "Public IPv4" | sed -n 2p)
log "New Droplet ID: $NEW_DROPLET_ID"
log "New Droplet IP: $NEW_DROPLET_IP"

# Put droplet in firewall
log "Putting droplet into firewall"
doctl compute firewall add-droplets fd9c6ca0-736e-48e8-84a3-93cb6aa32026 --droplet-ids $NEW_DROPLET_ID

log "Running the healthcheck"
attempts=0
max_attempts=36

until $(curl -k --output /dev/null --silent --head --fail https://$NEW_DROPLET_IP:8443/actuator/health); do

  if [ ${attempts} -eq ${max_attempts} ]; then
    log "App failed to respond in a timely manner!"
    exit 1
  fi

  attempts=$(($attempts+1))
  log "Waiting for app to respond at https://$NEW_DROPLET_IP:8443/actuator/health ..."
  sleep 10
done

# Reassign jimandfangzhuo.com floating IP to new droplet
log "Reassigning the floating IP"
doctl compute floating-ip-action assign 45.55.122.61 $NEW_DROPLET_ID

# Move new droplet to jimandfangzhuo.com project
log "Moving droplet to Planner project"
doctl projects resources assign 945d09ea-b636-4fcb-ab18-4eb8002ce53b --resource=do:droplet:$NEW_DROPLET_ID

# Delete old droplet
log "Deleting the old Planner droplet"
doctl compute droplet delete -f $OLD_DROPLET

log "Done!"
