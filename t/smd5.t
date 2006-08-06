use Test::More tests => 66;

use MIME::Base64 2.21 qw(encode_base64);

BEGIN { use_ok "Authen::Passphrase::SaltedDigest"; }

SKIP: {
eval { Digest->new("MD5"); };
skip "no MD5 facility", 45 unless $@ eq "";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/(\S+) (\S+) *//;
	my($salt_hex, $hash_hex) = ($1, $2);
	my $salt = pack("H*", $salt_hex);
	my $hash = pack("H*", $hash_hex);
	my $ppr = Authen::Passphrase::SaltedDigest
			->new(algorithm => "MD5",
			      ($i & 1) ? (salt => $salt) :
					 (salt_hex => $salt_hex),
			      ($i & 2) ? (hash => $hash) :
					 (hash_hex => $hash_hex));
	$i++;
	ok $ppr;
	is $ppr->salt_hex, $salt_hex;
	is $ppr->salt, $salt;
	is $ppr->hash_hex, $hash_hex;
	is $ppr->hash, $hash;
	eval { $ppr->passphrase }; isnt $@, "";
	eval { $ppr->as_crypt }; isnt $@, "";
	is $ppr->as_rfc2307, "{SMD5}".encode_base64($hash.$salt, "");
	$pprs{$_} = $ppr;
}

foreach my $rightphrase (sort keys %pprs) {
	my $ppr = $pprs{$rightphrase};
	foreach my $passphrase (sort keys %pprs) {
		ok ($ppr->match($passphrase) xor $passphrase ne $rightphrase);
	}
}

}

__DATA__
616263 900150983cd24fb0d6963f7d28e17f72
717765 ce97e12b13baef6403b5456f8fc2ce99 0
212121 b097f957c235fd286364dc2084b2546d 1
787878 097412258a515fc61cfe73f421f58b8f foo
707966 c676f3ddf4b4ed188a89d73525ff678e supercalifragilisticexpialidocious
