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
djenriquez/nomad:v0.6.0 agent
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
djenriquez/nomad:v0.6.0 agent
```

The above command is identical to running this example in Nomad's documentation for [bootstrapping with Consul](https://www.nomadproject.io/docs/cluster/bootstrapping.html).

# Correctly configuring Nomad data directory

Due to the way Nomad exposed template files it generates, you need to take
special precautions when configuring its data directory.

In case you are running Docker containers and using the ``template`` stanza,
the Nomad ``data_dir`` has to be configured with the **exact same path as the
host path**, so the host Docker daemon mounts the correct paths, as exported by
the Nomad client, into the scheduled Docker containers.

You can run the Nomad container with the following options in this case:

```bash
export NOMAD_DATA_DIR=/host/path/to/nomad/data

docker run \
...\
-v $NOMAD_DATA_DIR:$NOMAD_DATA_DIR:rw \
-e NOMAD_DATA_DIR=$NOMAD_DATA_DIR \
djenriquez/nomad:latest agent
```
