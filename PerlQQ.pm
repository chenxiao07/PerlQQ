package PerlQQ;

use strict;
use warnings;
use PerlQQ::Login;
use PerlQQ::Action;
use PerlQQ::Auth;
use JSON qw/from_json to_json/;
use Data::Dumper;
use IPC::ShareLite;
use Text::ASCIITable;
use Encode qw/encode decode/;

sub new {
    my ($cls) = @_;
    my $args = {};
    $args->{data} = IPC::ShareLite->new(
            -key    => 100000+int(900000*rand()),
            -create => 'yes',
            -destroy   => 'no',
        );
    $args->{state} = 0;
    bless $args, $cls;
}

sub client {
    my $self = shift;
    $self->{action};
}

sub data {
    my $self = shift;
    $self->{data};
}

sub store {
    my ($self, $content) = @_;
    my $store;
    if (my $tmp = decode('UTF-8', $self->data->fetch)) {
        $store = from_json($tmp);
    } else {
        $store = {};
        $store->{_index} = 0;
    }
    $store->{_index} = $store->{_index} + 1;
    $store->{$store->{_index}} = $content;
    $self->data->store(encode('UTF-8', to_json($store)));
}

sub messages {
    my $self = shift;
    $self->{messages} = Text::ASCIITable->new();
    $self->{messages}->setCols('message type', 'receive date', 'content', 'from_user', 'from_group');
    if (my $tmp = $self->data->fetch) {
        my $store = from_json($tmp);
        for my $id (1..$store->{_index}) {
            my $r = $store->{$id};
            if ($r->{poll_type} eq 'message') {
                $self->{messages}->addRow($r->{poll_type}, $r->{value}->{time}, $r->{value}->{content}->[-1], $r->{value}->{from_uin}, "");
            } elsif ($r->{poll_type} eq 'group_message') {
                $self->{messages}->addRow($r->{poll_type}, $r->{value}->{time}, $r->{value}->{content}->[-1], $r->{value}->{send_uin}, $r->{value}->{from_uin});
            }
        }
    }
    $self->{messages};
}

sub friends {
    my $self = shift;
    unless ($self->{friends}) {
        $self->{friends} = Text::ASCIITable->new();
        $self->{friends}->setCols('user id', 'nickname');
        my $tmp = from_json($self->client->get_friends->content);
        for my $friend (@{$tmp->{result}->{info}}) {
            $self->{friends}->addRow($friend->{uin}, $friend->{nick});
        }
    }
    $self->{friends};
}

sub groups {
    my $self = shift;
    unless ($self->{groups}) {
        $self->{groups} = Text::ASCIITable->new();
        $self->{groups}->setCols('group name', 'group id', 'group code');
        my $tmp = from_json($self->client->get_groups->content);
        for my $group (@{$tmp->{result}->{gnamelist}}) {
            $self->{groups}->addRow($group->{name}, $group->{gid}, $group->{code});
        }
    }
    $self->{groups};
}

sub self_info {
    my $self = shift;
    unless ($self->{self_info}) {
        $self->{self_info} = $self->client->get_single_info->content;
    }
    $self->{self_info};
}

sub login {
    my ($self, $username, $password) = @_;
    my $login = PerlQQ::Login->new({username => $username, password => $password});
    my $auth = $login->login;
    $self->{action} = PerlQQ::Action->new({auth => $auth});
}

sub message_loop {
    my $self = shift;
    if ($self->{pid} = fork()) {
        $self->InterAct;
    } else {
        $self->KeepAlive;
    }
}

sub InterAct {
    my $self = shift;
    use Term::ReadLine;
    my $term = Term::ReadLine->new('PerlQQ交互终端');
    my $prompt = "请输入命令编号(h打印帮助): ";
    my $OUT = $term->OUT || \*STDOUT;
    while ( defined ($_ = $term->readline($prompt)) ) {
        my $res = $self->parse($_);
        print $OUT $res, "\n";
    }
}

sub parse {
    my ($self, $content) = @_;
    my $r = "";
    if ($content ~~ m/^1$/) {
        $r = $self->messages;
    } elsif ($content ~~ m/^2$/) {
        $r = $self->friends;
    } elsif ($content ~~ m/^3$/) {
        $r = $self->groups;
    } elsif ($content ~~ m/^4\s+\d+\s+[^\s].*$/ || $content eq "4") {
        if ($content eq "4") {
            $r = "格式：4 [好友uin] [要发送的信息]\n";
        } else {
            my ($uin, $msg) = ($content =~ m/^4\s+(\d+)\s+([^\s].*)$/);
            $msg = $msg;
            $r = $self->client->send_message($uin, $msg)->content;
        }
    } elsif ($content ~~ m/^5\s+\d+\s+[^\s].*$/ || $content eq "5") {
        if ($content eq "5") {
            $r = "格式：5 [qq群uin] [要发送的信息]\n";
        } else {
            my ($uin, $msg) = ($content =~ m/^5\s+(\d+)\s+([^\s].*)$/);
            $msg = $msg;
            $r = $self->client->send_group_message($uin, $msg)->content;
        }
    } elsif ($content ~~ m/^6\s+\d+$/ || $content eq "6") {
        if ($content eq "6") {
            $r = "格式：6 [好友uin]\n";
        } else {
            my ($uin) = ($content =~ m/^5\s+(\d+)$/);
            $r = $self->client->get_friend_info($uin)->content;
        }
    } elsif ($content ~~ m/^7\s+\d+$/ || $content eq "7") {
        if ($content eq "7") {
            $r = "格式：7 [qq群code]\n";
        } else {
            my ($code) = ($content =~ m/^7\s+(\d+)$/);
            $r = $self->client->get_group_info($code)->content;
        }
    } elsif ($content ~~ m/^8\s+[^\s].*$/ || $content eq "8") {
        if ($content eq "8") {
            $r = "格式：8 [签名内容]\n";
        } else {
            my ($msg) = ($content =~ m/^8\s+([^\s].*)$/);
            $msg = $msg;
            $r = $self->client->set_nick($msg)->content;
        }
    } elsif ($content ~~ m/^9$/) {
        delete $self->{friends};
        delete $self->{groups};
    } elsif ($content ~~ m/^0$/) {
        kill 9, $self->{pid};
        exit 1;
    } elsif ($content ~~ m/^h$/) {
        $r = "1, 打印消息列表\n".
            "2, 打印好友列表\n".
            "3, 打印群组列表\n".
            "4, 发送好友信息\n".
            "5, 发送群信息\n".
            "6, 获取好友信息\n".
            "7, 获取群信息\n".
            "8, 设置签名\n".
            "9, 清除本地缓存\n".
            "x, API列表一览\n".
            "0, 退出\n";
    } elsif ($content ~~ m/^x$/) {
        $r = "get_single_info\n".
            "get_friend_info\n".
            "get_nick\n".
            "get_level\n".
            "set_nick\n".
            "poll\n".
            "get_real_id\n".
            "get_group_info_pre\n".
            "get_group_info\n".
            "send_message\n".
            "send_group_message\n".
            "get_friends\n".
            "get_groups\n".
            '输入$self->client->{api}直接进行操作'.
            "\n";
    } else {
        eval ($content);
        warn $@ if $@;
        $r = $_;
    }
    $r;
}

sub KeepAlive {
    my $self = shift;
    while(my $res = $self->client->poll) {
        eval {
            my $result = from_json($res->content);
            if ($result->{retcode} == 0) {
                for my $msg (@{$result->{result}}) {
                    $self->logger($msg);
                    $self->store($msg);
                }
            } else {
                $self->logger($result);
            }
        } or do {
            $self->logger($@);
            $self->logger($res->content);
        }
    }
}

sub logger {
    my ($self, $content, $level) = @_;
    $level //= 0;
    $content = to_json($content) if ref $content;
    $content = encode('UTF-8', $content);
    open(MYFILE, ">>/var/tmp/webqq.txt");
    print MYFILE "[".localtime(time())."]  ".$content."\n";
    close(MYFILE);
}

1;
