irssi-MQTT-notify
=================

My MQTT notification script, based on my Jabber/XMPP notification script:
https://github.com/dm8tbr/irssi-xmpp-notify

It forwards all notification events generated by irssi over XMPP. 
Supported types are:
* hilights (see '/help hilight')
* private messages
* join/part/away (see '/help notify')
* topic changes

This script requires the Mosquitto client tools, specifically 'mosquitto_pub',
to work.

See https://github.com/dm8tbr/irssi-mqtt-sailfish for a client side implementation.
