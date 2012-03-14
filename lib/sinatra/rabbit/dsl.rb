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
        return @collections.find { |c| c.collection_name == name } unless block_given?
        @collections ||= []
        current_collection = BaseCollection.collection_class(name)
        current_collection.set_base_class(self)
        current_collection.generate(name, &block)
        @collections << current_collection
        Sinatra::Rabbit::DSL.register_collection(current_collection)
        use current_collection
        use current_collection.documentation unless Rabbit.disabled? :documentation
      end

      # Return all defined collections
      #
      def collections
        @collections
      end

      def self.collections
        @collections
      end

      def self.register_collection(c, &block)
        if block_given?
          instance_eval do
            collection c, block
          end
        end
        @collections ||= []
        @collections << c
      end

      module Helper
        def collections
          Sinatra::Rabbit::DSL.collections
        end
      end

    end
  end
end
