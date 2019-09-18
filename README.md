# Glider-Merlin: Setup a transparent proxy for [asuswrt-merlin.ng](https://www.asuswrt-merlin.net/) routers with [glider](https://github.com/nadoo/glider)

Glider-merlin will install glider to the asuswrt-merlin.ng router and setup a transparent ptoxy. Tested on a RT-AC66U_B1 router with the asuswrt-merlin 384.13 firmware.

## Get started

### Prerequisites

* The latest [Asuswrt-Merlin New Gen](https://www.asuswrt-merlin.net/) firmware installed.
* [SSH](https://github.com/RMerl/asuswrt-merlin/wiki/SSHD) enabled.
* [JFFS](https://github.com/RMerl/asuswrt-merlin/wiki/JFFS) partion enabled.
* [Entware](https://github.com/RMerl/asuswrt-merlin/wiki/Entware) installed.

### Installation

Make a connection to the router with this command:

`ssh <user>@<router>`

Run the following command in the router's terminal:

`curl -sSL https://raw.githubusercontent.com/bnuhero/glider-merlin/master/install.sh | sh`

This will clone the glider-merlin repository to `$GM_HOME` ( default value is `/opt/share/glider-merlin`) direcotry in the router and create a soft link to `$GM_HOME/script/glider-merlin.sh` as `/opt/sbin/glider-merlin`.

If you want to install glider-merlin to a different directory, e.g. `/opt/share/myglider`, run this:

`curl -sSL https://raw.githubusercontent.com/bnuhero/glider-merlin/master/install.sh | GM_HOME=/opt/share/myglider sh`

**Notice:** `/$GM_HOME/bin/glider` is built by the command:

`env GOOS=linux GOARCH=arm GOARM=5 go get -u github.com/nadoo/glider`. 

**Do check if `/$GM_HOME/bin/glider` can be run successfully in the router before you continue. If NOT, get or build the right version of [glider](https://github.com/nadoo/glider/releases) for your router.**

### Configuartion

#### etc/glider-merlin.conf

Nothing to change usually. Read the file for details.

#### etc/glider/glider.conf

Run `cp etc/glider/glider.sample.conf etc/glider/glider.conf` first.

Only `forward` setting MUST be modified. Read the file for details.

#### (optional) data/

Add custom domain|IP blacklist|whitelist file here.

#### etc/dnsmasq.d/

Run `glider-merlin config` to generate all the dnsmasq configurations.

### Usage

`glider-merlin config|fullconfig|start|stop|restart|remove|uninstall|update`

**Notice: If `GM_HOME` is set to a non-default directory, do run `glider-merlin` with the specified `GM_HOME` setting.**

* `config` - 1) Download well known domain|IP lists if NOT existed. 2) Generate the dnsmasq configration files using domain|IP whitelist|blacklist if NOT existed. 3) Create the corresponding ipsets.
* `fullconfig` - Do the above steps even if files existed.
* `start` - start the transparent proxy service.
* `stop` - stop the transparent proxy service.
* `restart` - restart the transparent proxy service.
* `remove` - stop the transparent proxy service and delete `glider-merlin` directory.
* `uninstall` - same as `remove`
* `update` - fetch the latest glider-merlin. **NOT IMPLEMENTED YET**

## Credits

Thank you for making the world better!

* [shadowsocks-asuswrt-merlin](https://github.com/Acris/shadowsocks-asuswrt-merlin)

## License

The MIT License (MIT)

Copyright (c) 2019 Raymond LIU

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
