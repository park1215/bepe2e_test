import argparse
import xml.etree.ElementTree as ET

def removeUnrunTests(filename):
    fi = open(filename,"r")
    content = fi.read()
    fi.close()
    root = ET.fromstring(content)
    suite = root.find('.//suite')
    testcases = suite.findall('.//test')
    fails = []
    for testcase in testcases:
        print(testcase.get('name'))
        status = testcase.findall('status')
        print(status[-1].get('status'))
        if status[-1].get('status')=="FAIL":            
            if "Test execution stopped due to a fatal error" in status[-1].text:
                fails.append(testcase.get('name'))
    print(str(fails))
    for test in fails:
        elem = root.find(".//suite/test/[@name='"+test+"']")
        suite.remove(elem)
    suite = root.find('.//suite')
    testcases = suite.findall('.//test')
    for testcase in testcases:
        print(testcase.get('name'))
    #for testcase in testcases:
    #    print(testcase.get('name'))
    #    status = testcase.findall('status')
    #   print(status[-1].get('status'))
    #tree = ET.ElementTree(root)
    #print(ET.tostring(tree,encoding="utf-8"))
    #content = str(ET.tostring(root))
    #fo = open('testout.xml',"w")
    #fo.write(content)
    #fo.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('filename', help='name of robot framework xunit output file')
    args = parser.parse_args()
    removeUnrunTests(args.filename)