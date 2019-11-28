# Demonstrates how to trigger a jenkins job remotely. 
import requests
jenkins_host = 'jenkinsmaster.bepe2e.viasat.io'
jenkins_user = 'bepe2e_preprod'
jenkins_token = '114b8b920125a8f2ddc574fc8e36eaafe9'
jenkins_job =  'Experiments/job/Test-env-vars'
action = 'build'

# code from https://gist.github.com/govindsh/a15fa7c502ff7559b28d43eee675af23
url = "https://{0}:{1}@{2}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)".format(jenkins_user,jenkins_token,jenkins_host)
crumb = requests.get(url,verify=False).text
job_url = "https://{0}:{1}@{2}/job/{3}/{4}".format(jenkins_user, jenkins_token, jenkins_host, jenkins_job, action)
headers = dict()
headers[crumb.split(":")[0]] = crumb.split(":")[1]
response = requests.post(job_url, headers=headers, verify=False)
print(response.status_code)