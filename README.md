# Dockerized Nomad
[![](https://images.microbadger.com/badges/image/djenriquez/nomad.svg)](https://microbadger.com/images/djenriquez/nomad)

This repo produces a dockerized version of Nomad following Hashicorp's model for their Dockerized Consul image found here: https://github.com/hashicorp/docker-Consul

This image is meant to be run with host network privileges. It can use preconfigured Nomad hcl files by mounting those config to `/etc/nomad`.

# To run:
Server:
```bash
docker run -d \
--name nomad \
--net host \
-e NOMAD_LOCAL_CONFIG='{ "server": {
        "enabled": true,
        "bootstrap_expect": 3
    },
    "datacenter": "${DATACENTER}",
    "region": "${REGION}",
    "data_dir": "/nomad/data/",
    "bind_addr": "0.0.0.0",
    "advertise": {
        "http": "${IPV4}:4646",
        "rpc": "${IPV4}:4647",
        "serf": "${IPV4}:4648"
    },
    "enable_debug": true }' \
-v "/opt/nomad:/opt/nomad" \
-v "/var/run/docker.sock:/var/run/docker.sock" \
-v "/tmp:/tmp" \
djenriquez/nomad:v0.4.1 agent
```

Client:
```bash
docker run -d \
--name nomad \
--net host \
-e NOMAD_LOCAL_CONFIG='{ "client": {
        "enabled": true
    },
    "datacenter": "${DATACENTER}",
    "region": "${REGION}",
    "data_dir": "/nomad/data/",
    "bind_addr": "0.0.0.0",
    "advertise": {
        "http": "${IPV4}:4646",
        "rpc": "${IPV4}:4647",
        "serf": "${IPV4}:4648"
    },
    "enable_debug": true }' \
-v "/opt/nomad:/opt/nomad" \
-v "/var/run/docker.sock:/var/run/docker.sock" \
-v "/tmp:/tmp" \
djenriquez/nomad:v0.4.1 agent
```

The above command is identical to running this example in Nomad's documentation for [bootstrapping with Consul](https://www.nomadproject.io/docs/cluster/bootstrapping.html).
