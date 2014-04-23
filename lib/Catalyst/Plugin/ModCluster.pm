package Catalyst::Plugin::ModCluster;

use strict;
use warnings;

use Data::Dumper;
use Net::MCMP;
use Text::SimpleTable;
use sigtrap handler => \&cleanup, qw/normal-signals/;

our $VERSION = '0.02';

my $mc_conf;
my @mcmp_objects;

sub setup {
	my $c = shift;

	$c->next::method(@_);

	$mc_conf = $c->config->{mod_cluster};
	
	unless (  ! $c->engine->env && exists $mc_conf->{Host} && exists $mc_conf->{Port} && exists $mc_conf->{Type}  ) {
		die 'Cannot get engine env, Host, Port and Type is required in that case';	
	}
	
	unless (  exists $mc_conf->{Host} ) {
		$mc_conf->{Host} =  $c->engine->env->{ SERVER_ADDR } || die 'Unable to determine a Host for your server';
	}
	
	unless ( exists $mc_conf->{Port} ) {
		$mc_conf->{Port} =  $c->engine->env->{ SERVER_PORT } || die 'Unable to determine a Port for your server';
	}
	
	unless ( exists $mc_conf->{Type} ) {
		$mc_conf->{Type} =  $c->engine->env->{ SERVER_PROTOCOL } || die 'Unable to determine a Type/Protocol for your server';
	}
	
	unless ( exists $mc_conf->{Alias} ) {
		$mc_conf->{Alias} = 'CatalystApp';
	}

	foreach my $key (qw/Context Alias/) {
		if ( exists $mc_conf->{$key} && ref $mc_conf->{$key} eq 'ARRAY' ) {
			$mc_conf->{$key} = join ',', @{ $mc_conf->{$key} };
		}
	}

	if ( $c->debug ) {
		my $mcdraw =
		  Text::SimpleTable->new( [ 20, 'Configuration' ], [ 51, 'Value' ] );

		foreach my $key ( keys %$mc_conf ) {
			$mcdraw->row( $key, $mc_conf->{$key} );
		}

		$c->log->debug(
			"Loaded Mod_Cluster configurations:\n" . $mcdraw->draw() . "\n" );

	}

	my @uris;

	if ( ref $mc_conf->{URI} eq 'ARRAY' ) {
		@uris = @{ $mc_conf->{URI} };
	}
	else {
		@uris = split ',', $mc_conf->{URI};
	}

	foreach my $uri (@uris) {
		my $mcmp =
		  Net::MCMP->new( { uri => $uri, debug => $mc_conf->{Debug} || 0 } );
		push @mcmp_objects, $mcmp;

		$mcmp->config(
			{
				Balancer            => $mc_conf->{Balancer},
				StickySession       => $mc_conf->{StickySession},
				StickySessionCookie => $mc_conf->{StickySessionCookie},
				StickySessionPath   => $mc_conf->{StickySessionPath},
				StickySessionRemove => $mc_conf->{StickySessionRemove},
				StickySessionForce  => $mc_conf->{StickySessionForce},
				WaitWorker          => $mc_conf->{WaitWorker},
				MaxAttempts         => $mc_conf->{MaxAttempts},
				JvmRoute            => $mc_conf->{NodeName},
				Domain              => $mc_conf->{Domain},
				Host                => $mc_conf->{Host},
				Port                => $mc_conf->{Port},
				Type                => $mc_conf->{Type},
				FlushPackets        => $mc_conf->{FlushPackets},
				FlushWait           => $mc_conf->{FlushWait},
				Ping                => $mc_conf->{Ping},
				Smax                => $mc_conf->{Smax},
				Ttl                 => $mc_conf->{Ttl},
				Timeout             => $mc_conf->{Timeout},
				Context             => $mc_conf->{Context},
				Alias               => $mc_conf->{Alias},
			}
		);

		$mcmp->enable_app(
			{
				JvmRoute => $mc_conf->{NodeName},
				Alias    => $mc_conf->{Alias},
				Context  => $mc_conf->{Context}
			}
		  ),

		  $mcmp->status(
			{
				JvmRoute => $mc_conf->{NodeName},
				Load     => 99,
			}
		  ),
		  ;
	}

}

sub cleanup {

	foreach my $mcmp (@mcmp_objects) {
		$mcmp->remove_app(
			{
				JvmRoute => $mc_conf->{NodeName},
				Alias    => $mc_conf->{Alias},
				Context  => $mc_conf->{Context}
			}
		);
		$mcmp->remove_route(
			{
				JvmRoute => $mc_conf->{NodeName},
			}
		);
	}
	exit;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::ModCluster - Mod Cluster integration	

=head1 SYNOPSIS

    use Catalyst qw/ModCluster/;
    
    MyApp->config({
		URI => "http://127.0.0.1:6666",
		NodeName => "MyApp1",
		Host => "127.0.0.1",
		Port => "3000",
		Type => "http",
		Context => "/myapp,/foo,/bar",
		Alias "myapp.example.com",
    });
    

=head1 DESCRIPTION

Plugin registers application node with apache mod_cluster, which allows
you to bring up new nodes in the cluster without modifying your load balancer
configurations.

When application starts, it will automatically send information to your cluster,
and if node dies, or getting turned off, plugin will update cluster with that information.

Official documentation for mod_cluster can be found here: https://www.jboss.org/mod_cluster

=head1 CONFIGURATION

=over 4

=item * URI

URI/address of your cluster, ex: "http://10.254.1.2:6666"
you can pass an array of URI's if you have multiple mod_cluster servers.

=item * NodeName

Unique name of your applications node, ex: "myapp001"

=item * Type

Servers protocol (http/https) of your node, if left blank
$c->engine->env->{ SERVER_PROTOCOL } will be used when possible,
otherwise application will fail to start

=item * Host

Hostname or IP address of your node. ex: 10.254.1.3, if
left blank, $c->engine->env->{ SERVER_ADDR } will be used when possible,
otherwise application will fail to start

=item * Port

Port number of your application. ex: 8080, if
left blank, $c->engine->env->{ SERVER_PORT } will be used when possible,
otherwise application will fail to start

=item * Context

Single context of your application, ex "/myapp", or an array of contexts.
	
=item * Alias

Server aliases that would be added to your apache virtual host on mod_cluster,
if not specified, default one will be used ("CatalystApp")

=back

		
=head1 SUPPORT

Please report all bugs via github at
https://github.com/winfinit/Catalyst-Plugin-ModCluster

=head1 AUTHOR

Roman Jurkov (winfinit) E<lt>winfinit@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 the Catalyst::Plugin::ModCluster L</AUTHORS> as listed above.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
