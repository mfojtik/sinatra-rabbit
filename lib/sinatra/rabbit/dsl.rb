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
    module DSL

      # Create DSL wrapper for creating a new collection
      #
      # Example:
      #
      #     collection :images do
      #       description "Images collection"
      #
      #       operation :index do
      #         ...
      #       end
      #     end
      def collection(name, &block)
        return self[name] unless block_given?
        current_collection = BaseCollection.collection_class(name) do |c|
          c.base_class = self
          c.generate(name, &block)
        end
        collections << current_collection
        DSL << current_collection
        use current_collection
      end

      # Return all defined collections
      #
      def collections
        @collections ||= []
      end

      def self.register_collection(c, &block)
        @collections ||= []
        @collections << c
      end

      def self.<<(c)
        register_collection(c)
      end

      def [](collection)
        collections.find { |c| c.collection_name == collection }
      end

    end
  end
end
