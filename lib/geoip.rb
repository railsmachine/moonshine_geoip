module Geoip
  GEOIP_TEMPLATES_DIR = File.join(File.dirname(__FILE__), '..', 'templates')

  # Define options for this plugin via the <tt>configure</tt> method
  # in your application manifest:
  #
  #   configure(:geoip => {:user_id => 'Joebob'})
  #
  # Then include the plugin and call the recipe(s) you need:
  #
  #   plugin :geoip
  #   recipe :geoip, :mod_geoip
  #
  # New Ubuntu versions have a <tt>geoip-database</tt> package, but MaxMind
  # updates the DB monthly, and I'm not sure the package will keep up. There
  # is also a built-in program to grab updates, *if* you have a license (see
  # <tt>man geoipupdate</tt>) -- this is used if you configure account
  # credentials, otherwise cron will be set up to fetch updates manually.
  #
  # The following options are configurable:
  #   * +geo_database_url+
  #   * +user_id+
  #   * +license_key+
  #   * +product_ids+
  # Most apply to licensees of paid GeoIP databases -- see {this page}[http://www.maxmind.com/app/license_key]
  # for information on how these are used. You can also specify the URL of the
  # database you wish to download and update -- default is 'GeoLite Country'.
  def geoip(opts={})
    options = {
      :geo_database_url => 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz'
    }.merge!(opts)

    package 'geoip-bin', :ensure => :installed, :notify => exec('new-geoip-db')

    db_update_command = nil
    db_basename = options[:geo_database_url] =~ /(GeoLiteCity)/ ? $1 : 'GeoIP'

    # Prefer to use the built-in +geoipupdate+ tool if possible, configuring
    # GeoIP for a licensed account if credentials are given.
    if options[:user_id] && options[:license_key]
      db_update_command = '/usr/bin/geoipupdate'

      file '/etc/GeoIP.conf',
        :ensure => :present,
        :mode => 644,
        :before => exec('new-geoip-db'),
        :content => template(File.join(GEOIP_TEMPLATES_DIR, 'etc-geoip.conf.erb'), binding)

      # First-time update
      exec 'new-geoip-db',
        :command => db_update_command,
        :require => package('geoip-bin'),
        :refreshonly => true
    else
      package 'wget', :ensure => :installed
      file '/usr/local/share/GeoIP', :ensure => :directory
      db_update_command =
        [
          "cd /tmp",
          "/usr/bin/wget #{options[:geo_database_url]}",
          "/bin/gunzip #{db_basename}.dat.gz",
          "/bin/mv -f #{db_basename}.dat /usr/local/share/GeoIP"
        ].join(' && ')

      # First-time update
      # An explicit +cd+ is done in the command rather than using a ShadowPuppet
      # +:cwd+ parameter so that it applies for cron job usage as well
      exec 'new-geoip-db',
        :command => db_update_command,
        :creates => "/usr/local/share/GeoIP/#{db_basename}.dat",
        :require => [
          package('wget'),
          file('/usr/local/share/GeoIP')
        ]
    end

    # Updates are released on the first of every month
    cron 'Monthly GeoIP database updates',
      :user => 'root',
      :command => db_update_command,
      :minute => 33, :hour => 3, :monthday => 2

    # Configure and enable the Apache mod_geoip module if opted for
    if options[:apache_module]
      package 'libapache2-mod-geoip', :ensure => :installed
      a2enmod 'geoip'
      file '/etc/apache2/mods-available/geoip.conf',
        :ensure => :present,
        :mode => '644',
        :content => template(File.join(GEOIP_TEMPLATES_DIR, 'geoip.conf.erb'), binding),
        :before => exec('a2enmod geoip'),
        :notify => service('apache2')
    end
  end
end

