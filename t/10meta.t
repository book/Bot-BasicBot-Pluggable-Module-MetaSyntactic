use Test::More;
use List::Util;
use Bot::BasicBot::Pluggable::Module::MetaSyntactic;

my $nick;

# "alter" the shuffle method
{
    no warnings;
    my ( $i, $j ) = ( 0, 0 );
    *List::Util::shuffle = sub { sort @_ };    # item selection
    *Acme::MetaSyntactic::any::shuffle =       # theme selection
        sub (@) { my @t = sort @_; push @t, shift @t for 1 .. $j; $j++; @t };
}

# create a mock bot
{
    no warnings;

    package Bot::BasicBot::Pluggable::Module;
    sub bot { bless {}, 'Bot::BasicBot' }

    package Bot::BasicBot;
    sub ignore_nick { $_[1] eq 'ignore_me' }
    sub nick {$nick}
}

# test the told() method
my @tests = (
    [   {   'body'     => 'hello bam',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'channel'  => '#zlonkbam',
            'raw_body' => 'hello bam',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'welcome here',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: welcome here',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'hi bam',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'hi bam',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'meta batman',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'channel'  => '#zlonkbam',
            'raw_body' => 'meta batman',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'meta foo',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo',
            '_nick'    => 'bam',
        } => 'bar'
    ],
    [   {   'body'     => 'meta: foo 2',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo 2',
            '_nick'    => 'bam',
        } => 'baz corge'
    ],
    [   {   'body'     => 'meta: foo 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo 0',
            '_nick'    => 'bam',
        } => 'bar baz corge foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy'
    ],
    [   {   'body'     => '++',
            'raw_nick' => 'BooK!~book@zlonk.bruhat.net',
            'who'      => 'BooK',
            'address'  => 'meta',
            'channel'  => '#perlfr',
            'raw_body' => 'meta++',
            '_nick'    => 'meta',
        } => undef,
    ],
    [   {   'body'     => 'meta foo/fr',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo/fr',
            '_nick'    => 'bam',
        } => 'bidon'
    ],
    [   {   'body'     => 'meta foo/fr 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo/fr 0',
            '_nick'    => 'bam',
        } => 'bidon bidule chose chouette machin pipo tata test1 test2 test3 titi toto truc tutu'
    ],
    [   {   'body'     => 'meta foo/fr 3',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo/fr 3',
            '_nick'    => 'bam',
        } => 'bidule chose chouette'
    ],
    [   {   'body'     => 'meta themes?',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta themes?',
            '_nick'    => 'bam',
        } => join( ' ', 'Available themes:', Acme::MetaSyntactic->themes )
    ],
);

plan tests => @tests + 1;

my $bot = Bot::BasicBot::Pluggable::Module::MetaSyntactic->new;
$ENV{LANGUAGE} = 'en';

# quick test of the help string
like( $bot->help(), qr/meta theme/, 'Basic usage line' );

for my $t (@tests) {
    $nick = delete $t->[0]{_nick};    # setup our nick
    is( $bot->told( $t->[0] ),
        $t->[1],
        qq{Answer to "$t->[0]{raw_body}" on channel $t->[0]{channel}} );
}

