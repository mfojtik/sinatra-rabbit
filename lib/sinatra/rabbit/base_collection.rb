#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.

module Sinatra
  module Rabbit

    class BaseCollection < Sinatra::Base
      set :views, Proc.new { File.join(File::dirname(__FILE__), "..", "..", "views") }
      enable :method_overide

      def self.route_for(collection, operation_name=nil)
        if operation_name
          o = Sinatra::Rabbit::STANDARD_OPERATIONS[operation_name]
          operation_path = (o && o[:member]) ? operation_name.to_s : nil
          id_param = (o && o[:collection]) ? nil : ":id"
          [route_for(collection), id_param, operation_path].compact.join('/')
        else
          "/#{collection}"
        end
      end

      def self.http_method_for(operation_name)
        o = Sinatra::Rabbit::STANDARD_OPERATIONS[operation_name]
        (o && o[:method]) ? o[:method] : :get
      end

      def self.collection_class(name)
        Sinatra::Rabbit.const_set(name.to_s.camelize + 'Collection', Class.new(Collection))
      end

    end
  end
end
