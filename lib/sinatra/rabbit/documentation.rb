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
    require 'haml'

    class Documentation < Sinatra::Base
      set :views, Proc.new { File.join(File::dirname(__FILE__), "documentation") }
      helpers Sinatra::Rabbit::DSL::Helper

      # FIXME: Add root_path prefix here
      get "/doc" do
        haml :index
      end

      def self.for_collection(collection, operations)
        send(:get, Rabbit::BaseCollection.root_path + doc_route_for(collection.collection_name), {}) do
          @collection = collection
          haml :collection  # TODO: Add HAML view for collection documentation
        end
        operations.each do |operation|
          send(:get, Rabbit::BaseCollection.root_path + doc_route_for(collection.collection_name, operation.operation_name), {}) do
            @collection, @operation = collection, operation
            haml :operation # TODO: Add HAML view for operation documentation
          end
        end
        self
      end

      def self.doc_route_for(collection, operation=nil)
        path = Rabbit::BaseCollection.route_for(collection, operation, :no_id_and_member)
        ['doc', path].join('/')
      end

    end

  end
end
