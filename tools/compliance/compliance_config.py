POLL_INTERVAL_MSEC = 86400000
productConfigHeaders = ["PRODUCT_FAMILY_ID","PRODUCT_FAMILY","PRODUCT_ID","PRODUCT_NAME","SALES_START_DATE","SALES_END_DATE","TAX_CATEGORY","TAX_CODE"]
productAttributeHeaders = ["PRODUCT_FAMILY_ID","PRODUCT_FAMILY_NAME","PRODUCT_ID","PRODUCT_NAME","DISPLAY_POSITION","ATTRIBUTE_UA_NAME","ATTRIBUTE_BILL_NAME","MANDATORY_BOO"]
#tariffConfigHeaders = ["CURRENT_CATALOG_ID","MARKET_SEGMENT_NAME","PRODUCT_FAMILY","PRODUCT_ID","PRODUCT_NAME","PARENT_TARIFF_ID","CHILD_TARIFF_ID","CHILD_PRICE_PLAN","CHILD_PRICE_PLAN_DESC"]
tariffConfigHeaders = ["CURRENT_CATALOG_ID","MARKET_SEGMENT_NAME","PRODUCT_FAMILY","PRODUCT_ID","PRODUCT_NAME","PARENT_TARIFF_ID","CHILD_TARIFF_ID","CHILD_PRICE_PLAN","CHILD_PRICE_PLAN_DESC", \
              "Tax_Category_ID","TAX_CATEGORY","TAX_CODE_ID","TAX_CODE","CHARGE_PERIOD","CHARGE_PERIOD_UNITS","IS_BILLED_IN_ADVANCE","IS_PRORATEABLE","IS_REFUNDABLE","IS_MARGINAL_PRICE_PLAN", \
              "HAS_CONTRACT","CONTRACT_TERM","CONTRACT_TERM_UNITS","INIT_REV_CODE","ONE_TIME_CHARGE","RECURRING_REV_CODE","RECURRING_RATE","MIN_OVERRIDE_PRICE","MAX_OVERRIDE_PRICE", \
              "SUSPEND_RATE","SUSP_REV_CODE","SUSPEND_RECURRING_RATE","USP_RECUR_REV_CODE","TERM_REV_CODE","TERM_CHARGE","ETF_REV_CODE","EARLY_TERM_FEE","IS_ETF_PRORATEABLE"]
otcChargesHeaders = ["CURRENT_CATALOG","MARKET_SEGMENT","OTC_ID","OTC","OTC_TYPE","OTC_TARIFF","PRICE_MNY","MIN_PRICE","MAX_PRICE","REVENUE_CODE","UST_CATEGORY","UST_CATEGORY_ID","UST_CODE","UST_CODE_ID"]
otcAttributeHeaders = ["CURRENT_CATALOG","MARKET_SEGMENT","OTC_ID","OTC","ATTRIBUTE_NAME","MANDATORY_BOO","DISPLAY_POSITION"]
taxCodesHeaders = ["PRODUCT_FAMILY_ID","PRODUCT_FAMILY","PRODUCT_ID","PRODUCT_NAME","SALES_START_DATE","SALES_END_DATE","CATEGORY_ID","TAX_CATEGORY","CODE_ID","TAX_CODE"]
taxComboHeaders = ["UST_CATEGORY_ID","UST_CODE_ID","UST_CHARGE_GROUP_ID"]
olfmHeaders = ["RB_CHARGE_SEQ","RB_CHARGE_TYPE","RB_CHARGE_TYPE_NAME","RB_CHARGE_ID","RB_CHARGE_TARIFF_ID","RB_CHARGE_NAME","OLFM_PRODUCT_ID","OLFM_PAYMENT_TYPE_CODE"]

productFamilyIdQuery = "SELECT product_family_id FROM geneva_admin.productfamily WHERE product_family_name = "
productIdQuery = "SELECT product_id FROM geneva_admin.product WHERE product_name = "

taxComboQuery = "SELECT * FROM GENEVA_ADMIN.USTCATEGORYCODEVALID"

olfmQuery = "SELECT * FROM RB_CUSTOM.IPGOLFMPRODUCTMAP"

taxCodesQuery = \
"SELECT DISTINCT  \
    product.product_family_id AS product_family_id  \
   ,productfamily.product_family_name  AS product_family  \
   ,product.product_id AS product_ID  \
   ,product.product_name AS product_name  \
   ,product.sales_start_dat AS sales_start_date  \
   ,product.sales_end_dat AS sales_end_date  \
   ,ustcategory.external_category_ID AS Category_ID  \
   ,ustcategory.external_category_name AS tax_category  \
   ,ustcode.external_code_ID AS Code_ID  \
   ,ustcode.external_code_name AS tax_code  \
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
    product.product_family_id"

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
    marketsegment.market_segment_name  \
   ,otctariff.otc_tariff_name  \
   ,onetimechargeattribute.display_position"

otcChargesQuery = \
"SELECT  \
           otctariff.catalogue_change_id AS current_catalog   \
          ,marketsegment.market_segment_name AS market_segment   \
          ,otctariff.otc_id AS otc_id   \
          ,otc.otc_name AS otc   \
          ,otctype.otc_type_name AS otc_type   \
          ,otctariff.otc_tariff_name AS otc_tariff   \
          ,otctariff.price_mny AS price_mny   \
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
           marketsegment.market_segment_name   \
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
            productfamily.product_family_id  \
           ,productattribute.product_id  \
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
           marketsegment.market_segment_name   \
          ,tariffelementband.product_id   \
          ,tariff.parent_tariff_id   \
          ,tariff.tariff_id"


productConfigQuery = "SELECT DISTINCT \
            product.product_family_id AS product_family_id \
           ,productfamily.product_family_name  AS product_family \
           ,product.product_id AS product_ID \
           ,product.product_name AS product_name \
           ,product.sales_start_dat AS sales_start_date \
           ,product.sales_end_dat AS sales_end_date \
           ,ustcategory.external_category_name AS tax_category \
           ,ustcode.external_code_name AS tax_code \
  FROM \
           geneva_admin.product product \
          ,geneva_admin.productfamily \
          ,geneva_admin.ustproductcategorycode ustproductcategorycode \
          ,geneva_admin.ustcategory ustcategory \
          ,geneva_admin.ustcode ustcode \
WHERE \
           product.product_family_id = productfamily.product_family_id \
    AND product.product_id = ustproductcategorycode.product_id (+) \
    AND ustproductcategorycode.ust_category_id = ustcategory.ust_category_id \
    AND ustproductcategorycode.ust_code_id = ustcode.ust_code_id \
ORDER BY \
           product.product_family_id \
          ,product.product_id"

configQueries = {"productConfig":productConfigQuery,"tariffConfig":tariffConfigQuery,"productAttribute":productAttributeQuery,"otcCharges":otcChargesQuery,"otcAttribute":otcAttributeQuery, \
                 "taxCodes":taxCodesQuery,"taxCombo":taxComboQuery,"olfm":olfmQuery}
configHeaders = {"productConfig":productConfigHeaders,"tariffConfig":tariffConfigHeaders,"productAttribute":productAttributeHeaders,"otcCharges":otcChargesHeaders,"otcAttribute":otcAttributeHeaders, \
                 "taxCodes":taxCodesHeaders,"taxCombo":taxComboHeaders,"olfm":olfmHeaders}
robotTestsResultLookup = {"Product Configuration":"productConfig","Tariff Configuration":"tariffConfig","Product Attribute":"productAttribute","OTC Charges":"otcCharges",\
              "OTC Attribute":"otcAttribute", "Tax Codes":"taxCodes","Tax Combo":"taxCombo","OLFM":"olfm"}
