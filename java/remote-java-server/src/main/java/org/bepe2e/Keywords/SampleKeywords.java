package org.bepe2e.Keywords;


import org.robotframework.javalib.annotation.ArgumentNames;
import org.robotframework.javalib.annotation.RobotKeyword;
import org.robotframework.javalib.annotation.RobotKeywords;

import java.io.File;
import Pages.LoginPage;
import StepDefinitions.Hook;

//import org.apache.commons.logging.Log;
//import org.apache.commons.logging.LogFactory;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import Utility.Constant;

@RobotKeywords
public class SampleKeywords {
    public Constant constant = new Constant();
    //public Log logger = LogFactory.getLog(SampleKeywords.class); 
    public Logger logger = LogManager.getLogger(SampleKeywords.class);
    @RobotKeyword("Test Keyword")
    public String TestKeyword(){
        return "test successful";        
    }

    @RobotKeyword("Open Portal")
    public String OpenPortal(){ 

        try {
            Hook hook = new Hook();
                logger.info("new Hook");
                try {
                    hook.setUp();
                    LoginPage loginpage = new LoginPage(hook.getDriver());
                    loginpage.WaitforLoginPage();
                    loginpage.login("swiledsisi","i+3Q+9AT85G8QlG81zCKkQ==");
                    try {
                        hook.screenshot();
                        
                    } catch (Exception e) {
                        logger.error("screenshot failure:"+e);
                    }
                    hook.TearDownTest();

                    logger.info("Hook teardown");
                } catch (Exception e) {
                    logger.error("no hook setup:"+e);
                }   
        } catch (Exception e) {
            logger.error("no new Hook");
        }

        return "done"; 
    }
    
}
