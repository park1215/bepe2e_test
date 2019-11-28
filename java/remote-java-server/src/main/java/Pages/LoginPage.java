package Pages;

import StepDefinitions.Hook;
import com.viasat.SeleniumWebDriver.Driver;
import encryptdecrypt.EncryptDecrypt;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.testng.Assert;

//import org.apache.commons.logging.Log;
//import org.apache.commons.logging.LogFactory;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class LoginPage {

    WebDriver driver;

    //public Log logger = LogFactory.getLog(LoginPage.class);
    public Logger logger = LogManager.getLogger(LoginPage.class);

    @FindBy(xpath = "//*[@id=\"IDToken1\"]")
    public WebElement username;

    @FindBy(id = "IDToken2")
    public WebElement password;

    @FindBy(name = "Login.Submit")
    public WebElement SubmitButton;

    @FindBy(id = "login-help")
    public WebElement LoginHelp;

    @FindBy(xpath = "//img[contains(@src, 'int_vsat_TM_rgb_grd.png')]")
    public WebElement LoginLogo;

    @FindBy(xpath = "//h1")
    public WebElement SignintoViaSat;

    @FindBy(id = "userNavLabel")
    public WebElement Userimage;

    @FindBy(id = "app_logout")
    public WebElement Logout;

    @FindBy(xpath = "//button[contains(text(), 'Close')]")
    public WebElement Close;


    public LoginPage(WebDriver driver)
    {
        this.driver = driver;
        PageFactory.initElements(driver, this);
    }


    public void login(String uname, String pwd) {
        logger.info("Logging in to the application");
        username.click();
        username.clear();
        logger.info("Entering username: "+uname);
        Driver.action.sendKeys(username, uname).build().perform();
        password.click();
        password.clear();
        try {
            Driver.action.sendKeys(password, EncryptDecrypt.decrypt(pwd)).build().perform();
        }catch (Exception e){
            logger.info("Decrypting password failed");
        } 
        logger.info("Submitting login");
        SubmitButton.click();
        
    }

    public void WaitforLoginPage() {
        logger.info("Waiting for the login page title to be Retailer Portal: Login");
        Driver.wait.until(ExpectedConditions.titleIs("Retailer Portal: Login"));
        logger.info("Waiting for username to be displayed");
        Driver.wait.until(ExpectedConditions.visibilityOf(username));
        Driver.wait.until(ExpectedConditions.jsReturnsValue("return document.readyState==\"complete\";"));
    }
    
}
