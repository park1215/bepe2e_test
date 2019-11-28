package Utility;

public class Constant {

    public String qa1url = "https://viasat--qa1.cs32.my.salesforce.com/console";

    public String uaturl = "https://viasat--uat.cs32.my.salesforce.com/console";

    public String testinstance = System.getProperty("env");

    public String browser = System.getProperty("browser");

    public static String workingDir = System.getProperty("user.dir").replace('\\', '/');

    public String screenshotspath = workingDir+"/screenshots/";
    
    public String logfilepath = workingDir+"/logs/";

    public String username = "xeroxdsapi2qa";

    public String password = "fyNcN+k8xoH9q+R3CauGtA==";


    public String Appurl() {
        if(testinstance.equals("qa1"))
            return qa1url;
        else
            return uaturl;
    }

    public String getdriverpath() {
        if(System.getProperty("os.name").contains("Windows")) {
            if (browser.equals("chrome")) return workingDir + "/executables/chromedriver.exe";
            else return workingDir + "/executables/geckodriver.exe";
        }else {
            if (browser.equals("chrome")) return workingDir + "/executables/chromedriver";
            else return workingDir + "/executables/geckodriver";
        }
    }

}
