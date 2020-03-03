# @summary
#   Generates modgenoverride configuration for servershards to set mods on enabled or disabled and provide custom mod configuration where defined.
#
# @api private
# 
# @param path
#   Directory path to the shards configuration
# @param mods
#   Configuration Hash for mods on this instance, see section Mod Config in Readme.md
define dstserver::config::modoverride (
  String $path,
  Optional[Hash] $mods,
) {
  $ensure = $mods ? { undef => absent, default => present}
  file{"${name}-modoverride":
    ensure  => $ensure,
    path    => "${path}/modoverride.lua",
    content => epp('dstserver/modoverrides.lua', {
      mods => pick($mods, []),
    })
  }
}
