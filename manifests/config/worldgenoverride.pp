# @summary
#   Create a worldgenoverride for a server shard if configured
#
# @api private
#
# @param path
#   Directory path to the shards configuration
# @param ensure
#   Ensure, the override file is present if configured or absent if not
# @param preset
#   DST Map preset to use in override
# @param enabled
#   Is the worldgenoverride enabled, or just defined for later use?
# @param overrides
#   Key-value pairs of overrides to set in the override file
#
# @see https://dontstarve.fandom.com/wiki/Guides/Simple_Dedicated_Server_Setup#World_Customization
define dstserver::config::worldgenoverride (
  String $path,
  Enum[present, absent] $ensure,
  String $preset = 'SURVIVAL_TOGETHER',
  Boolean $enabled = false,
  Hash $overrides = {},
) {
  file { "${name}-worldgenoverride":
    ensure  => $ensure,
    path    => "${path}/worldgenoverride.lua",
    content => epp('dstserver/worldgenoverride.lua', {
      enabled   => $enabled,
      preset    => $preset,
      overrides => $overrides,
    })
  }
}
