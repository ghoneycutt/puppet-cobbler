# Class: cobbler
#
# This module manages Cobbler
# https://fedorahosted.org/cobbler/
#
# Requires:
#   class apache::ssl
#   class dhcp::cobbler
#   class puppet
#   $cobbler_listen_ip be set in the nodes manifest, else defaults to $ipaddress_eth1
#
class cobbler {

    include apache::ssl
    include dhcp::cobbler
    include puppet

    package {[
        "cobbler-web",
        "hardlink",
        "pykickstart"
    ]:} # package

    File {
        require => Package["cobbler-web"],
        notify  => Exec["cobblersync"],
    } # File

    file {
        "/etc/cobbler/modules.conf":
            source  => "puppet:///modules/cobbler/modules.conf";
        "/etc/cobbler/users.digest":
            source  => "puppet:///modules/cobbler/users.digest",
            mode    => 660;
        "/etc/cobbler/settings":
            content => template("cobbler/settings.erb"),
            mode    => "664";
        "/etc/cobbler/dhcp.template":
            content => template("cobbler/dhcp.template.erb"),
            notify  => Service["dhcpd"];
    } # file

    # download content needed for netboots into /var/lib/cobbler/loaders/
    exec { "cobbler get-loaders":
        command => "/usr/bin/cobbler get-loaders",
        require     => Package["cobbler-web"],
        creates     => "${puppet::semaphores}/$name",
        refreshonly => true,
        notify      => [Service["cobblerd"], Exec["cobblersync"] ],
        before => Service["cobblerd"],
    } # exec

    # allow us to sync cobbler
    exec { "cobblersync":
        command     => "/usr/bin/cobbler sync",
        refreshonly => true;
    } # exec

    service { "cobblerd":
        ensure  => running,
        enable  => true,
        require => [ Service["apacheService"], Package["cobbler-web"] ],
    } # service
} # class cobbler
