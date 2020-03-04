# @summary
#   Configure a DST server cluster that can run several DST server shards
# 
# @api private
#
# @param autosave
#   Enable or disable automatic saving after each night
# @param caves
#   Configure and run a cave shard in addition to the overworld shard
# @param clusterkey
#   Key to authenticate the cluser nodes to each other
# @param console
#   Enable or disable the remote server console
# @param description
#   Server Description in the public server list
# @param intention
#   Your play style intention for this instance
# @param masterport
#   Port of the master listening for shard connections
# @param mode
#   Server map mode
# @param password
#   Join password for the server
# @param path
#   Absolute path this instance profile will be configured at
# @param pause
#   Autmatically pause the game when no players are connected to the server
# @param players
#   Maximum player slots for this instance
# @param pvp
#   Enable PvP on this instance
# @param servername
#   Servername in the public server list, defaults to the key in the instances config hash
# @param token
#   Klei dedicated server token for this instance, obtained in your account management on Klei's website
# @param vote_kick
#   Allow players to vote for kicks
define dstserver::entity::cluster (
  String $path,
  String $servername,
  String $token,

  Boolean $autosave = true,
  Boolean $caves = false,
  String $clusterkey = 'dst',
  Boolean $console = true,
  String $description = '',
  Enum[present, absent] $ensure = present,
  Enum['social', 'cooperative', 'competetive', 'madness'] $intention = 'social',
  Integer $masterport = 11031,
  Enum['survival', 'wilderness', 'endless'] $mode = 'survival',
  String $password = '',
  Boolean $pause = true,
  Integer $players = 5,
  Boolean $pvp = false,
  Boolean $vote_kick = true,
) {
  file{"${name}-token-cluster":
    ensure  => $ensure,
    path    => "${path}/cluster_token.txt",
    content => $token,
    mode    => '0400',
    require => File[$path],
  }
  file{"${name}-conf-cluster":
    ensure  => $ensure,
    path    => "${path}/cluster.ini",
    content => epp('dstserver/cluster.ini', {
      mode        => $mode,
      players     => $players,
      pvp         => $pvp,
      pause       => $pause,
      name        => $servername,
      description => $description,
      password    => $password,
      intention   => $intention,
      autosave    => $autosave,
      vote_kick   => $vote_kick,
      console     => $console,
      masterport  => $masterport,
      clusterkey  => $clusterkey,
    }),
    mode    => '0400',
    require => File[$path],
  }
}
