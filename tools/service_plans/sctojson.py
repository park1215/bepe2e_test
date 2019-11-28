import json
import os
import re
import edn_format
COUNTRY="mexico"
def _repl(m):
    return '"'+m.group(1)+'"'
def _realPath(filename):
    return os.path.join(os.path.dirname(os.path.realpath(__file__)),filename)
def _readServiceIds(filename):
    try:
        with open(_realPath(filename)) as json_file:
            business_plans_json = json.load(json_file)
    except FileNotFoundError: 
        print(os.getcwd())
        print("business plan file not found")
        return False
    except Exception as e:
        print("Error reading business plan file:"+ str(e))
        return False
    return business_plans_json

business_plans_json = _readServiceIds(COUNTRY+"_business_plans.json")
business_plans = business_plans_json[COUNTRY]

f=open("service_catalog.txt","r")
catalog_edn_string = f.read()
f.close()
catalog_json = edn_format.loads(catalog_edn_string)
catalog_json_string = str(catalog_json)

# finish converting edn format to json
catalog_json_string = re.sub('Keyword\(([a-zA-Z0-9\-]*)\)',_repl,catalog_json_string)
catalog_json_string = re.sub("'",'"', catalog_json_string)
catalog_json_string = re.sub("True","true",catalog_json_string)
catalog_json_string = re.sub("False","false",catalog_json_string)
catalog_json_string = re.sub("\(","[",catalog_json_string)
catalog_json_string = re.sub("\)","]",catalog_json_string)

catalog_json = json.loads(catalog_json_string)
business_plan_service_flow_ids = {}

# extract and save service data flow ids
for package in catalog_json['packages']:
    if package['catalogId'] in business_plans_mex:
        service_flow_ids = []
        for id in package['WiMAX-Attributes']['WiMAX-Packet-Flow-Descriptor']:
            service_flow_ids.append(id['WiMAX-Service-Data-Flow-Id'])
        business_plan_service_flow_ids[package['catalogId']] = service_flow_ids

f = open(COUNTRY+"_service_catalog.json","w")
f.write(str(business_plan_service_flow_ids))
f.close()
