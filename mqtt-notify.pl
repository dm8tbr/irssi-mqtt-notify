#!/usr/bin/env perl -w
#
# This is a simple irssi script to send out notifications over the network using
# mosquitto_pub. Currently, it sends notifications when e.g. your name/nick is
# highlighted, and when you receive private messages.
# Based on jabber-notify.pl script by Peter Krenesky, Thomas Ruecker.
# Based on growl-net.pl script by Alex Mason, Jason Adams.

use strict;
use vars qw($VERSION %IRSSI $AppName $MQTTUser $MQTTPass $MQTTServ $MQTTClient $MQTTTopic $MQTTTLS $MQTTPort $MQTTKeepalive $MQTTRetain $MQTTQoS @args  $j);

use Irssi;
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
  Irssi::print('%G>>%n mqtt_notify_tls : Set to enable TLS connection to mqtt server. [not implemented]');
  Irssi::print('%G>>%n mqtt_notify_port : Set to the mqtt server port number.');
  Irssi::print('%G>>%n mqtt_notify_qos : Set to the desired mqtt QoS level.');
  Irssi::print('%G>>%n mqtt_notify_retain : Set to the desired retain flag value.');
}

sub cmd_mqtt_notify_test {
  my $body = 'moo!';
  my @message_args = @args;
  push(@message_args, "-m", $body);
  system(@message_args) == 0 or Irssi::print("system @args failed: $?");
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
Irssi::settings_add_bool($IRSSI{'name'}, 'mqtt_notify_retain',    0);
Irssi::settings_add_int($IRSSI{'name'},  'mqtt_notify_debug',     0);

$MQTTUser      = Irssi::settings_get_str('mqtt_notify_user');
$MQTTPass      = Irssi::settings_get_str('mqtt_notify_pass');
$MQTTServ      = Irssi::settings_get_str('mqtt_notify_server');
$MQTTTopic     = Irssi::settings_get_str('mqtt_notify_topic');
$MQTTClient    = Irssi::settings_get_str('mqtt_notify_client');
$MQTTTLS       = Irssi::settings_get_bool('mqtt_notify_tls');
$MQTTPort      = Irssi::settings_get_int('mqtt_notify_port');
$MQTTKeepalive = Irssi::settings_get_int('mqtt_notify_keepalive');
$MQTTQoS       = Irssi::settings_get_int('mqtt_notify_qos');
$MQTTRetain    = Irssi::settings_get_bool('mqtt_notify_retain');
$debug         = Irssi::settings_get_int('mqtt_notify_debug');
$AppName       = "irssi $MQTTServ";

@args = ("mosquitto_pub", "-h", $MQTTServ, "-p", $MQTTPort, "-q", $MQTTQoS, "-i", $MQTTClient, "-u", $MQTTUser, "-P", $MQTTPass, "-t", $MQTTTopic,);
if (Irssi::settings_get_bool('mqtt_notify_retain')) {
  push(@args, "-r");
}


sub sig_message_private ($$$$) {
  return unless Irssi::settings_get_bool('mqtt_show_privmsg');

  my ($server, $data, $nick, $address) = @_;

  my $body = '(Private message from: '.$nick.')';
  if ((Irssi::settings_get_bool('mqtt_reveal_privmsg'))) {
    $body = '(PM: '.$nick.') '.$data;
  }
  utf8::decode($body);
  my @message_args = @args;
  push(@message_args, "-m", $body);
  system(@message_args) == 0 or Irssi::print("system @args failed: $?");
  @args = ("mosquitto-pub", "-h ".$MQTTServ, "-u ".$MQTTUser, "-P ".$MQTTPass, "-t ".$MQTTTopic, "-m '".$body."'",);
  system(@args) == 0 or Irssi::print('system @args failed: $?');
}

sub sig_print_text ($$$) {
  return unless Irssi::settings_get_bool('mqtt_show_hilight');

  my ($dest, $text, $stripped) = @_;

  if ($dest->{level} & MSGLEVEL_HILIGHT) {
    my $body = '['.$dest->{target}.'] '.$stripped;
    utf8::decode($body);
    my @message_args = @args;
    push(@message_args, "-m", $body);
    system(@message_args) == 0 or Irssi::print("system @args failed: $?");
  }
}

sub sig_notify_joined ($$$$$$) {
  return unless Irssi::settings_get_bool('mqtt_show_notify');

  my ($server, $nick, $user, $host, $realname, $away) = @_;

  my $body = "<$nick!$user\@$host>\nHas joined $server->{chatnet}";
  my @message_args = @args;
  push(@message_args, "-m", $body);
  system(@message_args) == 0 or Irssi::print("system @args failed: $?");
}

sub sig_notify_left ($$$$$$) {
  return unless Irssi::settings_get_bool('mqtt_show_notify');

  my ($server, $nick, $user, $host, $realname, $away) = @_;

  my $body = "<$nick!$user\@$host>\nHas left $server->{chatnet}";
  my @message_args = @args;
  push(@message_args, "-m", $body);
  system(@message_args) == 0 or Irssi::print("system @args failed: $?");
}

sub sig_message_topic {
  return unless Irssi::settings_get_bool('mqtt_show_topic');
  my($server, $channel, $topic, $nick, $address) = @_;

  my $body = 'Topic for '.$channel.': '.$topic;
  utf8::decode($body);
  my @message_args = @args;
  push(@message_args, "-m", $body);
  system(@message_args) == 0 or Irssi::print("system @args failed: $?");
}


Irssi::command_bind('mqtt-notify', 'cmd_mqtt_notify');
Irssi::command_bind('mqtt-test', 'cmd_mqtt_notify_test');

Irssi::signal_add_last('message private', \&sig_message_private);
Irssi::signal_add_last('print text', \&sig_print_text);
Irssi::signal_add_last('notifylist joined', \&sig_notify_joined);
Irssi::signal_add_last('notifylist left', \&sig_notify_left);
Irssi::signal_add_last('message topic', \&sig_message_topic);


Irssi::print('%G>>%n '.$IRSSI{name}.' '.$VERSION.' loaded (/mqtt-notify for help. /mqtt-test to test.)');
