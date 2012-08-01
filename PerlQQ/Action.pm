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
    $args->{fileid} = 1;
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

sub get_stranger_info2 {
    my ($self, $uin) = @_;
    my $t = time();
    my $vfwebqq = $self->auth->vfwebqq;

    my $res = $self->ua->get("http://s.web2.qq.com/api/get_stranger_info2?tuin=$uin&vfwebqq=$vfwebqq&t=$t&gid=0",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    return $res;
}

sub get_gface_sig2 {
    my ($self) = @_;
    my $t = time();
    my $clientid = $self->auth->clientid;
    my $psessionid = $self->auth->psessionid;

    my $res = $self->ua->get("http://d.web2.qq.com/channel/get_gface_sig2?clientid=$clientid&psessionid=$psessionid&t=$t",
        referer => "http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=1",
        cookie => $self->cookie,
    );

    my $result = from_json($res->content);
    $self->auth->{gface_key} = $result->{result}->{gface_key};
    $self->auth->{gface_sig} = $result->{result}->{gface_sig};

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
    my ($self, $to_id, $content, $size) = @_;
    $size //= 10;

    my $r = {
        to => $to_id,
        face => 0,
        content => "[\"$content\",[\"font\",{\"name\":\"Tahoma\",\"size\":\"$size\",\"style\":[0,0,0],\"color\":\"000000\"}]]",
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
    my ($self, $to_id, $content, $size) = @_;
    $size //= 10;

    my $r = {
        group_uin => $to_id,
        content => "[\"$content\",[\"font\",{\"name\":\"Tahoma\",\"size\":\"$size\",\"style\":[0,0,0],\"color\":\"000000\"}]]",
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

sub cface_upload {
    my ($self, $filepath) = @_;
    my $t = time();

    my $res = $self->ua->post("http://up.web2.qq.com/cgi-bin/cface_upload?time=$t",
        Content_Type => "form-data",
        Content => [from => "control",
                    f => "EQQ.Model.ChatMsg.callbackSendPicGroup",
                    vfwebqq => $self->auth->vfwebqq,
                    custom_face => ["$filepath"],
                    fileid => $self->{fileid},
                    ],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    $self->{fileid} += 1;

    return $res;
}

sub send_message_cface {
    my ($self, $to_id, $content, $path, $name, $filesize, $size) = @_;
    $size //= 10;
    warn "[\"offpic\",\"$path\",\"$name\",$filesize]";

    my $r = {
        to => $to_id,
        face => 543,
        content => "[[\"offpic\",\"$path\",\"$name\",$filesize], \"$content\", [\"font\",{\"name\":\"Tahoma\",\"size\":\"$size\",\"style\":[0,0,0],\"color\":\"000000\"}]]",
        msg_id => $self->msg_id,
        clientid => $self->auth->clientid,
        psessionid => $self->auth->psessionid,
    };

    warn decode('UTF-8', to_json($r));

    $self->{msg_id} += 1;

    my $res = $self->ua->post("http://d.web2.qq.com/channel/send_buddy_msg2",
        [r => decode('UTF-8', to_json($r)), clientid => $self->auth->clientid, psessionid => $self->auth->psessionid],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    return $res;
}

sub upload_offline_pic {
    my ($self, $filepath) = @_;
    my $t = time();
    warn substr $self->auth->{cookie}->{uin}, 1;
    warn $self->auth->{cookie}->{skey};

    my $res = $self->ua->post("http://weboffline.ftn.qq.com/ftn_access/upload_offline_pic?time=$t",
        Content_Type => "form-data",
        Content => [callback => "parent.EQQ.Model.ChatMsg.callbackSendPic",
                    locallangid => "2052",
                    clientversion => "1409",
                    uin => substr($self->auth->{cookie}->{uin}, 1),
                    skey => $self->auth->{cookie}->{skey},
                    appid => "1002101",
                    peeruin => "593023668",
                    file => ["$filepath"],
                    vfwebqq => $self->auth->vfwebqq,
                    fileid => $self->{fileid},
                    ],
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    $self->{fileid} += 1;

    return $res;
}

sub apply_offline_pic {
    my ($self, $f_uin, $path) = @_;
    my $t = time();
    my $clientid = $self->auth->clientid;
    my $psessionid = $self->auth->psessionid;

    my $res = $self->ua->get("http://d.web2.qq.com/channel/apply_offline_pic_dl2?f_uin=$f_uin&file_path=$path&clientid=$clientid&psessionid=$psessionid&t=$t",
        referer => "http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",
        cookie => $self->cookie,
    );

    return $res;
}

sub send_group_message_cface {
    my ($self, $to_id, $content, $filepath) = @_;
    my $result = $self->cface_upload($filepath)->content;
    $result = ($result =~ m/callbackSendPicGroup\((.+)\)/)[0];
    $result =~ s/'/"/g;
    $result = from_json($result);
    my $img_name = substr $result->{msg}, 0, 36;

    unless ($self->auth->{gface_key}) {
        $self->get_gface_sig2;
    }

    my $r = {
        group_uin => $to_id,
        key => $self->auth->{gface_key},
        sig => $self->auth->{gface_sig},
        content => "[[\"cface\",\"group\",\"$img_name\"],\"$content\",[\"font\",{\"name\":\"Tahoma\",\"size\":\"10\",\"style\":[0,0,0],\"color\":\"000000\"}]]",
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

sub send_group_message_cface_debug {
    my ($self, $to_id, $content, $img_name) = @_;

    my $r = {
        group_uin => $to_id,
        key => $self->auth->{gface_key},
        sig => $self->auth->{gface_sig},
        content => "[[\"cface\",\"group\",\"$img_name\"],\"$content\",[\"font\",{\"name\":\"Tahoma\",\"size\":\"10\",\"style\":[0,0,0],\"color\":\"000000\"}]]",
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

1;
