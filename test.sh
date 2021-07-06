#!/bin/bash
(
  cd /Users/stefan/Code/terraform/development/
  /usr/local/bin/terraform apply -auto-approve
) &
disown %1
say launched
