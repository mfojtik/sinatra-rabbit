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
    module Validator

      class ValidationError < StandardError
        attr_reader :http_status_code
        def initialize(code, message)
          @http_status_code = code
          super(message)
        end
      end

      class RequiredParameter < ValidationError
        def initialize(param_def, current_params)
          super(400, "Required parameter '%s' not found in [%s]" % [param_def.name, current_params.keys.join(',')])
        end
      end

      class InvalidValue < ValidationError
        def initialize(param_def, current_value)
          super(400, "Parameter '%s' value '%s' not found in list of allowed values [%s]" % [param_def.name,
                                                                                      current_value, 
                                                                                      param_def.values.join(',')]
               )
        end
      end

      def self.validate!(current_params, operation_params)
        operation_params.select { |p| p.required? }.each do |p|
          unless current_params.keys.include?(p.name.to_s)
            raise RequiredParameter.new(p, current_params)
          end
        end
        operation_params.select { |p| p.enum? }.each do |p|
          if p.enum? and !p.values.include?(current_params[p.name.to_s])
            raise InvalidValue.new(p, current_params[p.name.to_s])
          end
        end
      end

    end
  end
end
