#!perl

use strict;
use warnings;

use File::Spec;
use Data::Dumper;
use Test::More tests => 4, import => ['!pass'];
use Dancer qw/:tests/;

set template => 'template_flute';
set views => 't/views';

my $email_cids = {};

my $mail = template mail => {
                             email_cids => $email_cids,
                            };

like($mail, qr/cid:foopng.*cid:fooblapng/, "img src replaced")
  and diag $mail;

is_deeply $email_cids, {
                        foopng => {
                                   filename => 'foo.png',
                                  },
                        fooblapng => {
                                      filename => 'foo-bla.png'
                                     }
                       }, "Cids ok";

my $other = template mail => {};

like $other, qr/src="foo\.png".*src="foo-bla.png"/;
unlike $other, qr/cid:/, "No hashref passed, no cid replaced";

