# Duty-free, a Moonshine plugin for GeoIP

[Moonshine](http://github.com/railsmachine/moonshine) is a potent blend of Rails
deployment and configuration management done right -- now get a taste of the
spirits of the world by bringing a little GeoIP into your distillery.

This is a plugin for installing and managing the [mod_geoip Apache module](http://www.maxmind.com/app/mod_geoip)
and the GeoIP C library it depends on. With GeoIP, Apache can handle requests
with awareness of the client's locale, based on IP address. In addition to
installing and enabling the libraries and module, it configures a cron job for
regularly updating the GeoIP database.

### Instructions

* <tt>script/plugin install git://github.com/railsmachine/moonshine_geoip.git</tt>
* Include the plugin and recipe(s) in your Moonshine manifest
    plugin :geoip
    recipe :geoip

### Additional Configuration

The plugin defaults to installing the GeoIP C API and the 'GeoLite Country'
database with a cron job to update it. Configuration options are available to
also enable the +mod_geoip+ Apache module, use another available database, and
specify license details if you're a GeoIP licensee. Set these options via the
+configure+ method or <tt>moonshine.yml</tt> as usual:

    :geoip:
      :apache_module: true
      :geo_database_url: http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
      :user_id: Joebob
      :license_key: <your key>
      :product_ids: <your Product IDs for licensed databases>

    -- or --

    # In your manifests:
    configure(:geoip => {:user_id => 'Joebob'})  # etc.

Refer to MaxMind for [more on using your licensed products](http://www.maxmind.com/app/license_key).
As with all Moonshine plugins, you can also override the default templates
included with this plugin to customize configuration. So to set things for the
Apache module exactly how you want them:

    $ cp vendor/plugins/moonshine_geoip/templates/geoip.conf app/manifests/templates
    (hack)

***
Unless otherwise specified, all content copyright &copy; 2014, [Rails Machine, LLC](http://railsmachine.com)

