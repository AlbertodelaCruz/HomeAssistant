# HomeAssistant

## History

TLDR; I have a Garmin watch device and a Nest Thermostate. I usually have to login into google Home application to check temperature and I thought it will be easy to do it with my watch.

So, here we are. Many times if you have a big "problem", it is easy to split it up into small pieces. In this case, I found 2:
- Communications with thermostate
- Garmin app to present the information

Another useful tip is to search out there if someone else had this problem before.

For communicating with the Nest device, I found this [google nest python library](https://pypi.org/project/python-google-nest/). This helped me a lot in order to understand google api communication. 
After trying out and check it working, I started to think about how I was going to offer this info to the garmin device. Some ideas came into my mind, serve an API REST endpoint which call the specific method from the library to retrieve information... too complicated and I will need a server up&running to make it works.

So I started to explore [Nest API](https://developers.google.com/nest/device-access/get-started) by my own. After some tests, I had a clear view of API requests.

For the second part, the Garmin app, I downloaded [SDK](https://developer.garmin.com/connect-iq/sdk/) and integrated it into VSCode. Works like a charm.
