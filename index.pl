#!/usr/bin/perl

	use strict;
	use warnings;
	no warnings 'uninitialized';

	use CGI;
	use DBI;
	use JSON;
	use lib './';
	use Date::Simple( ':all' );

	use feature 'say';
	$| = 1;


	my $host = '';
	my $db = '';
	my $db_user = '';
	my $db_password = '';


	my $q = CGI->new;
	$q->{title} = 'Appointments schedule';

		if ( $q->param('find') )	{
			my $result = do_search();
			$result = encode_json $result;
			print $q->header, $result;
			exit 0;
		}

	header_tm( $q );

	if ( $q->param('submit') and $q->param('submit') eq 'Add' )	{
		my $result = update_db();
		add_result( $result ) if $result;
		do_main_page( $result );
	}
	else	{
		do_main_page();
	}

	print $q->end_html;

exit 0;


	sub do_main_page	{
		my $result = shift;

		get_new();
		search_form();
		search_result();
	} # end: do_main_page
	


	sub update_db	{
		my $date = $q->param('fldate');
		my $time = $q->param('fltime');
		my $description = $q->param('desc');

		unless ( $date and $time )	{
			return 'No date/time' ;
		}

			$date =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/;
				my ( $app_month, $app_day, $app_year ) = ( $1, $2, $3 );
				$app_month = '0' . $app_month if $app_month =~ /^\d{1}$/;
				$app_day = '0' . $app_day if $app_day =~ /^\d{1}$/;

			my $date_time = "$app_year-$app_month-$app_day";

			my ( $app_hour, $app_min, $ft ) = $time =~ /^(\d{1,2})\:(\d{2})\s*(AM|PM|am|pm)*/i;
			my $error = qq{Invalid time <span style="color: darkred;">$time</span>} unless $app_hour and $app_min;
			return $error if $error;

		$app_hour += 12 if $ft =~ /PM/i and $app_hour < 12;

			my $today = today();

			my $diff = date( $date_time ) - date( $today );
			$error = qq{Appointment in past not allowed <span style="color: darkred;">$date $time</span>} if $diff < 0;
			return $error if $error;

			if ( $date_time eq $today ) 	{
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time );

				my $flag = 1;
				$flag = 0 if $app_min - $min > 0;
				$error = qq{Appointment in past not allowed <span style="color: darkred;">$date $time</span>} if $app_hour - $hour < $flag;
				return $error if $error;
			}

		$date_time .= " $app_hour:$app_min:00";


		my $dbh = open_dbi();

			my $SQL = qq{ SELECT id FROM appointment WHERE app_date = ? };
				my $result = $dbh->selectrow_array( $SQL, {}, $date_time );
				$error = qq{Doubled appointment time <span style="color: darkred;">$date_time</span>} if $result;
				return $error if $error;


			my $SQL = qq{INSERT INTO appointment( app_date, description ) VALUES( ?, ? );};
			my $rv = $dbh->do( $SQL, undef, $date_time, $description ) || die $DBI::errstr;

		close_dbi( $dbh );

		return "New appointment added";
	} # end: update_db



	sub do_search	{
		my $str = $q->param('search');
		my $result;# = {};

		my $dbh = open_dbi();

		if ( $str )	{
			my $SQL = qq{ SELECT DATE_FORMAT(app_date, '%M %e %Y') app_date, DATE_FORMAT(app_date, '%h:%i %p') app_time, description 
					FROM appointment 
					WHERE description like ? 
					ORDER BY id };
			$result = $dbh->selectall_arrayref( $SQL, { Slice => {} }, "%$str%" );
		}
		else	{
			my $SQL = qq{ SELECT DATE_FORMAT(app_date, '%M %e %Y') app_date, DATE_FORMAT(app_date, '%h:%i %p') app_time, description 
					FROM appointment 
					ORDER BY id };
			$result = $dbh->selectall_arrayref( $SQL, { Slice => {} } );
		}

		close_dbi( $dbh );

		return $result;
	} # end: do_search


	sub get_new	{
		print qq{
			<div id="newrec" style="text-align: left; display: block; margin-left: 250px;">
				<input type="button" value="New" style="height: 30px;" onClick="show_form();" />
			</div>

			<div id="addrec" style="text-align: left; display: none; margin-left: 250px; margin-right: 250px;">
				<div>
					<form id="f1" method="post" action="">
						<p />
						<input type="submit" name="submit" value="Add" style="height: 30px;" />
						<input type="button" name="cancel" value="Cancel" style="height: 30px;" onClick="hide_form();" />
						<p />
						<input id="fldate" type="text" name="fldate" placeholder="Date (MM/DD/YYYY)" value="" style="height: 30px; float: left;"/>
						<p />
						<input id="fltime" type="text" name="fltime" placeholder="Time (HH:MM)" value="" style="height: 30px; clear: left; float: left;"/>
						<p />
						<input id="desc" type="text" name="desc" placeholder="Description" value="" style="height: 30px; clear: left; float: left;">
					</form>
				</div> 
				<div class="red">			</div>
				<p style="clear: left;">
			</div>
			<div style="border-bottom: 2px dotted slategray; height: 50px; margin: 0 250px 0 250px;">		</div>
		};
	} # end: get_new


	sub search_form	{
		print qq{
			<div id="sf" style="text-align: left; display: block; margin-left: 250px;">
				<div>
					<form>
						<p />
						<input id="search" type="text" name="search" value="" style="height: 30px;"/>
						<input type="button" value="Search" style="height: 30px;" onClick="do_search();"/>
							
					</form>
				</div> 
				<div class="green">			</div>
				<div class="red">			</div>
			</div>
		};
	} # end: search_form


	sub search_result	{
		print qq{
			<div id="sresult" style="text-align: left; display: none; margin-left: 250px;">
					<div id="app_res" val=""></div>
			</div>
		};
	} # end: search_result




	sub add_result		{
		my $result = shift;
		print qq{
			<div id="res" style="text-align: left; color: slategray; display: block; margin: 20px 250px 20px 250px;">
				$result
			</div>
		}
	} # end: add_result



		sub open_dbi		{
			my $dbh = DBI->connect( "dbi:mysql:$db:$host", "$db_user", "$db_password", { AutoCommit => 1 } ) or die $DBI::errstr;
		}

		sub close_dbi	{
			my $dbh = shift;
			$dbh->disconnect or die $DBI::errstr;
		}

		sub header_tm		{
			my $q = shift;

			my $jquery = 'https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js';
			my $jquery_ui = 'https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js';
			my $jq_validate = 'https://cdn.jsdelivr.net/jquery.validation/1.16.0/jquery.validate.min.js';
			my $jq_additional = 'https://cdn.jsdelivr.net/jquery.validation/1.16.0/additional-methods.min.js';
			my $java_script = java_script();

			my $style = './css/style.css';
			my $jq_style = 'https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/themes/smoothness/jquery-ui.css';
			my $jq_style_2 = 'http://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css';
			my $jq_style_valid = 'https://jqueryvalidation.org/files/demo/site-demos.css';

			print $q->header( { -charset=>'utf-8' } );
			print $q->start_html( { 	-title => $q->{title}, 
							-script => [
									{ -type => 'javascript', -src => $jquery },
									{ -type => 'javascript', -src => $jquery_ui },
									{ -type => 'javascript', -src => $jq_validate },
									{ -type => 'javascript', -src => $jq_additional },
									{ -type => 'javascript', -code => $java_script }
							],

							-style	=> [
									{ -src => $style },
									{ -src => $jq_style },
									{ -src => $jq_style_2 },
									{ -src => $jq_style_valid }	]
					} );
			print $q->h3( { -style=> "text-align: center;" }, $q->{title} );
		} # end: header_tm

		sub java_script		{
			return qq{\n
function show_form()	{
	\$( "#newrec" ).hide();
	\$( '#addrec' ).show();
};

function hide_form()	{
	\$( '#addrec' ).hide();
	\$( '#newrec' ).show();
};

/*	================================================================================================================	*/
function do_search()	{
	\$( '#sresult' ).hide();
	\$( '#app_res' ).text( '' );

	var str = \$('#search').val();

	var path = 'main.pl?find=1&search=' + str;
	\$.ajax({
		url: path,
		success: function (data) { 
//			var x = jQuery.parseJSON( data );
			var x = eval('(' + data + ')');

// console.log( x.length );

			var table = '<table cellpadding=6 cellspacing=0 style="border-top: 1px solid slategray; border-right: 1px solid slategray; border-left: 1px solid slategray; font: normal .9em sans-serif;"><tr><td style="width: 150px; border-bottom: 1px solid slategray; border-right: 1px solid slategray;"><b>Date</b></td><td style="width: 100px; border-bottom: 1px solid slategray; border-right: 1px solid slategray;"><b>Time</b></td><td style="width: 200px; border-bottom: 1px solid slategray;"><b>Description</b></td></tr>';

			var d = '';

			for ( i = 0; i < x.length; i++ )	{
				d += '<tr><td style="border-bottom: 1px solid slategray; border-right: 1px solid slategray;">' + x[i].app_date + '</td><td style="border-bottom: 1px solid slategray; border-right: 1px solid slategray;">' + x[i].app_time + '</td><td style="border-bottom: 1px solid slategray;">' + x[i].description + '</td></tr>' ; 
			}

			table += d + '</table>'; 
			if ( x.length > 0 )	{
				\$( '#app_res' ).html( table );
			}
			else if ( str == '' ) {
				var t = 'No available appointments';
				\$( '#app_res' ).html( t );
			}
			else	{
				var t = 'No appointments found for "' + str +  '"';
				\$( '#app_res' ).html( t );
			}

			\$( '#sresult' ).show();
		},
		error: function (error) {
			var msg = 'error: ' + error.responseText;
console.log( msg );
		}
	});
};
/*	================================================================================================================	*/

\$( function() {
	\$( "#fldate" ).datepicker( { 	minDate: -0, maxDate: "+5Y", 
					showOn: 'both', buttonImageOnly: true, 
					buttonImage: 'images/calendar-green.gif',
					buttonText: "Select date"	} 
	); 
	\$('#f1').validate({
		rules:	{
			fldate:	{
				required: true,
				date: true
			},
			fltime:	{
				required: true,
			}
		}
	});
} );



};
		} # end: java_script

