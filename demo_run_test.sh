#!/bin/sh
command="robot -x x_output.xml -l log_sprint$1.html -e resvno -e verify -e modem -e cpe demo/demo_sprint$1.robot"
echo $command
robot -x x_output.xml -l log_sprint$1.html -e resvno -e verify -e modem -e cpe demo/demo_sprint$1.robot
