module Napkin
  module Helpers
    def handle_request (path, request, user)
      content_type 'text/plain'
      segments = path.split('/')
      response_text = "#{path} #{request.method} #{request} #{user}\n"
      return response_text
    end

    class Authenticator
      def check(username, password)
        return username == password
      end
    end
  end
end
