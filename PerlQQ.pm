package PerlQQ;

use strict;
use warnings;
use PerlQQ::Login;
use PerlQQ::Action;
use PerlQQ::Auth;


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
    while(my $res = poll()) {
        my $result = from_json($res->content);
        if ($result->{retcode} == 0) {
            for my $msg (@{$result->{result}}) {
                parse($msg);
            }
        } else {
            logger($result);
        }
    }
}

sub parse {
    my $msg = shift;
    logger($msg);
    eval {
        $msg = $msg->{value};
        my $from_uin = $msg->{from_uin};
        my $time = DateTime->from_epoch(epoch => $msg->{time});
        my $content = $msg->{content}->[1];
        my $font = $msg->{content}->[0];
        print $time."  ".$from_uin.": ".$content."\n";
    } or do {
        print Dumper $msg;
    }
}

sub logger {
    open(MYFILE, ">>/var/tmp/webqq.txt");
    print MYFILE "[".DateTime->now()."]  ".to_json(shift)."\n";
    close(MYFILE);
}
