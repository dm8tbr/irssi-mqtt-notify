#!/usr/bin/env perl -w
#
# This is a simple irssi script to send out notifications over the network using
# Net::MQTT. Currently, it sends notifications when e.g. your name/nick is
# highlighted, and when you receive private messages.
# Based on jabber-notify.pl script by Peter Krenesky, Thomas Ruecker.
# Based on growl-net.pl script by Alex Mason, Jason Adams.

use strict;
use vars qw($VERSION %IRSSI $AppName $MQTTUser $MQTTPass $MQTTServ $MQTTClient $MQTTTopic $MQTTTLS $MQTTPort $MQTTKeepalive $MQTTQOS $testing $Connection $j);

use Irssi;
use Net::MQTT::Constants;
use Net::MQTT::Message;
use IO::Socket::INET;
use utf8;
 
$VERSION = '0.1';
%IRSSI = (
  authors      =>   'Thomas B. Ruecker',
  contact      =>   'thomas@ruecker.fi, tbr on irc.freenode.net',
  name         =>   'MQTT-notify',
  description  =>   'Sends out notifications via MQTT for Irssi',
  license      =>   'BSD',
  url          =>   'http://github.com/dm8tbr/irssi-mqtt-notify/',

);

sub cmd_mqtt_notify {
  Irssi::print('%G>>%n MQTT-notify can be configured with these settings:');
  Irssi::print('%G>>%n mqtt_show_privmsg : Notify about private messages.');
  Irssi::print('%G>>%n mqtt_reveal_privmsg : Include content of private messages in notifications.');
  Irssi::print('%G>>%n mqtt_show_hilight : Notify when your name is hilighted.');
  Irssi::print('%G>>%n mqtt_show_notify : Notify when someone on your away list joins or leaves.');
  Irssi::print('%G>>%n mqtt_show_topic : Notify about topic changes.');
  Irssi::print('%G>>%n mqtt_notify_user : Set to mqtt account to send from.');
  Irssi::print('%G>>%n mqtt_notify_topic : Set to mqtt topic to publish message to.');;
  Irssi::print('%G>>%n mqtt_notify_server : Set to the mqtt server host name.');
  Irssi::print('%G>>%n mqtt_notify_pass : Set to the sending accounts jabber password.');
  Irssi::print('%G>>%n mqtt_notify_tls : Set to enable TLS connection to mqtt server.');
  Irssi::print('%G>>%n mqtt_notify_port : Set to the mqtt server port number.');
}

sub cmd_mqtt_notify_test {
#  my $message = new Net::Jabber::Message();
  my $body = 'moo!';
#  $message->SetMessage(to=>$XMPPRecv);
#  $message->SetMessage(
#    type=>"chat",
#    body=> $body );
#  $Connection->Send($message);

}

Irssi::settings_add_bool($IRSSI{'name'}, 'mqtt_show_privmsg',     1);
Irssi::settings_add_bool($IRSSI{'name'}, 'mqtt_reveal_privmsg',   1);
Irssi::settings_add_bool($IRSSI{'name'}, 'mqtt_show_hilight',     1);
Irssi::settings_add_bool($IRSSI{'name'}, 'mqtt_show_notify',      1);
Irssi::settings_add_bool($IRSSI{'name'}, 'mqtt_show_topic',       1);
Irssi::settings_add_str($IRSSI{'name'},  'mqtt_notify_pass',      'password');
Irssi::settings_add_str($IRSSI{'name'},  'mqtt_notify_server',    'localhost');
Irssi::settings_add_str($IRSSI{'name'},  'mqtt_notify_user',      'irssi');
Irssi::settings_add_str($IRSSI{'name'},  'mqtt_notify_topic',     'test');
Irssi::settings_add_str($IRSSI{'name'},  'mqtt_notify_client',    '');
Irssi::settings_add_bool($IRSSI{'name'}, 'mqtt_notify_tls',       0);
Irssi::settings_add_int($IRSSI{'name'},  'mqtt_notify_port',      1883);
Irssi::settings_add_int($IRSSI{'name'},  'mqtt_notify_keepalive', 120);
Irssi::settings_add_int($IRSSI{'name'},  'mqtt_notify_qos',       0);

$MQTTUser      = Irssi::settings_get_str('mqtt_notify_user');
$MQTTPass      = Irssi::settings_get_str('mqtt_notify_pass');
$MQTTServ      = Irssi::settings_get_str('mqtt_notify_server');
$MQTTTopic     = Irssi::settings_get_str('mqtt_notify_topic');
$MQTTClient    = Irssi::settings_get_str('mqtt_notify_client');
$MQTTTLS       = Irssi::settings_get_bool('mqtt_notify_tls');
$MQTTPort      = Irssi::settings_get_int('mqtt_notify_port');
$MQTTKeepalive = Irssi::settings_get_int('mqtt_notify_keepalive');
$MQTTQOS       = Irssi::settings_get_int('mqtt_notify_qos');
$AppName       = "irssi $MQTTServ";

#$Connection = Net::Jabber::Client->new();

#my $status = $Connection->Connect(
#  "hostname" => $XMPPServ,
#  "port" => $XMPPPort,
#  "componentname" => $XMPPDomain,
#  "tls" => $XMPPTLS );



if (!(defined($status)))
{
  Irssi::print("ERROR:  MQTT server is down or connection was not allowed.");
  Irssi::print ("        ($!)");
  return;
}


#my @result = $Connection->AuthSend(
#  "username" => $XMPPUser,
#  "password" => $XMPPPass,
#  "resource" => $XMPPRes );



#if ($result[0] ne "ok")
#{
#  Irssi::print("ERROR: Authorization failed ($XMPPUser".'@'."$XMPPDomain on server $XMPPServ) : $result[0] - $result[1]");
#  return;
#}
#Irssi::print ("Logged into server $XMPPServ as $XMPPUser".'@'."$XMPPDomain. Sending notifications to $XMPPRecv.");

sub sig_message_private ($$$$) {
  return unless Irssi::settings_get_bool('mqtt_show_privmsg');

  my ($server, $data, $nick, $address) = @_;

#  my $message = new Net::Jabber::Message();
  my $body = '(Private message from: '.$nick.')';
  if ((Irssi::settings_get_bool('mqtt_reveal_privmsg'))) {
    $body = '(PM: '.$nick.') '.$data;
  }
  utf8::decode($body);
#  $message->SetMessage(to=>$XMPPRecv);
#  $message->SetMessage(
#    type=>"chat",
#    body=> $body );
#  $Connection->Send($message);

}

sub sig_print_text ($$$) {
  return unless Irssi::settings_get_bool('mqtt_show_hilight');

  my ($dest, $text, $stripped) = @_;

  if ($dest->{level} & MSGLEVEL_HILIGHT) {
#    my $message = new Net::Jabber::Message();
    my $body = '['.$dest->{target}.'] '.$stripped;
    utf8::decode($body);
#    $message->SetMessage(to=>$XMPPRecv);
#    $message->SetMessage(
#      type=>"chat",
#      body=> $body );
#    $Connection->Send($message);
  }
}

sub sig_notify_joined ($$$$$$) {
  return unless Irssi::settings_get_bool('mqtt_show_notify');

  my ($server, $nick, $user, $host, $realname, $away) = @_;

#  my $message = new Net::Jabber::Message();
  my $body = "<$nick!$user\@$host>\nHas joined $server->{chatnet}";
#  $message->SetMessage(to=>$XMPPRecv);
#  $message->SetMessage(
#    type=>"chat",
#    body=> $body );
#  $Connection->Send($message);

}

sub sig_notify_left ($$$$$$) {
  return unless Irssi::settings_get_bool('mqtt_show_notify');

  my ($server, $nick, $user, $host, $realname, $away) = @_;

#  my $message = new Net::Jabber::Message();
  my $body = "<$nick!$user\@$host>\nHas left $server->{chatnet}";
#  $message->SetMessage(to=>$XMPPRecv);
#  $message->SetMessage(
#    type=>"chat",
#    body=> $body );
#  $Connection->Send($message);
}

sub sig_message_topic {
  return unless Irssi::settings_get_bool('mqtt_show_topic');
  my($server, $channel, $topic, $nick, $address) = @_;

#  my $message = new Net::Jabber::Message();
  my $body = 'Topic for '.$channel.': '.$topic;
  utf8::decode($body);
#  $message->SetMessage(to=>$XMPPRecv);
#  $message->SetMessage(
#    type=>"chat",
#    body=> $body );
#  $Connection->Send($message);
}


Irssi::command_bind('mqtt-notify', 'cmd_mqtt_notify');
Irssi::command_bind('mqtt-test', 'cmd_mqtt_notify_test');

Irssi::signal_add_last('message private', \&sig_message_private);
Irssi::signal_add_last('print text', \&sig_print_text);
Irssi::signal_add_last('notifylist joined', \&sig_notify_joined);
Irssi::signal_add_last('notifylist left', \&sig_notify_left);
Irssi::signal_add_last('message topic', \&sig_message_topic);


Irssi::print('%G>>%n '.$IRSSI{name}.' '.$VERSION.' loaded (/mqtt-notify for help. /mqtt-test to test.)');

