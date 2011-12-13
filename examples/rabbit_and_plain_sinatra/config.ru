require 'rubygems'
require 'rabbit_modular'
require 'plain'

map '/' do
  run Home
end

map '/api' do
  run Example
end
