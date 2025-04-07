#!/bin/bash

mkdir -p ~/.kube

scp ubuntu@192.168.123.10:/etc/rancher/k3s/k3s.yaml ~/.kube/config

sed -i 's/127.0.0.1/192.168.123.10/g' ~/.kube/config