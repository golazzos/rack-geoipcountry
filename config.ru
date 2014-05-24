require 'rubygems'
require 'bundler'
Bundler.require

use GeoIPCountry, domains: {"Mexico" => "lvh.me.mx:3000", "N/A" => "lvh.me:3000"}, ip_override: "187.191.94.187"
run Proc.new { |env| ['200', {'Content-Type' => 'text/html'}, ["You're from #{env['X_GEOIP_COUNTRY']}"]] }
