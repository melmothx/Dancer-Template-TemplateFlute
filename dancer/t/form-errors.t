#!perl

use strict;
use warnings;

use Data::Dumper;
use Dancer qw/:syntax/;
use Dancer::Plugin::Form;
use Data::Transpose::Validator;

set template => 'template_flute';
set views => 't/views';
set log => 'debug';

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
    # call it just to see if we have a crash
    my $ref = $form->errors_hashed;
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

post '/invalid' => sub {
    my $form = form('edit');
    $form->errors([ error => 'hello' ]);
    return redirect '/';
};

post '/dtv' => sub {
    my $dtv = Data::Transpose::Validator->new;
    $dtv->prepare([
                   {
                    name => 'year',
                    validator => {
                                  class => 'NumericRange',
                                  options => {
                                              min => 1900,
                                              max => 2050,
                                              integer => 1,
                                             }
                                 },
                    required => 1,
                   },
                   {
                    name => 'email',
                    validator => 'EmailValid',
                    required => 1,
                   }
                  ]);
    my %params = params;
    my $form = form('dtv');
    if (my $values = $dtv->transpose(\%params)) {
        $form->fill($values);
    }
    else {
        $form->errors($dtv->errors_as_hashref_for_humans);
    }
    debug to_dumper($form);
    return redirect '/';

};

get '/dtv' => sub {
    my $form = form('dtv');
    template errors_display => { %{$form->error_tokens},
                                    form => $form };
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

use Test::More tests => 8, import => ['!pass'];
use Dancer::Test;

my $resp;

response_content_like([ GET => '/'], qr{div class="errors"></div>},
                      "No error on get");
response_redirect_location_is([ POST => '/'], 'http://localhost/',
                              "post redirect to /");
response_content_like([ GET => '/'], qr{div class="errors">input: Missing text\n</div>},
                      "Error on get after the post");

read_logs;
$resp = dancer_response(POST => '/invalid');

my $logs = read_logs;
is($logs->[0]->{level}, 'error');
like($logs->[0]->{message}, qr/accept.*only.*hashref/);

set logger => 'console';

$resp = dancer_response(GET => '/dtv');
response_content_like($resp,
                      qr{<div\s+class="error_email">
                         </div><div\s+class="error_year"></div>}x,
                      "No error found");
$resp = dancer_response(POST => '/dtv', { body => { year => 'abcd',
                                                    email => 'hello' } });
$resp = dancer_response(GET => '/dtv');
response_content_like($resp,
                      qr/error_email">rfc822</,
                      "Found the error for mail");
response_content_like($resp,
                      qr/error_year">Not a number, Not an integer</,
                      "Found the error for year");


