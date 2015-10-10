#!/bin/bash

/usr/sbin/sshd -D

supervisord -n
