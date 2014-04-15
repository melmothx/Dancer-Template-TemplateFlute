#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use File::Spec::Functions qw/catfile rel2abs/;
use Dancer qw/:script/;
use MIME::Entity;
use File::Type;
use Email::Sender::Simple 'sendmail';

set template => 'template_flute';
set views => $Bin;

my $cids = {};

my $mail = template mail => {
                             email_cids => $cids,
                            };

print to_dumper($cids);

my @attachments = ({
                    Path => rel2abs($0),
                    Type => File::Type->mime_type($0),
                    Encoding => 'base64',
                    Disposition => 'attachment',
                   });
foreach my $cid (keys %$cids) {
    push @attachments, {
                        Id => $cid,
                        Path => catfile($Bin, $cids->{$cid}->{filename}),
                        Type => File::Type->mime_type(catfile($Bin, $cids->{$cid}->{filename})),
                        Encoding => 'base64',
                       };
}

my ($from, $to) = @ARGV;
die "Missing sender and/or recipient" unless $from && $to;

my $mime = MIME::Entity->build(Type => "multipart/related",
                               From => $from,
                               Subject => 'Template::Flute test mail with attachments',
                               To => $to,
                              );

my $body = MIME::Entity->build(Charset  => 'utf-8',
                               Encoding => 'quoted-printable',
                               Type => 'text/html',
                               Data => $mail,
                               );

$mime->add_part($body);

foreach my $attach (@attachments) {
    $mime->attach(%$attach);
}

sendmail $mime;

# email $email;




