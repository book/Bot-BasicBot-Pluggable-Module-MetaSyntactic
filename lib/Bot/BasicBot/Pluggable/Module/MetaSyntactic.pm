package Bot::BasicBot::Pluggable::Module::MetaSyntactic;

use strict;
use warnings;
use Carp;
use Bot::BasicBot::Pluggable::Module;
use Acme::MetaSyntactic ();
use Text::Wrap;

our @ISA     = qw(Bot::BasicBot::Pluggable::Module);
our $VERSION = '0.01';

sub init {
    my $self = shift;

    $self->{meta} = {
        limit => 100,
        wrap  => 256,
    };

    $Text::Wrap::columns = $self->{meta}{wrap};

    $self->{meta}{main} = Acme::MetaSyntactic->new()
        or carp "fatal: Can't create new Acme::MetaSyntactic object"
        and return undef;
}

sub told {
    my ( $self, $mess ) = @_;
    my $bot = $self->bot();

    # we must be directly addressed
    return
        if !(   (   defined $mess->{address}
                    && $mess->{address} eq $bot->nick()
                )
                || $mess->{channel} eq 'msg'
        );

    # ignore people we ignore
    return if $bot->ignore_nick( $mess->{who} );

    # only answer to our command (which can be our name too)
    my $src = $bot->nick() eq 'meta' ? 'raw_body' : 'body';
    return if $mess->{$src} !~ /^\s*meta(.*)/i;

    # ignore the noise
    ( my $command = "$1" ) =~ s/^\W*//;

    # pick up the commands
    ( $command, my @args ) = split /\s+/, $command;
    return if !$command || !length $command;

    # it's a theme
    if ( $command =~ /^[\w\/]+$/ ) {
        my ( $theme, $category ) = split m'/', $command, 2;
        $self->{meta}{theme}{$command} ||= do {
            my $module = "Acme::MetaSyntactic::$theme";
            eval "require $module" or die;
            $module->new( ( category => $category ) x !!$category );
        };
        return "No such theme: $theme"
            if !$self->{meta}{main}->has_theme($theme);
        return join " ", $self->{meta}{theme}{$command}->name(@args);
    }
    elsif ( $command =~ /^themes\?$/ ) {
        return join ' ', 'Available themes:', $self->{meta}{main}->themes();
    }

    # TODO: other commands
    # - version?            : list all versions
    # - themes?             : list all known themes
    # - categories? <theme> : list all categories for the theme

    return;
}

sub help {'meta theme [count]'}

1;

