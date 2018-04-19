#!/bin/bash
set -e
source ${GITLAB_RUNTIME_DIR}/functions

chown -R git /etc/ssh
chown -R git /etc/ssl

echo ${GITLAB_DATA_DIR}
mkdir -p /home/git/data/ssh
chown -R git /home/git/data

chown -R git /etc/nginx

initialize_logdir
initialize_datadir

