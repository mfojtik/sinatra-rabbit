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
    class Feature
      attr_reader :name
      attr_reader :description
      attr_reader :collection
      attr_reader :operations
      attr_reader :constraints

      def initialize(name, opts={}, &block)
        @name = name
        @operations = []
        @collection = opts[:for]
        @constraints = {}
        raise "Each feature must define collection for which it will be valid using :for parameter" unless @collection
        instance_eval(&block) if block_given?
      end

      def operation(name, &block)
        @operations << Operation.new(name, &block) if block_given?
        @operations.find { |o| o.name == name }
      end

      def description(s=nil)
        @description ||= s
      end

      def constraint(name, value)
        @constraints[name] = value
      end

      class Operation
        attr_reader :name
        attr_reader :params

        def initialize(name, &block)
          @name = name
          @params = block
        end

        def params_array
          @p_arr = []
          instance_eval(&self.params)
          @p_arr
        end

        def param(*args)
          @p_arr << Rabbit::Param.new(*args)
        end

      end
    end

    module Features

      def features(&block)
        return @features || [] unless block_given?
        @features ||= []
        instance_eval(&block)
        @features
      end

      def feature(name, opts={}, &block)
        feature = @features.find { |f| f.name == name }
        return feature unless block_given?
        if feature
          feature.instance_eval(&block)
        else
          @features << Feature.new(name, opts, &block) if block_given?
        end
        @features.find { |f| f.name == name }
      end

      def self.included(base)
        base.register(Features) if base.respond_to? :register
      end

    end

  end
end
