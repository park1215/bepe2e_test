import sys
import argparse
import time
import datetime
import xml.etree.ElementTree as ET

HTML_START = '<!DOCTYPE html><html lang="en"><head><title>BEP E2E Test Run Times</title><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"> \
<link rel="stylesheet" type="text/css" href="response_times/response_times.css"> \
<style>.cell100.column3.time{font-size:18px;}</style> \
</head> \
<body><div class="limiter"><div class="container-table100"><div class="wrap-table100"><div class="table100 ver1 m-b-110"><div class="table100-head"><table><thead> \
<tr class="row100 head"><th class="cell100 column1" style="text-align:center;">Test Case</th><th class="cell100 column2" style="text-align:center;">Domains</th><th class="cell100 column3" style="text-align:center;">Seconds</th></tr></thead></table></div> \
<div class="table100-body js-pscroll"><table><tbody>'

HTML_END = '</tbody></table></div></div></div></div></div>'
def getTimes(filename):
    domains = ['OM','PSM','OFM','VPS','SPB','IRA','POM']
    fi = open(filename,"r")
    content = fi.read()
    fi.close()
    root = ET.fromstring(content)
    resources = root.findall('.//test')
    tests = []
    html = HTML_START
    for resource in resources:
        tagsOuter = resource.find('tags')
        if tagsOuter==None: continue
        tags = tagsOuter.findall('tag')
        tagnames = ''
        capture = False
        for tag in tags:
            tagname = tag.text.upper()
            if tagname in domains:
                if tagname=='POM': tagname = 'OFM'
                tagnames = tagnames + tag.text.upper() + '/'
            if tagname=='CAPTURERESPONSETIME':
                capture = True
        if capture == False: continue
        if len(tagnames) > 0: tagnames = tagnames[:-1]
        starttime = resource.find('status').get('starttime')
        starttime_parse = datetime.datetime.strptime(starttime, "%Y%m%d %H:%M:%S.%f")
        timestamp1 = time.mktime(starttime_parse.timetuple())*1000 + starttime_parse.microsecond/1000
        endtime = resource.find('status').get('endtime')
        endtime_parse = datetime.datetime.strptime(endtime, "%Y%m%d %H:%M:%S.%f")
        timestamp2 = time.mktime(endtime_parse.timetuple())*1000 + endtime_parse.microsecond/1000
        timediff = (timestamp2 -timestamp1)/1000
        htmlRow = '<tr class="row100 body"><td class="cell100 column1">' + resource.get('name') + '</td><td class="cell100 column2">' + tagnames + '</td><td class="cell100 column3 time">' + str(timediff) + '</td></tr>'
        html = html + htmlRow
    html = html + HTML_END
    fo = open('response_times.html',"w")
    fo.write(html)
    fo.close()
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('filename', help='name of robot framework output.xml file')
    args = parser.parse_args()
    getTimes(args.filename)
        
