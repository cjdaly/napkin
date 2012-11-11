import urllib, urllib2, base64

deviceId="bone1"
napkinConfigUrl="http://192.168.2.50:4567/config/bone1?key=test"
napkinChatterUrl="http://192.168.2.50:4567/chatter"

request = urllib2.Request(napkinConfigUrl);
authHeader = base64.encodestring('%s:%s' % (deviceId, deviceId)).replace('\n', '')
request.add_header("Authorization", "Basic %s" % authHeader)

text = urllib2.urlopen(request).read()
print text

postText = "Hello from bone1!\n"
postText += "foo=bar\n"
postText += "data...\n"

request = urllib2.Request(napkinChatterUrl, postText)
request.add_header("Authorization", "Basic %s" % authHeader)
response = urllib2.urlopen(request)
print response.read()

