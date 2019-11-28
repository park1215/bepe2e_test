if [ "$#" -ne 1 ]; then
    echo "Please enter desired version number"
fi
rm target/remote-java-server*.jar
cp pom.xml pom_save.xml
sed -i "0,/<version>[0-9\.]*</{s/\(<version>\)[0-9\.]*\(<\)/\1$1\2/}" pom.xml
sed -i "s/\(remote-java-server-\)[0-9\.]*/\1$1/" pom.xml
mvn package
curl -u bepe2e_preprod:AP21dyK5sjwLQ2iqxqYqGHgV6BKg75DauhsVEP -X PUT  "https://artifactory.viasat.com/artifactory/bbc-gen-preprod/bep/bepe2e_test/remote-java-server/$1/remote-java-server-$1.jar" -T target/remote-java-server-1.1.jar

