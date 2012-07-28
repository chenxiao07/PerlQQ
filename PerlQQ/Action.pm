package PerlQQ::Action;

use strict;
use warnings;
use LWP::UserAgent;
use PerlQQ::Auth;
use JSON qw/from_json to_json/;
use Encode qw/encode decode/;

sub new {
    my ($cls, $args) = @_;
    $args->{auth} = $args->{auth};
    $args->{msg_id} = 23500002;
    bless $args, $cls;
}

sub auth {
    my $self = shift;
    $self->{auth};
}

sub msg_id {
    my $self = shift;
    $self->{msg_id};
}

sub cookie {
    my $self = shift;
    $self->auth->cookie;
}

sub ua {
    my $self = shift;
    unless ($self->{ua}) {
        $self->{ua} = LWP::UserAgent->new;
        $self->{ua}->agent('Mozilla/5.0');
    }
    $self->{ua};
}

sub get_single_info {
    my ($self, $uin) = @_;
    my $res = $self->ua->get("http://s.web2.qq.com/api/get_single_info2?tuin=$uin",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_friend_info {
    my ($self, $uin) = @_;
    my $t = time();
    my $vfwebqq = $self->auth->vfwebqq;
    my $res = $self->ua->get("http://s.web2.qq.com/api/get_friend_info2?tuin=$uin&vfwebqq=$vfwebqq&t=$t",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_nick {
    my ($self, $uin) = @_;
    my $t = time();
    my $vfwebqq = $self->auth->vfwebqq;
    my $res = $self->ua->get("http://s.web2.qq.com/api/get_single_long_nick2?tuin=$uin&vfwebqq=$vfwebqq&t=$t",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_level {
    my ($self, $uin) = @_;
    my $t = time();
    my $vfwebqq = $self->auth->vfwebqq;
    my $res = $self->ua->get("http://s.web2.qq.com/api/get_qq_level2?tuin=$uin&vfwebqq=$vfwebqq&t=$t",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub set_nick {
    my ($self, $content) = @_;

    my $r = {
        nlk => $content,
        vfwebqq => $self->auth->vfwebqq,
    };

    my $res = $self->ua->post("http://s.web2.qq.com/api/set_long_nick2",
        [r => decode('UTF-8', to_json($r))],
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub poll {
    my ($self) = @_;
    my $r = {
        clientid => $self->auth->clientid,
        psessionid => $self->auth->psessionid,
        key => 0,
        ids => [],
    };

    my $res = $self->ua->post("http://d.web2.qq.com/channel/poll2",
        [r => to_json($r), clientid => $self->auth->clientid, psessionid => $self->auth->psessionid],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_real_id {
    my ($self, $uin) = @_;
    my $t = time();
    my $vfwebqq = $self->auth->vfwebqq;
    my $res = $self->ua->get("http://s.web2.qq.com/api/get_friend_uin2?type=1&tuin=$uin&vfwebqq=$vfwebqq&t=$t",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_group_info_pre {
    my ($self, $uin) = @_;
    my $t = time();
    my $vfwebqq = $self->auth->vfwebqq;
    my $res = $self->ua->get("http://s.web2.qq.com/api/get_group_info?gcode=%5B$uin%5D&retainKey=memo%2Cgcode&vfwebqq=$vfwebqq&t=$t",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_group_info {
    my ($self, $uin) = @_;
    my $t = time();
    my $vfwebqq = $self->auth->vfwebqq;
    my $res = $self->ua->get("http://s.web2.qq.com/api/get_group_info_ext2?gcode=$uin&vfwebqq=$vfwebqq&t=$t",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub send_message {
    my ($self, $to_id, $content) = @_;
    my $r = {
        to => $to_id,
        face => 0,
        content => "[\"$content\",[\"font\",{\"name\":\"Tahoma\",\"size\":\"10\",\"style\":[0,0,0],\"color\":\"000000\"}]]",
        msg_id => $self->msg_id,
        clientid => $self->auth->clientid,
        psessionid => $self->auth->psessionid,
    };

    $self->{msg_id} += 1;

    my $res = $self->ua->post("http://d.web2.qq.com/channel/send_buddy_msg2",
        [r => decode('UTF-8', to_json($r)), clientid => $self->auth->clientid, psessionid => $self->auth->psessionid],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    return $res;
}

sub send_group_message {
    my ($self, $to_id, $content) = @_;
    my $r = {
        group_uin => $to_id,
        content => "[\"$content\",[\"font\",{\"name\":\"Tahoma\",\"size\":\"10\",\"style\":[0,0,0],\"color\":\"000000\"}]]",
        msg_id => $self->msg_id,
        clientid => $self->auth->clientid,
        psessionid => $self->auth->psessionid,
    };

    $self->{msg_id} += 1;

    my $res = $self->ua->post("http://d.web2.qq.com/channel/send_qun_msg2",
        [r => decode('UTF-8', to_json($r)), clientid => $self->auth->clientid, psessionid => $self->auth->psessionid],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_friends {
    my ($self) = @_;
    my $r = {
        h => "hello",
        vfwebqq => $self->auth->vfwebqq,
    };

    my $res = $self->ua->post("http://s.web2.qq.com/api/get_user_friends2",
        [r => to_json($r)],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_groups {
    my ($self) = @_;
    my $r = {
        vfwebqq => $self->auth->vfwebqq,
    };

    my $res = $self->ua->post("http://s.web2.qq.com/api/get_group_name_list_mask2",
        [r => to_json($r)],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    return $res;
}

1;
