name             "postgres"
maintainer       "Wanelo, Inc"
maintainer_email "ops@wanelo.com"
license          "Apache 2.0"
description      "Installs/Configures postgres from sources, optimized for SmartOS, and ready for streaming replication"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.2"

supports "smartos"

depends  "rbac"
depends  "smf"
