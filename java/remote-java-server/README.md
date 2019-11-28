This is a standalone java-based server that serves Robot keywords, accessible via remote procedure calls from Robot. The Robot keywords are in /src/main/java/org/bepe2e/keywords.
We have pulled in Selenium-based classes from the Sales Operations teams (into src/main/java/Pages), and the Robot keywords invoke methods in those classes.
The "hook" file from Sales Operations, which instantiates browser-related objects, is in src/main/java/StepDefinitions, and has been fairly well modified from the original for our application.
This server uses the jrobotremoteserver library from https://git.viasat.com/bepe2e/jrobotremoteserver, which is compiled and saved into the local maven repository on the host on which this server runs.
After using "mvn package" to create a jar file, and "java -jar" to start the server, you can test using https://git.viasat.com/bepe2e/bepe2e_test/blob/master/demo/java_drivers/test_java.txt:
"pybot java_test.txt"
