SPB_JWT_URL="https://jwt.us-or.viasat.io/v1/token?stripe=spb-nonprod&name=gql-api"
SPB_DEV_URL="https://dev.spb-stub.spb-nonprod.viasat.io/graphql"
SPB_TEST_URL="https://test.spb.spb-nonprod.viasat.io/graphql"
SPB_PP_URL="https://api.preprod.spb-nonprod.viasat.io/graphql"
SPB_PP_GQL_VERSION_URL="https://api.preprod.spb-nonprod.viasat.io"
SPB_PYMT_TXN_VERSION_URL="https://dev.spb-pmttxn.spb-nonprod.viasat.io"
SPB_BULK_PYMT_VERSION_URL="https://test.spb-payments.spb-nonprod.viasat.io"
SPB_POF_UPDATE_VERSION_URL="https://dev.spb-pof-update.spb-nonprod.viasat.io"

SPB_VERSION_URLS={"SPB Graphql API":SPB_PP_GQL_VERSION_URL,"SPB Payment Transaction":SPB_PYMT_TXN_VERSION_URL,"SPB Bulk Payment":SPB_BULK_PYMT_VERSION_URL,"SPB POF Update":SPB_POF_UPDATE_VERSION_URL}

RB_QA_HOST = "rbm.api.dev.rbm.viasat.com"
RB_QA_PORT = '1522'
RB_QA_SERVICE_NAME = 'vsrba3'
RB_QA_DSN="""(DESCRIPTION=
(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCPS)(HOST=rbm.api.dev.rbm.viasat.com)(PORT=1522)))
(CONNECT_DATA=(SERVICE_NAME=vsrba3)))"""

# applies to VSP response, and also accountpayment and physicalpayment tables in NC
VSP_PAYMENT_STATUS = {0:"Pending",1:"Created",2:"Cancelled",3:"Failed"}
# following in NC's paymentrequest table
NC_PAYMENT_STATUS = {1:"Waiting to be processed",2:"Exported for external processing",3:"Paid",4:"Canceled",5:"Request faulted by collection subsystem",6:"Re-presented"}
# in prmandate table
MANDATE_STATUS = {1:"Pending",2:"Active",3:"Used",4:"OneOff",5:"Expired"}

S3_IRA_PII_FILE_BUCKET = "preprod-ira-spb-pii-exporter-pii-files"
S3_PSM_PII_FILE_BUCKET ="psm-preprod-pii-exporter-pii-files"
S3_IRA_PII_FILENAME = "pii.csv"
S3_PSM_PII_FILENAME = "location-pii.csv"

SPB_SNS_TOPIC = "arn:aws:sns:us-west-2:206977378963:spb-events-preprod"