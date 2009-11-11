module Geoip

  # Define options for this plugin via the <tt>configure</tt> method
  # in your application manifest:
  #
  #   configure(:geoip => {:foo => true})
  #
  # Then include the plugin and call the recipe(s) you need:
  #
  #  plugin :geoip
  #  recipe :geoip
  def geoip(options = {})
    # define the recipe
    # options specified with the configure method will be 
    # automatically available here in the options hash.
    #    options[:foo]   # => true
  end
  
end