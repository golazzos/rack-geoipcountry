require 'geoip'

module Rack
  # Rack::GeoIPCountry uses the geoip gem and the GeoIP database to lookup the country of a request by its IP address
  # The database can be downloaded from:
  # http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
  #
  # Usage:
  # use Rack::GeoIPCountry, db: "path/to/GeoIP.dat", domains: {"Mexico": "golazzos.com.mx", "N/A": "golazzos.com"}, allow_ip_override: true
  #
  # By default all requests are looked up and the X_GEOIP_* headers are added to the request
  # The headers can then be read in the application
  # The country name is added to the request header as X_GEOIP_COUNTRY, eg:
  # X_GEOIP_COUNTRY: United Kingdom
  class GeoIPCountry
    def initialize(app, options = {})
      options[:db] ||= 'GeoIP.dat'

      @domains = options[:domains]
      @ip_override = options[:ip_override]
      @exclude_paths = options[:exclude_paths] || []
      @db = GeoIP.new(options[:db])
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      ip = @ip_override || request.ip

      country = @db.country(ip).to_hash[:country_name]
      env['X_GEOIP_COUNTRY'] = country

      if valid_domain?(request, country, env)
        @app.call(env)
      else
        domain = get_domain(country)
        response = Rack::Response.new
        response.redirect "http://" + domain
        response.finish
      end
    end

    def valid_domain?(request, country, env)
      (request.host_with_port == get_domain(country)) ||  @exclude_paths.include?(env["PATH_INFO"])
    end

    def get_domain(country)
      @domains[country] ? @domains[country] : @domains["N/A"]
    end
  end
end
