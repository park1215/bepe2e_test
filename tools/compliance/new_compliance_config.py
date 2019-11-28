POLL_INTERVAL_MSEC = 86400000
productConfigHeaders = ["Product_Family_ID","Product_Family","Product_ID","Product_Name","Sales_Start_Date","Sales_End_Date","Tax_Category_Description","Tax_Code_Description"]
productAttributeHeaders = ["Product_Family_ID","Product_Family","Product_ID","Product_Name","Display_Position","Attribute_UA_Name","Attribute_Bill_Name","Mandatory"]
tariffConfigHeaders = ["Current_Catalog_ID","Market_Segment_Name","Product_Family","Product_ID","Product_Name","Parent_Tariff_ID","Child_Tariff_ID","Child_Price_Plan","Child_Price_Plan_Desc", \
              "Tax_Category_ID","Tax_Category_Description","Tax_Code_ID","Tax_Code_Description","Charge_Period","Charge_Period_Units","Billed_In_Advance","Proratable","Refundable","Marginal_Price_Plan", \
              "Has_Contract","Contract_Term","Contract_Term_Units","Init_Rev_code","One_Time_Charge","Rev_Code","Recurring_Rate","Min_Override_Price","Max_Override_Price", \
              "Suspend_Rate","Suspend_Rev_Code","Suspend_Recurring_Rate","Suspend_Recur_Rev_Code ","Term_Rev_Code","Term_Charge","ETF_Rev_Code","Early_Term_Fee","ETF_Proratable"]
otcChargeHeaders = ["Current_Catalog_ID","Market_Segment_Name","OTC_ID","OTC","OTC_Type_Name","OTC_Tariff_Name ","Min_Charge","Max_Charge","Rev_Code","Tax_Category_Description","Tax_Category_ID","Tax_Code_Description","Tax_Code_ID"]
otcAttributeHeaders = ["Current_Catalog_ID","Market_Segment_Name","OTC_ID","OTC","OTC_Attribute_Name","Mandatory","Display_Position"]
taxCodeHeaders = ["Product_Family_ID","Product_Family","Product_ID","Product_Name","Sales_Start_Date","Sales_End_Date","Tax_Category_ID","Tax_Category_Description","Tax_Code_ID","Tax_Code_Description"]
taxComboHeaders = ["UST_Tax_Category_ID","UST_Tax_Code_ID","Charge_Group_Id "]
olfmHeaders = ["RB_CHARGE_SEQ","RB_CHARGE_TYPE","RB_CHARGE_TYPE_NAME","RB_CHARGE_ID","RB_CHARGE_TARIFF_ID","RB_CHARGE_NAME","OLFM_PRODUCT_ID","OLFM_PAYMENT_TYPE_CODE"]

productFamilyIdQuery = "SELECT product_family_id FROM geneva_admin.productfamily WHERE Product_Family = "
productIdQuery = "SELECT product_id FROM geneva_admin.product WHERE product_name = "

taxComboQuery = "SELECT * FROM GENEVA_ADMIN.USTCATEGORYCODEVALID"

olfmQuery = "SELECT * FROM RB_CUSTOM.IPGOLFMPRODUCTMAP"

taxCodeQuery = \
"SELECT DISTINCT  \
    product.product_family_id AS Product_Family_ID  \
   ,productfamily.product_family_name  AS Product_Family  \
   ,product.product_id AS Product_ID  \
   ,product.product_name AS Product_Name  \
   ,product.sales_start_dat AS Sales_Start_Date  \
   ,product.sales_end_dat AS Sales_End_Date  \
   ,ustcategory.external_category_ID AS Tax_Category_ID  \
   ,ustcategory.external_category_name AS Tax_Category_Description  \
   ,ustcode.external_code_ID AS Tax_Code_ID  \
   ,ustcode.external_code_name AS Tax_Code_Description  \
  FROM  \
    geneva_admin.product product  \
   ,geneva_admin.productfamily  \
   ,geneva_admin.ustproductcategorycode ustproductcategorycode  \
   ,geneva_admin.ustcategory ustcategory  \
   ,geneva_admin.ustcode ustcode  \
WHERE  \
    product.product_family_id = productfamily.product_family_id  \
    AND product.product_id = ustproductcategorycode.product_id (+)  \
    AND ustproductcategorycode.ust_category_id = ustcategory.ust_category_id  \
    AND ustproductcategorycode.ust_code_id = ustcode.ust_code_id  \
ORDER BY  \
    product.product_id \
    ,product.product_family_id"

otcAttributeQuery = \
"SELECT \
    otctariff.catalogue_change_id AS current_catalog  \
   ,marketsegment.market_segment_name AS market_segment  \
   ,otctariff.otc_id AS otc_id  \
   ,otc.otc_name AS otc  \
   ,onetimechargeattribute.attribute_name   \
   ,onetimechargeattribute.mandatory_boo  \
   ,onetimechargeattribute.display_position  \
 FROM  \
    geneva_admin.onetimechargetariff otctariff  \
   ,geneva_admin.onetimecharge otc  \
   ,geneva_admin.otchasmarketsegment otchasmarketsegment  \
   ,geneva_admin.marketsegment marketsegment  \
   ,geneva_admin.onetimechargeattribute  \
WHERE  \
    otc.otc_id = otchasmarketsegment.otc_id  \
    AND otchasmarketsegment.market_segment_id = marketsegment.market_segment_id  \
    AND otc.otc_id = otctariff.otc_id  \
    AND otctariff.catalogue_change_id = (SELECT max(catalogue_change_id)  \
    FROM geneva_admin.onetimechargetariff)  \
    AND otc.otc_id = onetimechargeattribute.otc_id  \
ORDER BY  \
     otctariff.catalogue_change_id \
    ,otctariff.otc_id \
    ,marketsegment.market_segment_name  \
    ,otctariff.otc_tariff_name  \
    ,onetimechargeattribute.display_position"

otcChargeQuery = \
"SELECT  \
           otctariff.catalogue_change_id AS current_catalog   \
          ,marketsegment.market_segment_name AS market_segment   \
          ,otctariff.otc_id AS otc_id   \
          ,otc.otc_name AS otc   \
          ,otctype.otc_type_name AS otc_type   \
          ,otctariff.otc_tariff_name AS otc_tariff   \
          ,otctariff.min_price_mny AS min_price   \
          ,otctariff.max_price_mny AS max_price   \
          ,revenuecode.revenue_code_name AS revenue_code   \
          ,ustcategory.external_category_name AS ust_category   \
          ,ustcategory.external_category_id AS ust_category_id   \
          ,ustcode.external_code_name AS ust_code   \
          ,ustcode.external_code_id AS ust_code_id   \
 FROM   \
           geneva_admin.onetimechargetariff otctariff   \
          ,geneva_admin.onetimecharge otc   \
          ,geneva_admin.revenuecode revenuecode   \
          ,geneva_admin.onetimechargetype otctype   \
          ,geneva_admin.ustcategory ustcategory   \
          ,geneva_admin.ustcode ustcode   \
          ,geneva_admin.otchasmarketsegment otchasmarketsegment   \
          ,geneva_admin.marketsegment marketsegment   \
WHERE   \
           otc.otc_id = otchasmarketsegment.otc_id   \
    AND otchasmarketsegment.market_segment_id = marketsegment.market_segment_id  \
    AND otc.otc_id = otctariff.otc_id   \
    AND otc.otc_type_id = otctype.otc_type_id   \
    AND otctype.ust_category_id = ustcategory.ust_category_id   \
    AND otctype.ust_code_id = ustcode.ust_code_id   \
    AND otctariff.default_revenue_code_id = revenuecode.revenue_code_id   \
    AND otctariff.catalogue_change_id = (SELECT max(catalogue_change_id)   \
         FROM geneva_admin.onetimechargetariff)   \
ORDER BY   \
            otctariff.catalogue_change_id \
           ,otctariff.otc_id \
           ,marketsegment.market_segment_name   \
           ,otctariff.otc_tariff_name"
    
productAttributeQuery =   \
"SELECT  \
            productfamily.product_family_id  \
           ,productfamily.product_family_name  \
           ,productattribute.product_id  \
           ,product.product_name  \
           ,productattribute.display_position  \
           ,productattribute.attribute_ua_name  \
           ,productattribute.attribute_bill_name  \
           ,productattribute.mandatory_boo  \
  FROM  \
            geneva_admin.productattribute  \
           ,geneva_admin.product  \
           ,geneva_admin.productfamily  \
WHERE  \
            productattribute.product_id = product.product_id  \
     AND product.product_family_id = productfamily.product_family_id  \
ORDER BY  \
            productattribute.product_id \
           ,productfamily.product_family_id  \
           ,productattribute.display_position"

tariffConfigQuery = \
"SELECT  \
           tariff.catalogue_change_id AS current_catalog_ID   \
          ,marketsegment.market_segment_name   \
          ,productfamily.product_family_name  AS product_family   \
          ,tariffelementband.product_id AS product_ID   \
          ,product.product_name AS product_Name   \
          ,tariff.parent_tariff_id AS parent_tariff_ID   \
          ,tariff.tariff_id AS child_tariff_ID   \
          ,tariff.tariff_name AS child_price_plan   \
          ,tariff.tariff_desc AS child_price_plan_desc   \
          ,ustcategory.external_category_ID AS tax_category_ID   \
          ,ustcategory.external_category_name AS tax_category   \
          ,ustcode.external_code_ID AS tax_code_ID   \
          ,ustcode.external_code_name AS tax_code   \
          ,tariffelement.charge_period AS charge_period   \
          ,tariffelement.charge_period_units AS charge_period_units   \
          ,tariffelement.in_advance_boo AS is_billed_in_advance   \
          ,tariffelement.pro_rate_boo AS is_prorateable   \
          ,tariffelement.refundable_boo AS is_refundable   \
          ,tariffelement.marginal_boo AS is_marginal_price_plan   \
          ,tariff.contract_terms_boo AS has_contract   \
          ,tariff.contract_term AS contract_term   \
          ,tariff.contract_term_units AS contract_term_units   \
          ,revenuecode1.revenue_code_name AS init_rev_code   \
          ,tariffelementband.one_off_number AS one_time_charge   \
          ,revenuecode2.revenue_code_name AS recurring_rev_code   \
          ,tariffelementband.recurring_number AS recurring_rate   \
          ,tariffelementoverride.recur_min_number AS min_override_price   \
          ,tariffelementoverride.recur_max_number AS max_override_price   \
          ,tariffelementband.susp_number AS suspend_rate   \
          ,revenuecode5.revenue_code_name AS susp_rev_code   \
          ,tariffelementband.susp_recur_number AS suspend_recurring_rate   \
          ,revenuecode6.revenue_code_name AS susp_recur_rev_code   \
          ,revenuecode3.revenue_code_name AS term_rev_code   \
          ,tariffelementband.termination_number AS term_charge   \
          ,revenuecode4.revenue_code_name AS etf_rev_code   \
          ,tariffelementband.early_term_mult_mny AS early_term_fee   \
          ,tariffelement.early_term_pro_rate_boo AS is_etf_prorateable   \
  FROM \
           geneva_admin.tariff tariff   \
          ,geneva_admin.tariffelement tariffelement   \
          ,geneva_admin.tariffelementhasmktsegment   \
          ,geneva_admin.tariffelementband tariffelementband   \
          ,geneva_admin.tariffelementoverride   \
          ,geneva_admin.revenuecode revenuecode1   \
          ,geneva_admin.revenuecode revenuecode2   \
          ,geneva_admin.revenuecode revenuecode3   \
          ,geneva_admin.revenuecode revenuecode4   \
          ,geneva_admin.revenuecode revenuecode5   \
          ,geneva_admin.revenuecode revenuecode6   \
          ,geneva_admin.product product   \
          ,geneva_admin.productfamily   \
          ,geneva_admin.ustproductcategorycode ustproductcategorycode   \
          ,geneva_admin.ustcategory ustcategory   \
          ,geneva_admin.ustcode ustcode   \
          ,geneva_admin.marketsegment   \
WHERE \
           tariffelementhasmktsegment.catalogue_change_id = (SELECT MAX(catalogue_change_id)   \
FROM    \
   geneva_admin.tariffelementhasmktsegment)  \
    AND tariffelementhasmktsegment.tariff_id = tariff.tariff_id   \
    AND tariffelementhasmktsegment.catalogue_change_id = tariff.catalogue_change_id   \
    AND tariffelementhasmktsegment.product_id = product.product_id   \
    AND tariffelementhasmktsegment.market_segment_id = marketsegment.market_segment_id   \
    AND tariff.catalogue_change_id = tariffelementband.catalogue_change_id   \
    AND tariff.tariff_id = tariffelementband.tariff_id   \
    AND tariffelementband.product_id = product.product_id   \
    AND tariffelementband.catalogue_change_id =    tariffelementhasmktsegment.catalogue_change_id  \
    AND tariffelementband.product_id = tariffelementhasmktsegment.product_id   \
    AND tariffelementhasmktsegment.market_segment_id = marketsegment.market_segment_id   \
    AND tariffelementband.tariff_id = tariffelementoverride.tariff_id (+)   \
    AND tariffelementband.product_id = tariffelementoverride.product_id (+)   \
    AND tariffelementband.catalogue_change_id = tariffelementoverride.catalogue_change_id (+)   \
    AND product.product_id = tariffelement.product_id   \
    AND product.product_family_id = productfamily.product_family_id   \
    AND tariff.tariff_id = tariffelement.tariff_id   \
    AND tariff.catalogue_change_id = tariffelement.catalogue_change_id   \
    AND tariffelement.init_revenue_code_id = revenuecode1.revenue_code_id   \
    AND tariffelement.recur_revenue_code_id = revenuecode2.revenue_code_id   \
    AND tariffelement.susp_rev_code_id = revenuecode5.revenue_code_id   \
    AND tariffelement.susp_recur_rev_code_id = revenuecode6.revenue_code_id   \
    AND tariffelement.term_revenue_code_id = revenuecode3.revenue_code_id   \
    AND tariffelement.early_term_mult_rev_code_id = revenuecode4.revenue_code_id (+)   \
    AND product.product_id = ustproductcategorycode.product_id (+)   \
    AND ustproductcategorycode.ust_category_id = ustcategory.ust_category_id   \
    AND ustproductcategorycode.ust_code_id = ustcode.ust_code_id   \
GROUP BY \
           tariff.catalogue_change_id   \
          ,marketsegment.market_segment_name   \
          ,productfamily.product_family_name   \
          ,tariffelementband.product_id   \
          ,product.product_name   \
          ,tariff.tariff_name   \
          ,tariff.tariff_id   \
          ,tariff.tariff_desc   \
          ,tariff.parent_tariff_id   \
          ,ustcategory.external_category_ID   \
          ,ustcategory.external_category_name   \
          ,ustcode.external_code_ID   \
          ,ustcode.external_code_name   \
          ,tariffelement.charge_period   \
          ,tariffelement.charge_period_units   \
          ,tariffelement.in_advance_boo   \
          ,tariffelement.pro_rate_boo   \
          ,tariffelement.refundable_boo   \
          ,tariffelement.marginal_boo   \
          ,tariff.contract_terms_boo   \
          ,tariff.contract_term   \
          ,tariff.contract_term_units   \
          ,revenuecode1.revenue_code_name   \
          ,tariffelementband.one_off_number   \
          ,revenuecode2.revenue_code_name   \
          ,tariffelementband.recurring_number   \
          ,tariffelementoverride.recur_min_number   \
          ,tariffelementoverride.recur_max_number   \
          ,tariffelementband.susp_number   \
          ,revenuecode5.revenue_code_name   \
          ,tariffelementband.susp_recur_number   \
          ,revenuecode6.revenue_code_name   \
          ,revenuecode3.revenue_code_name   \
          ,tariffelementband.termination_number   \
          ,revenuecode4.revenue_code_name   \
          ,tariffelementband.early_term_mult_mny   \
          ,tariffelement.early_term_pro_rate_boo   \
ORDER BY   \
            tariff.tariff_id \
           ,marketsegment.market_segment_name   \
          ,tariffelementband.product_id   \
          ,tariff.parent_tariff_id"


productConfigQuery = "SELECT DISTINCT \
            product.product_family_id AS Product_Family_ID \
           ,productfamily.product_family_name  AS Product_Family \
           ,product.product_id AS Product_ID \
           ,product.product_name AS Product_Name \
           ,product.sales_start_dat AS Sales_Start_Date \
           ,product.sales_end_dat AS Sales_End_Date \
           ,ustcategory.external_category_name AS Tax_Category_Description \
           ,ustcode.external_code_name AS Tax_Code_Description \
  FROM \
           geneva_admin.product product \
          ,geneva_admin.productfamily productfamily\
          ,geneva_admin.ustproductcategorycode ustproductcategorycode \
          ,geneva_admin.ustcategory ustcategory \
          ,geneva_admin.ustcode ustcode \
WHERE \
           product.product_family_id = productfamily.product_family_id \
    AND product.product_id = ustproductcategorycode.product_id (+) \
    AND ustproductcategorycode.ust_category_id = ustcategory.ust_category_id \
    AND ustproductcategorycode.ust_code_id = ustcode.ust_code_id \
ORDER BY \
            product.product_id \
            ,product.product_family_id "

configQueries = {"productConfig":productConfigQuery,"tariffConfig":tariffConfigQuery,"productAttribute":productAttributeQuery,"otcCharge":otcChargeQuery,"otcAttribute":otcAttributeQuery, \
                 "taxCode":taxCodeQuery,"taxCombo":taxComboQuery,"olfm":olfmQuery}
#configQueries = {"productConfig":productConfigQuery}
configHeaders = {"productConfig":productConfigHeaders,"tariffConfig":tariffConfigHeaders,"productAttribute":productAttributeHeaders,"otcCharge":otcChargeHeaders,"otcAttribute":otcAttributeHeaders, \
                 "taxCode":taxCodeHeaders,"taxCombo":taxComboHeaders,"olfm":olfmHeaders}
robotTestsResultLookup = {"Product Configuration":"productConfig","Tariff Configuration":"tariffConfig","Product Attribute":"productAttribute","OTC Charge":"otcCharge",\
              "OTC Attribute":"otcAttribute", "Tax Code":"taxCode","Tax Combo":"taxCombo","OLFM":"olfm"}
