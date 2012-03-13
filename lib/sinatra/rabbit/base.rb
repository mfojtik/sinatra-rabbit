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

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative './dsl'
require_relative './param'
require_relative './base_collection'
require_relative './validator'
require_relative './documentation'

module Sinatra
  module Rabbit

    STANDARD_OPERATIONS = {
      :create => { :member => false, :method => :post, :collection => true },
      :show => { :member => false, :method => :get },
      :destroy => { :member => false, :method => :delete },
      :index => { :member => false, :method => :get, :collection => true }
    }

    def self.configure(&block)
      instance_eval(&block)
    end

    def self.configuration
      @configuration || {}
    end

    def self.enable(property)
      @configuration[property] = true
    end

    def self.enabled?(property)
      !@configuration[property].nil? and @configuration[property] == true
    end

    def self.disabled?(property)
      !@configuration[property].nil? and @configuration[property] == false
    end

    def self.disable(property)
      @configuration[property] = false
    end

    def self.set(property, value)
      @configuration[property] = value
    end

    # Automatically register the DSL to Sinatra::Base if this
    # module is included:
    #
    # Example:
    #
    #     class MyApp << Sinatra::Base
    #       include Sinatra::Rabbit
    #     end
    #
    def self.included(base)
      @configuration ||= {
        :root_path => '/'
      }
      base.register(DSL)
    end

    class Collection < BaseCollection

      def self.generate(name, &block)
        @collection_name = name.to_sym
        send(:head, root_path + route_for(path), {}) { status 200 } unless Rabbit.disabled? :head_routes
        class_eval(&block)
        op_list = operations
        send(:options, root_path + route_for(path), {}) do
          [200, { 'Allow' => op_list.map { |o| o.operation_name }.join(',') }, '']
        end unless Rabbit.disabled? :options_routes
        self
      end

      def self.control
        raise "The 'control' statement must be used only within context of Operation"
      end

      def self.collection_name; @collection_name; end

      class << self
        alias_method :path, :collection_name
      end

      def self.description(text=nil)
        return @description if text.nil?
        @description = text
      end

      def self.documentation
        Rabbit::Documentation.for_collection(self, operations)
      end

      def self.operation(operation_name, &block)
        @operations ||= []
        return @operations.find { |o| o.operation_name == operation_name } unless block_given?
        if operation_registred?(operation_name)
          raise "Operation #{operation_name} already registered in #{self.name} collection"
        end
        @operations << (operation = operation_class(self, operation_name).generate(self, operation_name, &block))
        unless Rabbit.disabled? :head_routes
          send(:head, root_path + route_for(path, operation_name, {})) { status 200 }
        end
        send(http_method_for(operation_name), root_path + route_for(path, operation_name), {}, &operation.control)
        unless Rabbit.disabled? :options_routes
          send(:options, root_path + route_for(path, operation_name, :member), {}) do
            [200, { 'Allow' => operation.params.map { |p| p.to_s }.join(',') }, '']
          end
        end
        self
      end

      def self.operations; @operations; end

      class Operation

        def self.generate(collection, name, &block)
          @name, @params = name, []
          class_eval(&block)
          self
        end

        def self.operation_name; @name; end

        def self.description(text=nil)
          return @description if text.nil?
          @description = text
        end

        def self.control(&block)
          params_def = @params
          @control ||= Proc.new do
            begin
              Rabbit::Validator.validate!(params, params_def)
            rescue => e
              if e.kind_of? Rabbit::Validator::ValidationError
                status e.http_status_code
                halt
              else
                raise e
              end
            end
            instance_eval(&block)
          end
        end

        def self.param(*args)
          return @params.find { |p| p.name == args[0] } if args.size == 1
          @params << Rabbit::Param.new(*args)
        end

        def self.params; @params; end
      end

      private

      def self.operation_registred?(name)
        @operations.any? { |o| o.name == name }
      end

      # Create an unique class name for all operations within Collection class
      def self.operation_class(collection_klass, operation_name)
        begin
          collection_klass.const_get(operation_name.to_s.camelize + 'Operation', Class.new(Operation))
        rescue NameError
          collection_klass.const_set(operation_name.to_s.camelize + 'Operation', Class.new(Operation))
        end
      end

    end
  end
end

