account_query = \
"""SELECT acc_num,
wb_ref,
status,
status_reason,
total_paid_tot,
TO_CHAR(effective_dtm, 'YYYY-MM-DD HH24:MI:SS') AS created_date,
TO_CHAR(next_bill_dtm, 'YYYY-MM-DD HH24:MI:SS') AS next_bill_date
FROM
(SELECT acc_num,
sub_ref,
prd_seq,
prd_id,
tariff_id,
wb_ref,
status,
status_reason,
total_paid_tot,
next_bill_dtm,
effective_dtm,
event_source,
start_dtm,
end_dtm,
LEAD(event_source,1,NULL) OVER (PARTITION BY cust_ref ORDER BY cust_ref,prd_seq,effective_dtm,end_dtm) AS next_mac_by_cust
FROM
(SELECT ac.customer_ref AS cust_ref,
ac.account_num AS acc_num,
ac.next_bill_dtm AS next_bill_dtm,
chp.subscription_ref AS sub_ref,
cps.product_seq AS prd_seq,
chp.product_id AS prd_id,
cptd.tariff_id,
cpad.attribute_value AS wb_ref,
p.product_name,
t.tariff_name,
cps.product_status AS status,
cps.status_reason_txt AS status_reason,
ac.total_paid_tot AS total_paid_tot,
cps.effective_dtm,
ces.event_source,
ces.start_dtm,
end_dtm
FROM geneva_admin.custhasproduct chp,
geneva_admin.product p,
geneva_admin.custproductstatus cps,
geneva_admin.custproductattrdetails cpad,
geneva_admin.account ac,
geneva_admin.accountattributes aa,
geneva_admin.custproducttariffdetails cptd,
geneva_admin.tariff t,
geneva_admin.custeventsource ces,
geneva_admin.productattribute pa,
(SELECT TO_DATE('2099-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS') AS end_date
FROM dual ) a
WHERE ac.account_num = aa.account_num(+)
AND pa.product_id = p.product_id
AND pa.ATTRIBUTE_UA_NAME = 'INVOICE_DISPLAY_NAME'
AND cpad.PRODUCT_ATTRIBUTE_SUBID=pa.PRODUCT_ATTRIBUTE_SUBID
AND p.product_name='%s'
AND ac.customer_ref = chp.customer_ref(+)
AND chp.product_id = p.product_id(+)
AND chp.customer_ref = cps.customer_ref(+)
AND chp.product_seq = cps.product_seq(+)
AND chp.customer_ref = cpad.customer_ref (+)
AND chp.product_seq = cpad.product_seq (+)
AND cps.customer_ref = cptd.customer_ref(+)
AND cps.product_seq = cptd.product_seq(+)
AND cptd.tariff_id = t.tariff_id(+)
AND chp.customer_ref = ces.customer_ref (+)
AND chp.product_seq = ces.product_seq (+)
AND cps.product_status = '%s'
AND ac.account_num in %s"""

subproduct_id_query = \
"""SELECT 			cust_ref,
        acc_num,
        sub_ref,
        prd_seq,
        prd_id,
        tariff_id,
        wb_ref,
        product_name,
        tariff_name,
        status,
        status_reason,
        TO_CHAR(effective_dtm, 'YYYY-MM-DD HH24:MI:SS') AS effective_date,
        event_source
      FROM
        (SELECT cust_ref,
          acc_num,
          sub_ref,
          prd_seq,
          prd_id,
          tariff_id,
          wb_ref,
          product_name,
          tariff_name,
          status,
          status_reason,
          effective_dtm,
          event_source
        FROM
          (SELECT ac.customer_ref AS cust_ref,
            ac.account_num AS acc_num,
            chp.subscription_ref   AS sub_ref,
            cps.product_seq        AS prd_seq,
            chp.product_id         AS prd_id,
            cptd.tariff_id,
            cpad.attribute_value AS wb_ref,
            p.product_name,
            t.tariff_name,
            cps.product_status    AS status,
            cps.status_reason_txt AS status_reason,
            cps.effective_dtm,
            ces.event_source
          FROM geneva_admin.custhasproduct chp,
            geneva_admin.product p,
            geneva_admin.custproductstatus cps,
            geneva_admin.custproductattrdetails cpad,
            geneva_admin.account ac,
            geneva_admin.custproducttariffdetails cptd,
            geneva_admin.tariff t,
            geneva_admin.custeventsource ces,
            (SELECT TO_DATE('2099-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS') AS end_date
            FROM dual ) a
          WHERE ac.customer_ref               = chp.customer_ref(+)
          AND chp.product_id                = p.product_id(+)
          AND chp.customer_ref              = cps.customer_ref(+) 
          AND chp.product_seq               = cps.product_seq(+)
          AND chp.customer_ref              = cpad.customer_ref (+)
          AND chp.product_seq               = cpad.product_seq (+)
          AND cps.customer_ref              = cptd.customer_ref(+)
          AND cps.product_seq               = cptd.product_seq(+)
          AND cptd.tariff_id               = t.tariff_id(+)     
          AND chp.customer_ref              = ces.customer_ref (+)
          AND chp.product_seq               = ces.product_seq (+)
          AND cpad.PRODUCT_ATTRIBUTE_SUBID=%d
          AND cps.product_status='%s'
          AND ac.account_num = '%s' ))"""

subproduct_name_query = \
"""SELECT 			cust_ref,
        acc_num,
        sub_ref,
        prd_seq,
        prd_id,
        tariff_id,
        wb_ref,
        subid,
        product_name,
        tariff_name,
        status,
        status_reason,
        TO_CHAR(effective_dtm, 'YYYY-MM-DD HH24:MI:SS') AS effective_date,
        event_source
      FROM
        (SELECT cust_ref,
          acc_num,
          sub_ref,
          prd_seq,
          prd_id,
          tariff_id,
          wb_ref,
          subid,
          product_name,
          tariff_name,
          status,
          status_reason,
          effective_dtm,
          event_source
        FROM
          (SELECT ac.customer_ref AS cust_ref,
            ac.account_num AS acc_num,
            chp.subscription_ref   AS sub_ref,
            cps.product_seq        AS prd_seq,
            chp.product_id         AS prd_id,
            cptd.tariff_id,
            cpad.attribute_value AS wb_ref,
            cpad.PRODUCT_ATTRIBUTE_SUBID AS subid,
            p.product_name,
            t.tariff_name,
            cps.product_status    AS status,
            cps.status_reason_txt AS status_reason,
            cps.effective_dtm,
            ces.event_source
          FROM geneva_admin.custhasproduct chp,
            geneva_admin.product p,
            geneva_admin.custproductstatus cps,
            geneva_admin.custproductattrdetails cpad,
            geneva_admin.account ac,
            geneva_admin.custproducttariffdetails cptd,
            geneva_admin.tariff t,
            geneva_admin.custeventsource ces,
            (SELECT TO_DATE('2099-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS') AS end_date
            FROM dual ) a
          WHERE ac.customer_ref               = chp.customer_ref(+)
          AND chp.product_id                = p.product_id(+)
          AND chp.customer_ref              = cps.customer_ref(+) 
          AND chp.product_seq               = cps.product_seq(+)
          AND chp.customer_ref              = cpad.customer_ref (+)
          AND chp.product_seq               = cpad.product_seq (+)
          AND cps.customer_ref              = cptd.customer_ref(+)
          AND cps.product_seq               = cptd.product_seq(+)
          AND cptd.tariff_id               = t.tariff_id(+)     
          AND chp.customer_ref              = ces.customer_ref (+)
          AND chp.product_seq               = ces.product_seq (+)
          AND chp.product_id = (SELECT DISTINCT cpad.product_id from custproductattrdetails cpad, account ac where cpad.customer_ref=ac.customer_ref AND  cpad.attribute_value='%s')
          AND cps.product_status='%s'
          AND ac.account_num = '%s'))"""
