# dstserver

A module to manage a set of server instances for Don't Starve Together on your machines.

__Important Note__  
This module was built and tested for my debian and ubuntu machines, but I don't see a reason, why it shouldn't work on redhat/centos as well.  
It hasn't been tested there yet, so if you run it on a RPM based machine, for your constructive feedback I'd be very appreciated.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with dstserver](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dstserver](#beginning-with-dstserver)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Node Configuration Parameters](#node-configuration-parameters)
    * [Instance Configuration Parameters](#instance-configuration-parameters)
    * [Mod Config](#mod-config)
    * [Worldgenoverride Config](#worldgenoverride-config)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module manages Dont Starve Together servers on your server, generating worldgen-configs, modoverride settings and mod install lists based on each nodes configuration.  
However, it is for now limited to a *classic* setup consisting of one Overworld (master) and (optional) one Cave shard per instance.  
For each shard it further installs a SystemD service script to start and stop the server process.  
There is also an update script that can be run as root to update the DST installation on your server.

## Setup

### Setup Requirements

For each instance, you need to obtain a server token during your Klei account at https://accounts.klei.com/account/game/servers?game=DontStarveTogether.  
You will need to provide the token in the later configuration.  
You don't need to get creative at this point, all settings including the servername will be set by the actual server configuration on your server.

Further this module depends on tamerz-steamcmd for installation of SteamCMD.

### Beginning with dstserver

For a quickstart with dstserver, be sure to obtain a token for your server as noted in Setup Requirements.  
In your node definition, include the dstserver class passing in your server token for the default server:  
`class {'dstserver': token => 'Your-Token-Goes-Here' }`

__Important Note:__ This is only for quickstart and demo purpose. Passing the token like this will globally override the token for all DST server instances on this node. See usage below to propper configure your DST server.

The example above will perform the following steps on your node:

* Install SteamCMD
* Create a system user `server-dst` and home directory `/srv/dst`
* Install DST dedicated server at `/srv/dst/app`
* Place the install and update script in `/srv/dst/bin`
* Configure a default server instance in `/srv/dst/.klei/DoNotStarveTogether/default`
* Place SystemD scripts for master and caves, ensuring they are enabled and running

## Usage

As shown above, you can include dstserver in your node definition using the class syntax. This enables you to directly pass your custom configuration to the module:

```puppet
class { 'dstserver': 
  ensure    => present,
  user      => 'server-dst',
  homedir   => '/srv/dst',
  instances => [
    ... Array containing hashes of instance configuration, see Configuration section below
  ],
}
```

However, you can leave the class attributes to the default values provided or set them using hiera (see data/common.yaml as example).  
If your instances are configured this way, you can just include dstserver to your node:

```puppet
include dstserver
```

### Node Configuration Parameters

To set the parameters with hiera, just prefix them with `dstserver::`, e.g. `dstserver::instances:`

| Option      | Default               | Description |
| ------------| ----------------------| ------------|
| ensure      | present               | __present__ install dstserver on node <br> __absent__ remove dstserver from node, ensure to set all instances to absent in a previous run, to ensure all systemd services are removed |
| user        | server-dst            | Username for the system user running DST |
| homedir     | /srv/dst              | Home directory for the system user holding DST installation and server profiles |
| instances   | see data/common.yaml  | Hash with configuration for multiple DST server instances, see below |

### Instance Configuration Parameters

Pass a hash of hashes containing the following fields to the dstserver class statement or set the configuration in your hiera data as shown in data/common.yaml

One hash in the config hash per instance, key is the system name (used for foldername and servicename), values hold the specific configuration.

```yaml
dstserver::instances:
  default:
    servername: My DST Server
      description: Are you able to survive the first winter?
      mode: survival
      intention: cooperative
      token: your-server-token-from-klei-goes-here
      players: 5
  the-easy:
    servername: My easy Server
      description: Again and again ...
      mode: endless
      intention: social
      token: your-server-token-from-klei-goes-here
      players: 10
```

Instance configuration options in alphabetical order, required parameters are __bold__:
| Option            | Default       | Description |
| ------------------| --------------| ------------|
| autosave          | `true`        | Automatically save the world after midnight |
| caves             | `false`       | Create and run an instance of the caves for this server instance |
| clusterkey        | `'dst'`       | Cluster internal key for authenticating the shards inside the cluster |
| console           | `true`        | Enable or disable the server console |
| description       | `''`          | Description of your server for the public server list |
| ensure            | `'present'`   | __present__: create and configure and run the server instance <br> __absent__: remove the server instance from the node |
| intention         | `'social'`    | Play style intention on your server. Choose from: *social*, *cooperative*, *competetive*, *madness* |
| mode              | `'survival'`  | Server mode of this instance. Choose from *survival*, *wilderness*, *endless* |
| mods              | `undef`       | Configuration of Mods for this instance, see section **Mod Config** below|
| pause             | `true`        | Enable or disable automatic pause when there are no players on the server |
| password          | `''`          | Password to join the server |
| players           | `5`           | Amount of players that could join simultanously |
| pvp               | `false`       | Enable or disable PVP |
| servername        | `$name`       | Name of the server in the serverlist. Defaults to the key in the instance list (e.g. default, the-easy) |
| startport         | `11031`       | First port to use for cluster and shards. Will consume 7 ports in total. E.g. from 11031 to 11037 |
| __token__         |               | Your klei server token for this server instance, see **Setup Requirements** |
| vote_kick         | `true`        | Enable or disable voting to kick players |
| worldgenoverrides | `undef`       | Overrides for world generation, see section **Worldgenoverride Config** below |

### Mod Config

For each instance you can provide a list of mods.  
This will generate a serverwide list of required mod ids to be installed upon restart of an instance. This way it is ensured, that mods get updated everytime an instance is restarted.

To include a mod, list its ID in the mods hash with the desired activation state as value. `true` downloads the mod and activates it on this instance, `false` downloads the mod but leaves it as disabled in the instances modoverride.lua config.

To provide further custom configuration for a mod, you can use a subhash containing the fields `enabled` (true or false, as before) and config (containing a text block with the configuration to write into modoverride.lua).

This example shows both ways. Just including and activatting mods and including one with additional configuration.

```yaml
mods:
  # Minimap HUD
  345692228: false
  # Combined Status
  376333686: true
  # Ultimate Starting Item Tuner
  1627929571:
    enabled: true
    # Additional configuration for the mod
    config: |
      ShouldOverrideMod=false,
      ShouldOverrideVanila=false,
      Data = {
          ["AllPlayers"] = {
              ["respawnnight"] = {
                  "torch"
              },
              [""] = {
                  "backpack"
              }
          }
        }
```

### Worldgenoverride Config

You can set Worldgenoverride settings for Overworld and Cave Shards providing a configuration hash if intended.

```yaml
worldgenoverrides:
  master:
    enabled: true
    preset: SURVIVAL_TOGETHER
    overrides:
      world_size: huge
  caves:
    enabled: true
    preset: DST_CAVE_PLUS
```

Use `enabled` to turn the overrides on or off and `preset` to choose an official worldgen preset for your new instance.  
`overrides` is just a hash with key-value pairs to list in the overrides-object of the worldgenoverride file.

For available presets and a list of possible overrides, please refer to the [documentation in the dst wiki](https://dontstarve.fandom.com/wiki/Guides/Simple_Dedicated_Server_Setup#World_Customization)

## Limitations

You cannot deploy *fancy setups*, e.g. with multiple Overworld-Cave Shards in the same setup. For most server setups it should be sufficient, though.

Further, this module was created on and for debian/ubuntu machines. I don't see a reason why it shouldn't work on Redhad, but lack of a redhat server and time to set it up I didn't verify that yet. So if you use this on redhat/centos and it works (or not), please let me know ;)

## Development

This module was created based on the needs for my own private dst server setup.  
It is my first puppet module and I code on it in my spare time.

Please use the issue tracker to report bugs with concrete examples how to reproduce the problem.  
You could also submit feature requests, but because I do this in my spare time I can not guarantee to implement them.

Furthermore I appreciate Pull Requests for bugfixes and new features including:

* a detailled description on the change
* for bugfixes: what problem is solved (scenario / issue #)
* for features: why / what for the new feature is needed
* corrections and additions in the documentation as needed
