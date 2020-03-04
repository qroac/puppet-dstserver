# @summary
#   Configure one cluster instance of DST and manage the sytemd service to ensure it is up and running
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
# @param ensure
#   Ensure the server is configured and ready or remove it from the node
# @param intention
#   Your play style intention for this instance
# @param mode
#   Server map mode
# @param mods
#   Configuration Hash for mods on this instance, see section Mod Config in Readme.md
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
# @param startport
#   Startport to use for required ports. Will obtain 7 ports in total beginning with this.
# @param token
#   Klei dedicated server token for this instance, obtained in your account management on Klei's website
# @param vote_kick
#   Allow players to vote for kicks
# @param worldgenoverrides
#   Configuration Hash for worldgenoverride on this instance, see section Worldgenoverride Config in Readme.md
define dstserver::instance(
  String $path,
  String $token,

  Boolean $autosave = true,
  Boolean $caves = false,
  String $clusterkey = 'dst',
  Boolean $console = true,
  String $description = '',
  String $ensure = present,
  Enum['social', 'cooperative', 'competetive', 'madness'] $intention = 'social',
  Enum['survival', 'wilderness', 'endless'] $mode = 'survival',
  String $password = '',
  Boolean $pause = true,
  Integer $players = 5,
  Boolean $pvp = false,
  String $servername = $name,
  Integer $startport = 11031,
  Boolean $vote_kick = true,
  Optional[Hash] $mods = undef,
  Optional[Hash] $worldgenoverrides = undef,
) {
  # Path variables for later use
  $path_master = "${path}/master"
  $path_caves = "${path}/caves"

  # Server Profile Folder
  # Force removal if instance is absent
  $ensure_profiledir = $ensure ? { present => directory, default => absent }
  file{$path:
    ensure => $ensure_profiledir,
    force  => true,
  }

  # Server Cluster
  dstserver::entity::cluster{$name:
    ensure      => $ensure,
    path        => $path,
    servername  => $servername,
    token       => $token,
    mode        => $mode,
    players     => $players,
    pvp         => $pvp,
    pause       => $pause,
    name        => $name,
    description => $description,
    password    => $password,
    intention   => $intention,
    autosave    => $autosave,
    vote_kick   => $vote_kick,
    console     => $console,
    masterport  => $startport,
    clusterkey  => $clusterkey,
    require     => File[$path],
  }

  # Shard Master -> Overworld
  $override_master = $worldgenoverrides ? { undef => undef, default => $worldgenoverrides['master']}
  dstserver::entity::master{$name:
    ensure           => $ensure,
    path             => $path_master,
    ports            => [
      $startport + 1,
      $startport + 2,
      $startport + 3,
    ],
    worldgenoverride => $override_master,
    mods             => $mods,
    require          => File[$path],
  }

  # Shard Caves -> Underworld and ruins
  $override_caves = $worldgenoverrides ? { undef => undef, default => $worldgenoverrides['caves']}
  if ($ensure == 'absent') {
    # Whole instance is set absent
    $ensure_caves = $ensure
  } elsif ($caves) {
    # Caves are enabled
    $ensure_caves = present
  } else {
    # Caves are disabled
    $ensure_caves = absent
  }
  dstserver::entity::caves{$name:
    ensure           => $ensure_caves,
    path             => $path_caves,
    ports            => [
      $startport + 4,
      $startport + 5,
      $startport + 6,
    ],
    worldgenoverride => $override_caves,
    mods             => $mods,
    require          => File[$path],
  }
}
