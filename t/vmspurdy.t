use Test::More tests => 103;

BEGIN { use_ok "Authen::Passphrase::VMSPurdy"; }

my $ppr = Authen::Passphrase::VMSPurdy
		->new(username => "jrandom", salt => 1234,
		      passphrase => "wibble");
ok $ppr;
is $ppr->algorithm, "PURDY_S";
is $ppr->username, "JRANDOM";
is $ppr->salt, 1234;
is $ppr->hash, "\x2c\xef\x67\x47\x77\xa5\x48\x80";
is $ppr->hash_hex, "2cef674777a54880";
is $ppr->as_crypt, '$VMS3$D2042CEF674777A54880JRANDOM';
is $ppr->as_rfc2307, '{CRYPT}$VMS3$D2042CEF674777A54880JRANDOM';

$ppr = Authen::Passphrase::VMSPurdy
		->new(algorithm => "PURDY",
		      username => "jrandom", salt => 1234,
		      passphrase => "wibble");
ok $ppr;
is $ppr->algorithm, "PURDY";
is $ppr->username, "JRANDOM";
is $ppr->salt, 1234;
is $ppr->hash, "\xee\xf2\xac\x3d\xe0\xd9\x86\xa7";
is $ppr->hash_hex, "eef2ac3de0d986a7";
is $ppr->as_crypt, '$VMS1$D204EEF2AC3DE0D986A7JRANDOM';
is $ppr->as_rfc2307, '{CRYPT}$VMS1$D204EEF2AC3DE0D986A7JRANDOM';

$ppr = Authen::Passphrase::VMSPurdy
		->new(algorithm => "PURDY_V",
		      username => "jrandom", salt => 1234,
		      passphrase => "wibble");
ok $ppr;
is $ppr->algorithm, "PURDY_V";
is $ppr->username, "JRANDOM";
is $ppr->salt, 1234;
is $ppr->hash, "\xe3\x76\xee\x1b\x7a\xfa\xd4\x64";
is $ppr->hash_hex, "e376ee1b7afad464";
is $ppr->as_crypt, '$VMS2$D204E376EE1B7AFAD464JRANDOM';
is $ppr->as_rfc2307, '{CRYPT}$VMS2$D204E376EE1B7AFAD464JRANDOM';

$ppr = Authen::Passphrase::VMSPurdy
		->new(algorithm => "PURDY_S",
		      username => "jrandom", salt => 1234,
		      passphrase => "WiBbLe");
ok $ppr;
is $ppr->algorithm, "PURDY_S";
is $ppr->username, "JRANDOM";
is $ppr->salt, 1234;
is $ppr->hash, "\x2c\xef\x67\x47\x77\xa5\x48\x80";
is $ppr->hash_hex, "2cef674777a54880";
is $ppr->as_crypt, '$VMS3$D2042CEF674777A54880JRANDOM';
is $ppr->as_rfc2307, '{CRYPT}$VMS3$D2042CEF674777A54880JRANDOM';

$ppr = Authen::Passphrase::VMSPurdy
		->new(username => "jrandom", salt_random => 1,
		      passphrase => "wibble");
is $ppr->algorithm, "PURDY_S";
is $ppr->username, "JRANDOM";
ok $ppr->salt >= 0 && $ppr->salt < 65536;
is length($ppr->hash), 8;
like $ppr->hash_hex, qr/\A[0-9a-f]{16}\z/;
ok $ppr->match("wibble");

$ppr = Authen::Passphrase::VMSPurdy
		->from_crypt('$VMS3$D2042CEF674777A54880JRANDOM');
ok $ppr;
is $ppr->algorithm, "PURDY_S";
is $ppr->username, "JRANDOM";
is $ppr->salt, 1234;
is $ppr->hash, "\x2c\xef\x67\x47\x77\xa5\x48\x80";
is $ppr->hash_hex, "2cef674777a54880";
is $ppr->as_crypt, '$VMS3$D2042CEF674777A54880JRANDOM';
is $ppr->as_rfc2307, '{CRYPT}$VMS3$D2042CEF674777A54880JRANDOM';

$ppr = Authen::Passphrase::VMSPurdy
		->from_rfc2307('{CrYpT}$VMS3$D2042CEF674777A54880JRANDOM');
ok $ppr;
is $ppr->algorithm, "PURDY_S";
is $ppr->username, "JRANDOM";
is $ppr->salt, 1234;
is $ppr->hash, "\x2c\xef\x67\x47\x77\xa5\x48\x80";
is $ppr->hash_hex, "2cef674777a54880";
is $ppr->as_crypt, '$VMS3$D2042CEF674777A54880JRANDOM';
is $ppr->as_rfc2307, '{CRYPT}$VMS3$D2042CEF674777A54880JRANDOM';

foreach my $badpass ("", "a b", "1!", "oaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoab") {
	eval {
		Authen::Passphrase::VMSPurdy
			->new(username => "jrandom", salt => 1234,
			      passphrase => $badpass);
	};
	isnt $@, "";
}

my %pprs;
while(<DATA>) {
	chomp;
	s/(\S+) (\S+) (\S+) (\S+) *//;
	my($algorithm, $username, $salt, $hash_hex) = ($1, $2, $3, $4);
	$ppr = Authen::Passphrase::VMSPurdy
			->new(algorithm => $algorithm, username => $username,
			      salt => $salt, hash_hex => $hash_hex);
	ok $ppr;
	is $ppr->algorithm, $algorithm;
	is $ppr->username, uc($username);
	is $ppr->salt, $salt;
	is $ppr->hash, pack("H*", $hash_hex);
	is $ppr->hash_hex, $hash_hex;
	eval { $ppr->passphrase }; isnt $@, "";
	$pprs{$_} = $ppr;
}

foreach my $rightphrase (sort keys %pprs) {
	my $ppr = $pprs{$rightphrase};
	foreach my $passphrase (sort keys %pprs) {
		ok ($ppr->match($passphrase) xor $passphrase ne $rightphrase);
	}
}

__DATA__
PURDY Chekov 63412 6ec0aed034aca888 0
PURDY_S Kirk 5623 4e9c1cf8b461c7ff 1
PURDY_V Spock 9084 7d63771c2bc9bb96 foo
PURDY_V Sulu 645 0bcedbfcec4dee1d supercalifragilisticexpialidocio
