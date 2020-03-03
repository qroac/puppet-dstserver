# @summary
#   Configure the cave shard of an instance and manage its systemd service
#
# @api private
# 
# @param path
#   Location to configure the shards data at
# @param ports
#   Ports to assign to this shard
# @param ensure
#   Install and run or remove the cave shard from the instance
# @param worldgenoverride
#   Worldgenoverride part for the caves of this instance, see section Worldgenoverride Config in Readme.md
# @param mods
#   Configuration Hash for mods on this instance, see section Mod Config in Readme.md
define dstserver::entity::caves(
  String $path,
  Array[Integer, 3, 3] $ports = [11035, 11036, 11037],
  Enum[present, absent] $ensure = present,
  Optional[Hash] $worldgenoverride,
  Optional[Hash] $mods,
  ) {
  if ($ensure == present) {
    # Caves active for this instance
    file{$path:
      ensure  => directory,
    }
    file{"${path}/server.ini":
      ensure  => [file, present],
      # Will be modified by the server process
      replace => 'no',
      content => epp('dstserver/server.caves.ini', {
        ports => $ports
      })
    }
    if $worldgenoverride {
      dstserver::config::worldgenoverride{"${name}-caves":
        ensure => present,
        path   => $path,
        *      => $worldgenoverride,
      }
    } else {
      dstserver::config::worldgenoverride{"${name}-caves":
        ensure => absent,
        path   => $path,
      }
    }
    dstserver::config::modoverride{"${name}-caves":
      path   => $path,
      mods   => $mods,
      notify => Service["dst-caves@${name}"],
    }
    service{"dst-caves@${name}":
      ensure  => running,
      enable  => true,
      require => File['service-dst-caves']
    }
  } else {
    # Caves disabled for this instance
    file{$path:
      ensure  => absent,
    }
    service{"dst-caves@${name}":
      ensure  => stopped,
      enable  => false,
      require => File['service-dst-caves']
    }
  }
}
