IRA_JWT_URL="https://jwt.us-or.viasat.io/v1/token?stripe=bep-ira&name=default"
IRA_ROLE="Admin"
#IRA_DEV_URL="http://localhost:8080/graphql"
#IRA_DEV_URL="https://dev.bep-ira-nonprod.viasat.io/graphql"
IRA_PP_URL="https://preprod.bep-ira-nonprod.viasat.io/graphql"
IRA_TEST_GROUPS="AcceptanceTesting"
IRA_MEX_PROVIDER_GROUP="MexicoResidential"
IRA_EU_PROVIDER_GROUP="EUResidential"
#IRA_EU_PROVIDER_GROUP="MexicoResidential"
#IRA_MEX_PROVIDER_ID="fe34ee49-6198-44b0-a96a-baa39bf59175"
#ADD_INDIVIDUAL_PAYLOAD={"query": "mutation {addIndividual(deduplicationId: DE_DUP_ID, groups: GROUPS, fullName: FULL_NAME){partyId fullName, version, groups{groupName}}}"}
#ADD_INDIVIDUAL_PAYLOAD={"query": "mutation {addIndividual(deduplicationId: \""+deDupId+"\", groups: \""+groups+"\", fullName: \""+fullName+"\"){partyId fullName, version, groups{groupName}}}"}
#IRA_SPAIN_TIN="spain_tin"
IRA_NOR_TIN="norway_tin"
IRA_POL_TIN="poland_tin"
#IRA_MEX_TIN="mexico_rfc_id"
#IRA_EUR_VAT_TYPE="vat_identification_number"
IRA_S3_BILLING_PII_BUCKET="preprod-ira-spb-pii-exporter-pii-files"
IRA_BILLING_PII_FILENAME="pii.csv"