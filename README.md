irssi-jabber-notify
===================

My Jabber/XMPP notification script forked from @kreneskyp

This script now also supports GTalk(Hangouts) and other multi-domain
jabber services. If the server you connect to doesn't have the same
host name as your JID, then use the "xmpp_notify_domain" setting.
This will only work for as long as Google will support XMPP clients,
which is currently unclear.

Peter's blog post:

http://blogs.osuosl.org/kreneskyp/2009/06/02/irssi-notifications-via-xmpp/

links the original:

http://staff.osuosl.org/~peter/myfiles/jabber-notify.pl


Side notes:

If you are using bitlbee or some other way that can possibly make 
the notification messages come back to your irssi, you might want to 
put the notification sending JID on ignore to avoid a feedback loop.

If you want to use this with a Google account you're in for some 'fun' 
for possibly painful values of such. Their XMPP support is degrading.
- You can't message yourself (Use a second account)
- If you use Hangouts, you won't get messages from non-Google accounts.
- This might break completely due to Google, consider Hangouts problematic.
