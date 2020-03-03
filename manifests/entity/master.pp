# @summary
#   Configure the master shard of an instance and manage its systemd service
#
# @api private
# 
# @param path
#   Location to configure the shards data at
# @param ports
#   Ports to assign to this shard
# @param ensure
#   Install and run the master shard or remove its system service
# @param worldgenoverride
#   Worldgenoverride part for the master of this instance, see section Worldgenoverride Config in Readme.md
# @param mods
#   Configuration Hash for mods on this instance, see section Mod Config in Readme.md
define dstserver::entity::master(
  String $path,
  Array[Integer, 3, 3] $ports = [11032, 11033, 11034],
  Enum[present, absent] $ensure = present,
  Optional[Hash] $worldgenoverride,
  Optional[Hash] $mods,
) {
  if($ensure == present){
    file{$path:
      ensure  => directory,
    }
    file{"${path}/server.ini":
      ensure  => [file, present],
      # Will be modified by the server process
      replace => 'no',
      content => epp('dstserver/server.master.ini', {
        ports => $ports
      })
    }
    if $worldgenoverride {
      dstserver::config::worldgenoverride{"${name}-master":
        ensure => present,
        path   => $path,
        *      => $worldgenoverride,
      }
    } else {
      dstserver::config::worldgenoverride{"${name}-master":
        ensure => absent,
        path   => $path,
      }
    }
    dstserver::config::modoverride{"${name}-master":
      path   => $path,
      mods   => $mods,
      notify => Service["dst-master@${name}"],
    }
    service{"dst-master@${name}":
      ensure  => running,
      enable  => true,
      require => File['service-dst-master']
    }
  } else {
    # Ensure service is removed
    service{"dst-master@${name}":
      ensure  => stopped,
      enable  => false,
      require => File['service-dst-master']
    }
  }
}
