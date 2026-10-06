#!/usr/bin/perl
use strict; use warnings;
use IO::Socket::INET;
my $port = $ARGV[0] || 8790;
my $root = $ENV{ST_ROOT} || '.';
my %mime = (html=>'text/html; charset=utf-8', js=>'application/javascript',
  css=>'text/css', png=>'image/png', ico=>'image/x-icon',
  json=>'application/json', svg=>'image/svg+xml', icns=>'image/icns');
my $srv = IO::Socket::INET->new(LocalAddr=>'127.0.0.1', LocalPort=>$port,
  Proto=>'tcp', Listen=>16, ReuseAddr=>1) or die "bind $port: $!\n";
$SIG{PIPE} = 'IGNORE';
while (my $c = $srv->accept) {
  my $req = <$c>;
  while (my $l = <$c>) { last if $l =~ /^\r?\n$/; }   # skip headers
  if ($req && $req =~ m{^GET\s+(\S+)\s}) {
    my $path = $1; $path =~ s/\?.*//; $path =~ s{\.\.}{}g;
    $path = '/index.html' if $path eq '/';
    my $file = $root . $path;
    if (-f $file) {
      my ($ext) = $file =~ /\.(\w+)$/;
      my $ct = $mime{lc($ext // '')} // 'application/octet-stream';
      open(my $fh, '<:raw', $file) or next; local $/; my $d = <$fh>; close $fh;
      print $c "HTTP/1.1 200 OK\r\nContent-Type: $ct\r\n"
             . "Content-Length: ".length($d)."\r\nConnection: close\r\n\r\n$d";
    } else {
      print $c "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
    }
  }
  close $c;
}
