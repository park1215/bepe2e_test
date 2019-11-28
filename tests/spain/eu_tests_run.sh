#!/bin/sh
command="robot -x x_output.xml -l log.html $1 --argumentfile eu_tests.robot"
echo $command
robot -x x_output.xml -l log.html $1 --argumentfile eu_tests.robot
