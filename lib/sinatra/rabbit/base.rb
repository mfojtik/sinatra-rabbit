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
require_relative './features'

module Sinatra
  module Rabbit

    STANDARD_OPERATIONS = {
      :create => {
        :member => false,
        :method => :post,
        :collection => true
      },
      :show => {
        :member => false,
        :method => :get,
        :required_params => [ :id ]
      },
      :destroy => {
        :member => false,
        :method => :delete,
        :required_params => [ :id ]
      },
      :index => {
        :member => false,
        :method => :get,
        :collection => true
      },
      :update => {
        :member => false,
        :method => :patch,
        :required_params => [ :id ] 
      }
    }

    def self.configure(&block)
      instance_eval(&block)
    end

    def self.configuration
      Thread.current[:rabbit_configuration] ||= {}
    end

    def self.enable(property)
      configuration[property] = true
    end

    def self.enabled?(property)
      !configuration[property].nil? and configuration[property] == true
    end

    def self.disabled?(property)
      !configuration[property].nil? and configuration[property] == false
    end

    def self.disable(property)
      configuration[property] = false
    end

    def self.set(property, value)
      configuration[property] = value
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
      configuration[:root_path] = '/'
      base.register(DSL)
    end

    class Collection < BaseCollection

      include DSL

      def self.generate(name, parent_collection=nil, &block)
        @collection_name = name.to_sym
        @collections ||= []
        @parent_collection = parent_collection
        class_eval(&block)
        send(:head, full_path, {}) { status 200 } unless Rabbit.disabled? :head_routes
        send(:options, full_path, {}) do
          [200, { 'Allow' => operations.map { |o| o.operation_name }.join(',') }, '']
        end unless Rabbit.disabled? :options_routes
        self
      end

      def self.collection(name, opts={}, &block)
        unless block_given?
          return @collections.find { |c| c.collection_name == name }
        end
        current_collection = BaseCollection.collection_class(name, self)
        current_collection.set_base_class(self.base_class)
        current_collection.with_id!(opts.delete(:with_id)) if opts.has_key? :with_id
        current_collection.no_member! if opts.has_key? :no_member
        current_collection.generate(name, self, &block)
        @collections << current_collection
      end

      def self.parent_routes
        return '' if @parent_collection.nil?
        route = ["#{@parent_collection.collection_name}"]
        current_parent = @parent_collection
        while current_parent = current_parent.parent_collection
          route << current_parent.collection_name
        end
        route.reverse.join('/')+'/'
      end

      def self.set_base_class(klass)
        @klass = klass
      end

      def self.control(*args)
        raise "The 'control' statement must be used only within context of Operation"
      end

      def self.features
        return [] unless base_class.respond_to? :features
        base_class.features.select { |f| f.collection == collection_name }
      end

      def self.feature(name)
        features.find { |f| f.name == name }
      end

      def self.with_id!(id)
        @with_id = ":#{id}"
      end

      def self.no_member!
        @no_member = true
      end

      def self.path
        with_id_param = @with_id.nil? ? '' : ':id' + (@no_member ? '' : '/')
        parent_routes + with_id_param + ((@no_member) ? '' :  collection_name.to_s)
      end

      def self.base_class;@klass;end
      def self.full_path;root_path + route_for(path);end
      def self.collection_name; @collection_name; end
      def self.parent_collection; @parent_collection; end
      def self.collections; @collections; end

      def self.description(text=nil)
        return @description if text.nil?
        @description = text
      end

      def self.documentation
        Rabbit::Documentation.for_collection(self, operations)
      end


      def self.operation(operation_name, opts={}, &block)
        @operations ||= []
        # Return operation when no block is given
        return @operations.find { |o| o.operation_name == operation_name } unless block_given?

        # Check if current operation is not already registred
        if operation_registred?(operation_name)
          raise "Operation #{operation_name} already registered in #{self.name} collection"
        end

        # Create operation class
        operation = operation_class(self, operation_name).generate(self, operation_name, opts, &block)
        @operations << operation

        # Generate HEAD routes
        unless Rabbit.disabled? :head_routes
          send(:head, root_path + route_for(path, operation_name, {})) { status 200 }
        end

        # Add route conditions if defined
        if opts.has_key? :if
          base_class.send(:set, :if_true) do |value|
            condition do
              (value.kind_of?(Proc) ? value.call : value) == true
            end
          end
          opts[:if_true] = opts.delete(:if)
        end

        # Make the full_path method on operation return currect operation path
        operation.set_route(root_path + route_for(path, operation_name, :id_name => @with_id || ':id'))

        # Change the HTTP method to POST automatically for 'action' operations
        if opts[:http_method]
          operation.http_method(opts.delete(:http_method))
        end

        # Define Sinatra::Base route
        route_options = opts.clone
        route_options.delete :with_capability
        base_class.send(operation.http_method || http_method_for(operation_name), operation.full_path, route_options, &operation.control)

        # Generate OPTIONS routes
        unless Rabbit.disabled? :options_routes
          send(:options, root_path + route_for(path, operation_name, :member), {}) do
            [200, { 'Allow' => operation.params.map { |p| p.to_s }.join(',') }, '']
          end
        end
        self
      end

      def self.action(action_name, opts={}, &block)
        opts.merge!(:http_method => :post) unless opts[:http_method]
        operation(action_name, opts, &block)
      end

      def self.operations; @operations; end

      class Operation

        def self.set_route(path)
          @operation_path = path
        end

        def self.http_method(method=nil)
          @method ||= method || BaseCollection.http_method_for(@name)
        end

        def self.generate(collection, name, opts={}, &block)
          @name, @params, @collection = name, [], collection
          @options = opts
          http_method(@options.delete(:http_method)) if @options.has_key? :http_method
          @collection.features.select { |f| f.operations.map { |o| o.name}.include?(@name) }.each do |feature|
            if Sinatra::Rabbit.configuration[:check_features]
              next unless Sinatra::Rabbit.configuration[:check_features].call(collection.collection_name, feature.name)
            end
            feature.operations.each do |o|
              instance_eval(&o.params)
            end
          end
          if Sinatra::Rabbit::STANDARD_OPERATIONS.has_key? name
            required_params = Sinatra::Rabbit::STANDARD_OPERATIONS[name][:required_params]
            required_params.each do |p|
              param p, :required, :string, "The #{p} parameter"
            end unless required_params.nil?
          end
          class_eval(&block)
          description "#{name.to_s.capitalize} operation on #{@collection.name} collection" if description.nil?
          self
        end

        def self.full_path; @operation_path; end
        def self.operation_name; @name; end

        def self.has_capability?
          @capability ||= Sinatra::Rabbit.configuration[:check_capability]
          if @capability and @options.has_key?(:with_capability)
            @capability.call(@options[:with_capability])
          else
            true
          end
        end

        def self.description(text=nil)
          return @description if text.nil?
          @description = text
        end

        def self.control(&block)
          params_def = @params
          if not has_capability?
            @control = Proc.new { [412, {}, "The required capability to execute this operation is missing"] }
          else
            @control ||= Proc.new do
              begin
                Rabbit::Validator.validate!(params, params_def)
              rescue => e
                if e.kind_of? Rabbit::Validator::ValidationError
                  halt e.http_status_code, e.message
                else
                  raise e
                end
              end
              instance_eval(&block)
            end
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
          collection_klass.const_get(operation_name.to_s.camelize + 'Operation')
        rescue NameError
          collection_klass.const_set(operation_name.to_s.camelize + 'Operation', Class.new(Operation))
        end
      end

    end
  end
end

