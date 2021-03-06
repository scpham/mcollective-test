module MCollective
  module Test
    module Matchers
      def have_data_items(*items); RPCResultItems.new(items);end

      class RPCResultItems
        def initialize(expected)
          @expected = expected
          @actual = []
        end

        def matches?(actual)
          # Data::Result has a bug in it's method missing in < 2.2.2 and < 2.3.0
          # which raised the wrong exception class should someone call for example
          # #to_ary like [x].flatten does causing the tests to fail, this works
          # around that bug while we fix it in core.
          unless actual.is_a?(Array)
            actual = [actual]
          end

          if actual == []
            return false
          end

          actual.each do |result|
            if result.is_a?(MCollective::RPC::Result)
              result = result.results
            elsif result.is_a?(MCollective::Data::Result)
              result = {:data => result.instance_variable_get("@data")}
            end

            @nodeid = result[:data][:test_sender]
            @actual << result
            @expected.each do |e|
              if e.is_a? Hash
                e.keys.each do |k|
                  unless result[:data].keys.include?(k)
                    return false
                  end
                end
                e.keys.each do |k|
                  if e[k].is_a?(String) || e[k].is_a?(Regexp)
                    unless result[:data][k].match e[k]
                      return false
                    end
                  else
                    unless result[:data][k] == e[k]
                      return false
                    end
                  end
                end
              else
                unless result[:data].keys.include? e
                  return false
                end
              end
            end
          end
          true
        end

        def failure_message
          return_string = "Failure from #{@nodeid}\n"
          return_string << "Expected : \n"
          @expected.each do |e|
            if e.is_a? Hash
              e.keys.each do |k|
                return_string << " '#{k}' with value '#{e[k]}'\n"
              end
            else
              return_string << " '#{e}' to be present\n"
            end
          end

          return_string << "Got : \n"
          @actual.each do |a|
            if a[:sender] == @nodeid
              a[:data].each do |data|
                return_string << " '#{data[0]}' with value '#{data[1]}'\n"
              end
            end
          end

          return_string
        end

        def negative_failure_message
          return_string = "Failure from #{@nodeid}\n"
          return_string << "Did not expect : \n"
          @expected.each do |e|
            if e.is_a? Hash
              e.keys.each do |k|
                return_string << " '#{k}' with value '#{e[k]}'\n"
              end
            else
              return_string << " '#{e}' to not be present\n"
            end
          end

          return_string << "But got : \n"
          @actual.each do |a|
            if a[:sender] == @nodeid
              a[:data].each do |data|
                return_string << " '#{data[0]}' with value '#{data[1]}'\n"
              end
            end
          end

          return_string
        end

      end
    end
  end
end
