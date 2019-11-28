import sys, getopt
import re

# change suite name in output.xml to incorporate config parameters
def main(argv):
    
   try:
      opts, args = getopt.getopt(argv,"h",["modem=","plan="])
   except getopt.GetoptError:
      print('python conv.py --modem <modem> --plan <plan>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
        print('python conv.py --modem <modem> --plan <plan>')
        sys.exit()
      elif opt=="--modem":
        modem = arg
      elif opt=="--plan":
        plan = arg 
        
   fpi = open("output.xml","r")
    
   # replace suite name with suite name followed by input parameters, separated by . 
   xml_input = fpi.read()
   match = re.search('name="(.*?)"',xml_input)
   result = match.groups()[0]
   modem_type = re.sub(r'^(.*?)-.*',r'\1',modem)
   plan_string = re.sub(r'\s',r'_',plan)   
   xml_output = re.sub(result,result+"."+modem_type+"."+plan_string,xml_input)

   fpi.close()
   fpo = open("output.xml","w")
   fpo.write(xml_output)
   fpo.close()
   
if __name__ == "__main__":
   main(sys.argv[1:])
            

