require 'sinatra/base'

class Home < Sinatra::Base

  get '/' do
    "i'm #{self.class}"
  end

end
