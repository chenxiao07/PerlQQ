package PerlQQ;

use strict;
use warnings;
use PerlQQ::Login;
use PerlQQ::Action;
use PerlQQ::Auth;
use JSON qw/from_json to_json/;
use Data::Dumper;


sub new {
    my ($cls, $args) = @_;
    bless {}, $cls;
}

sub client {
    my $self = shift;
    $self->{action};
}

sub login {
    my ($self, $username, $password) = @_;
    my $login = PerlQQ::Login->new({username => $username, password => $password});
    my $auth = $login->login;
    $self->{action} = PerlQQ::Action->new({auth => $auth});
}

sub message_loop {
    my $self = shift;
    if (fork()) {
        $self->InterAct;
    } else {
        $self->KeepAlive;
    }
}

sub InterAct {
    use Term::ReadLine;
    my $term = Term::ReadLine->new('Simple Perl calc');
    my $prompt = "Enter your arithmetic expression: ";
    my $OUT = $term->OUT || \*STDOUT;
    while ( defined ($_ = $term->readline($prompt)) ) {
        my $res = eval($_);
        warn $@ if $@;
        print $OUT $res, "\n" unless $@;
        $term->addhistory($_) if /\S/;
    }
}

sub KeepAlive {
    my $self = shift;
    while(my $res = $self->client->poll) {
        my $result = from_json($res->content);
        if ($result->{retcode} == 0) {
            for my $msg (@{$result->{result}}) {
                $self->parse($msg);
            }
        } else {
            $self->logger($result);
        }
    }
}

sub parse {
    my ($self, $msg) = @_;
    $self->logger($msg);
    eval {
        $msg = $msg->{value};
        my $from_uin = $msg->{from_uin};
        my $time = localtime($msg->{time});
        my $content = $msg->{content}->[1];
        my $font = $msg->{content}->[0];
        print $time."  ".$from_uin.": ".$content."\n";
    } or do {
        print Dumper $msg;
    }
}

sub logger {
    my ($self, $content) = @_;
    open(MYFILE, ">>/var/tmp/webqq.txt");
    print MYFILE "[".localtime(time())."]  ".to_json($content)."\n";
    close(MYFILE);
}

1;
