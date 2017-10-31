# Date::Simple - a simple date object

package Date::Simple;

BEGIN {
    $VERSION = '3.03';
}

use Exporter ();
@ISA = ('Exporter');

@EXPORT_OK = qw(
  today ymd d8 leap_year days_in_month
  date date_fmt date_d8 date_iso
);

%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );


if ( !defined(&_add) ) {
    my $err = $Date::Simple::NoXS;
    unless ($err) {

        
        local ($@);
        local @ISA = ('DynaLoader');
        require DynaLoader;
        eval { __PACKAGE__->bootstrap($VERSION); };
        $err = $@;
    }
    if ($err) {
        $Date::Simple::NoXs = 1;
        require Date::Simple::NoXS;
    }
}

use strict;
use Carp ();
use overload
  '+'    => '_add',
  '-'    => '_subtract',
  '=='   => '_eq',
  '!='   => '_ne',
  '<=>'  => '_compare',
  'eq'   => '_eq',
  'ne'   => '_ne',
  'cmp'  => '_compare',
  'bool' => sub { 1 },
  '""'   => 'as_iso';

use Scalar::Util qw(refaddr reftype);
use warnings::register;
require Date::Simple::Fmt;
require Date::Simple::ISO;
require Date::Simple::D8;

sub d8 {

    
    if ( $#_ == 0 ) {
        return __PACKAGE__->_d8(@_);
    }

    
    else {
        if ( ref $_[0] eq 'SCALAR' ) {
            return $_[0]->SUPER::_d8(@_);
        }
        else {
            return $_[0]->_d8(@_);
        }
    }
}

sub today {
    if ( $#_ == -1 ) {
        return __PACKAGE__->_today(@_);
    }
    else {
        return shift->_today(@_);
    }
}

sub ymd {

    
    if ( $#_ == 2 ) {
        return __PACKAGE__->_ymd(@_);
    }

    
    else {
        if ( ref $_[0] eq 'SCALAR' ) {
            return $_[0]->SUPER::_ymd(@_);
        }
        else {
            return $_[0]->_ymd(@_);
        }
    }
}

sub _today {
    my ( $y, $m, $d ) = (localtime)[ 5, 4, 3 ];
    $y += 1900;
    $m += 1;
    return $_[0]->_ymd( $y, $m, $d );
}

sub _inval {
    my ($first);
    $first = shift;
    Carp::croak( "Invalid "
          . ( ref($first) || $first )
          . " constructor args: ('"
          . join( "', '", @_ )
          . "')" );
}

sub _new {
    my ( $that, @ymd ) = @_;

    my $class = ref($that) || $that;

    if ( @ymd == 1 ) {
        my $x = $ymd[0];
        if ( ref $x and reftype($x) eq 'ARRAY' ) {
            @ymd = @$x;
        }
        elsif ( UNIVERSAL::isa( $x, __PACKAGE__ ) ) {
            return ($x);
        }
        elsif ($x =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/
            || $x =~ /^(\d\d\d\d)(\d\d)(\d\d)$/ ) {
            @ymd = ( $1, $2, $3 );
        }
        else {
            return (undef);
        }
    }
    
    return $class->_today() unless @ymd;

  
    if ( @ymd == 3 ) {
        my $days = ymd_to_days(@ymd);
        return undef if !defined($days);
        return ( bless( \$days, $class ) );
    }

    $class->_inval(@ymd);
}

sub date { scalar __PACKAGE__->_new(@_) }

sub date_fmt {
    my $format = shift;
    my $obj    = Date::Simple::Fmt->_new(@_);
    $obj->default_format($format)
      if $obj;
    $obj;
}

sub date_d8  { scalar Date::Simple::D8->_new(@_) }
sub date_iso { scalar Date::Simple::ISO->_new(@_) }


sub new {
    my ( $class, $date );

    $date = &_new;
    if ( !$date && scalar(@_) == 1 ) {
        Carp::croak( "'" . shift() . "' is not a valid ISO formated date" );
    }
    return ($date);
}

sub next { return ( $_[0] + 1 ); }
sub prev { return ( $_[0] - 1 ); }

sub _gmtime {
    my ( $y, $m, $d ) = days_to_ymd( ${ $_[0] } );
    $y -= 1900;
    $m -= 1;
    return ( 0, 0, 0, $d, $m, $y );
}

BEGIN {
    our $Standard_Format = "%Y-%m-%d";
    my %fmts = (
        'Date::Simple'      => $Standard_Format,
        'Date::Simple::ISO' => $Standard_Format,
        'Date::Simple::D8'  => "%Y%m%d",
        'Date::Simple::Fmt' => $Standard_Format,
    );

    sub format {
        my ( $self, $format ) = @_;

        $format =
             $fmts{ refaddr($self) || '' }
          || $fmts{ ref($self) }
          || $Standard_Format
          if @_ == 1;

        return "$self" unless defined($format);
        require POSIX;
        local $ENV{TZ} = 'UTC+0';
        return POSIX::strftime( $format, _gmtime($self) );
    }

    sub strftime { &format }
    sub as_str   { &format }

    sub default_format {
        my ( $self, $val ) = @_;

        my $o = refaddr($self) || $self;

        if ( @_ > 1 ) {
            $fmts{$o} = $val;
            warnings::warnif "Setting class specific date format '$o' to" . "'"
              . ( defined $val ? $val : 'undef' ) . "'"
              unless ref $self;
        }

        return $fmts{$o} || $Standard_Format;
    }

    sub DESTROY {
        delete $fmts{ refaddr $_[0] };
    }
}

1;


