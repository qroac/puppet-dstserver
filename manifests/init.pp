# @summary 
#   Install, configure and run DST server instances
# 
# @api public
#
# @param user
#   Username for the dstserver system user
# @param homedir
#   Home directory for the system user and install location for all DST related data
# @param instances
#   Instances of DST servers to be configured and started. Each key is used as resourcename for one instance, 
#   the values refer to the parameters for dstserver::instance (except path).
# @param ensure
#   Ensure DST is installed and running, or removed from the node
# @param token
#   Klei server instance token. Use only for demo purpose with the default demo instance because it overrides 
#   the token value for all instances. In production, set the token along with the configuration for each instance.
#
# @example with configuration data from hiera
#         include dstserver
#
# @example with inline configuration
#         class { 'dstserver':
#           instances => {
#             my-dst-server => {
#               servername => 'My First Server',
#               token      => 'token-from-klei',
#             },
#             my-second-server => {
#               servername => 'My Second Server',
#               token      => 'another-token-from-klei',
#             },
#           }
#         }
class dstserver(
  String $user,
  String $homedir,
  Hash $instances,
  Enum['present', 'absent'] $ensure = present,
  Optional[String] $token = undef,
) {

  File{
    owner => $user,
    group => $user,
  }
  $bin_dir = "${homedir}/bin"
  $install_dir = "${homedir}/app"
  $profile_dir = "${homedir}/.klei"

  # Get a list of names of defined master and cave shards
  $masters = keys($instances)
  $caves = keys($instances.filter |$name, $data| { $data['caves'] == true })

  class {'dstserver::setup':
    ensure  => $ensure,
    user    => $user,
    homedir => $homedir,
    masters => $masters,
    caves   => $caves,
  }

  # place serverglobal mod setup script
  $used_mods = $instances.map |$name, $data| { if $data['mods'] { $data['mods'].keys } else {[]} }
  file{"${install_dir}/mods/dedicated_server_mods_setup.lua":
    ensure  => present,
    content => epp('dstserver/dedicated_server_mods_setup.lua', { mods => $used_mods.flatten.unique }),
    require => Exec['install-dst'],
  }

  # Generate dstserver instances
  $instances.each |$name, $data| {
    $server_dir = "${profile_dir}/DoNotStarveTogether/${name}"
    dstserver::instance{$name:
      require => File['dst-serverprofiles'],
      path    => $server_dir,
      *       => $data + {
        token => pick($token, $data['token'], "no token given for dstserver::instances.${name}.token")
      },
    }
  }
}
