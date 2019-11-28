package StepDefinitions;

import Utility.Constant;
import Utility.Order;
import com.viasat.SeleniumWebDriver.Driver;
import com.viasat.SeleniumWebDriver.GetDriver;
import org.apache.commons.io.FileUtils;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;

import javax.imageio.ImageIO;
import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class Hook {

    WebDriver driver;
    private static boolean initialized = false;
    public Constant constant = new Constant();
    public Order dto = new Order();
    public Log logger = LogFactory.getLog(Hook.class);
    
    public void setUp()
    {
        logger.info("Deleting all screen shots in workspace");
        if (!initialized) {
            try {
                logger.info("Deleting all screen shots in workspace");
                FileUtils.cleanDirectory(new File(constant.screenshotspath));
            } catch (Exception e) {
                logger.info("Exception deleting all screen shots in workspace");
            }
            initialized = true;
        }
       
        try {
            driver = new GetDriver().startDriver("chrome", "headless");
            driver.manage().window().maximize();
            Driver.initcommonobjects(driver);
            driver.get("https://uat-myexede.cs32.force.com/dealerportal/login");

            // replace this with a "wait for page to appear"
            Thread.sleep(4000);
            try {
                String result = screenshot();          
            } catch (Exception e) {
            }

        } catch (Exception e) {
            logger.info("exception = "+e);
        }

    }

    public  void TearDownTest()
    {
        driver.quit();
        driver = null;
    }

    public WebDriver getDriver() {
        return driver;
    }

    public String screenshot() {
        driver.switchTo().defaultContent();

        String result = "login";
        String outFolderScreenshots = constant.screenshotspath;
        logger.info("Trying to take screenshot");
        String time = new SimpleDateFormat("MMddyyyy_HHmmss").format(Calendar.getInstance().getTime());
        result = outFolderScreenshots+"Cucumber_"+time+".png";
        try {
            File f1 = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
            FileUtils.copyFile(f1, new File(result)); // Location to save screenshot
            result = "Screenshot was saved in "+result;
        }
        catch(Exception e){
            result = "\n" + "Exception to capture screenshot in "+result+" :"+e.getMessage();
        }
        logger.info(result);
        return result;
    }

}
