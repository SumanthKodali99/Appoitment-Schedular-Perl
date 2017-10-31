package Date::Simple::D8;
use Date::Simple 3;
use base qw/Date::Simple/;
use overload '""' => 'as_d8';

*EXPORT      = *Date::Simple::EXPORT;
*EXPORT_OK   = *Date::Simple::EXPORT_OK;
*EXPORT_TAGS = *Date::Simple::EXPORT_TAGS;

sub d8    { shift->_d8(@_) }
sub today { shift->_today(@_) }
sub ymd   { shift->_ymd(@_) }

1;

