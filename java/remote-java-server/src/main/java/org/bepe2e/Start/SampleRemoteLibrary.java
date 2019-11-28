package org.bepe2e.Start;

import org.robotframework.javalib.library.AnnotationLibrary;
import org.robotframework.remoteserver.RemoteServer;
import Utility.Parameters;
//import org.apache.commons.logging.Log;
//import org.apache.commons.logging.LogFactory;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class SampleRemoteLibrary extends AnnotationLibrary {
    //public Log logger = LogFactory.getLog(SampleRemoteLibrary.class);
    public Logger logger = LogManager.getLogger(SampleRemoteLibrary.class);
    public SampleRemoteLibrary() {
        super("org/bepe2e/Keywords/*.class");
    }

    @Override
    public String getKeywordDocumentation(String keywordName) {
        if (keywordName.equals("__intro__")) {
            return "Intro";
        }

        return super.getKeywordDocumentation(keywordName);
    }
    public void reporter(){
        logger.info("Starting remote server");
    }

    public static void main(String[] args) throws Exception {
    
        //Parameters parameters = new Parameters();
        System.setProperty("logfilename", "logs/remote-java-server");
        try
        {
            SampleRemoteLibrary obj = new SampleRemoteLibrary ();
            obj.reporter ();
        }
        catch (Exception e)
        {
            e.printStackTrace ();
        }

        RemoteServer server = new RemoteServer();
        server.addLibrary(SampleRemoteLibrary.class, 8270);
        server.start();
    }
}

