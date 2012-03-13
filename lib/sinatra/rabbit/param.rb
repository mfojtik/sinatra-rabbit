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
    class Param
      attr_reader :name, :klass, :required, :values, :description

      def initialize(*args)
        args.reverse!
        @name, @klass = args.pop, args.pop
        raise "DSL: You need to specify the name and param type (#{@name})" unless @name or @klass
        parse_params!(args)
        @description ||= "Description not available"
      end

      def required?; @required == true; end
      def optional?; !required?; end
      def enum?; !@values.nil?; end
      def number?; [:integer, :float, :number].include?(@klass); end
      def string?; @klass == :string; end

      def to_s
        "#{name}:#{klass}:#{required? ? 'required' : 'optional'}"
      end

      private

      def parse_params!(args)
        @values = args.pop if args.last.kind_of? Array
        @required = args.pop == :required if [:required, :optional].include? args.last
        @description = args.pop
      end

    end

  end
end
