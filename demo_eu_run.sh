#!/bin/sh
command="robot -x x_output.xml -l log_sprint$2.html $1 demo/demo_sprint$2.robot"
echo $command
robot -x x_output.xml -l log_sprint$2.html $1 demo/demo_sprint$2.robot
