# Appoitment-Schedular-Perl


Work flow.

All the files should be unzipped in same directory.
Main executable program file is index.pl which should be chmod-ed to 755 (if needed). 


Program uses MySQL database that is accessed by following requisites: 
	my $host = '';
	my $db = '';
	my $db_user = '';
	my $db_password = '';
All the above variables are located at top line of index.pl, make sure they are filled properly. 
Program uses only one table "appointment" with 3 columns - SQL dump file that creates this table is appointment.sql. 

It creates new appointments and shows existing ones. Date and time validation is performed, appointments in the past are not allowed and they can't use same time of the day twice. System shows error messages in all cases new appointment can't be added.
Search function is Ajax based (no page refreshing) script returns JSON encoded results. Searching with an empty string returns all available records. 

Program uses standard jQuery scripts and css files. 
Included is also Date::Simple Perl module (in case it doesn't exist in the system). 
