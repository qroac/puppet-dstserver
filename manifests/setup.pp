# @summary 
#   Create the dstserver system user and required directories in its home location.  
#   Ensure, SteamCMD is available, place install and update scripts and install DST via SteamCMD.  
#   Place required systemd service units in the system folder.
#  
# @api private
# 
# @param ensure
#   Ensure, DST is installed and configured or remove the system service scripts
# @param user
#   Username for the dstserver system user
# @param homedir
#   Home directory for the system user and install location for all DST related data
# @param app_id
#   ID of the DST Server App in Steam
# @param masters
#   List of DST master shards to restart with systemctl during update
# @param caves
#   List of DST cave shards to restart with systemctl during update
# @param bin_dir
#   Directory to store required scripts in
# @param install_dir
#   Directory to install DST into
# @param profile_dir
#   Required location of the Klei profile directory
class dstserver::setup (
  Enum['present', 'absent'] $ensure,
  String $user,
  String $homedir,
  Integer $app_id,
  Array[String] $masters,
  Array[String] $caves,
  String $bin_dir = "${homedir}/bin",
  String $install_dir = "${homedir}/app",
  String $profile_dir = "${homedir}/.klei"
) {
  # DSTServer requires steamcmd to be installed
  class { 'steamcmd': }

  File{
    owner => $user,
    group => $user,
  }

  # create the system user for dst servers
  # will be removed if dstserver is ensured to be absent
  user{$user:
    ensure     => $ensure,
    comment    => 'System User for Dont Starve Togehter Gameservers',
    home       => $homedir,
    managehome => true,
    password   => '!!',
    shell      => '/bin/bash',
    system     => true,
  }

  if $ensure == 'present' {
    file{$bin_dir:
      ensure  => directory,
      require => User[$user],
    }
    # Install app from steam
    file{"${bin_dir}/install-dst.sh":
      ensure  => present,
      content => epp('dstserver/install.sh', {
        install_dir => $install_dir,
        app_id      => $app_id,
      }),
      mode    => '0500',
      require => File[$bin_dir],
    }
    exec{'install-dst':
      command => "${bin_dir}/install-dst.sh",
      user    => $user,
      creates => "${install_dir}/version.txt",
      require => [
        Class['steamcmd'],
        File["${bin_dir}/install-dst.sh"],
        ],
    }
    # Place app update script

    file{"${bin_dir}/update-dst.sh":
      ensure  => present,
      mode    => '0500',
      content => epp('dstserver/update.sh', {
        master => $masters,
        caves  => $caves,
      }),
      require => File[$bin_dir],
    }

    # create required folders
    file{$profile_dir:
      ensure  => directory,
      require => User['server-dst'],
    }
    file{'dst-serverprofiles':
      ensure  => directory,
      path    => "${profile_dir}/DoNotStarveTogether",
      require => File[$profile_dir],
    }
  }

  # Install or remove service script
  file{'service-dst-master':
    ensure  => $ensure,
    path    => '/etc/systemd/system/dst-master@.service',
    content => epp('dstserver/master.service', {
      install_dir => $install_dir,
      home_dir    => $homedir,
    }),
  }
  file{'service-dst-caves':
    ensure  => $ensure,
    path    => '/etc/systemd/system/dst-caves@.service',
    content => epp('dstserver/cave.service', {
      install_dir => $install_dir,
      home_dir    => $homedir,
    }),
  }
}
