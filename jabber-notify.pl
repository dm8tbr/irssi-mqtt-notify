#!/usr/bin/env perl -w
#
# This is a simple irssi script to send out notifications ovet the network using
# Net::XMMP2. Currently, it sends notifications when your name is
# highlighted, and when you receive private messages.
# Based on growl-net.pl script by Alex Mason, Jason Adams.

use strict;
use vars qw($VERSION %IRSSI $AppName $XMPPUser $XMPPPass $XMPPDomain $XMPPServ $XMPPRes $XMPPRecv $XMPPTLS $XMPPPort $testing $Connection $j);

use Irssi;
use Net::Jabber qw( Client );
use utf8;

$VERSION = '0.01';
%IRSSI = (
  authors		=>	'Thomas B. Ruecker, Based on Peter Krenesky\'s script, Based on growl-net.pl script by Alex Mason, Jason Adams (based on the growl.pl script from Growl.info by Nelson Elhage and Toby Peterson)',
  contact		=>	'thomas@ruecker.fi, tbr on irc.freenode.net',
  name		=>	'XMPP-notify',
  description	=>	'Sends out notifications via XMPP for Irssi',
  license		=>	'BSD',
  url		=>	'http://github.com/dm8tbr/irssi-jabber-notify/',
);

sub cmd_xmpp_notify {
  Irssi::print('%G>>%n XMPP-notify can be configured with these settings:');
  Irssi::print('%G>>%n xmpp_show_privmsg : Notify about private messages.');
  Irssi::print('%G>>%n xmpp_show_hilight : Notify when your name is hilighted.');
  Irssi::print('%G>>%n xmpp_show_notify : Notify when someone on your away list joins or leaves.');
  Irssi::print('%G>>%n xmpp_notify_user : Set to xmpp account to send from.');
  Irssi::print('%G>>%n xmpp_notify_recv : Set to xmpp account to receive message.');;
  Irssi::print('%G>>%n xmpp_notify_server : Set to the xmpp server host name');
  Irssi::print('%G>>%n xmpp_notify_pass : Set to the sending accounts jabber password');
  Irssi::print('%G>>%n xmpp_notify_tls : Set to enable TLS connection to xmpp server');
  Irssi::print('%G>>%n xmpp_notify_port : Set to the xmpp server port number');
  Irssi::print('%G>>%n xmpp_notify_domain : Set to the xmpp domain name if different from server name');
}

sub cmd_xmpp_notify_test {
  my $message = new Net::Jabber::Message();
  my $body = 'moo!';
  $message->SetMessage(to=>$XMPPRecv);
  $message->SetMessage(type=>"chat",
    body=> $body );
  $Connection->Send($message);

}

Irssi::settings_add_bool($IRSSI{'name'}, 'xmpp_show_privmsg', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'xmpp_show_hilight', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'xmpp_show_notify', 1);
Irssi::settings_add_str($IRSSI{'name'}, 'xmpp_notify_pass', 'password');
Irssi::settings_add_str($IRSSI{'name'}, 'xmpp_notify_server', 'localhost');
Irssi::settings_add_str($IRSSI{'name'}, 'xmpp_notify_user', 'irssi');
Irssi::settings_add_str($IRSSI{'name'}, 'xmpp_notify_domain', undef);
Irssi::settings_add_str($IRSSI{'name'}, 'xmpp_notify_recv', 'noone');
Irssi::settings_add_str($IRSSI{'name'}, 'xmpp_notify_res', '');
Irssi::settings_add_bool($IRSSI{'name'}, 'xmpp_notify_tls', 1);
Irssi::settings_add_int($IRSSI{'name'}, 'xmpp_notify_port', 5222);

$XMPPUser   = Irssi::settings_get_str('xmpp_notify_user');
$XMPPPass   = Irssi::settings_get_str('xmpp_notify_pass');
$XMPPDomain = Irssi::settings_get_str('xmpp_notify_domain');
$XMPPServ   = Irssi::settings_get_str('xmpp_notify_server');
$XMPPRecv   = Irssi::settings_get_str('xmpp_notify_recv');
$XMPPRes    = Irssi::settings_get_str('xmpp_notify_res');
$XMPPTLS    = Irssi::settings_get_bool('xmpp_notify_tls');
$XMPPPort   = Irssi::settings_get_int('xmpp_notify_port');
$AppName    = "irssi $XMPPServ";

if (!$XMPPDomain)
{
  $XMPPDomain = $XMPPServ;
}

if (!$XMPPRecv)
{
  $XMPPRecv = $XMPPUser.'@'.$XMPPDomain;
}

$Connection = Net::Jabber::Client->new();

my $status = $Connection->Connect( "hostname" => $XMPPServ,
  "port" => $XMPPPort,
  "componentname" => $XMPPDomain,
  "tls" => $XMPPTLS );



if (!(defined($status)))
{
  Irssi::print("ERROR:  Jabber server is down or connection was not allowed.");
  Irssi::print ("        ($!)");
  return;
}


my @result = $Connection->AuthSend( "username" => $XMPPUser,
  "password" => $XMPPPass,
  "resource" => $XMPPRes );



if ($result[0] ne "ok")
{
  Irssi::print("ERROR: Authorization failed ($XMPPUser".'@'."$XMPPDomain on server $XMPPServ) : $result[0] - $result[1]");
  return;
}
Irssi::print ("Logged into server $XMPPServ as $XMPPUser".'@'."$XMPPDomain. Sending notifications to $XMPPRecv.");

sub sig_message_private ($$$$) {
  return unless Irssi::settings_get_bool('xmpp_show_privmsg');

  my ($server, $data, $nick, $address) = @_;

  my $message = new Net::Jabber::Message();
  my $body = '(PM: '.$nick.') '.$data;
  utf8::decode($body);
  $message->SetMessage(to=>$XMPPRecv);
  $message->SetMessage(type=>"chat",
    body=> $body );
  $Connection->Send($message);

}

sub sig_print_text ($$$) {
  return unless Irssi::settings_get_bool('xmpp_show_hilight');

  my ($dest, $text, $stripped) = @_;

  if ($dest->{level} & MSGLEVEL_HILIGHT) {
    my $message = new Net::Jabber::Message();
    my $body = '['.$dest->{target}.'] '.$stripped;
    utf8::decode($body);
    $message->SetMessage(to=>$XMPPRecv);
    $message->SetMessage(type=>"chat",
      body=> $body );
    $Connection->Send($message);
  }
}

sub sig_notify_joined ($$$$$$) {
  return unless Irssi::settings_get_bool('xmpp_show_notify');

  my ($server, $nick, $user, $host, $realname, $away) = @_;

  my $message = new Net::Jabber::Message();
  my $body = "<$nick!$user\@$host>\nHas joined $server->{chatnet}";
  $message->SetMessage(to=>$XMPPRecv);
  $message->SetMessage(type=>"chat",
    body=> $body );
  $Connection->Send($message);

}

sub sig_notify_left ($$$$$$) {
  return unless Irssi::settings_get_bool('xmpp_show_notify');

  my ($server, $nick, $user, $host, $realname, $away) = @_;

  my $message = new Net::Jabber::Message();
  my $body = "<$nick!$user\@$host>\nHas left $server->{chatnet}";
  $message->SetMessage(to=>$XMPPRecv);
  $message->SetMessage(type=>"chat",
    body=> $body );
  $Connection->Send($message);
}



Irssi::command_bind('xmpp-notify', 'cmd_xmpp_notify');
Irssi::command_bind('xn-test', 'cmd_xmpp_notify_test');

Irssi::signal_add_last('message private', \&sig_message_private);
Irssi::signal_add_last('print text', \&sig_print_text);
Irssi::signal_add_last('notifylist joined', \&sig_notify_joined);
Irssi::signal_add_last('notifylist left', \&sig_notify_left);


Irssi::print('%G>>%n '.$IRSSI{name}.' '.$VERSION.' loaded (/xmpp-notify for help. /xn-test to test.)');

