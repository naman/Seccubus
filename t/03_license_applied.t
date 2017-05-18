#!/usr/bin/env perl
# Copyright 2017 Frank Breedijk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------------------------------------------------------
# This little script checks all files te see if they are perl files and if so
# ------------------------------------------------------------------------------

use strict;
use Test::More;

my $travis = 1 if ( `pwd` =~ /\/travis\// );

my %exclude = (
	"./lib/IVIL.pm" 	=> "MIT Licensed project",
	"./SeccubusV2/OpenVAS/OMP.pm" 	=> "Artistic License 2.0",
	"./bin/dump_ivil" 	=> "MIT Licensed project",
	"./AUTHORS.txt"		=> "Part of the license",
	"./NOTICE.txt"		=> "Part of the license",
	"./ChangeLog.md"	=> "No license needed",
	"./README.md"		=> "No license needed",
	"./docs/Development_environment.md"
						=> "No license needed",
	"./docs/Development_on_MacOS.md"
						=> "No license needed",
	"./LICENSE.txt"		=> "It is the license itself",
	"./MANIFEST"		=> "Auto generated",
	"./MYMETA.json"		=> "Auto generated",
	"./MYMETA.yml"		=> "Auto generated",
	"Makefile"			=> "Auto generated",
	"./jmvc/seccubus/production.css"
						=> "Compiled file",
	"./jmvc/seccubus/production.js"
						=> "Compiled file",
	"./scanners/NessusLegacy/update-nessusrc"
						=> "Third party software",
	"./deb/debian.changelog"
						=> "No comments supported",
	"./deb/debian.control"
						=> "No comments supported",
	"./deb/debian.docs"	=> "No comments supported",
	"./deb/seccubus.dsc"
						=> "No comments supported",
	"./Makefile"		=> "Generated",
	"./junit_output.xml"
						=> "Build file",
	"./etc/config.xml"	=> "Local config file",
	"./etc/v2.seccubus.com.bundle"
						=> "Certificate bundle"
);
my $tests = 0;

my @files = split(/\n/, `find . -type f`);

foreach my $file ( @files ) {
	if ( $file !~ /\/\./ &&				# Skip hidden files
	     $file !~ /tmp/ &&				# Skip temp files
	     $file !~ /\.\/blib\// &&		# Skip blib directory
	     $file !~ /\.(3pm|gif|jpg|png|pdf|doc|di2|uml|mwb|pdn|psd|ico|gz|deb|rpm)/i &&
	     								# Skip binary formats
	     $file !~ /\.json$|\.nbe$|^\.\/scanners\/.*\/(defaults|description)\.txt$/ &&
	     								# Skip formats without comments
	     $file !~ /docs\/(HTML|TXT|WORD)\// &&
	     								# Skip files generated by Word
	     $file !~ /^\.\/jmvc\/(documentjs|MIT\-LICENSE\.txt|changelog\.md|funcunit|js|js\.bat|README|jquery|steal)/ &&
	     								# Skip JMVC framework
	     $file !~ /^\.\/www\// &&		# Skip complied JMVC code
	     $file !~ /^\.\/obs\/home:seccubus/ &&
	     								# OpenSuse Build services files
	     $file !~ /\.(bak|old|log)$/	# Skip backups and logs
	) { #skip certain files
		my $type = `file '$file'`;
		chomp($type);
		if ( $type =~ /Perl|shell script|ASCII|XML\s+document text|HTML document|script text|exported SGML document|Unicode text|PEM certificate/i ) {
			if ( ! $exclude{$file} ) {
				if ( $file =~ /\_service|\.xml\..*$|\.xml$|\.nessus$|.py$/ ) {
					# License starts at line 2
					is(checklic($file,2), 0, "Is the Apache license applied to $file");
					$tests++;
				} elsif ( $file =~ /jmvc\/.*\.md$/ ) {
					# License starts at line 3
					is(checklic($file,3), 0, "Is the Apache license applied to $file");
					$tests++;
				} elsif ( $file =~ /\.ejs$/ ) {
					# License starts at line 0
					is(checklic($file,0), 0, "Is the Apache license applied to $file");
					$tests++;
				} else {
					# License starts at line 1
					is(checklic($file,1), 0, "Is the Apache license applied to $file");
					$tests++;
				}
				is(hasauthors($file), 1, "Has file '$file' got all 'git blame' authors in it?");
				$tests++;
			}
		} elsif ( $type =~ /empty/ ) {
			# Skip
		} else {
			die "Unknown file type $type";
		}
	}
}
done_testing($tests);

sub checklic {
	my $file = shift;
	my $start = shift;
	$start = 1 unless defined $start;

	open F, $file or die "Unable to open file $file";
	my @data = (<F>);
	close F;
	return 1 if $data[$start+0] !~ /Copyright/;
	return 2 if $data[$start+2] !~ /Licensed under the Apache License, Version 2\.0 \(the "License"\);/;
	return 3 if $data[$start+3] !~ /you may not use this file except in compliance with the License\./;
	return 4 if $data[$start+4] !~ /You may obtain a copy of the License at/;

	return 5 if $data[$start+6] !~ /http\:\/\/www\.apache\.org\/licenses\/LICENSE\-2\.0/;

	return 6 if $data[$start+8] !~ /Unless required by applicable law or agreed to in writing, software/;
	return 7 if $data[$start+9] !~ /distributed under the License is distributed on an "AS IS" BASIS,/;
	return 8 if $data[$start+10] !~ /WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied\./;
	return 9 if $data[$start+11] !~ /See the License for the specific language governing permissions and/;
	return 10 if $data[$start+12] !~ /limitations under the License\./;

	# All OK
	return 0;
}

sub hasauthors {
	my $file = shift;
	my $result = 1;

	my $head = `head -20 '$file'|grep Copyright`;
	$head =~ /Copyright (\d+)/;
	my $year = $1;

	$ENV{PERLBREW_ROOT} = "" unless $ENV{PERLBREW_ROOT};
	my $blame = `git blame '$file' 2>&1`;
	my %authors = ();
	my $cyear = 0;

	unless ( $blame =~ /no such path.*in HEAD/ && $file ne "./t/03_license_applied.t" ) {
		foreach my $line ( split /\n/, $blame ) {
			$line =~ /\((.*?)\s+(\d\d\d\d)\-\d\d\-\d\d/;
			my $name = $1;
			$name = "Petr" if $name eq 'Петр';
			$name = "Petr" if $name eq 'ĐĐľŃŃ';
			$authors{$1} = 1;
			$cyear = $2 if $2 > $cyear;
		}

		foreach my $auth ( sort keys %authors ) {
			unless ( $auth eq "Not Committed Yet" ) {
				like($head, qr/$auth/, "Author $auth is duely credited in file: $file");
				$tests++;
			}
		}
		#unless( $travis ) {
			# Travis CI uses a truncated history (-depth=50), so this gives skewed results
			is($year, $cyear, "Copyright year of file: $file");
			$tests++;
		#}
	}

	return 1;
}
