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

      def self.route_for(collection, operation_name=nil, member=:member)
        unless operation_name.nil?
          o = Sinatra::Rabbit::STANDARD_OPERATIONS[operation_name]
          if o
            o = o.clone
            o[:member] = false if member == :no_member
            o[:collection] = true if member == :no_id
            if member == :no_id_and_member or member == :docs
              o[:collection] = true
              o[:member] = true
            end
          end
          operation_path = (o && o[:member]) ? operation_name.to_s : nil
          operation_path = operation_name.to_s unless o
          id_param = (o && o[:collection]) ? nil : (member.kind_of?(Hash) ? member[:id_name] : ":id")
          id_param.gsub!(':', '') if id_param and member  == :docs
          [route_for(collection), id_param, operation_path].compact.join('/')
        else
          collection.to_s
        end
      end

      def self.http_method_for(operation_name)
        o = Sinatra::Rabbit::STANDARD_OPERATIONS[operation_name]
        (o && o[:method]) ? o[:method] : :get
      end

      def self.collection_class(name, parent_class=nil)
        if base_module = Rabbit::configuration[:base_module]
          begin
            base_module = base_module.const_get 'Rabbit'
          rescue NameError
            base_module = base_module.const_set('Rabbit', Module.new)
          end
        else
          base_module = Sinatra::Rabbit
        end
        klass = parent_class || base_module
        begin
          yield k = klass.const_get(name.to_s.camelize + 'Collection')
        rescue NameError
          yield k = klass.const_set(name.to_s.camelize + 'Collection', Class.new(Collection))
        end
        return k
      end

      def self.root_path
        Sinatra::Rabbit.configuration[:root_path] || '/'
      end

    end
  end
end
