#! perl

use strict;
use warnings;

use File::Spec;
use Data::Dumper;

use Dancer qw/:syntax/;
use Dancer::Plugin::Form;

set template => 'template_flute';
set views => 't/views';
set log => 'debug';

get '/' => sub {
    my $form = form('textarea');
    $form->fill({ content => "Hello\r\nWorld" });
    template textarea => {
                          form => $form,
                         }, { layout => undef };
};

use Test::More tests => 2, import => ['!pass'];
use Dancer::Test;

my $resp = dancer_response GET => '/';
response_content_like($resp, qr/hello\s+world/i, "Text inserted");
response_content_like($resp, qr/hello\r\nworld/i, "newlines ok");



  
