#!perl

use strict;
use warnings;

use Dancer qw/:syntax/;
use Dancer::Plugin::Form;

set template => 'template_flute';
set views => 't/views';
set log => 'debug';
set logger => 'console';

get '/' => sub {
    my $form = form('edit');
    my %values = %{$form->values};
    $form->fill(\%values);
    my $error_string = '';
    if (my $errors = $form->errors) {
        foreach my $error (@$errors) {
            $error_string .= $error->{name} . ': ' . $error->{label} . "\n";
        }
    }
    template 'error-form' => {
                              errors => $error_string,
                              form => $form,
                             }, { layout => undef };
};

post '/' => sub {
    my %params = params;
    my $errors = validate(%params);
    my $form = form('edit');
    $form->errors($errors);
    return redirect '/';
};

sub validate {
    my %params = @_;
    if (length($params{input})) {
        return;
    }
    else {
        return {
                input => "Missing text",
               };
    }
}

use Test::More tests => 3, import => ['!pass'];
use Dancer::Test;

my $resp;

response_content_like([ GET => '/'], qr{div class="errors"></div>},
                      "No error on get");
response_redirect_location_is([ POST => '/'], 'http://localhost/',
                              "post redirect to /");
response_content_like([ GET => '/'], qr{div class="errors">input: Missing text\n</div>},
                      "Error on get after the post");

