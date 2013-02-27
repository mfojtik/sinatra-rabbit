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

require 'haml'
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
      configuration[:root_path] ||= '/'
      base.register(Rabbit::DSL) if base.respond_to? :register
      if configuration[:use_namespace]
        configuration[:base_module] = const_get(base.name.split('::').first)
      end
      base.get '/docs' do
        css_file = File.read(File.join(File.dirname(__FILE__), '..', 'docs', 'bootstrap.min.css'))
        index_file = File.read(File.join(File.dirname(__FILE__), '..', 'docs', 'api.haml'))
        haml index_file, :locals => { :base => base.respond_to?(:documentation_class) ? base.documentation_class : base, :css => css_file }
      end
    end

    class Collection < BaseCollection

      include Rabbit::DSL

      def self.generate(name, parent_collection=nil, &block)
        @collection_name = name.to_sym
        @parent_collection = parent_collection
        class_eval(&block)
        generate_head_route unless Rabbit.disabled? :head_routes
        generate_options_route unless Rabbit.disabled? :options_routes
        generate_docs_route unless Rabbit.disabled? :docs
        self
      end

      def self.generate_options_route
        methods = (['OPTIONS'] + operations.map { |o| o.http_method.to_s.upcase }).uniq.join(',')
        base_class.options full_path do
          headers 'Allow' => methods
          status 200
        end
      end

      def self.generate_head_route
        base_class.head full_path do
          status 200
        end
      end

      def self.docs_url
        root_path  + 'docs/' + route_for(path)
      end

      def self.generate_docs_route
        collection = self
        base_class.get docs_url do
          css_file = File.read(File.join(File.dirname(__FILE__), '..', 'docs', 'bootstrap.min.css'))
          collection_file = File.read(File.join(File.dirname(__FILE__), '..', 'docs', 'collection.haml'))
          haml collection_file, :locals => { :collection => collection, :css => css_file }
        end
      end

      # Define new collection using the name
      #
      # opts[:with_id]  Define :id used if the collection is a subcollection
      #
      def self.collection(name, opts={}, &block)
        return collections.find { |c| c.collection_name == name } if not block_given?
        new_collection = BaseCollection.collection_class(name, self) do |c|
          c.base_class = self.base_class
          c.with_id!(opts.delete(:with_id)) if opts.has_key?(:with_id)
          c.no_member! if opts.has_key?(:no_member)
          c.generate(name, self, &block)
        end
        collections << new_collection
      end

      def self.parent_routes
        return '' if @parent_collection.nil?
        route = [ @parent_collection.collection_name.to_s ]
        current_parent = @parent_collection
        while current_parent = current_parent.parent_collection
          route << current_parent.collection_name
        end
        route.reverse.join('/')+'/'
      end

      def self.base_class=(klass)
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

      def self.base_class
        @klass
      end

      def self.collection_name; @collection_name; end
      def self.parent_collection; @parent_collection; end

      def self.subcollection?
        !parent_collection.nil?
      end

      def self.collections
        @collections ||= []
      end

      def self.full_path
        root_path + route_for(path)
      end

      def self.description(text=nil)
        return @description if text.nil?
        @description = text
      end

      def self.[](obj_id)
        collections.find { |c| c.collection_name == obj_id } || operation(obj_id)
      end

      def self.operation(operation_name, opts={}, &block)
        # Return operation when no block is given
        return operations.find { |o| o.operation_name == operation_name } unless block_given?

        # Check if current operation is not already registred
        if operation_registred?(operation_name)
          raise "Operation #{operation_name} already registered in #{self.name} collection"
        end

        # Create operation class
        new_operation = operation_class(self, operation_name).generate(self, operation_name, opts, &block)
        operations << new_operation

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
        new_operation.route = root_path + route_for(path, operation_name, :id_name => @with_id || ':id')

        # Change the HTTP method to POST automatically for 'action' operations
        new_operation.http_method = opts.delete(:http_method) if opts[:http_method]

        # Remove :with_capability from Sinatra route options
        route_options = opts.clone
        route_options.delete :with_capability

        # Define Sinatra route and generate OPTIONS route if enabled
        base_class.send(new_operation.http_method || http_method_for(operation_name), new_operation.full_path, route_options, &new_operation.control)

        new_operation.generate_options_route(root_path + route_for(path, operation_name, :no_id_and_member)) unless Rabbit.disabled?(:options_routes)
        new_operation.generate_head_route(root_path + route_for(path, operation_name, :member)) unless Rabbit.disabled?(:head_routes)
        new_operation.generate_docs_route(new_operation.docs_url) unless Rabbit.disabled?(:doc_routes)
        self
      end

      def self.action(action_name, opts={}, &block)
        opts.merge!(:http_method => :post) unless opts[:http_method]
        operation(action_name, opts, &block)
      end

      def self.operations
        @operations ||= []
      end

      def self.features_for(operation_name)
        features.select { |f| f.operations.map { |o| o.name}.include?(operation_name) }
      end

      class Operation < BaseCollection

        def self.docs_url
          @collection.root_path + ['docs', @collection.collection_name, operation_name].join('/')
        end

        def self.route=(path)
          @operation_path = path
        end

        def self.http_method
          @method ||= BaseCollection.http_method_for(@name)
        end

        def self.http_method=(method)
          @method = method
        end

        def self.generate_head_route(path)
          @collection.base_class.head path do
            status 200
          end
        end

        def self.generate_docs_route(path)
          operation = self
          collection = @collection
          @collection.base_class.get path do
            css_file = File.read(File.join(File.dirname(__FILE__), '..', 'docs', 'bootstrap.min.css'))
            operation_file = File.read(File.join(File.dirname(__FILE__), '..', 'docs', 'operation.haml'))
            haml operation_file, :locals => {
              :css => css_file,
              :operation => operation,
              :collection => collection
            }
          end
        end

        def self.generate_options_route(path)
          operation_params = params.map { |p| p.to_s }.join(',')
          @collection.base_class.options path do
            headers 'Allow' => operation_params
            status 200
          end
        end

        def self.features
          @collection.features_for(operation_name)
        end

        def self.features_params
          features.map { |f| f.operations.map { |o| o.params_array } }.flatten
        end

        def self.generate(collection, name, opts={}, &block)
          @name, @params, @collection = name, [], collection
          @options = opts

          if @options.has_key?(:http_method)
            @method = @options.delete(:http_method)
          end

          features.each do |feature|
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
              param p, :string, :required, "The #{p} parameter"
            end unless required_params.nil?
          end
          class_eval(&block)
          description "#{name.to_s.capitalize} operation on #{@collection.name} collection" if description.nil?
          self
        end

        def self.full_path; @operation_path; end
        def self.operation_name; @name; end

        def self.required_capability
          @options[:with_capability]
        end

        def self.description(text=nil)
          @description ||= text
        end

        # TODO: This method is here only to maintain 'backward' compatibility
        #
        def self.has_capability?
          true
        end

        def self.control(&block)
          params_def = @params
          klass = self
          @control ||= Proc.new {
            if settings.respond_to?(:capability) and !settings.capability(klass.required_capability)
              halt([412, { 'Expect' => klass.required_capability.to_s }, "The required capability to execute this operation is missing"])
            end
            begin
              Rabbit::Validator.validate!(params, params_def)
            rescue => e
              if e.kind_of? Rabbit::Validator::ValidationError
                halt e.http_status_code, e.message
              else
                raise e
              end
            end
            instance_eval(&block) if block_given?
          }
        end

        def self.param(*args)
          return @params.find { |p| p.name == args[0] } if args.size == 1
          @params << Rabbit::Param.new(*args)
        end

        def self.params; @params; end
      end

      private

      def self.operation_registred?(name)
        operations.any? { |o| o.name == name }
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

