package Utility;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.text.RandomStringGenerator;

public class Order {
    public String firstname = "Automation";
    public String lastname = "Test";
    public String middlename = "";
    public String streetaddress1 = "6155 El Camino Real";
    public String streetaddress2 = "APT 102";
    public String city = "Carlsbad";
    public String state = "CA";
    public String zipcode = "92009";
    public String email = "qateamtest@viasat.com";
    public String phonenumber = "234-567-8901";
    public String streetnumber = "6155";
    public String streetname = "El Camino Real";
    public String voicepassword = "Password@1";
    public String DateofBirth = "01/01/1988";
    public String CreditCardNumber = "4012000077777777";
    public String ExpiryMonth = "Apr";
    public String ExpiryYear = "2019";
    public String Billingzip = "63146";
    public String AccountType = "Checking";
    public String BankRoutingNumber = "000000000";
    public String BankAccountNumber = "1111";
    public String ExternalReferenceNumber  = "";
    public String InternalReferenceNumber = "";
    public String ServiceAgreementNumber = "";
    public String OrderType = "Residential";
    public String Optout = "Decline";
    public String EquipmentType = "Monthly";
    public String EasyCare = "Decline";
    public String Voice = "Decline";
    public String DTV = "Decline";
    public String Campaign = "NONE";
    public String Company = "n/a";
    public List<String> Allplans = new ArrayList<String>();

    public Order(){
        String random = new RandomStringGenerator.Builder().withinRange('a', 'z').build().generate(5);
        firstname+=random;
        lastname+=random;
    }
}
