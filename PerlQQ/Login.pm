package PerlQQ::Login;

use strict;
use warnings;
use LWP::UserAgent;
use URI::Escape;
use Digest::MD5 qw(md5 md5_hex);
use JSON qw(from_json to_json);
use PerlQQ::Auth;

sub new {
    my ($cls, $args) = @_;
    $args->{username} = $args->{username};
    $args->{password} = $args->{password};
    bless $args, $cls;
}

sub ua {
    my $self = shift;
    unless ($self->{ua}) {
        $self->{ua} = LWP::UserAgent->new;
        $self->{ua}->agent('Mozilla/5.0');
    }
    $self->{ua};
}

sub auth {
    my $self = shift;
    unless ($self->{auth}) {
        $self->{auth} = PerlQQ::Auth->new;
    }
    $self->{auth};
}

sub _do_on_line {
    my $self = shift;
    my $ptwebqq = $self->auth->{cookie}->{ptwebqq};
    my $r = {
        status => "online",
        ptwebqq => $ptwebqq,
        passwd_sig => "",
        clientid => $self->auth->clientid,
        psessionid => "null",
    };

    my $res = $self->ua->post("http://d.web2.qq.com/channel/login2",
        [r => to_json($r), clientid => $self->auth->clientid, psessionid => "null"], 
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->auth->cookie,
    );
    print "获取登录令牌\n";

    my $result = from_json($res->content);
    $self->auth->parse_cookie($res->headers->as_string);
    $self->auth->{vfwebqq} = $result->{result}->{vfwebqq};
    $self->auth->{psessionid} = $result->{result}->{psessionid};
}

sub _check_username {
    my $self = shift;
    my $uri = URI->new("http://check.ptlogin2.qq.com/check");
    $uri->query_form(
        uin => $self->{username},
        appid => 1003903,
        r => 0.7712028087116778,
    );
    my $res = $self->ua->get($uri->as_string);
    print "获取登录码\n";

    if ($res->is_success) {
        my $result = $res->content;
        $self->auth->parse_cookie($res->headers->as_string);
        my ($is_need_verify, $code1, $code2) = split(',', $result);
        $is_need_verify = ($is_need_verify =~ m/'(.+)'/)[0];
        $code1 = ($code1 =~ m/'(.+)'/)[0];
        $code2 = ($code2 =~ m/'(.+)'[^']/)[0];
        $code2 = eval('"'.$code2.'"');
        if ($is_need_verify) {
            $code1 = <>;
        }
        my $p = md5_hex(uc(md5_hex(md5($self->{password}).$code2).$code1));
        $self->{code1} = $code1;
        $self->{p} = $p;
    } else {
        print $res->status_line;
        exit 0;
    }
}

sub _check_password {
    my $self = shift;
    my $uri = URI->new("http://ptlogin2.qq.com/login");
    $uri->query_form(
        u => $self->{username},
        p => $self->{p},
        verifycode => $self->{code1},
        webqq_type => 1,
        remeber_uin => 1,
        login2qq => 1,
        aid => 1003903,
        u1 => 'http://w.qq.com/loginproxy.html?login2qq=1&webqq_type=10',
        h => 1,
        ptredirect => 0,
        ptlang => 2052,
        from_ui => 1,
        pttype => 1,
        dumy => '',
        fp => "loginerroralert",
        action => "2-8-3749",
        mibao_css => "m_webqq",
        t => 1,
        g => 1,
    );

    my $res = $self->ua->get($uri->as_string,
        cookie => $self->auth->cookie,
    );
    print "登录\n";

    if ($res->is_success) {
        $self->auth->parse_cookie($res->headers->as_string);
    } else {
        print $res->status_line;
        return 0;
    }
}

sub login {
    my ($self) = @_;

    $self->_check_username;
    $self->_check_password;
    $self->_do_on_line;

    $self->{auth};
}

1;
