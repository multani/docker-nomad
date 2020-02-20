# Run [Nomad](https://www.nomadproject.io) from a Docker container

[![microbadger](https://images.microbadger.com/badges/image/multani/nomad.svg)](https://microbadger.com/images/multani/nomad) [![Docker Pulls](https://img.shields.io/docker/pulls/multani/nomad.svg)](https://hub.docker.com/r/multani/nomad/)

This repository builds a Docker image to run the
[Nomad](https://www.nomadproject.io) scheduler.

The image is mostly useful for testing purpose, when you want to ship a small
stack running Nomad along other containers. It is meant to be run with host
network privileges. Nomad itself can be configured:

* either by bind-mounting [HCL/JSON configuration
  files](https://www.nomadproject.io/docs/configuration/) into `/etc/nomad`

* and/or by setting the configuration content directly into the
  `NOMAD_LOCAL_CONFIG` environment variable (see examples below).

You also need to bind-mount the following directories (unless you really now
what you are doing):

* `/var/run/docker.sock`: to access the Docker socket, used by Nomad Docker's
  driver
* `/tmp`: default temporary directory used by Nomad's `-dev` mode


The repository produces a dockerized version of Nomad following Hashicorp's
model for their [Dockerized Consul
image](https://github.com/hashicorp/docker-consul). It is based on the work from
[djenriquez/nomad](https://github.com/djenriquez/nomad).


## To run:

You can use the Docker Compose file to get started:

```bash
docker-compose up
```

The relevant Docker Compose bits are:

```yaml
version: '2.1'

services:
  nomad:
    image: multani/nomad
    build: .
    command: agent -dev
    privileged: true
    network_mode: host
    environment:
      NOMAD_LOCAL_CONFIG: |
        data_dir = "/nomad/data/"

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - /tmp:/tmp
```

Or you can configured Nomad on dedicated host with the following command lines.

### Server:

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

### Client

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

## Correctly configuring Nomad data directory

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
  -v "$NOMAD_DATA_DIR:$NOMAD_DATA_DIR:rw" \
  -e "NOMAD_DATA_DIR=$NOMAD_DATA_DIR" \
  multani/nomad agent
```
