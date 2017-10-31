package Date::Simple::Fmt;
use Date::Simple 3;
use base qw/Date::Simple/;
use overload '""' => '_format';

*EXPORT      = *Date::Simple::EXPORT;
*EXPORT_OK   = *Date::Simple::EXPORT_OK;
*EXPORT_TAGS = *Date::Simple::EXPORT_TAGS;

sub d8    { shift->_d8(@_) }
sub today { shift->_today(@_) }
sub ymd   { shift->_ymd(@_) }

sub new {
    my ( $class, $fmt, @args ) = @_;
    my $self = $class->SUPER::new(@args);
    $self->default_format($fmt);
    $self;
}

sub _format { shift->format() }

1;


