require File.join(File.dirname(__FILE__), 'spec_helper.rb')

class GeoipManifest < Moonshine::Manifest::Rails
  plugin :geoip
end

describe "A manifest with the Geoip plugin" do
  before do
    @manifest = GeoipManifest.new
  end

  shared_examples_for "default behavior" do
    before do
      @manifest.geoip
    end

    it 'should install the geoip-bin package' do
      @manifest.packages.keys.should include('geoip-bin')
    end

    it 'should use the GeoLite Country database' do
      @manifest.execs['new-geoip-db'].command.should match(/GeoLiteCountry/)
    end

    it 'should create GeoIP.dat under /usr/local' do
      @new_db_exec = @manifest.execs['new-geoip-db']
      @new_db_exec.command.should match(%r{/usr/local/share})
      @new_db_exec.creates.should match(%r{/usr/local/share})
    end

    it 'should not create /etc/GeoIP.conf' do
      @manifest.files.keys.should_not include('/etc/GeoIP.conf')
    end

    it 'should create cron job updating database in /usr/local' do
      cron_job = @manifest.crons['Monthly GeoIP database updates']
      cron_job.command.should match(%r{/usr/local/share/GeoIP})
    end

    describe "and using the mod_geoip Apache module" do
      before do
        @manifest.geoip(:apache_module => true)
      end

      it 'should use /usr/local database in the module conf' do
        conf_file = @manifest.files['/etc/apache2/mods-available/geoip.conf']
        conf_file.content.should match(%r{GeoIPDBFile /usr/local/share})
      end

    end

  end

  describe "with no options" do
    it_should_behave_like "default behavior"
  end

  describe "with options for user_id and license_key" do
    before do
      @manifest.geoip(:user_id => 'Bob', :license_key => 'tiddlywinks')
    end

    it 'should install the geoip-bin package' do
      @manifest.packages.keys.should include('geoip-bin')
    end

    it 'should create /etc/GeoIP.conf' do
      @manifest.files.keys.should include('/etc/GeoIP.conf')
      @manifest.files['/etc/GeoIP.conf'].content.should match(/tiddlywinks/)
    end

    it 'should use built-in geoipupdate tool for DB setup and updates' do
      @manifest.execs['new-geoip-db'].command.should match(/geoipupdate/)
      cron_job = @manifest.crons['Monthly GeoIP database updates']
      cron_job.command.should match(/geoipupdate/)
    end

    describe "and using the mod_geoip Apache module" do
      before do
        @manifest.geoip(
          :apache_module => true,
          :user_id => 'Bob', :license_key => 'tiddlywinks'
        )
      end

      it 'should use /usr/share database in the module conf' do
        conf_file = @manifest.files['/etc/apache2/mods-available/geoip.conf']
        conf_file.content.should match(%r{GeoIPDBFile /usr/share})
      end

    end

  end

  describe "with custom database updates URL" do
    before do
      @manifest.geoip(:geo_database_url => 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz')
    end

    it 'should fetch the custom URL for first update' do
      @manifest.execs['new-geoip-db'].command.should match(%r{database/GeoLiteCity})
    end

    it 'should fetch the custom URL for cron updates' do
      @manifest.crons['Monthly GeoIP database updates'].command.should match(%r{database/GeoLiteCity})
    end

    it 'should operate on correct DB file basename' do
      @manifest.crons['Monthly GeoIP database updates'].command.should match(/gunzip GeoLiteCity/)
      @manifest.crons['Monthly GeoIP database updates'].command.should match(/mv \-f GeoLiteCity/)
    end

    describe "and using the mod_geoip Apache module" do
      before do
        @manifest.geoip(
          :apache_module => true,
          :geo_database_url => 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz'
        )
      end

      it 'should use the correct DB file in the module conf' do
        conf_file = @manifest.files['/etc/apache2/mods-available/geoip.conf']
        conf_file.content.should match(%r{GeoLiteCity.dat})
      end

    end

  end

  describe "with only the user_id option set" do
    before do
      @manifest.geoip(:user_id => 'Joebob')
    end

    it_should_behave_like "default behavior"
  end

  describe "with only the license_key option set" do
    before do
      @manifest.geoip(:license_key => 'tiddlywinks')
    end

    it_should_behave_like "default behavior"
  end

end

