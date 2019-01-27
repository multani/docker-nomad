# Dockerized Nomad
[![](https://images.microbadger.com/badges/image/multani/nomad.svg)](https://microbadger.com/images/multani/nomad)

This is based on the work from [djenriquez/nomad](https://github.com/djenriquez/nomad).

This repo produces a dockerized version of Nomad following Hashicorp's model
for their Dockerized Consul image found here:
https://github.com/hashicorp/docker-Consul


This image is meant to be run with host network privileges. It can use
preconfigured Nomad hcl files by mounting those config to `/etc/nomad`.

# To run:

You can use the Docker Compose file to get started:

```bash
docker-compose up
```

Or you can configured Nomad on dedicated host with the following command lines.

## Server:

```bash
docker run -d \
--name nomad \
--net host \
-e NOMAD_LOCAL_CONFIG='
server {
  enabled = true
  bootstrap_expect = 3
}

datacenter = "${REGION}"
region     = "${DATACENTER}"

data_dir = "/nomad/data/"

bind_addr = "0.0.0.0"

advertise {
  http = "{{ GetPrivateIP }}:4646"
  rpc  = "{{ GetPrivateIP }}:4647"
  serf = "{{ GetPrivateIP }}:4648"
}
' \
-v "/srv/nomad/data:/nomad/data:rw" \
multani/nomad agent
```

## Client

Note that you need the `privileged` flag turned on for Nomad to run correctly):

```bash
docker run -d \
--name nomad \
--net host \
--privileged \
-e NOMAD_LOCAL_CONFIG='
client {
  enabled = true
}

datacenter = "${REGION}"
region     = "${DATACENTER}"

data_dir = "/nomad/data/"

bind_addr = "0.0.0.0"

advertise {
  http = "{{ GetPrivateIP }}:4646"
  rpc  = "{{ GetPrivateIP }}:4647"
  serf = "{{ GetPrivateIP }}:4648"
}
' \
-v "/srv/nomad/data:/nomad/data:rw" \
-v "/var/run/docker.sock:/var/run/docker.sock" \
-v "/tmp:/tmp" \
multani/nomad agent
```

The above command is identical to running this example in Nomad's documentation
for [bootstrapping with
Consul](https://www.nomadproject.io/docs/cluster/bootstrapping.html).

# Correctly configuring Nomad data directory

Due to the way Nomad exposed template files it generates, you need to take
special precautions when configuring its data directory.

In case you are running Docker containers and using the `template` stanza,
the Nomad `data_dir` has to be configured with the **exact same path as the
host path**, so the host Docker daemon mounts the correct paths, as exported by
the Nomad client, into the scheduled Docker containers.

You can run the Nomad container with the following options in this case:

```bash
export NOMAD_DATA_DIR=/host/path/to/nomad/data

docker run \
...\
-v $NOMAD_DATA_DIR:$NOMAD_DATA_DIR:rw \
-e NOMAD_DATA_DIR=$NOMAD_DATA_DIR \
multani/nomad agent
```
