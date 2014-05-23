require 'geoip'

module Rack
  # Rack::GeoIPCountry uses the geoip gem and the GeoIP database to lookup the country of a request by its IP address
  # The database can be downloaded from:
  # http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
  #
  # Usage:
  # use Rack::GeoIPCountry, db: "path/to/GeoIP.dat", domains: {"Mexico": "golazzos.com.mx", "default": "golazzos.com"}, allow_ip_override: true
  #
  # By default all requests are looked up and the X_GEOIP_* headers are added to the request
  # The headers can then be read in the application
  # The country name is added to the request header as X_GEOIP_COUNTRY, eg:
  # X_GEOIP_COUNTRY: United Kingdom
  class GeoIPCountry
    def initialize(app, options = {})
      options[:db] ||= 'GeoIP.dat'

      @domains = options[:domains]
      @ip_override = options[:allow_ip_override]
      @db = GeoIP.new(options[:db])
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      ip = @ip_override ? request.params["ip"] : request.ip
      country = @db.country(ip).to_hash[:country_name]
      env['X_GEOIP_COUNTRY'] = country

      if valid_domain?(env, country)
        redirect_to_domain(country)
      else
        @app.call(env)
      end
    end

    def valid_domain?(env, country)
      env['SERVER_NAME'].include?(get_domain(country))
    end

    def redirect_to_(country)
      domain = get_domain(country)
      response = Rack::Response.new
      response.redirect domain
      response.finish
    end

    def get_domain(country)
      @domains[country] ? @domains[country] : @domains["default"]
    end
  end
end
