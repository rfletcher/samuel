module Samuel
  module DriverPatches

    module NetHTTP
      def self.included(klass)
        methods_to_wrap = %w(request connect)
        methods_to_wrap.each do |method|
          klass.send(:alias_method, "#{method}_without_samuel", method)
          klass.send(:alias_method, method, "#{method}_with_samuel")
        end
      end

      def request_with_samuel(request, body = nil, &block)
        if !started?
          request_without_samuel(request, body, &block)
        else
          request_time, response, exception_raised = Time.now, nil, false
          begin
            response = request_without_samuel(request, body, &block)
          rescue Exception => response
            exception_raised = true
          end

          Samuel::Diary.record_request(self, request, request_time)
          Samuel::Diary.record_response(self, request, response, Time.now)

          raise response if exception_raised
          response
        end
      end

      def connect_with_samuel
        connect_without_samuel
      rescue Exception => response
        fake_request = Object.new
        def fake_request.path; ""; end
        def fake_request.method; "CONNECT"; end
        Samuel::Diary.record_request(self, fake_request, Time.now)
        Samuel::Diary.record_response(self, fake_request, response, Time.now)
        raise
      end
    end

  end
end
