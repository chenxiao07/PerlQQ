package PerlQQ::Auth;

use strict;
use warnings;
use JSON qw(from_json to_json);

sub new {
    my ($cls, $args) = @_;
    $args->{clientid} //= int(100000000+9000000*rand());
    bless $args, $cls;
}

sub psessionid {
    my ($self) = @_;
    return $self->{psessionid};
}

sub vfwebqq {
    my ($self) = @_;
    return $self->{vfwebqq};
}

sub clientid {
    my ($self) = @_;
    return $self->{clientid};
}

sub parse_cookie {
    my ($self, $s) = @_;
    unless ($self->{cookie}) {
        $self->{cookie} = {};
    }
    my @result = ($s =~ m/Set-Cookie:\s([^=]+)=([^;]*);/g);
    while(@result > 0) {
        my $key = shift @result;
        $self->{cookie}->{$key} = shift @result;
    }
}

sub cookie {
    my ($self) = @_;
    my $result = "";
    for my $key (keys %{$self->{cookie}}) {
        $result = $result."$key=".$self->{cookie}->{$key}.";";
    }
    return $result;
}

1;
