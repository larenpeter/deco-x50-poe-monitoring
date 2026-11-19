# deco-x50-poe-monitoring

Prometheus metrics and Homepage tiles for a TP-Link Deco X50-PoE mesh, using
the [deco-rate](https://github.com/SimonJPegg/deco-rate) exporter.

The exporter's own README names an XE75 as its tested model. This repo records
that it also runs on a Deco X50-PoE, and packages a setup you can start with
one command. The Home Assistant integration that the exporter's API client comes
from already lists the Deco X50 as tested. This repo adds the exporter on an
X50-PoE. The deployment files, config and dashboard tiles are my own work.
No upstream code is copied: Docker builds deco-rate from upstream at a pinned
commit, and I did not modify its source.

## Tested on
- Deco X50-PoE, hardware 1.0, firmware 1.2.5 Build 20231122 Rel. 58711, two nodes
- Ubuntu 26.04 LTS with Docker 29
- deco-rate at commit 819ca53a4b91a18f3b609346711797d2f4c2f5a9

## What works on the X50-PoE
Client count, per-client download and upload rates, per-node client counts,
nodes online, CPU and memory usage, internet status, 2.4 GHz and 5 GHz node
signal, a firmware-update flag and WAN info.

## What does not
- The backhaul speed metrics (`deco_node_backhaul_speed` and
  `deco_node_backhaul_max_speed`) did not appear. The exporter reads a
  `backhual_speed` field (TP-Link's spelling) from each node, and my nodes did
  not return one. I did not investigate why.
  X50 has no such page, and the other metrics are unaffected.

## Quick start
    git clone https://github.com/larenpeter/deco-x50-poe-monitoring.git
    cd deco-x50-poe-monitoring
    cp config.example.yaml config.yaml
    chmod 600 config.yaml
    nano config.yaml
    docker compose up -d --build

Set `host` to your main Deco's address, and use your TP-Link ID and password.
After about two minutes, check that data arrives:

    docker compose exec prometheus wget -qO- 'http://localhost:9090/api/v1/query?query=deco_clients_total'

## Login notes
- Use the Deco owner login. The Home Assistant integration this client comes
  from documents that manager accounts do not work, and a manager account
  was rejected as invalid credentials in my test.
- The owner login can only hold one session. Signing into the Deco app as
  the owner logs the exporter out, and the exporter's next login logs the
  app out. Create a separate manager account in the Deco app (More, then
  Managers) for daily use, and keep the owner login for the exporter.
- The Deco counts failed logins (mine warned `8 attempts remaining`). Check
  `config.yaml` before the first start, and stop the container if you see that
  message.
- `config.yaml` holds your TP-Link password. It is in `.gitignore`. Keep it
  that way, and do not reuse the password anywhere else.

## Security notes
- The exporter runs with a read-only filesystem, no capabilities and no
  published ports. Prometheus is bound to 127.0.0.1.
- The exporter's logs contain a session token inside a URL. Remove it before
  you post logs anywhere.

## Homepage
`homepage/services.example.yaml` has two tiles that use Homepage's Prometheus
Metric widget. Merge them into your `services.yaml`, then attach Homepage to
this stack's network so it can reach `http://prometheus:9090`:

    networks:
      default:
        name: deco-x50
        external: true

## Credits and licence
deco-rate is by [SimonJPegg](https://github.com/SimonJPegg) and is MIT licensed
(copyright amosyuen, 2021). Its API client comes from
[amosyuen/ha-tplink-deco](https://github.com/amosyuen/ha-tplink-deco). The
files in this repo are also MIT.
