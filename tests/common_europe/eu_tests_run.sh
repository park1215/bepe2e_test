#!/bin/sh

if [ $2 = 'ES' ]; then
    echo "Running Spain Tests!!"
    command="robot -x x_output.xml -l log.html $1 --argumentfile spain_tests.robot"
    echo $command
    robot -x x_output.xml -l log.html $1 --argumentfile spain_tests.robot
fi

if [ $2 = 'NO' ]; then
    echo "Running Norway Tests!!"
    command="robot -x x_output.xml -l log.html $1 --argumentfile norway_tests.robot"
    echo $command
    robot -x x_output.xml -l log.html $1 --argumentfile norway_tests.robot
fi

if [ $2 = 'PL' ]; then
    echo "Running Poland Tests!!"
    command="robot -x x_output.xml -l log.html $1 --argumentfile poland_tests.robot"
    echo $command
    robot -x x_output.xml -l log.html $1 --argumentfile poland_tests.robot
fi
