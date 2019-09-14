# Glider-Merlin: Setup a transparent proxy for [asuswrt-merlin.ng](https://github.com/RMerl/asuswrt-merlin.ng) routers with [glider](https://github.com/nadoo/glider)

Glider-merlin will install glider to the asuswrt-merlin.ng router and setup a transparent ptoxy. Tested on a RT-AC66U_B1 router with the asuswrt-merlin 384.13 firmware.

## Get started

### Prerequisites

* The latest Asuswrt-Merlin New Gen firmware installed.
* [SSH](https://github.com/RMerl/asuswrt-merlin/wiki/SSHD) enabled.
* [JFFS](https://github.com/RMerl/asuswrt-merlin/wiki/JFFS) partion enabled.
* [Entware](https://github.com/RMerl/asuswrt-merlin/wiki/Entware) installed.

### Installation

Make a connection to the router with this command:

`ssh <user>@<router>`

Run the following command in the router's terminal:

`curl -sSL https://raw.githubusercontent.com/bnuhero/glider-merlin/master/install.sh | sh`

This will clone the glider-merlin repository to `/opt/share/glider-merlin` direcotry in the router and create a soft link to `/opt/share/glider-merlin/script/glider-merlin.sh` as `/opt/sbin/glider-merlin`.

**NOTICE: Check if `/opt/share/glider-merlin/bin/glider` can be run successfully in the router terminal. If NOT, your SHOULD compile glider for the router by yourself and replace the original glider with it.**

### Configuartion

#### etc/glider-merlin.conf

Nothing to change usually. Read the file for details.

#### etc/glider/glider.conf

Only `forward` setting MUST be provided. Read the file for details.

#### (optional) data/

Add custom domain|IP blacklist|whitelist file here.

#### etc/dnsmasq.d/

Run `glider-merlin config` in the terminal. That's all.

### Usage

`glider-merlin config|fullconfig|start|stop|restart|remove|uninstall|update`

* `config` - 1) Download the well known domain|IP lists if NOT existed. 2) Generate the dnsmasq configration files using domain|IP whitelist|blacklist if NOT existed. 3) Create the corresponding ipsets.
* `fullconfig` - Do the above steps even if files existed.
* `start` - start the transparent proxy service.
* `stop` - stop the transparent proxy service.
* `restart` - restart the transparent proxy service.
* `remove` - stop the transparent proxy service and delete `glider-merlin` directory.
* `uninstall` - same as `remove`
* `update` - fetch the latest glider-merlin. **NOT IMPLEMENTED**

### Credits

Thank you for making the world better!

* [shadowsocks-asuswrt-merlin](https://github.com/Acris/shadowsocks-asuswrt-merlin)

### License

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